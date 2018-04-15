/*
 *  SCCoreDataStore.m
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

#import "SCCoreDataStore.h"

#import "SCEntityDefinition.h"
#import "SCCoreDataFetchOptions.h"


@interface SCCoreDataStore ()

@property (nonatomic, strong, readwrite) NSMutableSet *boundSet;
@property (nonatomic, strong, readwrite) NSMutableOrderedSet *boundOrderedSet;
@property (nonatomic, readwrite) BOOL boundSetOwnsStoreObjects;

- (void)willSaveContext;

@end



@implementation SCCoreDataStore

+ (instancetype)storeWithManagedObjectContext:(NSManagedObjectContext *)context defaultEntityDefinition:(SCEntityDefinition *)definition
{
	return [[[self class] alloc] initWithManagedObjectContext:context defaultEntityDefinition:definition];
}

+ (instancetype)storeWithManagedObjectContext:(NSManagedObjectContext *)context boundSet:(NSMutableSet *)set boundSetEntityDefinition:(SCEntityDefinition *)definition boundSetOwnsStoreObjects:(BOOL)ownsStoreObjects
{
    return [[[self class] alloc] initWithManagedObjectContext:context boundSet:set boundSetEntityDefinition:definition boundSetOwnsStoreObjects:ownsStoreObjects];
}


- (instancetype)init
{
	if( (self = [super init]) )
	{
        _managedObjectContext = nil;
        _boundSet = nil;
        _boundOrderedSet = nil;
        _boundSetOwnsStoreObjects = FALSE;
        
        // Register with managed object notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveContext) name:NSManagedObjectContextWillSaveNotification object:nil];
	}
	return self;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context defaultEntityDefinition:(SCEntityDefinition *)definition
{
    if( (self=[self initWithDefaultDataDefinition:definition]) )
    {
        self.managedObjectContext = context;
    }
    return self;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context boundSet:(NSMutableSet *)set boundSetEntityDefinition:(SCEntityDefinition *)definition boundSetOwnsStoreObjects:(BOOL)ownsStoreObjects
{
    if( (self=[self initWithDefaultDataDefinition:definition]) )
    {
        self.managedObjectContext = context;
        self.boundSet = set;
        self.boundSetOwnsStoreObjects = ownsStoreObjects;
    }
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)willSaveContext
{
    // Make sure all invalid unadded objects are removed otherwise Core Data will throw an exception
    [self forceDiscardAllUnaddedObjects];
}

// overrides superclass
- (NSObject *)createNewObjectWithDefinition:(SCDataDefinition *)definition
{
    NSObject *object = nil;
    
    if([definition isKindOfClass:[SCEntityDefinition class]])
    {
        SCEntityDefinition *entityDefinition = (SCEntityDefinition *)definition;
        
        // get the new object's order
        NSInteger order = NSNotFound;
        if(entityDefinition.orderAttributeName && [entityDefinition isValidPropertyName:entityDefinition.orderAttributeName])
        {
            NSArray *objectsArray = [self fetchObjectsWithOptions:[self.defaultDataDefinition generateCompatibleDataFetchOptions]];
            
            if(objectsArray.count == 0) 
            {
                order = 0;
            }
            else
            {
                NSObject *lastObject = [objectsArray objectAtIndex:objectsArray.count-1];
                order = [(NSNumber *)[lastObject valueForKey:entityDefinition.orderAttributeName] intValue] + 1;
            }
        }
        
        object = [NSEntityDescription insertNewObjectForEntityForName:entityDefinition.entity.name inManagedObjectContext:self.managedObjectContext];
        if(self.boundSet)
            [self.boundSet addObject:object];
        else if(self.boundOrderedSet)
            [self.boundOrderedSet addObject:object];
        if(order != NSNotFound)
            [object setValue:[NSNumber numberWithInteger:order] forKey:entityDefinition.orderAttributeName];
    }
    
    [self addDataDefinition:definition];
    if(object)
        [_uninsertedObjects addObject:object];

    return object;
}

// overrides superclass
- (BOOL)discardUninsertedObject:(NSObject *)object
{
    // Remove the new object from context
    if(object)
        return [self deleteObject:object];
    //else
    return TRUE;
}

// overrides superclass
- (void)applicationWillEnterForeground
{
    // restore all objects that have been deleted during UIApplicationDidEnterBackgroundNotification
    for(NSManagedObject *object in _uninsertedObjects)
    {
        if(!object.managedObjectContext)
            [self.managedObjectContext insertObject:object];
    }
}

// overrides superclass
- (BOOL)insertObject:(NSObject *)object
{
    SCDataDefinition *definition = [self definitionForObject:object];
    if(![definition isKindOfClass:[SCEntityDefinition class]])
        return FALSE;
    
    if([_uninsertedObjects indexOfObjectIdenticalTo:object] != NSNotFound)
    {
        [self.managedObjectContext insertObject:(NSManagedObject *)object];
        if(self.boundSet)
            [self.boundSet addObject:object];
        else if(self.boundOrderedSet)
            [self.boundOrderedSet addObject:object];
    }
    
    [_uninsertedObjects removeObjectIdenticalTo:object];
    
    return TRUE;
}

- (BOOL)changeOrderForObject:(NSObject *)object toOrder:(NSUInteger)toOrder subsetArray:(NSArray *)subsetArray
{
    if(self.boundOrderedSet)
    {
        NSInteger objectIndex = [self.boundOrderedSet indexOfObject:object];
        if(objectIndex == NSNotFound)
            return FALSE;
        
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:objectIndex];
        [self.boundOrderedSet moveObjectsAtIndexes:indexes toIndex:toOrder];
        
        return TRUE;
    }
    
    
    SCDataDefinition *definition = [self definitionForObject:object];
    SCEntityDefinition *entityDefinition = nil;
    if([definition isKindOfClass:[SCEntityDefinition class]])
        entityDefinition = (SCEntityDefinition *)definition;
    
    if(!entityDefinition || !entityDefinition.orderAttributeName)
        return FALSE;
    
    
    NSObject *toObject = [subsetArray objectAtIndex:toOrder];
    if(toObject == object)
        return TRUE;  // no need to change order
    
    NSInteger fromObjectOrderAttributeValue = [[object valueForKey:entityDefinition.orderAttributeName] integerValue];
    NSInteger toObjectOrderAttributeValue = [[toObject valueForKey:entityDefinition.orderAttributeName] integerValue];
    
    // Determine absoluteFromOrder
    NSMutableArray *objectsArray = [NSMutableArray arrayWithArray:[self fetchObjectsWithOptions:[self.defaultDataDefinition generateCompatibleDataFetchOptions]]];
    NSInteger absoluteFromOrder = [objectsArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
                                   {
                                       BOOL found = ([[obj valueForKey:entityDefinition.orderAttributeName] integerValue] == fromObjectOrderAttributeValue);
                                       if(found)
                                           *stop = YES;
                                       
                                       return found;
                                   }];
    if(absoluteFromOrder == NSNotFound)
    {
        SCDebugLog(@"Unexpected object not found while reordering for: %@", object);
        return FALSE;
    }
    
    // Determine absoluteToOrder
    NSInteger absoluteToOrder = [objectsArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
                                 {
                                     BOOL found = ([[obj valueForKey:entityDefinition.orderAttributeName] integerValue] == toObjectOrderAttributeValue);
                                     if(found)
                                         *stop = YES;
                                     
                                     return found;
                                 }];
    if(absoluteToOrder == NSNotFound)
    {
        SCDebugLog(@"Unexpected object not found while reordering for: %@", toObject);
        return FALSE;
    }
    
    // Modify the object's order attribute to toObjectOrderAttributeValue
    [object setValue:[NSNumber numberWithInteger:toObjectOrderAttributeValue] forKey:entityDefinition.orderAttributeName];
    
    
    // Reorder objectsArray too! (to enable next code chuck to work correctly)
    [objectsArray removeObjectAtIndex:absoluteFromOrder];
    [objectsArray insertObject:object atIndex:absoluteToOrder];
    
    // Make sure all objects above and below absoluteTorder have correct order values
    NSInteger currentOrderValue = toObjectOrderAttributeValue;
    for(NSInteger i=absoluteToOrder-1; i>=0; i--)
    {
        NSObject *obj = [objectsArray objectAtIndex:i];
        NSInteger objAttributeValue = [[obj valueForKey:entityDefinition.orderAttributeName] integerValue];
        if(objAttributeValue < currentOrderValue)
            break;
        
        currentOrderValue--;
        [obj setValue:[NSNumber numberWithInteger:currentOrderValue] forKey:entityDefinition.orderAttributeName];
    }
    currentOrderValue = toObjectOrderAttributeValue;
    for(NSInteger i=absoluteToOrder+1; i<objectsArray.count; i++)
    {
        NSObject *obj = [objectsArray objectAtIndex:i];
        NSInteger objAttributeValue = [[obj valueForKey:entityDefinition.orderAttributeName] integerValue];
        if(objAttributeValue > currentOrderValue)
            break;
        
        currentOrderValue++;
        [obj setValue:[NSNumber numberWithInteger:currentOrderValue] forKey:entityDefinition.orderAttributeName];
    }
    
    return TRUE;
}

// overrides superclass
- (BOOL)deleteObject:(NSObject *)object
{
    if(self.boundSet)
    {
        [self.boundSet removeObject:object];
    }
    else if(self.boundOrderedSet)
    {
        [self.boundOrderedSet removeObject:object];
    }
    
    if( (!self.boundSet && !self.boundOrderedSet) || _boundSetOwnsStoreObjects)
    {
        [self.managedObjectContext deleteObject:(NSManagedObject *)object];
    }
    
    return TRUE;
}

// overrides superclass
- (NSArray *)fetchObjectsWithOptions:(SCDataFetchOptions *)fetchOptions
{
    SCCoreDataFetchOptions *defaultFetchOptions = (SCCoreDataFetchOptions *)[self.defaultDataDefinition generateCompatibleDataFetchOptions];
    
    SCCoreDataFetchOptions *coreDataFetchOptions;
    if([fetchOptions isKindOfClass:[SCCoreDataFetchOptions class]])
    {
        coreDataFetchOptions = (SCCoreDataFetchOptions *)fetchOptions;
        
        if(coreDataFetchOptions.sort && !coreDataFetchOptions.sortKey)
            coreDataFetchOptions.sortKey = defaultFetchOptions.sortKey;
    }
    else
    {
        coreDataFetchOptions = defaultFetchOptions;
        if(fetchOptions.filterPredicate)
            coreDataFetchOptions.filterPredicate = fetchOptions.filterPredicate;
    }
    
    NSPredicate *filterPredicate = nil;
    if(coreDataFetchOptions.filter)
        filterPredicate = coreDataFetchOptions.filterPredicate;
    
    NSArray *sortDescriptors = nil;
    if(!self.boundOrderedSet)
        sortDescriptors = [coreDataFetchOptions sortDescriptors];
    
    NSMutableArray *array = [NSMutableArray array];
    if(self.boundSet || self.boundOrderedSet)
    {
        if(self.boundSet)
            [array addObjectsFromArray:[self.boundSet allObjects]];
        else
            [array addObjectsFromArray:[self.boundOrderedSet array]];
        if(filterPredicate)
        {
            @try 
            {
                [array filterUsingPredicate:filterPredicate];
            }
            @catch (NSException * e) 
            {
                SCDebugLog(@"Warning: Invalid filter predicate: %@.", filterPredicate);
            }
        }
        if(sortDescriptors)
        {
            @try 
            {
                [array sortUsingDescriptors:sortDescriptors];
            }
            @catch (NSException * e) 
            {
                SCDebugLog(@"Warning: Invalid sort key: %@ or orderAttribute:%@.", coreDataFetchOptions.sortKey, coreDataFetchOptions.orderAttributeName);
            }
        }
    }
    else 
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        if(fetchOptions.batchSize)
        {
            [fetchRequest setFetchLimit:coreDataFetchOptions.batchSize];
            [fetchRequest setFetchOffset:coreDataFetchOptions.batchCurrentOffset*coreDataFetchOptions.batchSize];
        }
        if(sortDescriptors)
            [fetchRequest setSortDescriptors: sortDescriptors];
        if(filterPredicate)
            [fetchRequest setPredicate:filterPredicate];
		
        // fetch all entities in dataDefinitions
        NSArray *allEntities = [_dataDefinitions allValues];
        for(SCEntityDefinition *entityDefinition in allEntities)
        {
            if(![entityDefinition isKindOfClass:[SCEntityDefinition class]])
                continue;
            
            [fetchRequest setEntity:entityDefinition.entity];
            [array addObjectsFromArray:[entityDefinition.managedObjectContext executeFetchRequest:fetchRequest error:NULL]];
        }
		
		if(coreDataFetchOptions.batchSize)
            [coreDataFetchOptions incrementBatchOffset];
    }
    
    return array;
}

// overrides superclass
- (NSObject *)valueForPropertyName:(NSString *)propertyName inObject:(NSObject *)object
{
    SCDataType dataType = [[self definitionForObject:object] propertyDataTypeForPropertyWithName:propertyName];
    
    NSObject *value = nil;
    switch (dataType)
    {
        case SCDataTypeNSMutableSet:
            value = [(NSManagedObject *)object mutableSetValueForKey:propertyName];
            break;
            
        default:
            value = [super valueForPropertyName:propertyName inObject:object];
            break;
    }
    
    return value;
}

// overrides superclass
- (void)setValue:(NSObject *)value forPropertyName:(NSString *)propertyName inObject:(NSObject *)object
{
    if(![SCUtilities propertyName:propertyName existsInObject:object])
        return;
    
    NSArray *keyPathArray = [propertyName componentsSeparatedByString:@"."];
    if(keyPathArray.count == 1)
    {
        [object setValue:value forKey:propertyName];
    }
    else
    {
        if([object isKindOfClass:[NSManagedObject class]])
        {
            // Make sure all entity objects on the path exist, otherwise create them
            NSManagedObject *mObject = (NSManagedObject *)object;
            for(int i=0; i<keyPathArray.count-1; i++)
            {
                NSString *key = [keyPathArray objectAtIndex:i];
                NSManagedObject *subObject = [mObject valueForKey:key];
                if(!subObject)
                {
                    NSRelationshipDescription *subObjectRel = [[mObject.entity relationshipsByName] valueForKey:key];
					if(subObjectRel)
					{
						subObject = [NSEntityDescription insertNewObjectForEntityForName:[[subObjectRel destinationEntity] name] inManagedObjectContext:mObject.managedObjectContext];
						[mObject setValue:subObject forKey:key];
					}
                }
                
                if(subObject)
                    mObject = subObject;
                else
                    break;
            }
        }
        [object setValue:value forKeyPath:propertyName];
    }
}

// overrides superclass
- (BOOL)validateInsertForObject:(NSObject *)object
{
    return [(NSManagedObject *)object validateForInsert:nil];
}

// overrides superclass
- (BOOL)validateUpdateForObject:(NSObject *)object
{
    return [(NSManagedObject *)object validateForUpdate:nil];
}

// overrides superclass
- (BOOL)validateDeleteForObject:(NSObject *)object
{
    return [(NSManagedObject *)object validateForDelete:nil];
}

// overrides superclass
- (BOOL)validateOrderChangeForObject:(NSObject *)object
{
    if(self.boundOrderedSet)
        return TRUE;
    
    
    BOOL orderCanChange = FALSE;
    
    SCDataDefinition *definition = [self definitionForObject:object];
    if([definition isKindOfClass:[SCEntityDefinition class]])
    {
        SCEntityDefinition *entityDefinition = (SCEntityDefinition *)definition;
        if(entityDefinition.orderAttributeName)
            orderCanChange = TRUE;
    }
    
    return orderCanChange;
}

// overrides superclass
- (SCDataDefinition *)definitionForObject:(NSObject *)object
{
    if(![object isKindOfClass:[NSManagedObject class]])
        return nil;
    
    NSString *dataStructureName = [(NSManagedObject *)object entity].name;
    
    return [_dataDefinitions valueForKey:dataStructureName];
}

// overrides superclass
- (void)bindStoreToPropertyName:(NSString *)propertyName forObject:(NSObject *)object withDefinition:(SCDataDefinition *)definition
{
    [super bindStoreToPropertyName:propertyName forObject:object withDefinition:definition];
    
    SCPropertyDefinition *propertyDefiniton = [definition propertyDefinitionWithName:propertyName];
    
    self.boundSet = nil;
    self.boundOrderedSet = nil;
    switch (propertyDefiniton.dataType)
    {
        case SCDataTypeNSMutableSet:
            @try
            {
                self.boundSet = [(NSManagedObject *)_boundObject mutableSetValueForKeyPath:_boundPropertyName];
                
                // determine if boundSet owns the store's objects
                if([propertyDefiniton.attributes isKindOfClass:[SCArrayOfObjectsAttributes class]])
                    self.boundSetOwnsStoreObjects = TRUE;
                else
                    self.boundSetOwnsStoreObjects = FALSE;
            }
            @catch (NSException *exception)
            {
                SCDebugLog(@"Warning: SCCoreDataStore unable to bind to property '%@' in object '%@'. ", _boundPropertyName, _boundObject);
                
                _boundObject = nil;
                _boundPropertyName = nil;
                self.boundSetOwnsStoreObjects = FALSE;
            }
                break;
            
        case SCDataTypeNSMutableOrderedSet:
            @try
            {
                self.boundOrderedSet = [(NSManagedObject *)_boundObject mutableOrderedSetValueForKey:_boundPropertyName];
                
                // determine if boundSet owns the store's objects
                if([propertyDefiniton.attributes isKindOfClass:[SCArrayOfObjectsAttributes class]])
                    self.boundSetOwnsStoreObjects = TRUE;
                else
                    self.boundSetOwnsStoreObjects = FALSE;
            }
            @catch (NSException *exception)
            {
                SCDebugLog(@"Warning: SCCoreDataStore unable to bind to property '%@' in object '%@'. ", _boundPropertyName, _boundObject);
                
                _boundObject = nil;
                _boundPropertyName = nil;
                self.boundSetOwnsStoreObjects = FALSE;
            }
            break;
    
            
        default:
            SCDebugLog(@"Warning: SCCoreDataStore unable to bind to property '%@' in object '%@'. ", _boundPropertyName, _boundObject);
            break;
    }
}

// overrides superclass
- (void)commitData
{
    NSError *error;
    if (self.managedObjectContext) 
    {
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) 
        {
            SCDebugLog(@"Error commiting the Core Data store: %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}


@end
