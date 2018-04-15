/*
 *  SCArrayOfObjectsModel+Parse.h
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

#import <SensibleTableView/SensibleTableView.h>

#import "SCParseDefinition.h"


@interface SCArrayOfObjectsModel (STVParse)

/**
 Allocates and returns an initialized SCArrayOfObjectsModel given a UITableView
 and a Parse definition.
 
 @note This method creates a model with all the objects that fetched by the Parse definition.
 
 @param tableView The UITableView to be bound to the model.
 @param definition The Parse definition of the objects to fetch.
 */
+ (instancetype)modelWithTableView:(UITableView *)tableView parseDefinition:(SCParseDefinition *)definition;

/**
 Allocates and returns an initialized SCArrayOfObjectsModel given a UITableView
 and a Parse definition.
 
 @note This method creates a model with all the objects that fetched by the Parse definition.
 
 @param tableView The UITableView to be bound to the model.
 @param definition The Parse definition of the objects to fetch.
 @param batchSize The size of the batch to be fetched.
 */
+ (instancetype)modelWithTableView:(UITableView *)tableView parseDefinition:(SCParseDefinition *)definition batchSize:(NSUInteger)batchSize;


/**
 Returns an initialized SCArrayOfObjectsModel given a UITableView
 and a Parse definition.
 
 @note This method creates a model with all the objects that fetched by the Parse definition.
 
 @param tableView The UITableView to be bound to the model.
 @param definition The Parse definition of the objects to fetch.
 */
- (instancetype)initWithTableView:(UITableView *)tableView parseDefinition:(SCParseDefinition *)definition;

/**
 Returns an initialized SCArrayOfObjectsModel given a UITableView
 and a Parse definition.
 
 @note This method creates a model with all the objects that fetched by the Parse definition.
 
 @param tableView The UITableView to be bound to the model.
 @param definition The Parse definition of the objects to fetch.
 @param batchSize The size of the batch to be fetched.
 */
- (instancetype)initWithTableView:(UITableView *)tableView parseDefinition:(SCParseDefinition *)definition batchSize:(NSUInteger)batchSize;

@end
