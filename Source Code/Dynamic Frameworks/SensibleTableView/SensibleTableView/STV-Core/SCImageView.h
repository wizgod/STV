/*
 *  SCImageView.h
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

#import <UIKit/UIKit.h>

/****************************************************************************************/
/*	class SCBadgeView	*/
/****************************************************************************************/
/**
 This class provides a way for UIImageViews to bind themselves to a specific object property.
 */
@interface SCImageView : UIImageView

/** The property the image view is bound to. The runtime value of this property must be one of the following: 1. A UIImage object. 2. An NSURL object containing a URL to the image. 3. The literal name of an image in the app's Resource folder (e.g. "MyImage.png"). */
@property (nonatomic, copy) IBInspectable NSString *boundPropertyName;

@end
