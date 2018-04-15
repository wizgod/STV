/*
 *  SCNumberDefinition.m
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


#import "SCNumberDefinition.h"

#import "SCArrayStore.h"
#import <objc/runtime.h>


@implementation SCNumberDefinition

@synthesize numberPropertyDefinition = _numberPropertyDefinition;


+ (instancetype)definition
{
    return [[[self class] alloc] init];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
        _numberPropertyDefinition = [[SCPropertyDefinition alloc] initWithName:@"number"];
        _numberPropertyDefinition.dataType = SCDataTypeNSNumber;
        _numberPropertyDefinition.type = SCPropertyTypeNumericTextField;
        
        [propertyDefinitions addObject:_numberPropertyDefinition];
	}
    
	return self;
}



// overrides superclass
- (SCDataType)propertyDataTypeForPropertyWithName:(NSString *)propertyName
{
    return SCDataTypeNSNumber;
}

// overrides superclass
- (NSString *)titleValueForObject:(NSObject *)object
{
    NSString *numberString;
    NSNumberFormatter *numberFormatter = nil;
    if([self.numberPropertyDefinition.attributes isKindOfClass:[SCNumericTextFieldAttributes class]])
    {
        numberFormatter = [(SCNumericTextFieldAttributes *)self.numberPropertyDefinition.attributes numberFormatter];
    }
    
    if(numberFormatter)
    {
        numberString = [numberFormatter stringFromNumber:(NSNumber *)object];
    }
    else
    {
        numberString = [(NSNumber *)object stringValue];
    }
    
    return numberString; 
}

// overrides superclass
- (NSString *)descriptionValueForObject:(NSObject *)object
{
    // Not applicable for NSNumber objects
    return nil;
}

// overrides superclass
- (NSString *)dataStructureName
{
	return [SCUtilities dataStructureNameForClass:[NSNumber class]];
}

// overrides superclass
- (SCDataStore *)generateCompatibleDataStore
{
    return [SCArrayStore storeWithObjectsArray:nil defaultDefiniton:self];
}


@end
