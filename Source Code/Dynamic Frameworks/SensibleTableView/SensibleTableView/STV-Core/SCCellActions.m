/*
 *  SCCellActions.m
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


#import "SCCellActions.h"
#import "SCGlobals.h"

@implementation SCCellActions


- (instancetype)init
{
    if( (self=[super init]) )
    {
        // initialzations here
    }
    
    return self;
}



- (void)setActionsTo:(SCCellActions *)actions overrideExisting:(BOOL)override
{
    if((override || !self.willStyle) && actions.willStyle)
        self.willStyle = actions.willStyle;
    if((override || !self.willConfigure) && actions.willConfigure)
        self.willConfigure = actions.willConfigure;
    if((override || !self.didLayoutSubviews) && actions.didLayoutSubviews)
        self.didLayoutSubviews = actions.didLayoutSubviews;
    if((override || !self.willDisplay) && actions.willDisplay)
        self.willDisplay = actions.willDisplay;
    if((override || !self.lazyLoad) && actions.lazyLoad)
        self.lazyLoad = actions.lazyLoad;
    if((override || !self.willSelect) && actions.willSelect)
        self.willSelect = actions.willSelect;
    if((override || !self.didSelect) && actions.didSelect)
        self.didSelect = actions.didSelect;
    if((override || !self.willDeselect) && actions.willDeselect)
        self.willDeselect = actions.willDeselect;
    if((override || !self.didDeselect) && actions.didDeselect)
        self.didDeselect = actions.didDeselect;
    if((override || !self.editActions) && actions.editActions)
        self.editActions = actions.editActions;
    if((override || !self.customEditingStyle) && actions.customEditingStyle)
        self.customEditingStyle = actions.customEditingStyle;
    if((override || !self.didBecomeFirstResponder) && actions.didBecomeFirstResponder)
        self.didBecomeFirstResponder = actions.didBecomeFirstResponder;
    if((override || !self.didResignFirstResponder) && actions.didResignFirstResponder)
        self.didResignFirstResponder = actions.didResignFirstResponder;
    if((override || !self.accessoryButtonTapped) && actions.accessoryButtonTapped)
        self.accessoryButtonTapped = actions.accessoryButtonTapped;
    if((override || !self.returnButtonTapped) && actions.returnButtonTapped)
        self.returnButtonTapped = actions.returnButtonTapped;
    if((override || !self.valueChanged) && actions.valueChanged)
        self.valueChanged = actions.valueChanged;
    if((override || !self.valueIsValid) && actions.valueIsValid)
        self.valueIsValid = actions.valueIsValid;
    if((override || !self.calculatedValue) && actions.calculatedValue)
        self.calculatedValue = actions.calculatedValue;
    if((override || !self.didLoadBoundValue) && actions.didLoadBoundValue)
        self.didLoadBoundValue = actions.didLoadBoundValue;
    if((override || !self.willCommitBoundValue) && actions.willCommitBoundValue)
        self.willCommitBoundValue = actions.willCommitBoundValue;
    
    if((override || !self.customButtonTapped) && actions.customButtonTapped)
        self.customButtonTapped = actions.customButtonTapped;
    
    if((override || !self.detailViewController) && actions.detailViewController)
        self.detailViewController = actions.detailViewController;
    if((override || !self.detailTableViewModel) && actions.detailTableViewModel)
        self.detailTableViewModel = actions.detailTableViewModel;
    
    if((override || !self.detailModelCreated) && actions.detailModelCreated)
        self.detailModelCreated = actions.detailModelCreated;
    if((override || !self.detailModelConfigured) && actions.detailModelConfigured)
        self.detailModelConfigured = actions.detailModelConfigured;
    if((override || !self.detailModelWillPresent) && actions.detailModelWillPresent)
        self.detailModelWillPresent = actions.detailModelWillPresent;
    if((override || !self.detailModelDidPresent) && actions.detailModelDidPresent)
        self.detailModelDidPresent = actions.detailModelDidPresent;
    if((override || !self.detailModelShouldDismiss) && actions.detailModelShouldDismiss)
        self.detailModelShouldDismiss = actions.detailModelShouldDismiss;
    if((override || !self.detailModelWillDismiss) && actions.detailModelWillDismiss)
        self.detailModelWillDismiss = actions.detailModelWillDismiss;
    if((override || !self.detailModelDidDismiss) && actions.detailModelDidDismiss)
        self.detailModelDidDismiss = actions.detailModelDidDismiss;
    
    if((override || !self.shouldChangeCharactersInRange) && actions.shouldChangeCharactersInRange)
        self.shouldChangeCharactersInRange = actions.shouldChangeCharactersInRange;
    
    if((override || !self.didFinishPickingMedia) && actions.didFinishPickingMedia)
        self.didFinishPickingMedia = actions.didFinishPickingMedia;
    if((override || !self.imageName) && actions.imageName)
        self.imageName = actions.imageName;
    if((override || !self.saveImage) && actions.saveImage)
        self.saveImage = actions.saveImage;
    if((override || !self.loadImage) && actions.loadImage)
        self.loadImage = actions.loadImage;
    
    if((override || !self.shouldShowMenu) && actions.shouldShowMenu)
        self.shouldShowMenu = actions.shouldShowMenu;
    if((override || !self.canPerformAction) && actions.canPerformAction)
        self.canPerformAction = actions.canPerformAction;
    if((override || !self.performAction) && actions.performAction)
        self.performAction = actions.performAction;
}

@end




