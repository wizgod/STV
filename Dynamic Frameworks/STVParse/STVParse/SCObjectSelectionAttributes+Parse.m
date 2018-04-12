/*
 *  SCObjectSelectionAttributes+Parse.m
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
 *  Copyright 2012-2014 Sensible Cocoa. All rights reserved.
 *
 *
 *	This notice may not be removed from this file.
 *
 */

#import "SCObjectSelectionAttributes+Parse.h"

#import "SCParseStore.h"

@implementation SCObjectSelectionAttributes (STVParse)

+ (instancetype)attributesWithObjectsParseDefinition:(SCParseDefinition *)definition
                    allowMultipleSelection:(BOOL)allowMultipleSel
                          allowNoSelection:(BOOL)allowNoSel
{
    return [[[self class] alloc] initWithObjectsParseDefinition:definition
                                              allowMultipleSelection:allowMultipleSel
                                                    allowNoSelection:allowNoSel];
}


- (instancetype)initWithObjectsParseDefinition:(SCParseDefinition *)definition
              allowMultipleSelection:(BOOL)allowMultipleSel
                    allowNoSelection:(BOOL)allowNoSel
{
    if( (self=[self init]) )
    {
        self.selectionItemsStore = [SCParseStore storeWithDefaultParseDefinition:definition];
        
        self.allowMultipleSelection = allowMultipleSel;
        self.allowNoSelection = allowNoSel;
    }
    return self;
}

@end
