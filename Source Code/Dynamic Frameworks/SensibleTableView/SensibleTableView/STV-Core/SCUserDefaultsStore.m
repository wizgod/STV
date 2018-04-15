/*
 *  SCUserDefaultsStore.m
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


#import "SCUserDefaultsStore.h"

@implementation SCUserDefaultsStore

- (NSUserDefaults *)standardUserDefaultsObject
{
    return [NSUserDefaults standardUserDefaults];
}

// overrides superclass
- (SCDataDefinition *)definitionForObject:(NSObject *)object
{
    return self.defaultDataDefinition;
}

// overrides superclass
- (void)setDefaultsDictionary:(NSDictionary *)defaultsDictionary
{
    [super setDefaultsDictionary:defaultsDictionary];
    
    [self.standardUserDefaultsObject registerDefaults:defaultsDictionary];
}

// overrides superclass
- (NSArray *)fetchObjectsWithOptions:(SCDataFetchOptions *)fetchOptions
{
    return [NSArray arrayWithObject:self.standardUserDefaultsObject];
}

// overrides superclass
- (void)commitData
{
    [self.standardUserDefaultsObject synchronize];
}

@end


