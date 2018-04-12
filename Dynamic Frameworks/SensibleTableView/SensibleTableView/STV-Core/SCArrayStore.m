/*
 *  SCArrayStore.m
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

#import "SCArrayStore.h"

#import "SCClassDefinition.h"
#import "SCDictionaryDefinition.h"
#import "SCStringDefinition.h"
#import "SCNumberDefinition.h"
#import "SCDateDefinition.h"
#import <objc/runtime.h>


@implementation SCArrayStore



+ (instancetype)storeWithObjectsArray:(NSMutableArray *)array defaultDefiniton:(SCDataDefinition *)definition
{
	return [[[self class] alloc] initWithObjectsArray:array defaultDefiniton:definition];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
        // initialize here
	}
	return self;
}

- (instancetype)initWithObjectsArray:(NSMutableArray *)array defaultDefiniton:(SCDataDefinition *)definition
{
    if( (self=[self initWithDefaultDataDefinition:definition]) )
    {
        self.objectsArray = array;
    }
    return self;
}




- (NSMutableArray *)objectsArray
{
    return (NSMutableArray *)self.storedData;
}

- (void)setObjectsArray:(NSMutableArray *)objectsArray
{
    self.storedData = objectsArray;
}

// overrides superclass
- (void)setStoredData:(NSObject *)data
{
    // only set data of the correct type
    if([data isKindOfClass:[NSMutableArray class]])
    {
        [super setStoredData:data];
    }
    else
    {
        [super setStoredData:nil];
        
        if(data)
            SCDebugLog(@"Warning: SCArrayStore expecting NSMutableArray but got %@ instead. (Data: %@)", NSStringFromClass([data class]) , data);
    }
}

// overrides superclass
- (NSObject *)createNewObjectWithDefinition:(SCDataDefinition *)definition
{
    NSObject *object = nil;
    
    if([definition isKindOfClass:[SCClassDefinition class]])
    {
        SCClassDefinition *classDefinition = (SCClassDefinition *)definition;
        
        object = [[classDefinition.cls alloc] init];
    }
    else 
        if([definition isKindOfClass:[SCDictionaryDefinition class]])
        {
            object = [NSMutableDictionary dictionary];
        }
        else 
            if([definition isKindOfClass:[SCStringDefinition class]])
            {
                object = [NSMutableString string];
            }
            else 
                if([definition isKindOfClass:[SCNumberDefinition class]])
                {
                    object = [[NSNumber alloc] init];
                }
                else 
                    if([definition isKindOfClass:[SCDateDefinition class]])
                    {
                        object = [NSDate date];
                    }
        
    
    [self addDataDefinition:definition];
    if(object)
        [_uninsertedObjects addObject:object];
    
    return object;
}

// overrides superclass
- (BOOL)discardUninsertedObject:(NSObject *)object
{
    [_uninsertedObjects removeObjectIdenticalTo:object];
    
    return TRUE;
}

// overrides superclass
- (BOOL)insertObject:(NSObject *)object
{
    [self.objectsArray addObject:object];
    
    [_uninsertedObjects removeObjectIdenticalTo:object];
    
    return TRUE;
}

// overrides superclass
- (BOOL)deleteObject:(NSObject *)object
{
    NSUInteger index = [self.objectsArray indexOfObjectIdenticalTo:object];
    
    if(index == NSNotFound)
        return FALSE;
    //else
    [self.objectsArray removeObjectAtIndex:index];
    
    return TRUE;
}

// overrides superclass
- (BOOL)insertObject:(NSObject *)object atOrder:(NSUInteger)order
{
    [self.objectsArray insertObject:object atIndex:order];
    
    return TRUE;
}

- (BOOL)validateOrderChangeForObject:(NSObject *)object
{
    return TRUE;  // Always true since objectsArray is an ordered storage class.
}

- (BOOL)changeOrderForObject:(NSObject *)object toOrder:(NSUInteger)toOrder subsetArray:(NSArray *)subsetArray
{
    NSUInteger index = [self.objectsArray indexOfObjectIdenticalTo:object];
    if(index == NSNotFound)
        return FALSE;
    
    if(index == toOrder)
        return TRUE;
    
    [self.objectsArray removeObjectAtIndex:index];
    [self.objectsArray insertObject:object atIndex:toOrder];
    
    return TRUE;
}

// overrides superclass
- (NSArray *)fetchObjectsWithOptions:(SCDataFetchOptions *)fetchOptions
{
    if(_boundObject && _boundPropertyName)
    {
        id value = [self valueForPropertyName:_boundPropertyName inObject:_boundObject];
        if([value isKindOfClass:[NSMutableArray class]])
            self.objectsArray = value;
    }
    
    NSArray *array = [NSMutableArray arrayWithArray:self.objectsArray];
    
    if(fetchOptions)
    {
        [fetchOptions filterMutableArray:(NSMutableArray *)array];
        [fetchOptions sortMutableArray:(NSMutableArray *)array];
        
        if(fetchOptions.batchSize)
        {
            NSRange range = {fetchOptions.batchCurrentOffset*fetchOptions.batchSize, fetchOptions.batchSize};
            if(range.location > array.count)
            {
                array = [NSArray array];  // empty array
            }
            else 
            {
                NSInteger delta = (range.location+range.length)-array.count;
                if(delta > 0)
                {
                    range.length -= delta;
                }
                
                array = [array subarrayWithRange:range];
            }
            
            [fetchOptions incrementBatchOffset];
        }
    }
    
    return array;
}

// overrides superclass
- (void)setValue:(NSObject *)value forPropertyName:(NSString *)propertyName inObject:(NSObject *)object
{
    if([SCUtilities isBasicDataTypeClass:[object class]])
    {
        // replace old data type object with new one
        NSUInteger index = [self.objectsArray indexOfObjectIdenticalTo:object];
        if(index != NSNotFound)
        {
            [self.objectsArray replaceObjectAtIndex:index withObject:value];
        }
    }
    else 
    {
        [super setValue:value forPropertyName:propertyName inObject:object];
    }
}

- (BOOL)validateInsertForObject:(NSObject *)object
{
    return TRUE;
}

- (BOOL)validateUpdateForObject:(NSObject *)object
{
    return TRUE;
}

- (BOOL)validateDeleteForObject:(NSObject *)object
{
    return TRUE;
}

- (SCDataDefinition *)definitionForObject:(NSObject *)object
{
    NSString *className = [SCUtilities dataStructureNameForClass:[object class]];
    
    return [_dataDefinitions valueForKey:className];
}

- (void)bindStoreToPropertyName:(NSString *)propertyName forObject:(NSObject *)object withDefinition:(SCDataDefinition *)definition
{
    [super bindStoreToPropertyName:propertyName forObject:object withDefinition:definition];
    
    id value = [self valueForPropertyName:propertyName inObject:object];
    
    if([value isKindOfClass:[NSMutableArray class]])
        self.objectsArray = value;
}

@end
