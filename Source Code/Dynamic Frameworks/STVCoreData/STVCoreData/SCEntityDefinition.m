/*
 *  SCEntityDefinition.m
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

#import "SCEntityDefinition.h"

#import <SensibleTableView/SCPluginUtilities.h>
#import <SensibleTableView/SCClassDefinition.h>

#import "SCCoreDataFetchOptions.h"
#import "SCCoreDataStore.h"



@implementation SCEntityDefinition

@synthesize entity = _entity;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize orderAttributeName = _orderAttributeName;

+ (instancetype)definitionWithEntityName:(NSString *)entityName autoGeneratePropertyDefinitions:(BOOL)autoGenerate
{
	return [[[self class] alloc] initWithEntityName:entityName autoGeneratePropertyDefinitions:autoGenerate];
}

+ (instancetype)definitionWithEntityName:(NSString *)entityName propertyNamesString:(NSString *)propertyNamesString
{
    return [[[self class] alloc] initWithEntityName:entityName propertyNamesString:propertyNamesString];
}

+ (instancetype)definitionWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context autoGeneratePropertyDefinitions:(BOOL)autoGenerate
{
	return [[[self class] alloc] initWithEntityName:entityName managedObjectContext:context autoGeneratePropertyDefinitions:autoGenerate];
}

+ (instancetype)definitionWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNamesString:(NSString *)propertyNamesString
{
    return [[[self class] alloc] initWithEntityName:entityName managedObjectContext:context propertyNamesString:propertyNamesString];
}

+ (instancetype)definitionWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNames:(NSArray *)propertyNames
{
	return [[[self class] alloc] initWithEntityName:entityName managedObjectContext:context propertyNames:propertyNames];
}

+ (instancetype)definitionWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNames:(NSArray *)propertyNames propertyTitles:(NSArray *)propertyTitles
{
	return [[[self class] alloc] initWithEntityName:entityName managedObjectContext:context propertyNames:propertyNames propertyTitles:propertyTitles];
}

+ (instancetype)definitionWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyGroups:(SCPropertyGroupArray *)groups
{
    return [[[self class] alloc] initWithEntityName:entityName managedObjectContext:context propertyGroups:groups];
}

// overrides superclass
- (SCDataType)propertyDataTypeForPropertyWithName:(NSString *)propertyName
{
	SCDataType dataType = SCDataTypeUnknown;
	
    NSPropertyDescription *propertyDescription = [self propertyDescriptionForAttributeWithName:propertyName inEntity:self.entity];
    
    if(propertyDescription)
    {
        if([propertyDescription isKindOfClass:[NSAttributeDescription class]])
        {
            NSAttributeDescription *attribute = (NSAttributeDescription *)propertyDescription;
            switch ([attribute attributeType]) 
            {
                case NSInteger16AttributeType:
                case NSInteger32AttributeType:
                case NSInteger64AttributeType:
                    dataType = SCDataTypeNSNumber;
                    break;
                    
                case NSDecimalAttributeType:
                case NSDoubleAttributeType:
                case NSFloatAttributeType:
                    dataType = SCDataTypeNSNumber;
                    break;
                    
                case NSStringAttributeType:
                    dataType = SCDataTypeNSString;
                    break;
                    
                case NSBooleanAttributeType:
                    dataType = SCDataTypeNSNumber;
                    break;
                    
                case NSDateAttributeType:
                    dataType = SCDataTypeNSDate;
                    break;
                    
                case NSTransformableAttributeType:
                    dataType = SCDataTypeTransformable;
                    break;
                    
                default:
                    dataType = SCDataTypeUnknown;
                    break;
            }
        }
        if([propertyDescription isKindOfClass:[NSRelationshipDescription class]])
        {
            NSRelationshipDescription *relationship = (NSRelationshipDescription *)propertyDescription;
            
            if([relationship isToMany])
            {
                if(relationship.ordered)
                    dataType = SCDataTypeNSMutableOrderedSet;
                else
                    dataType = SCDataTypeNSMutableSet;
            }
            else
            {
                dataType = SCDataTypeNSObject;
            }
        }
        else
            if([propertyDescription isKindOfClass:[NSFetchedPropertyDescription class]])
            {
                dataType = SCDataTypeNSMutableSet;
            }
    }
	
	return dataType;
}

- (instancetype)initWithEntityName:(NSString *)entityName autoGeneratePropertyDefinitions:(BOOL)autoGenerate
{
    return [self initWithEntityName:entityName managedObjectContext:[self defaultManagedObjectContext] autoGeneratePropertyDefinitions:autoGenerate];
}

- (instancetype)initWithEntityName:(NSString *)entityName propertyNamesString:(NSString *)propertyNamesString
{
    return [self initWithEntityName:entityName managedObjectContext:[self defaultManagedObjectContext] propertyNamesString:propertyNamesString];
}

- (instancetype)initWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context autoGeneratePropertyDefinitions:(BOOL)autoGenerate
{
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName
														 inManagedObjectContext:context];
    if(!entityDescription)
        SCDebugLog(@"Warning: unable to load entity with name: %@", entityName);
	
	if(!autoGenerate)
	{
		self = [self init];
		_managedObjectContext = context;
		_entity = entityDescription;
		return self;
	}
	//else
	
	NSMutableArray *propertyNames = [NSMutableArray arrayWithCapacity:entityDescription.properties.count];
	for(NSPropertyDescription *propertyDescription in entityDescription.properties)
	{
		[propertyNames addObject:[propertyDescription name]];
	}
	return [self initWithEntityName:entityName managedObjectContext:context propertyNames:propertyNames];
}

- (instancetype)initWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNamesString:(NSString *)propertyNamesString
{
	if( (self = [self init]) )
	{
		_managedObjectContext = context;
		_entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
		
		[self generatePropertiesFromPropertyNamesString:propertyNamesString];
		
		[self setupDefaultConfiguration];
	}
	
	return self;
}

- (instancetype)initWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNames:(NSArray *)propertyNames
{
	return [self initWithEntityName:entityName managedObjectContext:context propertyNames:propertyNames propertyTitles:nil];
}

- (instancetype)initWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNames:(NSArray *)propertyNames propertyTitles:(NSArray *)propertyTitles
{
	if( (self = [self init]) )
	{
		_managedObjectContext = context;
		_entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
		
		[self generatePropertiesFromPropertyNamesArray:propertyNames propertyTitlesArray:propertyTitles];
		
		[self setupDefaultConfiguration];
	}
	
	return self;
}

- (instancetype)initWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyGroups:(SCPropertyGroupArray *)groups
{
    NSMutableArray *propertyNames = [[NSMutableArray alloc] init];
    for(NSInteger i=0; i<groups.groupCount; i++)
    {
        SCPropertyGroup *propertyGroup = [groups groupAtIndex:i];
        for(NSInteger j=0; j<propertyGroup.propertyNameCount; j++)
            [propertyNames addObject:[propertyGroup propertyNameAtIndex:j]];
    }
    
    if( (self=[self initWithEntityName:entityName managedObjectContext:context propertyNames:propertyNames]) )
    {
        for(NSInteger i=0; i<groups.groupCount; i++)
        {
            [self.propertyGroups addGroup:[groups groupAtIndex:i]];
        }
    }
      
    return self;
}

// overrides superclass
- (instancetype)initWithibDictionary:(NSMutableDictionary *)ibDictionary
{
    NSString *entityName = [ibDictionary valueForKey:@"entityName"];
    [ibDictionary removeObjectForKey:@"entityName"];
    
    self = [self initWithEntityName:entityName autoGeneratePropertyDefinitions:NO];
    
    if(self)
    {
        [self setAllPropertiesFromibDictionary:ibDictionary];
    }
    
    return self;
}


- (NSManagedObjectContext *)defaultManagedObjectContext
{
    NSManagedObjectContext *context = nil;
    
    if([[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(managedObjectContext)])
        context = [[[UIApplication sharedApplication] delegate] performSelector:@selector(managedObjectContext) withObject:nil];
    
    if(!context)
        SCDebugLog(@"Warning: %@ unable to automatically determine the default managed object context.", self);
    
    return context;
}

// overrides superclass
- (void)generatePropertiesFromPropertyNamesArray:(NSArray *)propertyNamesArray propertyTitlesArray:(NSArray *)propertyTitlesArray
{
    for(int i=0; i<propertyNamesArray.count; i++)
    {
        // Get entity and propertyName
        NSEntityDescription *_dynamicentity = self.entity;
        NSString *propertyName = nil;
        NSString *keyPath = [propertyNamesArray objectAtIndex:i];
        
        if([keyPath characterAtIndex:0] == '~')  // A custom property
        {
            [self addPropertyDefinitionWithName:keyPath title:[SCUtilities getUserFriendlyTitleFromName:keyPath] type:SCPropertyTypeCustom];
            
            continue;
        }
        
        NSArray *keyPathArray = [keyPath componentsSeparatedByString:@"."];
        for(int i=0; i<keyPathArray.count; i++)
        {
            propertyName = [keyPathArray objectAtIndex:i];
            NSPropertyDescription *propertyDescription = [self propertyDescriptionForAttributeWithName:propertyName inEntity:_dynamicentity];
            if(!propertyDescription)
            {
                SCDebugLog(@"Warning: Attribute '%@' does not exist in entity '%@'.", propertyName, _dynamicentity.name);
                propertyName = nil;
                break;
            }
            
            if(i<keyPathArray.count-1) // if not last property in keyPath
            {
                if(![propertyDescription isKindOfClass:[NSRelationshipDescription class]])
                    break;
                NSRelationshipDescription *relationship = (NSRelationshipDescription *)propertyDescription;
                if(![relationship isToMany])
                {
                    _dynamicentity = relationship.destinationEntity;
                }
                else
                {
                    SCDebugLog(@"Invalid: Class definition key path '%@' for entity '%@' has a to-many relationship (%@).", keyPath, _dynamicentity.name, propertyName);
                    propertyName = nil;
                    break;
                }
            }
        }
        
        
        NSString *propertyTitle;
        if(i < propertyTitlesArray.count)
            propertyTitle = [propertyTitlesArray objectAtIndex:i];
        else
            propertyTitle = [SCUtilities getUserFriendlyTitleFromName:propertyName];
        NSPropertyDescription *propertyDescription = [self propertyDescriptionForAttributeWithName:propertyName inEntity:_dynamicentity];
        
        if(propertyDescription)
        {
            SCPropertyDefinition *propertyDef = [SCPropertyDefinition 
                                                 definitionWithName:keyPath
                                                 title:propertyTitle
                                                 type:SCPropertyTypeUndefined];
            propertyDef.required = ![propertyDescription isOptional];
            
            if([propertyDescription isKindOfClass:[NSAttributeDescription class]])
            {
                NSAttributeDescription *attribute = (NSAttributeDescription *)propertyDescription;
                switch ([attribute attributeType]) 
                {
                    case NSInteger16AttributeType:
                    case NSInteger32AttributeType:
                    case NSInteger64AttributeType:
                        propertyDef.dataType = SCDataTypeNSNumber;
                        propertyDef.type = SCPropertyTypeNumericTextField;
                        propertyDef.attributes = [SCNumericTextFieldAttributes 
                                                  attributesWithMinimumValue:nil 
                                                  maximumValue:nil 
                                                  allowFloatValue:FALSE];
                        break;
                        
                    case NSDecimalAttributeType:
                    case NSDoubleAttributeType:
                    case NSFloatAttributeType:
                        propertyDef.dataType = SCDataTypeNSNumber;
                        propertyDef.type = SCPropertyTypeNumericTextField;
                        break;
                        
                    case NSStringAttributeType:
                        propertyDef.dataType = SCDataTypeNSString;
                        propertyDef.type = SCPropertyTypeTextField;
                        break;
                        
                    case NSBooleanAttributeType:
                        propertyDef.dataType = SCDataTypeNSNumber;
                        propertyDef.type = SCPropertyTypeSwitch;
                        break;
                        
                    case NSDateAttributeType:
                        propertyDef.dataType = SCDataTypeNSDate;
                        propertyDef.type = SCPropertyTypeDate;
                        break;
                        
                        
                    default:
                        propertyDef.type = SCPropertyTypeNone;
                        break;
                }
            }
            else
                if([propertyDescription isKindOfClass:[NSRelationshipDescription class]])
                {
                    NSRelationshipDescription *relationship = (NSRelationshipDescription *)propertyDescription;
                    
                    if([relationship isToMany])
                    {
                        if(relationship.ordered)
                            propertyDef.dataType = SCDataTypeNSMutableOrderedSet;
                        else
                            propertyDef.dataType = SCDataTypeNSMutableSet;
                        
                        propertyDef.type = SCPropertyTypeArrayOfObjects;
                    }
                    else
                    {
                        propertyDef.dataType = SCDataTypeNSObject;
                        propertyDef.type = SCPropertyTypeObject;
                    }
                }
                else
                    if([propertyDescription isKindOfClass:[NSFetchedPropertyDescription class]])
                    {
                        propertyDef.dataType = SCDataTypeNSMutableArray;
                        propertyDef.type = SCPropertyTypeArrayOfObjects;
                    }
            
            [self addPropertyDefinition:propertyDef];
        }
    }
}

// overrides superclass
- (NSString *)dataStructureName
{
	return [self.entity name];
}

- (void)setOrderAttributeName:(NSString *)orderAttributeName
{
    if(![self isValidPropertyName:orderAttributeName])
    {
        SCDebugLog(@"Warning: orderAttributeName '%@' is not valid for entity '%@'.", orderAttributeName, self.entity.name);
        
        return;
    }
    
    SCDataType dataType = [self propertyDataTypeForPropertyWithName:orderAttributeName];
    BOOL dataTypeValid = NO;
    if(dataType==SCDataTypeNSNumber || dataType==SCDataTypeDouble || dataType==SCDataTypeFloat || dataType==SCDataTypeInt)
        dataTypeValid = YES;
    if(!dataTypeValid)
    {
        SCDebugLog(@"Warning: orderAttributeName '%@' must be of Integer type.", orderAttributeName);
        
        return;
    }
	
	_orderAttributeName = [orderAttributeName copy];
}

// overrides superclass
- (BOOL)isValidPropertyName:(NSString *)propertyName
{
	BOOL valid = TRUE;
    
    NSArray *keyPathArray = [propertyName componentsSeparatedByString:@"."];
    NSString *_propertyName = nil;
    
    if(self.entity)
    {
        NSEntityDescription *_dynamicentity = self.entity;
        for(int i=0; i<keyPathArray.count; i++)
        {
            _propertyName = [keyPathArray objectAtIndex:i];
            NSPropertyDescription *propertyDescription = [self propertyDescriptionForAttributeWithName:_propertyName inEntity:_dynamicentity];
            if(!propertyDescription)
            {
                valid = FALSE;
                break;
            }
            
            if(i<keyPathArray.count-1) // if not last property in keyPath
            {
                if(![propertyDescription isKindOfClass:[NSRelationshipDescription class]])
                {
                    valid = FALSE;
                    break;
                }
                
                NSRelationshipDescription *relationship = (NSRelationshipDescription *)propertyDescription;
                if(![relationship isToMany])
                {
                    _dynamicentity = relationship.destinationEntity;
                }
                else
                {
                    valid = FALSE;
                    break;
                }
            }
        }
    }
    
    return valid;
}

// overrides superclass
- (SCDataStore *)generateCompatibleDataStore
{
    return [SCCoreDataStore storeWithManagedObjectContext:self.managedObjectContext defaultEntityDefinition:self];
}

// overrides superclass
- (SCDataFetchOptions *)generateCompatibleDataFetchOptions
{
    SCCoreDataFetchOptions *coreDataFetchOptions = [[SCCoreDataFetchOptions alloc] init];
    coreDataFetchOptions.sortKey = self.keyPropertyName;
    coreDataFetchOptions.orderAttributeName = self.orderAttributeName;
    
    return coreDataFetchOptions;
}


- (NSPropertyDescription *)propertyDescriptionForAttributeWithName:(NSString *)attributeName inEntity:(NSEntityDescription *)attributeEntity
{
    NSPropertyDescription *propertyDescription = [[attributeEntity propertiesByName] valueForKey:attributeName];
    
    if(!propertyDescription)
    {
        // Check if the attribute is a calculated attribute defined in an NSManagedObject subclass
        Class entityClass = NSClassFromString([attributeEntity managedObjectClassName]);
        if(entityClass)
        {
            SCClassDefinition *entityClassDef = [SCClassDefinition definitionWithClass:entityClass propertyNamesString:attributeName];
            SCPropertyDefinition *attributePDef = [entityClassDef propertyDefinitionWithName:attributeName];
            if(attributePDef)
            {
                // Create attributeDescription based on attributePDef
                NSAttributeDescription *attributeDescription = [[NSAttributeDescription alloc] init];
                attributeDescription.name = attributeName;
                switch (attributePDef.dataType)
                {
                    case SCDataTypeNSNumber:
                    case SCDataTypeInt:
                    case SCDataTypeFloat:
                    case SCDataTypeDouble:
                    case SCDataTypeBOOL:
                        attributeDescription.attributeType = NSInteger16AttributeType;
                        break;
                    
                    case SCDataTypeNSString:
                        attributeDescription.attributeType = NSStringAttributeType;
                        break;
                        
                    case SCDataTypeNSDate:
                        attributeDescription.attributeType = NSDateAttributeType;
                        break;
                        
                    default:
                        break;
                }
                
                propertyDescription = attributeDescription;
            }
        }
    }
    
    return propertyDescription;
}

@end
