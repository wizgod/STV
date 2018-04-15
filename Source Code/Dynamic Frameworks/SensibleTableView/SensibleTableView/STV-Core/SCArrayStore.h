/*
 *  SCArrayStore.h
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

#import "SCDataStore.h"


/****************************************************************************************/
/*	class SCArrayStore	*/
/****************************************************************************************/ 
/**	
 SCArrayStore is an SCDataStore subclass that encapsulates NSArray memory storage, providing means for the SC framework to communicate with this array storage to fetch, add, update and remove data objects.

 @note It is very rare when you'll need to create an SCArrayStore instance yourself, as it's typically automatically created for you when you use data definitions such as SCClassDefinition and SCDictionaryDefinition. For example, when you use the SCArrayOfObjectsSection initializer method called [SCArrayOfObjectsSection sectionWithHeaderTitle:items:itemsDefinition:], SCArrayOfObjectsSection automatically sets its dataStore property by calling your itemsDefinition's [SCDataDefinition generateCompatibleDataStore:] method.
 
 @note For more information on data stores, check out the SCDataStore base class documentation.
*/
@interface SCArrayStore : SCDataStore


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Creation and Initialization
//////////////////////////////////////////////////////////////////////////////////////////

/** Allocates and returns an initialized SCArrayStore given an array of objects and their default data definition. */
+ (instancetype)storeWithObjectsArray:(NSMutableArray *)array defaultDefiniton:(SCDataDefinition *)definition;

/** Returns an initialized SCArrayStore given an array of objects and their default data definition. */
- (id)initWithObjectsArray:(NSMutableArray *)array defaultDefiniton:(SCDataDefinition *)definition;

/** The objects array storage managed by the memory store. */
@property (nonatomic, strong) NSMutableArray *objectsArray;

@end





// Create an SCArrayStore alias called SCMemoryStore (for backward compatibility with STV 3.0)
#define SCMemoryStore   SCArrayStore



