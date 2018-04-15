/*
 *  SCEntityDefinition.h
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

#import <CoreData/CoreData.h>


#import <SensibleTableView/SCDataDefinition.h> 


/****************************************************************************************/
/*	class SCEntityDefinition	*/
/****************************************************************************************/ 
/**	
 This class functions as a means to further extend the definition of user-defined Core Data entities.
 Using entity definitions, classes like SCObjectCell and SCObjectSection 
 will be able to better generate user interface elements that truly represent the 
 properties of their bound objects. 
 
 SCEntityDefinition mainly consists of one or more property definitions of type SCPropertyDefinition.
 Upon creation, SCEntityDefinition will (optionally) automatically generate all the
 property definitions for the given entity. From there, the user will be able to customize
 the generated property definitions, add new definitions, or remove generated definitions.
 
 Sample use:
    // Extend the definition of 'TaskEntity' (user defined Core Data entity)
    SCEntityDefinition *taskDef = [SCEntityDefinition definitionWithEntityName:@"TaskEntity"
        managedObjectContext:context
        propertyNamesString:@"Task Details:(name,description,category,dueDate);Task Status:(completed)"];
    SCPropertyDefinition *namePropertyDef = [taskDef propertyDefinitionWithName:@"name"];
    namePropertyDef.required = TRUE;
    SCPropertyDefinition *descPropertyDef = [taskDef propertyDefinitionWithName:@"description"];
    descPropertyDef.type = SCPropertyTypeTextView;
    SCPropertyDefinition *categoryPropertyDef = [taskDef propertyDefinitionWithName:@"category"];
    categoryPropertyDef.type = SCPropertyTypeSelection;
    NSArray *categoryItems = [NSArray arrayWithObjects:@"Home", @"Work", @"Other", nil];
    categoryPropertyDef.attributes = [SCSelectionAttributes attributesWithItems:categoryItems 
        allowMultipleSelection:NO allowNoSelection:NO];
 
 @see SCPropertyDefinition.
 */
@interface SCEntityDefinition : SCDataDefinition


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Creation and Initialization
//////////////////////////////////////////////////////////////////////////////////////////

/** Allocates and returns an initialized SCEntityDefinition given a Core Data entity name and the option to auto generate property definitions for the given entity's properties.
 
 The method will also generate user friendly property titles from the names of
 the generated properties. These titles can be modified by the user later as part of
 the property definition customization.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param autoGenerate If TRUE, 'SCClassDefinition' will automatically generate all the property definitions for the given entity's attributes.
 
 @warning Note: This method attempts to automatically determine the required NSManagedObjectContext by querying the current app delegate. If your app delegate does not provide an NSManagedObjectContext, or if you'd like to provide a diffrerent one, please use definitionWithEntityName:managedObjectContext:autoGeneratePropertyDefinitions: instead.
 */
+ (instancetype)definitionWithEntityName:(NSString *)entityName autoGeneratePropertyDefinitions:(BOOL)autoGenerate;

/** Allocates and returns an initialized SCEntityDefinition given a Core Data entity name and a string of the property names to generate property definitions for.
 
 The method will also generate user friendly property titles from the names of 
 the given properties. These titles can be modified by the user later as part of
 the property definition customization.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param propertyNamesString A string with the property names separated by semi-colons. Example string: @"firstName;lastName". Property groups can also be defined in the string using the following format: @"Personal Details:(firstName, lastName); Address:(street, state, country)". The group title can also be ommitted to create a group with no title. For example: @":(firstName, lastName)".
 
 Property names string syntax options:
    @"property1;property2;property3;..."
    @"group1 header:(property1, property2,...):group1 footer;group2..."
 
 @warning Note: This method attempts to automatically determine the required NSManagedObjectContext by querying the current app delegate. If your app delegate does not provide an NSManagedObjectContext, or if you'd like to provide a diffrerent one, please use definitionWithEntityName:managedObjectContext:propertyNamesString: instead.
 */
+ (instancetype)definitionWithEntityName:(NSString *)entityName propertyNamesString:(NSString *)propertyNamesString;

