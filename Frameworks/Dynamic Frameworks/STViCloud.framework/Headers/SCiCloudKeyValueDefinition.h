/*
 *  SCiCloudKeyValueDefinition.h
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


#import <SensibleTableView/SCDictionaryDefinition.h>


/****************************************************************************************/
/*	class SCiCloudKeyValueDefinition	*/
/****************************************************************************************/ 
/**	
 This class functions as a means to define iCloud key-value fields that the framework can automatically generate a user interface for. As with all other types of binding, once the UI is generated, the framework will also be responsible for automatically reading and writing the values to iCloud.
 
 Sample use:
    // Create the iCloud key-value definition
    SCiCloudKeyValueDefinition *iCloudDef = [SCiCloudKeyValueDefinition definitionWithiCloudKeyNamesString:
        @"Login Details:(username,password):Will be automatically signed in"];
    SCPropertyDefinition *passwordDef = [iCloudDef propertyDefinitionWithName:@"password"];
    passwordDef.attributes = [SCTextFieldAttributes attributesWithPlaceholder:nil secureTextEntry:YES
        autocorrectionType:UITextAutocorrectionTypeNo autocapitalizationType:UITextAutocapitalizationTypeNone];
 
    // Generate the UI for the iCloud keys
    [self.tableViewModel generateSectionsForiCloudKeyValueDefinition:iCloudDef];
 
 @see SCPropertyDefinition.
 */


@interface SCiCloudKeyValueDefinition : SCDictionaryDefinition


/** Allocates and returns an initialized SCiCloudKeyValueDefinition given the iCloud key names string. 
 
 By default, all property definitions generated for the given keyNames will have a type of SCPropertyTypeTextField. This can be fully customized after initialization.
 
 @param keyNamesString A string with the key names separated by semi-colons. Example string: @"firstName;lastName". Property groups can also be defined in the string using the following format: @"Personal Details:(firstName, lastName); Address:(street, state, country)". The group title can also be ommitted to create a group with no title. For example: @":(firstName, lastName)".
 
 Key names string syntax options:
    @"key1;key2;key3;..."
    @"group1 header:(key1, key2,...):group1 footer;group2..."
 */
+ (instancetype)definitionWithiCloudKeyNamesString:(NSString *)keyNamesString;

/** Allocates and returns an initialized SCiCloudKeyValueDefinition given the iCloud key names. 
 
 By default, all property definitions generated for the given keyNames will have a type of SCPropertyTypeTextField. This can be fully customized after initialization.
 
 @param keyNames An array of the user defaults key names. All array elements must be of type NSString.
 */
+ (instancetype)definitionWithiCloudKeyNames:(NSArray *)keyNames;

/** Allocates and returns an initialized SCiCloudKeyValueDefinition given the iCloud key names and their titles. 
 
 By default, all property definitions generated for the given keyNames will have a type of SCPropertyTypeTextField. This can be fully customized after initialization.
 
 @param keyNames An array of the user defaults key names. All array elements must be of type NSString.
 @param keyTitles An array of titles to the keys in keyNames. All array elements must be of type NSString.
 */
+ (instancetype)definitionWithiCloudKeyNames:(NSArray *)keyNames keyTitles:(NSArray *)keyTitles;


/** Returns an initialized SCiCloudKeyValueDefinition given the iCloud key names string. 
 
 By default, all property definitions generated for the given keyNames will have a type of SCPropertyTypeTextField. This can be fully customized after initialization.
 
 @param keyNamesString A string with the key names separated by semi-colons. Example string: @"firstName;lastName". Property groups can also be defined in the string using the following format: @"Personal Details:(firstName, lastName); Address:(street, state, country)". The group title can also be ommitted to create a group with no title. For example: @":(firstName, lastName)".
 
 Key names string syntax options:
    @"key1;key2;key3;..."
    @"group1 header:(key1, key2,...):group1 footer;group2..."
 */
- (instancetype)initWithiCloudKeyNamesString:(NSString *)keyNamesString;

/** Returns an initialized 'SCiCloudKeyValueDefinition' given the iCloud key names. 
 
 By default, all property definitions generated for the given keyNames will have a type of SCPropertyTypeTextField. This can be fully customized after initialization.
 
 @param keyNames An array of the user defaults key names. All array elements must be of type NSString.
 */
- (instancetype)initWithiCloudKeyNames:(NSArray *)keyNames;

/** Returns an initialized 'SCiCloudKeyValueDefinition' given the iCloud key names and their titles. 
 
 By default, all property definitions generated for the given keyNames will have a type of SCPropertyTypeTextField. This can be fully customized after initialization.
 
 @param keyNames An array of the user defaults key names. All array elements must be of type NSString.
 @param keyTitles An array of titles to the keys in keyNames. All array elements must be of type NSString.
 */
- (instancetype)initWithiCloudKeyNames:(NSArray *)keyNames keyTitles:(NSArray *)keyTitles;



@end
