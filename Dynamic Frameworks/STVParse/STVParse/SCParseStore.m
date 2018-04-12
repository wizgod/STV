/*
 *  SCParseStore.m
 *  Sensible TableView
 *  Version: 5.4.0
 *
 *
 *	THIS SOURCE CODE AND ANY ACCOMPANYING DOCUMENTATION ARE PROTECTED BY UNITED STATES
 *	INTELLECTUAL PROPERTY LAW AND INTERNATIONAL TREATIES. UNAUTHORIZED REPRODUCTION OR
 *	DISTRIBUTION IS SUBJECT TO CIVIL AND CRIMINAL PENALTIES. YOU SHALL NOT DEVELOP NOR
 *	MAKE AVAILABLE ANY WORK THAT COMPETES WITH A SENSIBLE COCOA PRODUCT DERIVED FROM THIS
 *	SOURCE CODE. THIS SOURCE CODE MAY NOT BE RESOLD OR REDISTRIBUTED ON A STAND ALONE BASIS.
 *
 *	USAGE OF THIS SOURCE CODE IS BOUND BY THE LICENSE AGREEMENT PROVIDED WITH THE
 *	DOWNLOADED PRODUCT.
 *
 *  Copyright 2011-2015 Sensible Cocoa. All rights reserved.
 *
 *
 *	This notice may not be removed from this file.
 *
 */

#import "SCParseStore.h"



@interface SCParseStore ()
{
    PFRelation *_boundRelation;
}

@end


@implementation SCParseStore

+ (instancetype)storeWithDefaultParseDefinition:(SCParseDefinition *)definition
{
    return [[[self class] alloc] initWithDefaultParseDefinition:definition];
}


- (instancetype)init
{
    if( (self = [super init]) )
    {
        self.storeMode = SCStoreModeAsynchronous;
        
        self.supportsNilValues = NO;
    }
    return self;
}

- (instancetype)initWithDefaultParseDefinition:(SCParseDefinition *)definition
{
    if( (self=[self initWithDefaultDataDefinition:definition]) )
    {
        // further initialization here
    }
    return self;
}


- (void)setValue:(NSObject *)value forPropertyName:(NSString *)propertyName inObject:(NSObject *)object
{
    if(value && ![value isEqual:[NSNull null]])
    {
        [super setValue:value forPropertyName:propertyName inObject:object];
    }
    else
    {
        PFObject *parseObject = (PFObject *)object;
        [parseObject removeObjectForKey:propertyName];
    }
}


- (SCParseDefinition *)defaultParseDefinition
{
    SCParseDefinition *definition = nil;
    if([self.defaultDataDefinition isKindOfClass:[SCParseDefinition class]])
        definition = (SCParseDefinition *)self.defaultDataDefinition;
    
    return definition;
}


- (void)setParseAppIdAndCliendKeyForObject:(PFObject *)object
{
    if(![[Parse getApplicationId] length])
    {
        SCParseDefinition *definition = (SCParseDefinition *)[self definitionForObject:object];
        if([definition.applicationId length] && [definition.clientKey length])
            [Parse setApplicationId:definition.applicationId clientKey:definition.clientKey];
    }
}


// overrides superclass
- (SCDataDefinition *)definitionForObject:(NSObject *)object
{
    if(![object isKindOfClass:[PFObject class]])
        return nil;
    
    PFObject *parseObject = (PFObject *)object;
    SCDataDefinition *definition = [_dataDefinitions valueForKey:parseObject.parseClassName];
    
    if(![definition isKindOfClass:[SCParseDefinition class]])
        return nil;
    //else
    return definition;
}

// overrides superclass
- (void)bindStoreToPropertyName:(NSString *)propertyName forObject:(NSObject *)object withDefinition:(SCDataDefinition *)definition
{
    [super bindStoreToPropertyName:propertyName forObject:object withDefinition:definition];
    
    if(![object isKindOfClass:[PFObject class]])
    {
        SCDebugLog(@"Error: SCParseStore - Unexcpected object type! Expecting 'PFObject' or subclass but got %@ instead.", object);
        return;
    }
    
    PFObject *parseObject = (PFObject *)object;
    PFRelation *relation = [parseObject relationForKey:propertyName];
    if(relation)
    {
        _boundRelation = relation;
    }
    else
    {
        _boundRelation = nil;
        
        SCParseDefinition *parseDefinition = nil;
        if([definition isKindOfClass:[SCParseDefinition class]])
            parseDefinition = (SCParseDefinition *)definition;
        SCDebugLog(@"Warning: SCParseStore - Relationship with name:'%@' in Parse class:'%@' is not of type 'Relation'", propertyName, parseDefinition.className);
    }
}