/** Allocates and returns an initialized SCEntityDefinition given a Core Data entity name and the option to auto generate property definitions for the given entity's properties.
 
 The method will also generate user friendly property titles from the names of
 the generated properties. These titles can be modified by the user later as part of
 the property definition customization.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param context The managed object context of the entity.
 @param autoGenerate If TRUE, 'SCClassDefinition' will automatically generate all the property definitions for the given entity's attributes.
 */
+ (instancetype)definitionWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context autoGeneratePropertyDefinitions:(BOOL)autoGenerate;

/** Allocates and returns an initialized SCEntityDefinition given a Core Data entity name and a string of the property names to generate property definitions for.
 
 The method will also generate user friendly property titles from the names of
 the given properties. These titles can be modified by the user later as part of
 the property definition customization.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param context The managed object context of the entity.
 @param propertyNamesString A string with the property names separated by semi-colons. Example string: @"firstName;lastName". Property groups can also be defined in the string using the following format: @"Personal Details:(firstName, lastName); Address:(street, state, country)". The group title can also be ommitted to create a group with no title. For example: @":(firstName, lastName)".
 
 Property names string syntax options:
    @"property1;property2;property3;..."
    @"group1 header:(property1, property2,...):group1 footer;group2..."
 */
+ (instancetype)definitionWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNamesString:(NSString *)propertyNamesString;

/** Allocates and returns an initialized SCEntityDefinition given a Core Data entity name and an array of the property names to generate property definitions for.
 
 The method will also generate user friendly property titles from the names of 
 the given properties. These titles can be modified by the user later as part of
 the property definition customization.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param context The managed object context of the entity.
 @param propertyNames An array of the names of properties to be generated. All array elements must be of type NSString.
 */
+ (instancetype)definitionWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNames:(NSArray *)propertyNames;

/** Allocates and returns an initialized 'SCEntityDefinition' given a Core Data entity name, an array of
 the property names to generate property definitions for, and array of titles
 for these properties.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param context The managed object context of the entity.
 @param propertyNames An array of the names of properties to be generated. All array elements must be of type NSString.
 @param propertyTitles An array of titles to the properties in propertyNames. All array elements must be of type NSString.
 */
+ (instancetype)definitionWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNames:(NSArray *)propertyNames propertyTitles:(NSArray *)propertyTitles;

/** Allocates and returns an initialized SCEntityDefinition given a Core Data entity name and an SCPropertyGroupArray.
 * 
 *	@param entityName The name of the entity for which the definition will be extended.
 *	@param context The managed object context of the entity.
 *	@param groups A collection of property groups. 
 */
+ (instancetype)definitionWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyGroups:(SCPropertyGroupArray *)groups;


/** Returns an initialized SCEntityDefinition given a Core Data entity name and the option to auto generate property definitions for the given entity's properties.
 
 The method will also generate user friendly property titles from the names of 
 the generated properties. These titles can be modified by the user later as part of
 the property definition customization.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param autoGenerate If TRUE, SCEntityDefinition will automatically generate all the property definitions for the given entity's attributes.
 
 @warning Note: This method attempts to automatically determine the required NSManagedObjectContext by querying the current app delegate. If your app delegate does not provide an NSManagedObjectContext, or if you'd like to provide a diffrerent one, please use initWithEntityName:managedObjectContext:autoGeneratePropertyDefinitions: instead.
 */
- (instancetype)initWithEntityName:(NSString *)entityName autoGeneratePropertyDefinitions:(BOOL)autoGenerate;

/** Returns an initialized SCEntityDefinition given a Core Data entity name and a string of the property names to generate property definitions for.
 
 The method will also generate user friendly property titles from the names of 
 the given properties. These titles can be modified by the user later as part of
 the property definition customization.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param propertyNamesString A string with the property names separated by semi-colons. Example string: @"firstName;lastName". Property groups can also be defined in the string using the following format: @"Personal Details:(firstName, lastName); Address:(street, state, country)". The group title can also be ommitted to create a group with no title. For example: @":(firstName, lastName)".
 
 Property names string syntax options:
    @"property1;property2;property3;..."
    @"group1 header:(property1, property2,...):group1 footer;group2..."
 
 @warning Note: This method attempts to automatically determine the required NSManagedObjectContext by querying the current app delegate. If your app delegate does not provide an NSManagedObjectContext, or if you'd like to provide a diffrerent one, please use initWithEntityName:managedObjectContext:propertyNamesString: instead.
 */
