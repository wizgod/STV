/*
 *  SCParseStore.h
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

#import <SensibleTableView/SensibleTableView.h>
#import <Parse/Parse.h>

#import "SCParseDefinition.h"


typedef PFQuery*(^SCParseStoreQueryConfiguredAction_Block)(PFQuery *query);
typedef NSDictionary*(^SCParseStoreFetchObjectsCloudCodeFunctionParametersAction_Block)();


/****************************************************************************************/
/*	class SCParseStore	*/
/****************************************************************************************/
/**
 SCParseStore is an SCDataStore subclass that encapsulates remote parse.com data storage, providing means for the SC framework to communicate with this storage to fetch, add, update and remove Parse objects.
 
 @note It is very rare when you'll need to create an SCParseStore instance yourself, as it's typically automatically created for you when you use the SCParseDefinition data definition. For example, when you use the SCArrayOfObjectsSection initializer method called [SCArrayOfObjectsSection sectionWithHeaderTitle:parseDefinition:batchSize:], SCArrayOfObjectsSection automatically sets its dataStore property by calling your parseDefinition's [SCDataDefinition generateCompatibleDataStore:] method.
 
 @note For more information on data stores, check out the SCDataStore base class documentation.
 */
@interface SCParseStore : SCDataStore

//////////////////////////////////////////////////////////////////////////////////////////
/// @name Creation and Initialization
//////////////////////////////////////////////////////////////////////////////////////////

/** Allocates and returns an initialized SCWebServiceStore given a default web service definition. */
+ (instancetype)storeWithDefaultParseDefinition:(SCParseDefinition *)definition;

/** Returns an initialized SCWebServiceStore given a default web service definition. */
- (instancetype)initWithDefaultParseDefinition:(SCParseDefinition *)definition;

//////////////////////////////////////////////////////////////////////////////////////////
/// @name Configuration
//////////////////////////////////////////////////////////////////////////////////////////

/** The Parse store's default data definition. */
@property (nonatomic, strong, readonly) SCParseDefinition *defaultParseDefinition;


/** Action gets called right after the query responsible for fetching the parse objects is configured.
 
 This action is typically used to further customize the query.
 
 @return Return the PFQuery responsible for fetching the parse objects.
 
 Example:
 
    // Objective-C
    myParseStore.queryConfiguredAction = ^PFQuery*(PFQuery *query)
    {
        [query whereKey:@"name" hasPrefix:@"Task"];  // only retrieve objects whose name starts with the word 'Task'
 
        return query;
    };
 
    // Swift
    myParseStore.queryConfiguredAction =
    {
        (query)->PFQuery in
 
        query.whereKey("name", hasPrefix: "Task")  // only retrieve objects whose name starts with the word 'Task'
 
        return query
    }
 
 */
@property (nonatomic, copy) SCParseStoreQueryConfiguredAction_Block queryConfiguredAction;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Cloud Code Configuration
//////////////////////////////////////////////////////////////////////////////////////////

/** When set, STV uses the given PFCloud function to fetch objects instead of a regular PFQuery. */
@property (nonatomic, copy) NSString *fetchObjectsCloudCodeFunctionName;

/** Action gets called to give the user a change to pass on parameters to the specified 'fetchObjectsCloudCodeFunctionName'.
 
 @return Return NSDictionary containing the parameters.
 
 Example:
 
    // Objective-C
    myParseStore.fetchObjectsCloudCodeFunctionParametersAction = ^NSDictionary*(PFQuery *query)
    {
        return @{@"taskStatus" : @"complete"};
    };
 
    // Swift
    myParseStore.fetchObjectsCloudCodeFunctionParametersAction =
    {
        ()->NSDictionary in
 
        return [@"taskStatus" : @"complete"]
    }
 
 */
@property (nonatomic, copy) SCParseStoreFetchObjectsCloudCodeFunctionParametersAction_Block fetchObjectsCloudCodeFunctionParametersAction;


@end