// overrides superclass
- (NSObject *)createNewObjectWithDefinition:(SCDataDefinition *)definition
{
    if(![definition isKindOfClass:[SCParseDefinition class]])
        return nil;
    
    SCParseDefinition *parseDefinition = (SCParseDefinition *)definition;
    
    if(!parseDefinition.className)
    {
        SCDebugLog(@"Warning: className not set for definition: %@, ibName: '%@'", parseDefinition, parseDefinition.ibName);
        
        return nil;
    }
    
    [self addDataDefinition:parseDefinition];
    
    PFObject *parseObject = [[PFObject alloc] initWithClassName:parseDefinition.className];
    if(parseDefinition.accessControl == SCParseAccessControlCurrentUser)
        parseObject.ACL = [PFACL ACLWithUser:[PFUser currentUser]];
    
    [_uninsertedObjects addObject:parseObject];
    
    return parseObject;
}

// overrides superclass
- (BOOL)discardUninsertedObject:(NSObject *)object
{
    [_uninsertedObjects removeObjectIdenticalTo:object];
    
    return TRUE;
}

// overrides superclass
- (void)asynchronousInsertObject:(NSObject *)object success:(SCDataStoreInsertSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    PFObject *parseObject = (PFObject *)object;
    [self setParseAppIdAndCliendKeyForObject:parseObject];
    
    PFRelation *relation = _boundRelation;  // to avoid unnecessarily retaining self in block
    if([SCUtilities IsInternetConnectionAvailable])
    {
        [parseObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if(succeeded)
             {
                 if(relation)
                     [relation addObject:(PFObject *)object];
                 
                 if(success_block)
                     success_block();
             }
             else
             {
                 if(failure_block)
                     failure_block(error);
             }
         }];
    }
    else
    {
        BOOL tryAgainLater = YES;
        if(noConnection_block)
            tryAgainLater = noConnection_block();
        
        if(tryAgainLater)
        {
            [parseObject saveEventually:^(BOOL succeeded, NSError *error)
             {
                 if(succeeded)
                 {
                     if(relation)
                         [relation addObject:(PFObject *)object];
                     
                     if(success_block)
                         success_block();
                 }
                 else
                 {
                     if(failure_block)
                         failure_block(error);
                 }
             }];
        }
        else
        {
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
    }
}

// overrides superclass
- (void)asynchronousUpdateObject:(NSObject *)object success:(SCDataStoreUpdateSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    PFObject *parseObject = (PFObject *)object;
    [self setParseAppIdAndCliendKeyForObject:parseObject];
    
    if([SCUtilities IsInternetConnectionAvailable])
    {
        [parseObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if(succeeded)
             {
                 if(success_block)
                     success_block();
             }
             else
             {
                 if(failure_block)
                     failure_block(error);
             }
         }];
    }
    else
    {
        BOOL tryAgainLater = YES;
        if(noConnection_block)
            tryAgainLater = noConnection_block();
        
        if(tryAgainLater)
        {
            [parseObject saveEventually:^(BOOL succeeded, NSError *error)
             {
                 if(succeeded)
                 {
                     if(success_block)
                         success_block();
                 }
                 else
                 {
                     if(failure_block)
                         failure_block(error);
                 }
             }];
        }
        else
        {
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
    }
}

// overrides superclass
- (void)asynchronousDeleteObject:(NSObject *)object success:(SCDataStoreDeleteSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    PFObject *parseObject = (PFObject *)object;
    if(!_boundRelation)
    {
        parseObject = (PFObject *)object;
    }
    else
    {
        parseObject = (PFObject *)_boundObject;
        [_boundRelation removeObject:(PFObject *)object];
    }
    
    [self setParseAppIdAndCliendKeyForObject:parseObject];
    
    if([SCUtilities IsInternetConnectionAvailable])
    {
        [parseObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if(succeeded)
             {
                 if(success_block)
                     success_block();
             }
             else
             {
                 if(failure_block)
                     failure_block(error);
             }
         }];
    }
    else
    {
        BOOL tryAgainLater = YES;
        if(noConnection_block)
            tryAgainLater = noConnection_block();
        
        if(tryAgainLater)
        {
            
            [parseObject deleteEventually]; // Parse API does not yet support [deleteEventually:block]
            if(success_block)
                success_block();
        }
        else
        {
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
    }
}

