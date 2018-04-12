/*
 *  SCArrayOfObjectsCell+CoreData.m
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

#import "SCArrayOfObjectsCell+CoreData.h"

#import "SCCoreDataStore.h"



@implementation SCArrayOfObjectsCell (STVCoreData)

+ (instancetype)cellWithEntityDefinition:(SCEntityDefinition *)definition
{
	return [[[self class] alloc] initWithEntityDefinition:definition];
}

+ (instancetype)cellWithBoundItemsSet:(NSMutableSet *)cellItemsSet boundSetEntityDefinition:(SCEntityDefinition *)definition boundSetOwnsObjects:(BOOL)ownsObjects
{
	return [[[self class] alloc] initWithBoundItemsSet:cellItemsSet boundSetEntityDefinition:definition boundSetOwnsObjects:ownsObjects];
}

- (instancetype)initWithEntityDefinition:(SCEntityDefinition *)definition
{
	SCCoreDataStore *store = [SCCoreDataStore storeWithManagedObjectContext:definition.managedObjectContext defaultEntityDefinition:definition];
	
	self = [self initWithDataStore:store];
    
    return self;
}

- (instancetype)initWithBoundItemsSet:(NSMutableSet *)cellItemsSet boundSetEntityDefinition:(SCEntityDefinition *)definition boundSetOwnsObjects:(BOOL)ownsObjects
{
	SCCoreDataStore *store = [SCCoreDataStore storeWithManagedObjectContext:definition.managedObjectContext boundSet:cellItemsSet boundSetEntityDefinition:definition boundSetOwnsStoreObjects:ownsObjects];
    
	self = [self initWithDataStore:store];
    
    return self;
}

@end
