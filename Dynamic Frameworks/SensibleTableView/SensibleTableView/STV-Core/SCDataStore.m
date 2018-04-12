/*
 *  SCDataStore.m
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

#import "SCDataStore.h"

NSString * const SCDataStoreWillDiscardAllUninsertedObjectsNotification = @"SCDataStoreWillDiscardAllUninsertedObjectsNotification";


@implementation SCDataStore

@synthesize storeMode = _storeMode;
@synthesize storedData = _storedData;
@synthesize defaultDataDefinition = _defaultDataDefinition;
@synthesize defaultsDictionary = _defaultsDictionary;

+ (instancetype)storeWithDefaultDataDefinition:(SCDataDefinition *)definition;
{
    return [[[self class] alloc] initWithDefaultDataDefinition:definition];
}


- (instancetype)init
{
	if( (self = [super init]) )
	{
        _storeMode = SCStoreModeSynchronous;
        
        _supportsNilValues = YES;
        
        _storedData = nil;
        _defaultDataDefinition = nil;
        _dataDefinitions = [[NSMutableDictionary alloc] init];
        
        _uninsertedObjects = [[NSMutableArray alloc] init];
        _boundObject = nil;
        _boundPropertyName = nil;
        _boundObjectDefinition = nil;
        
        _defaultsDictionary = nil;
        
        // Register with UIApplication notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commitData) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commitData) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
	}
	return self;
}

- (instancetype)initWithDefaultDataDefinition:(SCDataDefinition *)definition
{
    if( (self = [self init]) )
    {
        self.defaultDataDefinition = definition;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDefaultDataDefinition:(SCDataDefinition *)definition
{
    _defaultDataDefinition = definition;
    
    [self addDataDefinition:definition];
}

- (NSObject *)createNewObject
{
    return [self createNewObjectWithDefinition:self.defaultDataDefinition];
}

- (NSObject *)createNewObjectWithDefinition:(SCDataDefinition *)definition
{
    // Subclasses must override.
    return nil;
}

- (BOOL)insertObject:(NSObject *)object
{
    // Subclasses must override.
    return FALSE;
}

- (BOOL)discardUninsertedObject:(NSObject *)object
{
    // Subclasses must override.
    return TRUE;
}

- (BOOL)insertObject:(NSObject *)object atOrder:(NSUInteger)order
{
    // Subclasses must override
    return FALSE;
}

- (BOOL)changeOrderForObject:(NSObject *)object toOrder:(NSUInteger)toOrder subsetArray:(NSArray *)subsetArray
{
    // Subclasses must override.
    return FALSE;
}

- (BOOL)updateObject:(NSObject *)object
{
    // Subclasses must override.
    return FALSE;
}

- (BOOL)deleteObject:(NSObject *)object
{
    // Subclasses must override.
    return FALSE;
}

- (NSArray *)fetchObjectsWithOptions:(SCDataFetchOptions *)fetchOptions
{
    // Subclasses must override.
    return nil;
}

- (NSObject *)valueForPropertyName:(NSString *)propertyName inObject:(NSObject *)object
{
    if([SCUtilities isBasicDataTypeClass:[object class]])
        return object;
    
    if(!propertyName)
		return nil;
	
	NSArray *propertyNames = [propertyName componentsSeparatedByString:@";"];
	NSMutableArray *valuesArray = [NSMutableArray arrayWithCapacity:propertyNames.count];
	for(NSString *pName in propertyNames)
	{
		NSObject *value = nil;
		@try 
		{
            if([object isKindOfClass:[NSUbiquitousKeyValueStore class]])
            {
                value = [(NSUbiquitousKeyValueStore *)object objectForKey:pName];
            }
            else
            {
                value = [object valueForSensibleKeyPath:pName];
            }
		}
		@catch (NSException * e) 
		{
			SCDebugLog(@"Warning: Property '%@' does not exist in object '%@'.", propertyName, NSStringFromClass([object class]));
		}
		if(!value)
			value = [NSNull null];
		[valuesArray addObject:value];
	}
	
    NSObject *value = nil;
	if(propertyNames.count > 1)
    {
        value = valuesArray;
    }
    else 
    {
        value = [valuesArray objectAtIndex:0];
        if([value isKindOfClass:[NSNull class]])
            value = nil;
    }
    
    if(!value && self.defaultsDictionary)
        value = [self.defaultsDictionary valueForKey:propertyName];
    
	return value;
}

- (NSString *)stringValueForPropertyName:(NSString *)propertyName inObject:(NSObject *)object
separateValuesUsingDelimiter:(NSString *)delimiter
{
    if([SCUtilities isBasicDataTypeClass:[object class]])
        return [NSString stringWithFormat:@"%@", object];
    
    NSObject *value = [self valueForPropertyName:propertyName inObject:object];
	
	if(!value)
		return nil;
	
	NSMutableString *stringValue = [NSMutableString string];
	if([value isKindOfClass:[NSArray class]])
	{
		NSArray *stringsArray = (NSArray *)value;
		for(NSUInteger i=0; i<stringsArray.count; i++)
		{
			NSObject *str = [stringsArray objectAtIndex:i];
			if(![str isKindOfClass:[NSNull class]])
			{
				if(i!=0 && delimiter)
					[stringValue appendString:delimiter];
				[stringValue appendString:[NSString stringWithFormat:@"%@", str]];
			}
		}
	}
	else
	{
		if(value)
			[stringValue appendFormat:@"%@", value];
	}
	
	return stringValue;
}

- (void)setValue:(NSObject *)value forPropertyName:(NSString *)propertyName inObject:(NSObject *)object
{
    if([SCUtilities isBasicDataTypeClass:[object class]])
        return;
    
    if(![SCUtilities propertyName:propertyName existsInObject:object])
        return;
    
    if([object isKindOfClass:[NSUbiquitousKeyValueStore class]])
    {
        [(NSUbiquitousKeyValueStore *)object setObject:value forKey:propertyName];
    }
    else
    {
        if(value == nil)
        {
            if(!self.supportsNilValues)
                value = [NSNull null];
            
            // check if the property's data type is scalar since scalars don't support nil
            SCDataDefinition *dataDef = [self definitionForObject:object];
            SCPropertyDefinition *propertyDef = [dataDef propertyDefinitionWithName:propertyName];
            if(propertyDef.dataTypeScalar)
            {
                value = [NSNumber numberWithUnsignedShort:0];
            }
        }
        [object setValue:value forKeyPath:propertyName];
    }
}

- (BOOL)validateInsertForObject:(NSObject *)object
{
    // Subclasses must override.
    return FALSE;
}

- (BOOL)validateUpdateForObject:(NSObject *)object
{
    // Subclasses must override.
    return FALSE;
}

- (BOOL)validateDeleteForObject:(NSObject *)object
{
    // Subclasses must override.
    return FALSE;
}

- (BOOL)validateOrderChangeForObject:(NSObject *)object
{
    // Subclasses must override.
    return FALSE;
}

- (void)addDataDefinition:(SCDataDefinition *)definition
{
    if(definition && definition.dataStructureName && ![_dataDefinitions valueForKey:definition.dataStructureName])
        [_dataDefinitions setValue:definition forKey:definition.dataStructureName];
}

- (SCDataDefinition *)definitionForObject:(NSObject *)object
{
    // Subclasses should override in case of multiple data definitions.
    return self.defaultDataDefinition;
}

- (void)bindStoreToPropertyName:(NSString *)propertyName forObject:(NSObject *)object withDefinition:(SCDataDefinition *)definition
{
    _boundPropertyName = propertyName;
    _boundObject = object;
    _boundObjectDefinition = definition;
}

- (void)forceDiscardAllUnaddedObjects
{
    if(!_uninsertedObjects.count)
        return;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:SCDataStoreWillDiscardAllUninsertedObjectsNotification object:self];
    
    for(NSInteger i=_uninsertedObjects.count-1; i>=0; i--)
    {
        [self discardUninsertedObject:[_uninsertedObjects objectAtIndex:i]];
    }
}

- (void)applicationWillEnterForeground
{
    // Does nothing. Should be implemented as needed by subclasses.
}

- (void)asynchronousInsertObject:(NSObject *)object success:(SCDataStoreInsertSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    // Must be implemented by subclasses that support SCDataStoreModeAsynchronous
    if(failure_block)
        failure_block(nil);
}

- (void)asynchronousUpdateObject:(NSObject *)object success:(SCDataStoreUpdateSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    // Must be implemented by subclasses that support SCDataStoreModeAsynchronous
    if(failure_block)
        failure_block(nil);
}

- (void)asynchronousDeleteObject:(NSObject *)object success:(SCDataStoreDeleteSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    // Must be implemented by subclasses that support SCDataStoreModeAsynchronous
    if(failure_block)
        failure_block(nil);
}

- (void)asynchronousFetchObjectsWithOptions:(SCDataFetchOptions *)options success:(SCDataStoreFetchSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block noConnection:(SCNoConnection_Block)noConnection_block
{
    // Must be implemented by subclasses that support SCDataStoreModeAsynchronous
    if(failure_block)
        failure_block(nil);
}

- (void)fetchObjectsSuccessful:(NSArray *)objects successBlock:(SCDataStoreFetchSuccess_Block)success_block failure:(SCDataStoreFailure_Block)failure_block
{
    if(self.postAsynchronousFetchObjectsAction)
    {
        self.postAsynchronousFetchObjectsAction(objects, ^(NSArray *updatedObjects, NSError *error)
                                          {
                                              if(!error)
                                              {
                                                  if(success_block)
                                                      success_block(updatedObjects);
                                              }
                                              else
                                              {
                                                  if(failure_block)
                                                      failure_block(error);
                                              }
                                          }
                                          );
    }
    else
    {
        if(success_block)
            success_block(objects);
    }
}

- (void)commitData
{
    // Does nothing. Should be overridden by subclasses where applicable.
}

@end













/* Missing framework classes (internal) */

@implementation SCMissingFrameworkDataDefinition

- (SCDataStore *)generateCompatibleDataStore
{
    return [SCMissingFrameworkDataStore storeWithDefaultDataDefinition:self];
}

@end


@implementation SCMissingFrameworkDataStore

- (SCMissingFrameworkDataDefinition *)missingFrameworkDataDefinition
{
    return (SCMissingFrameworkDataDefinition *)self.defaultDataDefinition;
}

@end



