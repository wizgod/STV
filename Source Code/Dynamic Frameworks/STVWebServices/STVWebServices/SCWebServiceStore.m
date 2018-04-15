/*
 *  SCWebServiceStore.m
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


#import "SCWebServiceStore.h"

#import "SCWebServiceFetchOptions.h"
#import "SCWebServiceDefinition.h"



// Define RUN_ON_MAIN_THREAD macro

#define RUN_ON_MAIN_THREAD(CODE)   dispatch_async(dispatch_get_main_queue(), ^{CODE;})



@interface SCWebServiceStore ()

@property (nonatomic, strong, readonly) SCWebServiceDefinition *defaultWebServiceDefinition;

@property (nonatomic, strong) NSURLSessionDataTask *sessionDataTask;

@end



@implementation SCWebServiceStore

+ (instancetype)storeWithDefaultWebServiceDefinition:(SCWebServiceDefinition *)definition
{
    return [[[self class] alloc] initWithDefaultWebServiceDefinition:definition];
}


- (instancetype)init
{
	if( (self = [super init]) )
	{
        _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        self.storeMode = SCStoreModeAsynchronous;
	}
	return self;
}

- (instancetype)initWithDefaultWebServiceDefinition:(SCWebServiceDefinition *)definition
{
    if( (self=[self initWithDefaultDataDefinition:definition]) )
    {
        // further initialization here
    }
    return self;
}


- (SCWebServiceDefinition *)defaultWebServiceDefinition
{
    SCWebServiceDefinition *definition = nil;
    if([self.defaultDataDefinition isKindOfClass:[SCWebServiceDefinition class]])
        definition = (SCWebServiceDefinition *)self.defaultDataDefinition;
    
    return definition;
}

- (void)setDefaultDataDefinition:(SCDataDefinition *)definition
{
    [super setDefaultDataDefinition:definition];
    
    // futher settings
}

// overrides superclass
- (NSObject *)createNewObjectWithDefinition:(SCDataDefinition *)definition
{
    [self addDataDefinition:definition];
    
    NSMutableDictionary *object = [NSMutableDictionary dictionary];
    [_uninsertedObjects addObject:object];
    
    return object;
}

// overrides superclass
- (BOOL)discardUninsertedObject:(NSObject *)object
{
    [_uninsertedObjects removeObjectIdenticalTo:object];
    
    return TRUE;
}

- (BOOL)validateOrderChangeForObject:(NSObject *)object
{
    return FALSE; 
}

// overrides superclass
- (void)asynchronousInsertObject:(NSObject *)object success:(SCDataStoreInsertSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    if(![SCUtilities IsInternetConnectionAvailable])
    {
        BOOL tryAgainLater = NO;
        if(noConnection_block)
            tryAgainLater = noConnection_block();
        
        if(tryAgainLater)
        {
            // try again not yet supported
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
        else
        {
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
        
        return;
    }
    
    if(!self.defaultWebServiceDefinition.insertObjectAPI)
    {
        if(failure_block)
            RUN_ON_MAIN_THREAD(failure_block(nil));
            
        SCDebugLog(@"Warning: No valid insertObjectAPI specified in SCWebServiceDefinition.");
        
        return;
    }
    
    // serialize object
    NSError *serializeError = nil;
    NSData *objectData = [NSJSONSerialization dataWithJSONObject:object options:0 error:&serializeError];
    if(serializeError)
    {
        if(failure_block)
            RUN_ON_MAIN_THREAD(failure_block(serializeError));

        SCDebugLog(@"Object serialization error during INSERT: %@.", serializeError);
        
        return;
    }
    
    // Configure the network insert call
    NSMutableURLRequest *request = [self requestWithURL:self.defaultWebServiceDefinition.insertURL httpMethod:self.defaultWebServiceDefinition.insertHTTPMethod parameters:self.defaultWebServiceDefinition.insertObjectParameters objectData:objectData];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration];
    __weak typeof(self) weak_self = self;
    self.sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            if(error)
            {
                SCDebugLog(@"Web Service error during INSERT: %@", error);
                if(failure_block)
                    RUN_ON_MAIN_THREAD(failure_block(error));
                
                return;
            }
            
            
            [_uninsertedObjects removeObjectIdenticalTo:object];
            
            id responseObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if([responseObject isKindOfClass:[NSDictionary class]] && weak_self.defaultWebServiceDefinition.objectIdKeyName)
            {
                NSString *objectId = [responseObject valueForKey:weak_self.defaultWebServiceDefinition.objectIdKeyName];
                [object setValue:objectId forKey:weak_self.defaultWebServiceDefinition.objectIdKeyName];
            }
            
            if(success_block)
                RUN_ON_MAIN_THREAD(success_block());
        }];
    
    // Intiate the network insert call
    [self.sessionDataTask resume];
}

// overrides superclass
- (void)asynchronousUpdateObject:(NSObject *)object success:(SCDataStoreUpdateSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    if(![SCUtilities IsInternetConnectionAvailable])
    {
        BOOL tryAgainLater = NO;
        if(noConnection_block)
            tryAgainLater = noConnection_block();
        
        if(tryAgainLater)
        {
            // try again not yet supported
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
        else
        {
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
        
        return;
    }
    
    if(!self.defaultWebServiceDefinition.updateObjectAPI)
    {
        if(failure_block)
            RUN_ON_MAIN_THREAD(failure_block(nil));
        SCDebugLog(@"Warning: No valid updateObjectAPI specified in SCWebServiceDefinition.");
        
        return;
    }
    
    NSString *objectId = [object valueForKey:self.defaultWebServiceDefinition.objectIdKeyName];
    if(!objectId)
    {
        if(failure_block)
        {
            SCDebugLog(@"Object update failed - no value for objectIdKeyName: %@", self.defaultWebServiceDefinition.objectIdKeyName);
            if(failure_block)
                RUN_ON_MAIN_THREAD(failure_block(nil));
            
            return;
        }
    }
    
    NSMutableDictionary *objectDictionary = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)object];
    NSArray *readOnlyKeys = [self.defaultWebServiceDefinition.readOnlyKeyNames componentsSeparatedByString:@";"];
    for(NSString *readOnlyKey in readOnlyKeys)
        [objectDictionary removeObjectForKey:readOnlyKey];
    
    // serialize object
    NSError *serializeError = nil;
    NSData *objectData = [NSJSONSerialization dataWithJSONObject:objectDictionary options:0 error:&serializeError];
    if(serializeError)
    {
        if(failure_block)
            RUN_ON_MAIN_THREAD(failure_block(serializeError));
        SCDebugLog(@"Object serialization error during UPDATE: %@.", serializeError);
        
        return;
    }
    
    // Configure the network update call
    NSString *updateURLString = [NSString stringWithFormat:@"%@/%@", [self.defaultWebServiceDefinition.updateURL absoluteString], objectId];
    NSURL *updateURL = [NSURL URLWithString:updateURLString];
    NSMutableURLRequest *request = [self requestWithURL:updateURL httpMethod:self.defaultWebServiceDefinition.updateHTTPMethod parameters:self.defaultWebServiceDefinition.updateObjectParameters objectData:objectData];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration];
    self.sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            if(error)
            {
                SCDebugLog(@"Web Service error during UPDATE: %@", error);
                if(failure_block)
                    RUN_ON_MAIN_THREAD(failure_block(error));
                
                return;
            }
            
            if(success_block)
                RUN_ON_MAIN_THREAD(success_block());
        }];
    
    // Intiate the network update call
    [self.sessionDataTask resume];
}

// overrides superclass
- (void)asynchronousDeleteObject:(NSObject *)object success:(SCDataStoreDeleteSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    if(![SCUtilities IsInternetConnectionAvailable])
    {
        BOOL tryAgainLater = NO;
        if(noConnection_block)
            tryAgainLater = noConnection_block();
        
        if(tryAgainLater)
        {
            // try again not yet supported
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
        else
        {
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
        
        return;
    }
    
    if(!self.defaultWebServiceDefinition.deleteObjectAPI)
    {
        if(failure_block)
            RUN_ON_MAIN_THREAD(failure_block(nil));
        SCDebugLog(@"Warning: No valid deleteObjectAPI specified in SCWebServiceDefinition.");
        
        return;
    }
    
    NSString *objectId = [object valueForKey:self.defaultWebServiceDefinition.objectIdKeyName];
    if(!objectId)
    {
        if(failure_block)
        {
            SCDebugLog(@"Object delete failed - no value for objectIdKeyName: %@", self.defaultWebServiceDefinition.objectIdKeyName);
            if(failure_block)
                RUN_ON_MAIN_THREAD(failure_block(nil));
            
            return;
        }
    }
    
    // Configure the network DELETE call
    NSString *deleteURLString = [NSString stringWithFormat:@"%@/%@", [self.defaultWebServiceDefinition.deleteURL absoluteString], objectId];
    NSURL *deleteURL = [NSURL URLWithString:deleteURLString];
    NSMutableURLRequest *request = [self requestWithURL:deleteURL httpMethod:@"DELETE" parameters:self.defaultWebServiceDefinition.deleteObjectParameters objectData:nil];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration];
    self.sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                            {
                                if(error)
                                {
                                    SCDebugLog(@"Web Service error during DELETE: %@", error);
                                    if(failure_block)
                                        RUN_ON_MAIN_THREAD(failure_block(error));
                                    
                                    return;
                                }
                                
                                if(success_block)
                                    RUN_ON_MAIN_THREAD(success_block());
                            }];
    
    // Intiate the network update call
    [self.sessionDataTask resume];
}

// overrides superclass
- (void)asynchronousFetchObjectsWithOptions:(SCDataFetchOptions *)fetchOptions success:(SCDataStoreFetchSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    if(![SCUtilities IsInternetConnectionAvailable])
    {
        BOOL tryAgainLater = NO;
        if(noConnection_block)
            tryAgainLater = noConnection_block();
        
        if(tryAgainLater)
        {
            // try again not yet supported
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
        else
        {
            if(failure_block)
                failure_block([NSError errorWithDomain:kNoInternetConnectionString code:0 userInfo:nil]);
        }
        
        return;
    }
    
    if(!self.defaultWebServiceDefinition.fetchObjectsAPI)
    {
        if(failure_block)
            RUN_ON_MAIN_THREAD(failure_block(nil));
        SCDebugLog(@"Error: No valid fetchObjectsAPI specified in SCWebServiceDefinition.");
        
        return;
    }
    
    SCWebServiceFetchOptions *webFetchOptions = nil;
    if([fetchOptions isKindOfClass:[SCWebServiceFetchOptions class]])
        webFetchOptions = (SCWebServiceFetchOptions *)fetchOptions;
    
    NSMutableString *path = [NSMutableString stringWithString:self.defaultWebServiceDefinition.fetchObjectsAPI];
    
    NSDictionary *parameters;
    if(webFetchOptions.nextBatchURLString)
    {
        [path appendString:webFetchOptions.nextBatchURLString];
        parameters = nil;
    }
    else 
    {
        parameters = self.defaultWebServiceDefinition.fetchObjectsParameters;
        
        if(webFetchOptions.nextBatchToken)
        {
            [parameters setValue:webFetchOptions.nextBatchToken forKey:self.defaultWebServiceDefinition.batchTokenParameterName];
        }
        else
        {
            if(self.defaultWebServiceDefinition.batchSizeParameterName && webFetchOptions.batchSize)
            {
                [parameters setValue:[NSNumber numberWithUnsignedInteger:webFetchOptions.batchSize]
                              forKey:self.defaultWebServiceDefinition.batchSizeParameterName];
            }
            if(self.defaultWebServiceDefinition.batchStartIndexParameterName)
            {
                NSUInteger nextBatchIndex = self.defaultWebServiceDefinition.batchInitialStartIndex+webFetchOptions.nextBatchStartIndex;
                [parameters setValue:[NSNumber numberWithUnsignedInteger:nextBatchIndex]
                              forKey:self.defaultWebServiceDefinition.batchStartIndexParameterName];
            }
        }
    }
    
    // Configure the network update call
    NSURL *fetchObjectsURL = [NSURL URLWithString:path relativeToURL:self.defaultWebServiceDefinition.baseURL];
    NSMutableURLRequest *request = [self requestWithURL:fetchObjectsURL httpMethod:@"GET" parameters:parameters objectData:nil];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration];
    __weak typeof(self) weak_self = self;
    self.sessionDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                            {
                                if(error)
                                {
                                    SCDebugLog(@"Web Service error during GET: %@", error);
                                    if(failure_block)
                                        RUN_ON_MAIN_THREAD(failure_block(error));
                                    
                                    return;
                                }
                                
                                NSError *JSONError;
                                id JSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
                                
                                if(JSONError)
                                {
                                    if(failure_block)
                                        RUN_ON_MAIN_THREAD(failure_block(nil));
                                    SCDebugLog(@"Error: Error while deserializing JSON data:%@", JSONError);
                                    
                                    return;
                                }
                                
                                NSArray *resultsArray = nil;
                                if([JSON isKindOfClass:[NSArray class]])
                                {
                                    resultsArray = (NSArray *)JSON;
                                }
                                else
                                {
                                    if(![JSON isKindOfClass:[NSDictionary class]])
                                    {
                                        if(failure_block)
                                            RUN_ON_MAIN_THREAD(failure_block(nil));
                                        SCDebugLog(@"Error: Invalid web service response. Expecting 'NSDictionary' but got '%@' instead.", NSStringFromClass([JSON class]));
                                        
                                        return;
                                    }
                                    
                                    if(weak_self.defaultWebServiceDefinition.nextBatchURLKeyName && webFetchOptions)
                                    {
                                        webFetchOptions.nextBatchURLString = [JSON valueForSensibleKeyPath:weak_self.defaultWebServiceDefinition.nextBatchURLKeyName];
                                        [webFetchOptions incrementBatchOffset];
                                    }
                                    else
                                        if(weak_self.defaultWebServiceDefinition.batchStartIndexParameterName && webFetchOptions)
                                        {
                                            [webFetchOptions incrementBatchOffset];
                                        }
                                        else
                                            if(weak_self.defaultWebServiceDefinition.nextBatchTokenKeyName && webFetchOptions)
                                            {
                                                webFetchOptions.nextBatchToken = [JSON valueForSensibleKeyPath:weak_self.defaultWebServiceDefinition.nextBatchTokenKeyName];
                                                [webFetchOptions incrementBatchOffset];
                                            }
                                    
                                    
                                    if(weak_self.defaultWebServiceDefinition.atomicResultKeyName)
                                    {
                                        id atomicResult = [JSON valueForSensibleKeyPath:weak_self.defaultWebServiceDefinition.atomicResultKeyName];
                                        NSArray *atomicArray;
                                        if([atomicResult isKindOfClass:[NSArray class]])
                                        {
                                            atomicArray = atomicResult;
                                        }
                                        else
                                        {
                                            atomicArray = [NSArray arrayWithObject:atomicResult];
                                        }
                                        
                                        if(weak_self.defaultWebServiceDefinition.resultsKeyName && atomicArray.count)
                                        {
                                            NSDictionary *dictionary = [atomicArray objectAtIndex:0];
                                            resultsArray = [dictionary valueForKey:weak_self.defaultWebServiceDefinition.resultsKeyName];
                                        }
                                        else
                                        {
                                            resultsArray = atomicArray;
                                        }
                                    }
                                    else
                                    {
                                        if(!weak_self.defaultWebServiceDefinition.resultsKeyName)
                                        {
                                            if(failure_block)
                                                RUN_ON_MAIN_THREAD(failure_block(nil));
                                            SCDebugLog(@"Error: Can't fetch results from web service dictionary since resultsKeyName is nil.");
                                            
                                            return;
                                        }
                                        
                                        resultsArray = [JSON valueForSensibleKeyPath:weak_self.defaultWebServiceDefinition.resultsKeyName];
                                    }
                                    
                                    if(!resultsArray)
                                    {
                                        if(failure_block)
                                            RUN_ON_MAIN_THREAD(failure_block(nil));
                                        SCDebugLog(@"Error: resultsKeyName:'%@' does not exist in returned response.", weak_self.defaultWebServiceDefinition.resultsKeyName);
                                        
                                        return;
                                    }
                                    
                                    if(![resultsArray isKindOfClass:[NSArray class]])
                                    {
                                        if(failure_block)
                                            RUN_ON_MAIN_THREAD(failure_block(nil));
                                        SCDebugLog(@"Error: Invalid web service response. Expecting results array with type 'NSArray' but got '%@' instead.", NSStringFromClass([resultsArray class]));
                                        
                                        return;
                                    }
                                }
                                
                                NSMutableArray *array = [NSMutableArray array];
                                for (NSDictionary *dictionary in resultsArray)
                                {
                                    if(![dictionary isKindOfClass:[NSDictionary class]])
                                    {
                                        if(failure_block)
                                            RUN_ON_MAIN_THREAD(failure_block(nil));
                                        SCDebugLog(@"Error: Invalid web service response. Expecting results item of type'NSDictionary' but got '%@' instead.", NSStringFromClass([dictionary class]));
                                        
                                        return;
                                    }
                                    
                                    NSMutableDictionary *webObject = [NSMutableDictionary dictionaryWithDictionary:dictionary];
                                    [array addObject:webObject];
                                }
                                
                                if(fetchOptions)
                                {
                                    [fetchOptions filterMutableArray:array];
                                    [fetchOptions sortMutableArray:array];
                                }
                                
                                if(success_block)
                                    RUN_ON_MAIN_THREAD(success_block(array));
                            }];
    
    // Intiate the network update call
    [self.sessionDataTask resume];
}

- (BOOL)validateInsertForObject:(NSObject *)object
{
    return self.defaultWebServiceDefinition.insertObjectAPI != nil;
}

- (BOOL)validateUpdateForObject:(NSObject *)object
{
    return self.defaultWebServiceDefinition.updateObjectAPI != nil;
}

- (BOOL)validateDeleteForObject:(NSObject *)object
{
    return self.defaultWebServiceDefinition.deleteObjectAPI != nil;
}

- (SCDataDefinition *)definitionForObject:(NSObject *)object
{
    return [_dataDefinitions valueForKey:[SCUtilities dataStructureNameForClass:[NSDictionary class]]];
}

- (void)bindStoreToPropertyName:(NSString *)propertyName forObject:(NSObject *)object withDefinition:(SCDataDefinition *)definition
{
    [super bindStoreToPropertyName:propertyName forObject:object withDefinition:definition];
    
    // does nothing
}



#pragma mark - Networking helper methods

- (NSMutableURLRequest *)requestWithURL:(NSURL *)url httpMethod:(NSString *)method parameters:(NSDictionary *)parameters objectData:(NSData *)data
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:method];
    [request setAllHTTPHeaderFields:self.defaultWebServiceDefinition.httpHeaders];
    
    if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"])
    {
        [request setHTTPShouldUsePipelining:YES];
    }
    
    if([parameters count])
    {
        if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"])
        {
            NSString *URLString = [url absoluteString];
            NSString *URLStringWithParameters = [URLString stringByAppendingFormat:[URLString rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", [self queryStringUsingParameters:parameters]];
            url = [NSURL URLWithString:URLStringWithParameters];
            [request setURL:url];
        }
        else
        {
            NSString *charset = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
            [request setValue:[NSString stringWithFormat:@"application/json; charset=%@", charset] forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:[[self JSONStringUsingParameters:parameters] dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    else
    {
        [request setHTTPBody:data];
    }
    
    return request;
}

- (NSString *)queryStringUsingParameters:(NSDictionary *)parameters
{
    NSMutableArray *queryComponents = [NSMutableArray array];
    for(NSString *key in parameters)
    {
        id value = [parameters valueForKey:key];
        [queryComponents addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }
    
   return [queryComponents componentsJoinedByString:@"&"];
}

- (NSString *)JSONStringUsingParameters:(NSDictionary *)parameters
{
    NSError *error = nil;
    NSData *JSONData = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:&error];
    
    if(!error)
        return [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
    //else
    return nil;
}

@end



