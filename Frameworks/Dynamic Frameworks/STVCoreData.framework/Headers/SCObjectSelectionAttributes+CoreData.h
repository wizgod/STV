/*
 *  SCObjectSelectionAttributes+CoreData.h
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


#import <SensibleTableView/SCPropertyAttributes.h> 

#import "SCEntityDefinition.h"



@interface SCObjectSelectionAttributes (STVCoreData)

//////////////////////////////////////////////////////////////////////////////////////////
/// @name Creation and Initialization
//////////////////////////////////////////////////////////////////////////////////////////

/** Allocates and returns an initialized SCObjectSelectionAttributes.
 *
 *	@param entityDefinition The entity definition of the entity whose objects are to be presented for selection.
 *  @param predicate The predicate used to filter the selection objects. Set to nil to ignore.
 *	@param allowMultipleSel Determines if the generated selection control allows multiple selection.
 *  @warning allowMultipleSel should only be set to TRUE if relationship is many to many.
 *	@param allowNoSel Determines if the generated selection control allows no selection.
 */
+ (instancetype)attributesWithObjectsEntityDefinition:(SCEntityDefinition *)entityDefinition
                             usingPredicate:(NSPredicate *)predicate
                     allowMultipleSelection:(BOOL)allowMultipleSel
                           allowNoSelection:(BOOL)allowNoSel;

/** Returns an initialized SCObjectSelectionAttributes.
 *
 *	@param classDefinition The class definition of the entity whose objects are to be presented for selection.
 *  @param predicate The predicate used to filter the selection objects. Set to nil to ignore.
 *	@param allowMultipleSel Determines if the generated selection control allows multiple selection.
 *  @warning allowMultipleSel should only be set to TRUE if relationship is many to many.
 *	@param allowNoSel Determines if the generated selection control allows no selection.
 */
- (instancetype)initWithObjectsEntityDefinition:(SCEntityDefinition *)entityDefinition
                       usingPredicate:(NSPredicate *)predicate
               allowMultipleSelection:(BOOL)allowMultipleSel
                     allowNoSelection:(BOOL)allowNoSel;



@end
