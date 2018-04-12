/*
 *  SCClassDefinition.m
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

#import "SCClassDefinition.h"

#import "SCArrayStore.h"
#import <objc/runtime.h>



@implementation SCClassDefinition

@synthesize cls;

+ (instancetype)definitionWithClass:(Class)_cls autoGeneratePropertyDefinitions:(BOOL)autoGenerate
{
	return [[[self class] alloc] initWithClass:_cls autoGeneratePropertyDefinitions:autoGenerate];
}

+ (instancetype)definitionWithClass:(Class)_cls propertyNamesString:(NSString *)propertyNamesString
{
    return [[[self class] alloc] initWithClass:_cls propertyNamesString:propertyNamesString];
}

+ (instancetype)definitionWithClass:(Class)_cls propertyNames:(NSArray *)propertyNames
{
	return [[[self class] alloc] initWithClass:_cls propertyNames:propertyNames];
}

+ (instancetype)definitionWithClass:(Class)_cls propertyNames:(NSArray *)propertyNames propertyTitles:(NSArray *)propertyTitles
{
	return [[[self class] alloc] initWithClass:_cls propertyNames:propertyNames propertyTitles:propertyTitles];
}

+ (instancetype)definitionWithClass:(Class)_cls propertyGroups:(SCPropertyGroupArray *)groups
{
    return [[[self class] alloc] initWithClass:_cls propertyGroups:groups];
}


// overrides superclass
- (SCDataType)propertyDataTypeForPropertyWithName:(NSString *)propertyName
{
	SCDataType dataType = SCDataTypeUnknown;
	
    objc_property_t property = class_getProperty(self.cls, [propertyName UTF8String]);
    if(!property)
        return SCDataTypeUnknown;
    NSArray *attributesArray = [[NSString stringWithUTF8String: property_getAttributes(property)] 
                                componentsSeparatedByString:@","];
    NSSet *attributesSet = [NSSet setWithArray:attributesArray];
    
    if([attributesSet containsObject:[NSString stringWithFormat:@"T@\"%@\"",  NSStringFromClass([NSString class])]] ||
       [attributesSet containsObject:@"T@"])  // @"T@" is for Swift 'String' strings
        dataType = SCDataTypeNSString;
    else
        if([attributesSet containsObject:[NSString stringWithFormat:@"T@\"%@\"", NSStringFromClass([NSNumber class])]])
            dataType = SCDataTypeNSNumber;
        else
            if([attributesSet containsObject:[NSString stringWithFormat:@"T@\"%@\"",  NSStringFromClass([NSDate class])]])
                dataType = SCDataTypeNSDate;
            else
                if([attributesSet containsObject:[NSString stringWithFormat:@"T@\"%@\"",  NSStringFromClass([NSMutableSet class])]])
                    dataType = SCDataTypeNSMutableSet;
                else
                    if([attributesSet containsObject:[NSString stringWithFormat:@"T@\"%@\"",  NSStringFromClass([NSMutableArray class])]])
                        dataType = SCDataTypeNSMutableArray;
                    else
                        if([attributesSet containsObject:@"Tc"] || [attributesSet containsObject:@"TB"])
                            dataType = SCDataTypeBOOL;
                        else
                            if([attributesSet containsObject:@"Ti"] || [attributesSet containsObject:@"Tq"])
                                dataType = SCDataTypeInt;
                            else
                                if([attributesSet containsObject:@"Tf"])
                                    dataType = SCDataTypeFloat;
                                else
                                    if([attributesSet containsObject:@"Td"])
                                        dataType = SCDataTypeDouble;
    
    
	return dataType;
}


- (instancetype) init
{
	if( (self = [super init]) )
	{
        cls = nil;
	}
	return self;
}

- (instancetype)initWithClass:(Class)_cls autoGeneratePropertyDefinitions:(BOOL)autoGenerate
{
	if( (self=[self init]) )
	{
		cls = _cls;
		
		if(autoGenerate)
		{
			unsigned int count = 0; 
			objc_property_t *properties = class_copyPropertyList(self.cls, &count);
			for (unsigned int i = 0; i < count; i++ )
			{	
				NSString *propertyName = [NSString stringWithUTF8String: property_getName(properties[i])];
				[self addPropertyDefinitionWithName:propertyName 
											  title:[SCUtilities getUserFriendlyTitleFromName:propertyName] 
											   type:SCPropertyTypeAutoDetect];
			}
			free(properties);
		}
		
		[self setupDefaultConfiguration];
	}
	
	return self;
}

- (instancetype)initWithClass:(Class)_cls propertyNamesString:(NSString *)propertyNamesString
{
    if( (self=[self initWithClass:_cls autoGeneratePropertyDefinitions:NO]) )
	{
		[self generatePropertiesFromPropertyNamesString:propertyNamesString];
		
		[self setupDefaultConfiguration];
		
		self.descriptionPropertyName = nil;
	}
	
	return self;
}

- (instancetype)initWithClass:(Class)_cls propertyNames:(NSArray *)propertyNames
{
	return [self initWithClass:_cls propertyNames:propertyNames propertyTitles:nil];
}

- (instancetype)initWithClass:(Class)_cls propertyNames:(NSArray *)propertyNames propertyTitles:(NSArray *)propertyTitles
{
	if( (self=[self initWithClass:_cls autoGeneratePropertyDefinitions:NO]) )
	{
		[self generatePropertiesFromPropertyNamesArray:propertyNames propertyTitlesArray:propertyTitles];
		
		[self setupDefaultConfiguration];
		
		self.descriptionPropertyName = nil;
	}
	
	return self;
}

- (instancetype)initWithClass:(Class)_cls propertyGroups:(SCPropertyGroupArray *)groups
{
    NSMutableArray *propertyNames = [[NSMutableArray alloc] init];
    for(NSInteger i=0; i<groups.groupCount; i++)
    {
        SCPropertyGroup *propertyGroup = [groups groupAtIndex:i];
        for(NSInteger j=0; j<propertyGroup.propertyNameCount; j++)
            [propertyNames addObject:[propertyGroup propertyNameAtIndex:j]];
    }
    
    if( (self=[self initWithClass:_cls propertyNames:propertyNames]) )
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
    NSString *className = [ibDictionary valueForKey:@"className"];
    [ibDictionary removeObjectForKey:@"className"];
    Class _class = [SCUtilities swiftCompatibleNSClassFromString:className];
    
    self = [self initWithClass:_class autoGeneratePropertyDefinitions:NO];
    
    if(self)
    {
        [self setAllPropertiesFromibDictionary:ibDictionary];
    }
    
    return self;
}


// overrides superclass
- (void)generatePropertiesFromPropertyNamesArray:(NSArray *)propertyNamesArray propertyTitlesArray:(NSArray *)propertyTitlesArray
{
    for(NSUInteger i=0; i<propertyNamesArray.count; i++)
    {
        NSString *propertyName = [propertyNamesArray objectAtIndex:i];
        NSString *propertyTitle;
        if(i < propertyTitlesArray.count)
            propertyTitle = [propertyTitlesArray objectAtIndex:i];
        else
            propertyTitle = [SCUtilities getUserFriendlyTitleFromName:propertyName];
        [self addPropertyDefinitionWithName:propertyName
                                      title:propertyTitle
                                       type:SCPropertyTypeAutoDetect];
    }
}

// overrides superclass
- (NSString *)dataStructureName
{
    return [SCUtilities dataStructureNameForClass:self.cls];
}

// overrides superclass
- (BOOL)insertPropertyDefinition:(SCPropertyDefinition *)propertyDefinition
						 atIndex:(NSInteger)index
{
	if(![propertyDefinition isKindOfClass:[SCCustomPropertyDefinition class]])
	{
		// determine property's data type
        // Get class and propertyName
        Class _class = self.cls;
        NSString *propertyName = nil;
        NSArray *keyPathArray = [propertyDefinition.name componentsSeparatedByString:@"."];
        for(NSUInteger i=0; i<keyPathArray.count; i++)
        {
            propertyName = [keyPathArray objectAtIndex:i];
            objc_property_t property = class_getProperty(_class, [propertyName UTF8String]);
            if(!property)
            {
                SCDebugLog(@"Warning: Property '%@' does not exist in class '%@'.", propertyName, NSStringFromClass(_class));
                return FALSE;
            }
            if(i<keyPathArray.count-1)  // if not last property in keyPath
            {
                NSArray *attributesArray = [[NSString stringWithUTF8String:property_getAttributes(property)] 
                                            componentsSeparatedByString:@","];
                NSString *typeDescription = [attributesArray objectAtIndex:0];
                NSString *className = [typeDescription substringWithRange:NSMakeRange(3, typeDescription.length-4)];
                _class = NSClassFromString(className);
            }
        }
        
        // Set property's dataType & dataReadOnly properties
        objc_property_t property = class_getProperty(_class, [propertyName UTF8String]);
        if(!property)
        {
            SCDebugLog(@"Warning: Property '%@' does not exist in class '%@'.", propertyName, NSStringFromClass(_class));
            return FALSE;
        }
        NSArray *attributesArray = [[NSString stringWithUTF8String: property_getAttributes(property)] 
                                    componentsSeparatedByString:@","];
        NSSet *attributesSet = [NSSet setWithArray:attributesArray];
        
        propertyDefinition.dataReadOnly = [attributesSet containsObject:@"R"];
        propertyDefinition.dataType = [self propertyDataTypeForPropertyWithName:propertyDefinition.name];
	}
    
    return [super insertPropertyDefinition:propertyDefinition atIndex:index];
}

// overrides superclass
- (BOOL)isValidPropertyName:(NSString *)propertyName
{
	BOOL valid = TRUE;
    
    NSArray *keyPathArray = [propertyName componentsSeparatedByString:@"."];
    NSString *pname = nil;
    
    Class _class = self.cls;
    for(NSUInteger i=0; i<keyPathArray.count; i++)
    {
        pname = [keyPathArray objectAtIndex:i];
        objc_property_t property = class_getProperty(_class, [pname UTF8String]);
        if(!property)
        {
            valid = FALSE;
            break;
        }
        if(i<keyPathArray.count-1)  // if not last property in keyPath
        {
            NSArray *attributesArray = [[NSString stringWithUTF8String:property_getAttributes(property)] 
                                        componentsSeparatedByString:@","];
            NSString *typeDescription = [attributesArray objectAtIndex:0];
            NSString *className = [typeDescription substringWithRange:NSMakeRange(3, typeDescription.length-4)];
            _class = NSClassFromString(className);
        }
    }
    
    return valid;
}

// overrides superclass
- (SCDataStore *)generateCompatibleDataStore
{
    return [SCArrayStore storeWithObjectsArray:nil defaultDefiniton:self];
}

@end




