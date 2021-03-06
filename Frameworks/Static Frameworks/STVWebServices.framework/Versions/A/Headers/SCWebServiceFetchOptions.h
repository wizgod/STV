/*
 *  SCWebServiceFetchOptions.h
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
/*	class SCWebServiceFetchOptions	*/
/****************************************************************************************/ 
/**	
 SCWebServiceFetchOptions further extends the SCDataFetchOptions subclass to control how data is fetched from SCWebServiceStore. 
 
 @note For more information on fetch options, check out the SCDataFetchOptions documentation.
 */
@interface SCWebServiceFetchOptions : SCDataFetchOptions

// Property used internally by the framework to store the URL of the next objects batch.
@property (nonatomic, copy) NSString *nextBatchURLString;

// Property used internally by the framework to store the token of the next objects batch.
@property (nonatomic, copy) NSString *nextBatchToken;

@end
