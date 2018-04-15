/*
 *  SCArrayOfObjectsSection+CoreData.h
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


#import <SensibleTableView/SCTableViewSection.h> 

#import "SCEntityDefinition.h"

@interface SCArrayOfObjectsSection (STVCoreData)

/** 
 Allocates and returns an initialized 'SCArrayOfObjectsSection' given a header title and 
 an entity definition. 
 
 @note This method creates a section with all the objects that
 exist in classDefinition's entity's managedObjectContext. To create a section with only a subset
 of these objects, consider using the other section initializers.
 
 @param sectionHeaderTitle A header title for the section.
 @param definition The entity definition of the objects to fetch.
 */
+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle entityDefinition:(SCEntityDefinition *)definition;

/** Allocates and returns an initialized 'SCArrayOfObjectsSection' given a header title, an entity definition, and an NSPredicate. 
 *
 *	@param sectionHeaderTitle A header title for the section.
 *	@param definition The entity definition of the objects to fetch.
 *	@param perdicate The predicate that will be used to filter the fetched objects.
 */
+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle entityDefinition:(SCEntityDefinition *)definition filterPredicate:(NSPredicate *)predicate;


/** 
 Returns an initialized 'SCArrayOfObjectsSection' given a header title and 
 an entity definition. 
 
 @note This method creates a section with all the objects that
 exist in classDefinition's entity's managedObjectContext. To create a section with only a subset
 of these objects, consider using the other section initializers.
 
 @param sectionHeaderTitle A header title for the section.
 @param definition The entity definition of the objects to fetch.
 */
- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle entityDefinition:(SCEntityDefinition *)definition;

/** Returns an initialized 'SCArrayOfObjectsSection' given a header title, an entity definition, and an NSPredicate. 
 *
 *	@param sectionHeaderTitle A header title for the section.
 *	@param definition The entity definition of the objects to fetch.
 *	@param perdicate The predicate that will be used to filter the fetched objects.
 */
- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle entityDefinition:(SCEntityDefinition *)definition filterPredicate:(NSPredicate *)predicate;

@end
