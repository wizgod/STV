/*
 *  SCSectionActions.m
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


#import "SCSectionActions.h"

#import "SCGlobals.h"


@implementation SCSectionActions


- (instancetype)init
{
    if( (self=[super init]) )
    {
        // initializations here
    }
    
    return self;
}


- (void)setActionsTo:(SCSectionActions *)actions overrideExisting:(BOOL)override
{
    if((override || !self.didAddToModel) && actions.didAddToModel)
        self.didAddToModel = actions.didAddToModel;
    if((override || !self.willDisplayHeaderView) && actions.willDisplayHeaderView)
        self.willDisplayHeaderView = actions.willDisplayHeaderView;
    if((override || !self.willDisplayFooterView) && actions.willDisplayFooterView)
        self.willDisplayFooterView = actions.willDisplayFooterView;
    if((override || !self.valueChanged) && actions.valueChanged)
        self.valueChanged = actions.valueChanged;
    
    if((override || !self.detailModelCreated) && actions.detailModelCreated)
        self.detailModelCreated = actions.detailModelCreated;
    if((override || !self.detailModelConfigured) && actions.detailModelConfigured)
        self.detailModelConfigured = actions.detailModelConfigured;
    if((override || !self.customPresentDetailModel) && actions.customPresentDetailModel)
        self.customPresentDetailModel = actions.customPresentDetailModel;
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
    
    if((override || !self.didFetchItemsFromStore) && actions.didFetchItemsFromStore)
        self.didFetchItemsFromStore = actions.didFetchItemsFromStore;
    if((override || !self.fetchItemsFromStoreFailed) && actions.fetchItemsFromStoreFailed)
        self.fetchItemsFromStoreFailed = actions.fetchItemsFromStoreFailed;
    if((override || !self.didAddSpecialCells) && actions.didAddSpecialCells)
        self.didAddSpecialCells = actions.didAddSpecialCells;
    
    if((override || !self.detailViewControllerForRowAtIndexPath) && actions.detailViewControllerForRowAtIndexPath)
        self.detailViewControllerForRowAtIndexPath = actions.detailViewControllerForRowAtIndexPath;
    if((override || !self.detailTableViewModelForRowAtIndexPath) && actions.detailTableViewModelForRowAtIndexPath)
        self.detailTableViewModelForRowAtIndexPath = actions.detailTableViewModelForRowAtIndexPath;
    
    if((override || !self.cellForRowAtIndexPath) && actions.cellForRowAtIndexPath)
        self.cellForRowAtIndexPath = actions.cellForRowAtIndexPath;
    if((override || !self.reuseIdentifierForRowAtIndexPath) && actions.reuseIdentifierForRowAtIndexPath)
        self.reuseIdentifierForRowAtIndexPath = actions.reuseIdentifierForRowAtIndexPath;
    if((override || !self.customHeightForRowAtIndexPath) && actions.customHeightForRowAtIndexPath)
        self.customHeightForRowAtIndexPath = actions.customHeightForRowAtIndexPath;
    
    if((override || !self.didCreateItem) && actions.didCreateItem)
        self.didCreateItem = actions.didCreateItem;
    if((override || !self.willInsertItem) && actions.willInsertItem)
        self.willInsertItem = actions.willInsertItem;
    if((override || !self.insertItemNoConnection) && actions.insertItemNoConnection)
        self.insertItemNoConnection = actions.insertItemNoConnection;
    if((override || !self.insertItemFailed) && actions.insertItemFailed)
        self.insertItemFailed = actions.insertItemFailed;
    if((override || !self.didInsertItem) && actions.didInsertItem)
        self.didInsertItem = actions.didInsertItem;
    if((override || !self.willUpdateItem) && actions.willUpdateItem)
        self.willUpdateItem = actions.willUpdateItem;
    if((override || !self.updateItemNoConnection) && actions.updateItemNoConnection)
        self.updateItemNoConnection = actions.updateItemNoConnection;
    if((override || !self.updateItemFailed) && actions.updateItemFailed)
        self.updateItemFailed = actions.updateItemFailed;
    if((override || !self.didUpdateItem) && actions.didUpdateItem)
        self.didUpdateItem = actions.didUpdateItem;
    if((override || !self.willDeleteItem) && actions.willDeleteItem)
        self.willDeleteItem = actions.willDeleteItem;
    if((override || !self.deleteItemNoConnection) && actions.deleteItemNoConnection)
        self.deleteItemNoConnection = actions.deleteItemNoConnection;
    if((override || !self.deleteItemFailed) && actions.deleteItemFailed)
        self.deleteItemFailed = actions.deleteItemFailed;
    if((override || !self.didDeleteItem) && actions.didDeleteItem)
        self.didDeleteItem = actions.didDeleteItem;
}


@end