- (instancetype)initWithEntityName:(NSString *)entityName propertyNamesString:(NSString *)propertyNamesString;

/** Returns an initialized SCEntityDefinition given a Core Data entity name and the option to auto generate property definitions for the given entity's properties.
 
 The method will also generate user friendly property titles from the names of
 the generated properties. These titles can be modified by the user later as part of
 the property definition customization.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param context The managed object context of the entity.
 @param autoGenerate If TRUE, SCEntityDefinition will automatically generate all the property definitions for the given entity's attributes.
 */
- (instancetype)initWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context  autoGeneratePropertyDefinitions:(BOOL)autoGenerate;

/** Returns an initialized SCEntityDefinition given a Core Data entity name and a string of the property names to generate property definitions for.
 
 The method will also generate user friendly property titles from the names of
 the given properties. These titles can be modified by the user later as part of
 the property definition customization.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param context The managed object context of the entity.
 @param propertyNamesString A string with the property names separated by semi-colons. Example string: @"firstName;lastName". Property groups can also be defined in the string using the following format: @"Personal Details:(firstName, lastName); Address:(street, state, country)". The group title can also be ommitted to create a group with no title. For example: @":(firstName, lastName)".
 
 Property names string syntax options:
    @"property1;property2;property3;..."
    @"group1 header:(property1, property2,...):group1 footer;group2..."
 */
- (instancetype)initWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNamesString:(NSString *)propertyNamesString;

/** Returns an initialized SCEntityDefinition given a Core Data entity name and an array of the property names to generate property definitions for.
 
 The method will also generate user friendly property titles from the names of 
 the given properties. These titles can be modified by the user later as part of
 the property definition customization.
 
 @param entityName The name of the entity for which the definition will be extended.
 @param context The managed object context of the entity.
 @param propertyNames An array of the names of properties to be generated. All array elements must be of type NSString.
 */
- (instancetype)initWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNames:(NSArray *)propertyNames;

/** Returns an initialized SCEntityDefinition given a Core Data entity name, an array of
 the property names to generate property definitions for, and array of titles
 for these properties.
 *
 *	@param entityName The name of the entity for which the definition will be extended.
 *	@param context The managed object context of the entity.
 *	@param propertyNames An array of the names of properties to be generated. All array elements must be of type NSString.
 *	@param propertyTitles An array of titles to the properties in propertyNames. All array elements must be of type NSString.
 *
 */
- (instancetype)initWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyNames:(NSArray *)propertyNames propertyTitles:(NSArray *)propertyTitles;

/** Returns an initialized SCEntityDefinition given a Core Data entity name and an SCPropertyGroupArray.
 * 
 *	@param entityName The name of the entity for which the definition will be extended.
 *	@param context The managed object context of the entity.
 *	@param groups A collection of property groups. 
 */
- (instancetype)initWithEntityName:(NSString *)entityName managedObjectContext:(NSManagedObjectContext *)context propertyGroups:(SCPropertyGroupArray *)groups;

//////////////////////////////////////////////////////////////////////////////////////////
/// @name Configuration
//////////////////////////////////////////////////////////////////////////////////////////

/** The entity associated with the definition. */
@property (nonatomic, readonly, strong) NSEntityDescription *entity;

/** The managed object context of the entity associated with the definition. */
@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;

/**	The name of the entity attribute that will be used to store the display order of its objects. 
 
 Setting this property to a valid attribute name allows for custom re-ordering of the generated
 user interface elements representing the Core Data objects (e.g. custom re-ordering of cells).
 Setting this property overrides the value set for the keyPropertyName property.
 @warning Important: This Core Data attribute must be of integer type. */
@property (nonatomic, copy) NSString *orderAttributeName;


@end
