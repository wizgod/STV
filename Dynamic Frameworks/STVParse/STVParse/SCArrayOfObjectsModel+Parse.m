/*
 *  SCArrayOfObjectsModel+Parse.m
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
 *  Copyright 2012-2014 Sensible Cocoa. All rights reserved.
 *
 *
 *	This notice may not be removed from this file.
 *
 */

#import "SCArrayOfObjectsModel+Parse.h"

#import "SCParseStore.h"


@implementation SCArrayOfObjectsModel (STVParse)

+ (instancetype)modelWithTableView:(UITableView *)tableView parseDefinition:(SCParseDefinition *)definition
{
    return [[[self class] alloc] initWithTableView:tableView parseDefinition:definition];
}

+ (instancetype)modelWithTableView:(UITableView *)tableView parseDefinition:(SCParseDefinition *)definition batchSize:(NSUInteger)batchSize
{
    return [[[self class] alloc] initWithTableView:tableView parseDefinition:definition batchSize:batchSize];
}


- (instancetype)initWithTableView:(UITableView *)tableView parseDefinition:(SCParseDefinition *)definition
{
    SCParseStore *store = [SCParseStore storeWithDefaultParseDefinition:definition];
    
    if( (self = [self initWithTableView:tableView dataStore:store]) )
    {
        // initialize here
    }
    return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView parseDefinition:(SCParseDefinition *)definition batchSize:(NSUInteger)batchSize
{
    SCParseStore *store = [SCParseStore storeWithDefaultParseDefinition:definition];
    
    if( (self = [self initWithTableView:tableView dataStore:store]) )
    {
        self.dataFetchOptions.batchSize = batchSize;
    }
    return self;
}

@end
