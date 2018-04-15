/*
 *  SCParseDefinition.h
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


/** @enum The access control types of an SCParseDefinition */
typedef enum
{
    /**	Access only for the current logged in user. */
    SCParseAccessControlCurrentUser=0,
    /**	Public access. */
    SCParseAccessControlPublic=5
    
} SCParseAccessControl;



/****************************************************************************************/
/*	class SCParseDefinition	*/
/****************************************************************************************/
/**
 This class functions as a means to further extend the definition of http://parse.com application classes.
 
 Sample use:
    // Extend the parse.com Task class definition
    SCParseDefinition *taskDef = [SCParseDefinition definitionWithClassName:@"Task" columnNamesString:@"name;description;category;active" applicationId:@"5lg8lYLmgco0mFnimqXGdb4AK95YVOZabc4YJmHp" clientKey:@"OwBFtIYUFck5Eqo1zWbw7KJ8V6eyYet0AHMepESV"];
    SCPropertyDefinition *descPDef = [taskDef propertyDefinitionWithName:@"description"];
    descPDef.type = SCPropertyTypeTextView;
    SCPropertyDefinition *categoryPDef = [taskDef propertyDefinitionWithName:@"category"];
    categoryPDef.type = SCPropertyTypeSelection;
    categoryPDef.attributes = [SCSelectionAttributes attributesWithItems:@[@"Home", @"Work", @"Other"] allowMultipleSelection:NO allowNoSelection:NO];
    SCPropertyDefinition *activePDef = [taskDef propertyDefinitionWithName:@"active"];
    activePDef.type = SCPropertyTypeSwitch;
 
    // Create a section of all the parse.com task classes
    SCArrayOfObjectsSection *objectsSection = [SCArrayOfObjectsSection sectionWithHeaderTitle:nil parseDefinition:taskDef batchSize:0];
    objectsSection.dataFetchOptions.sort = TRUE;
    [self.tableViewModel addSection:objectsSection];
 
 @see SCPropertyDefinition.
 */
@interface SCParseDefinition : SCDictionaryDefinition

//////////////////////////////////////////////////////////////////////////////////////////
/// @name Creation and Initialization
//////////////////////////////////////////////////////////////////////////////////////////

/** Allocates and returns an initialized SCParseComDefinition.
 @param className The parse.com class name.
 @param columnNames The column names of the class separated by semi-colons.
 @param applicationId The parse.com application id.
 @param clientKey The parse.com rest API key.
 */
+ (instancetype)definitionWithClassName:(NSString *)className columnNamesString:(NSString *)columnNames applicationId:(NSString *)applicationId clientKey:(NSString *)clientKey;

/** Returns an initialized SCParseComDefinition.
 @param className The parse.com class name.
 @param columnNames The column names of the class separated by semi-colons.
 @param applicationId The parse.com application id.
 @param clientKey The parse.com rest API key.
 */
- (instancetype)initWithClassName:(NSString *)className columnNamesString:(NSString *)columnNames applicationId:(NSString *)applicationId clientKey:(NSString *)clientKey;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Configuration
//////////////////////////////////////////////////////////////////////////////////////////

/** The parse.com class name. */
@property (nonatomic, copy) NSString *className;

/** The parse.com application id. */
@property (nonatomic, copy) NSString *applicationId;

/** The parse.com client key. */
@property (nonatomic, copy) NSString *clientKey;

/** The access control for the data definition. */
@property (nonatomic) SCParseAccessControl accessControl;

@end





// Create an SCParseDefinition alias called SCParseComDefinition (for backwards compatibility with STV 3.0)
#define SCParseComDefinition   SCParseDefinition