// overrides superclass
- (void)asynchronousFetchObjectsWithOptions:(SCDataFetchOptions *)fetchOptions success:(SCDataStoreFetchSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    if(![[Parse getApplicationId] length])
    {
        if(!self.defaultParseDefinition.applicationId)
        {
            SCDebugLog(@"Warning: applicationId not set for definition: %@, ibName: '%@'", self.defaultParseDefinition, self.defaultParseDefinition.ibName);
            
            if(failure_block)
                failure_block([NSError errorWithDomain:@"Parse applicationId not set" code:0 userInfo:nil]);
            
            return;
        }
        
        if(!self.defaultParseDefinition.clientKey)
        {
            SCDebugLog(@"Warning: clientKey not set for definition: %@, ibName: '%@'", self.defaultParseDefinition, self.defaultParseDefinition.ibName);
            
            if(failure_block)
                failure_block([NSError errorWithDomain:@"Parse clientKey not set" code:0 userInfo:nil]);
            
            return;
        }
        
        [Parse setApplicationId:self.defaultParseDefinition.applicationId clientKey:self.defaultParseDefinition.clientKey];
    }
    
    
    if([SCUtilities IsInternetConnectionAvailable])
    {
        if(!self.fetchObjectsCloudCodeFunctionName)
        {
            [self asynchronousFetchObjectsUsingQueryWithOptions:fetchOptions success:success_block failure:failure_block];
        }
        else
        {
            [self asynchronousFetchObjectsUsingCloudCodeWithOptions:fetchOptions success:success_block failure:failure_block];
        }
    }
    else
    {
        BOOL tryAgainLater = YES;
        if(noConnection_block)
            tryAgainLater = noConnection_block();
        
        if(tryAgainLater)
        {
            // tryAgainLater not yet supported by Parse queries
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
        else
        {
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
    }
}

- (void)asynchronousFetchObjectsUsingQueryWithOptions:(SCDataFetchOptions *)fetchOptions success:(SCDataStoreFetchSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block
{
    NSPredicate *filterPredicate = nil;
    if(fetchOptions.filter)
        filterPredicate = fetchOptions.filterPredicate;
    
    PFQuery *query;
    if(!_boundRelation)
    {
        query = [PFQuery queryWithClassName:self.defaultParseDefinition.className predicate:filterPredicate];
    }
    else
    {
        query = [_boundRelation query];
        
        // apply filterPredicate after objects are fetched, since PFQuery does not yet support assigning a predicate after creation
    }
    
    if(!query)
    {
        SCDebugLog(@"Warning: SCParseStore - unexpected unable to initiate PFQuery.");
        if(failure_block)
            failure_block([NSError errorWithDomain:@"Unable to initiate PFQuery" code:0 userInfo:nil]);
        
        return;
    }
    
    if(fetchOptions.sort)
    {
        if(fetchOptions.sortAscending)
            [query orderByAscending:fetchOptions.sortKey];
        else
            [query orderByDescending:fetchOptions.sortKey];
    }
    if(fetchOptions.batchSize)
    {
        query.limit = fetchOptions.batchSize;
        query.skip = fetchOptions.nextBatchStartIndex;
    }
    
    [self addIncludeKeysForQuery:query];
    
    if(self.queryConfiguredAction)
        query = self.queryConfiguredAction(query);
    
    if(query)
    {
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             if (!error)
             {
                 if(filterPredicate && _boundRelation)
                 {
                     // apply the filterPredicate
                     objects = [objects filteredArrayUsingPredicate:filterPredicate];
                 }
                 
                 [self fetchObjectsSuccessful:objects successBlock:success_block failure:failure_block];
             }
             else
             {
                 if(failure_block)
                     failure_block(error);
             }
         }];
    }
    else
    {
        [self fetchObjectsSuccessful:[NSArray array] successBlock:success_block failure:failure_block];  // empty array
    }
}

- (void)asynchronousFetchObjectsUsingCloudCodeWithOptions:(SCDataFetchOptions *)fetchOptions success:(SCDataStoreFetchSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block
{
    NSDictionary *parameters = nil;
    if(self.fetchObjectsCloudCodeFunctionParametersAction)
        parameters = self.fetchObjectsCloudCodeFunctionParametersAction();
    
    [PFCloud callFunctionInBackground:self.fetchObjectsCloudCodeFunctionName
                       withParameters:parameters
                                block:^(id objects, NSError *error)
     {
         if (!error)
         {
             [self fetchObjectsSuccessful:objects successBlock:success_block failure:failure_block];
         }
         else
         {
             if(failure_block)
                 failure_block(error);
         }
     }];
}


- (void)addIncludeKeysForQuery:(PFQuery *)query
{
    // Auto detect include keys based on the data definition
    NSMutableArray *includeKeys = [NSMutableArray array];
    SCParseDefinition *parseDefinition = [self defaultParseDefinition];
    for(NSInteger i=0; i<parseDefinition.propertyDefinitionCount; i++)
    {
        SCPropertyDefinition *propertyDefintion = [parseDefinition propertyDefinitionAtIndex:i];
        switch (propertyDefintion.type)
        {
            case SCPropertyTypeArrayOfObjects:
            case SCPropertyTypeObject:
            case SCPropertyTypeObjectSelection:
            case SCPropertyTypeCustom:
                [includeKeys addObject:propertyDefintion.name];
                break;
                
            default:
                break;
        }
    }
    
    for(NSString *key in includeKeys)
        [query includeKey:key];
}

// overrides superclass
- (BOOL)validateInsertForObject:(NSObject *)object
{
    return TRUE;
}

// overrides superclass
- (BOOL)validateUpdateForObject:(NSObject *)object
{
    return TRUE;
}

// overrides superclass
- (BOOL)validateDeleteForObject:(NSObject *)object
{
    return TRUE;
}

// overrides superclass
- (BOOL)validateOrderChangeForObject:(NSObject *)object
{
    return FALSE;
}

@end
