/*
 *  SCDateDefinition.m
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


#import "SCDateDefinition.h"

#import "SCArrayStore.h"
#import <objc/runtime.h>


@implementation SCDateDefinition

@synthesize datePropertyDefinition = _datePropertyDefinition;


+ (instancetype)definition
{
    return [[[self class] alloc] init];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
        _datePropertyDefinition = [[SCPropertyDefinition alloc] initWithName:@"date"];
        _datePropertyDefinition.dataType = SCDataTypeNSDate;
        _datePropertyDefinition.type = SCPropertyTypeDate;
        
        [propertyDefinitions addObject:_datePropertyDefinition];
	}
    
	return self;
}



// overrides superclass
- (SCDataType)propertyDataTypeForPropertyWithName:(NSString *)propertyName
{
    return SCDataTypeNSDate;
}

// overrides superclass
- (NSString *)titleValueForObject:(NSObject *)object
{
    NSString *dateString;
    NSDateFormatter *dateFormatter = nil;
    if([self.datePropertyDefinition.attributes isKindOfClass:[SCDateAttributes class]])
    {
        dateFormatter = [(SCDateAttributes *)self.datePropertyDefinition.attributes dateFormatter];
    }
    
    if(dateFormatter)
    {
        dateString = [dateFormatter stringFromDate:(NSDate *)object];
    }
    else
    {
        dateString = [NSString stringWithFormat:@"%@", object];
    }
       
    return dateString; 
}

// overrides superclass
- (NSString *)descriptionValueForObject:(NSObject *)object
{
    // Not applicable for NSDate objects
    return nil;
}

// overrides superclass
- (NSString *)dataStructureName
{
	return [SCUtilities dataStructureNameForClass:[NSDate class]];
}

// overrides superclass
- (SCDataStore *)generateCompatibleDataStore
{
    return [SCArrayStore storeWithObjectsArray:nil defaultDefiniton:self];
}


@end
