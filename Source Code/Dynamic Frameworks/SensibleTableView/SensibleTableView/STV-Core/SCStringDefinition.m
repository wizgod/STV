/*
 *  SCStringDefinition.m
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


#import "SCStringDefinition.h"

#import "SCArrayStore.h"
#import <objc/runtime.h>


@implementation SCStringDefinition

@synthesize stringPropertyDefinition = _stringPropertyDefinition;


+ (instancetype)definition
{
    return [[[self class] alloc] init];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
        _stringPropertyDefinition = [[SCPropertyDefinition alloc] initWithName:@"string"];
        _stringPropertyDefinition.dataType = SCDataTypeNSString;
        _stringPropertyDefinition.type = SCPropertyTypeTextField;
        
        [propertyDefinitions addObject:_stringPropertyDefinition];
	}
    
	return self;
}



// overrides superclass
- (SCDataType)propertyDataTypeForPropertyWithName:(NSString *)propertyName
{
    return SCDataTypeNSString;
}

// overrides superclass
- (NSString *)titleValueForObject:(NSObject *)object
{
    return (NSString *)object;  // The object itself is an NSString
}

// overrides superclass
- (NSString *)descriptionValueForObject:(NSObject *)object
{
    // Not applicable for NSString objects
    return nil;
}

// overrides superclass
- (NSString *)dataStructureName
{
	return [SCUtilities dataStructureNameForClass:[NSString class]];
}

// overrides superclass
- (SCDataStore *)generateCompatibleDataStore
{
    return [SCArrayStore storeWithObjectsArray:nil defaultDefiniton:self];
}


@end
