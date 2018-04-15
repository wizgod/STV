/*
 *  SCCoreDataStore.h
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


#import "SCEntityDefinition.h"
#import <SensibleTableView/SCDataStore.h> 


/****************************************************************************************/
/*	class SCCoreDataStore	*/
/****************************************************************************************/ 
/**	
 SCCoreDataStore is an SCDataStore subclass that encapsulates Core Data persistent storage, providing means for the SC framework to communicate with this storage to fetch, add, update and remove data objects.
 
 @note It is very rare when you'll need to create an SCCoreDataStore instance yourself, as it's typically automatically created for you when you use the SCEntityDefinition data definition. For example, when you use the SCArrayOfObjectsSection initializer method called [SCArrayOfObjectsSection sectionWithHeaderTitle:entityDefinition:], SCArrayOfObjectsSection automatically sets its dataStore property by calling your entityDefinition's [SCDataDefinition generateCompatibleDataStore:] method.
 
 @note For more information on data stores, check out the SCDataStore base class documentation.
 */
@interface SCCoreDataStore : SCDataStore

//////////////////////////////////////////////////////////////////////////////////////////
/// @name Creation and Initialization
//////////////////////////////////////////////////////////////////////////////////////////

/** Allocates and returns an initialized SCCoreDataStore given a managed object context and an entity definition. 
 @param context The Core Data managed object context.
 @param definition The entity definition of the entity objects in the data store.
 */
+ (instancetype)storeWithManagedObjectContext:(NSManagedObjectContext *)context defaultEntityDefinition:(SCEntityDefinition *)definition;

/** Allocates and returns an initialized SCCoreDataStore given a managed object context and an NSMutableSet to bind the data store to. 
 @param context The Core Data managed object context.
 @param set An NSMutableSet that the data store will bind to and fetch all its objects from.
 @param definition The entity definition of the entity objects in the bound set.
 @param ownsStoreObjects When TRUE, objects removed from the bound set will also be removed from the data store.
 */
+ (instancetype)storeWithManagedObjectContext:(NSManagedObjectContext *)context boundSet:(NSMutableSet *)set boundSetEntityDefinition:(SCEntityDefinition *)definition boundSetOwnsStoreObjects:(BOOL)ownsStoreObjects;

/** Returns an initialized SCCoreDataStore given a managed object context and an entity definition. 
 @param context The Core Data managed object context.
 @param definition The entity definition of the entity objects in the data store.
 */
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context defaultEntityDefinition:(SCEntityDefinition *)definition;

/** Returns an initialized SCCoreDataStore given a managed object context and an NSMutableSet to bind the data store to. 
 @param context The Core Data managed object context.
 @param set An NSMutableSet that the data store will bind to and fetch all its objects from.
 @param definition The entity definition of the entity objects in the bound set.
 @param ownsStoreObjects When TRUE, objects removed from the bound set will also be removed from the data store.
 */
- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context boundSet:(NSMutableSet *)set boundSetEntityDefinition:(SCEntityDefinition *)definition boundSetOwnsStoreObjects:(BOOL)ownsStoreObjects;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Configuration
//////////////////////////////////////////////////////////////////////////////////////////

/** The managed object context associated with the store. */
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

/** The NSMutableSet the store is bound to. This property is automatically set by bindStoreToPropertyName:forObject:withDefinition: method. */
@property (nonatomic, strong, readonly) NSMutableSet *boundSet;

/** The NSMutableOrderedSet the store is bound to. This property is automatically set by bindStoreToPropertyName:forObject:withDefinition: method. */
@property (nonatomic, strong, readonly) NSMutableOrderedSet *boundOrderedSet;

/** When TRUE, objects removed from boundSet will also be removed from the data store. */
@property (nonatomic, readonly) BOOL boundSetOwnsStoreObjects;


@end
