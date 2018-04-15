/*
 *  SCArrayOfObjectsSection+WebServices.m
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


#import "SCArrayOfObjectsSection+WebServices.h"

#import "SCWebServiceFetchOptions.h"
#import "SCWebServiceStore.h"



@implementation SCArrayOfObjectsSection (STVWebServices)

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle webServiceDefinition:(SCWebServiceDefinition *)definition
{
    return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle webServiceDefinition:definition];
}

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle webServiceDefinition:(SCWebServiceDefinition *)definition batchSize:(NSUInteger)batchSize
{
    return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle webServiceDefinition:definition batchSize:batchSize];
}


- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle webServiceDefinition:(SCWebServiceDefinition *)definition
{
    SCWebServiceStore *store = [SCWebServiceStore storeWithDefaultWebServiceDefinition:definition];
    
    if( (self = [self initWithHeaderTitle:sectionHeaderTitle dataStore:store]) )
    {
        // initialize here
    }
    return self;
}

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle webServiceDefinition:(SCWebServiceDefinition *)definition batchSize:(NSUInteger)batchSize
{
    SCWebServiceStore *store = [SCWebServiceStore storeWithDefaultWebServiceDefinition:definition];
    
    if( (self = [self initWithHeaderTitle:sectionHeaderTitle dataStore:store]) )
    {
        self.dataFetchOptions.batchSize = batchSize;
    }
    return self;
}

@end
