/*
 *  SCCoreDataFetchOptions.h
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


#import <SensibleTableView/SCDataFetchOptions.h>

/****************************************************************************************/
/*	class SCCoreDataFetchOptions	*/
/****************************************************************************************/ 
/**	
 SCCoreDataFetchOptions further extends the SCDataFetchOptions subclass to control how data is fetched from SCCoreDataStore. 
 
 @note For more information on fetch options, check out the SCDataFetchOptions documentation.
 */

@interface SCCoreDataFetchOptions : SCDataFetchOptions
{
    NSString *_orderAttributeName;
}

/**	The name of the attribute that will be used to determine the fetch order of the objects. 
 
 @note This value is automatically set by the framework to the value in [SCEntityDefinition orderAttributeName], which makes you rarely need to set this value yourself.
 */
@property (nonatomic, copy) NSString *orderAttributeName;

@end
