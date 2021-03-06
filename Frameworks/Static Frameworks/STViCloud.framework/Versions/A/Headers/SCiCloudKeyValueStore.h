/*
 *  SCiCloudKeyValueStore.h
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


#import <SensibleTableView/SCDataStore.h>

/****************************************************************************************/
/*	class SCiCloudKeyValueStore	*/
/****************************************************************************************/ 
/**	
 SCiCloudKeyValueStore is an SCDataStore subclass that encapsulates the iCloud key-value storage, providing means for the SC framework to communicate with this storage to fetch, add, update and remove iCloud key-value entries.
 
 @note It is very rare when you'll need to create an SCiCloudKeyValueStore instance yourself, as it's typically automatically created for you when you use SCiCloudKeyValueDefinition. For example, when you use the SCTableViewModel method called [SCTableViewModel generateSectionsForiCloudKeyValueDefinition:], the model automatically sets its sections' dataStore property by calling your iCloudKeyValueDefinition's [SCDataDefinition generateCompatibleDataStore:] method.
 
 @note For more information on data stores, check out the SCDataStore base class documentation.
 */
@interface SCiCloudKeyValueStore : SCDataStore

/** The ubiquitous iCloud key-value store managed by the data store. */
@property (nonatomic, readonly) NSUbiquitousKeyValueStore *defaultiCloudKeyValueObject;

@end
