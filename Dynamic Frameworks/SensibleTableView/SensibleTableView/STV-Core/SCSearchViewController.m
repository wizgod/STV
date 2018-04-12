/*
 *  SCSearchViewController.m
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

#import "SCSearchViewController.h"

#import "SCTableViewModel.h"


@interface SCSearchViewController ()
{
    BOOL _searchBarNeedsLayout;
    BOOL _tableViewNeedsLayout;
}
@end



@implementation SCSearchViewController

@synthesize searchBar = _searchBar;

// overrides superclass
- (void)setTableViewModel:(SCTableViewModel *)model
{
    [super setTableViewModel:model];
    
    if([model isKindOfClass:[SCArrayOfItemsModel class]])
    {
        SCArrayOfItemsModel *itemsModel = (SCArrayOfItemsModel *)model;
        itemsModel.searchBar = self.searchBar;
        itemsModel.enableSearchController = TRUE;
    }
}

- (void)setSearchBar:(UISearchBar *)searchBar
{
    _searchBar = searchBar;
    
    if([self.tableViewModel isKindOfClass:[SCArrayOfItemsModel class]])
    {
        SCArrayOfItemsModel *itemsModel = (SCArrayOfItemsModel *)self.tableViewModel;
        itemsModel.searchBar = self.searchBar;
    }
}

- (UISearchBar *)searchBar
{
    if(!_searchBar)
    {
        _searchBar = [[UISearchBar alloc] init];
        [self.view addSubview:_searchBar];
        _searchBarNeedsLayout = TRUE;
    }
    
    return _searchBar;
}

- (UITableView *)tableView
{
    if(!_tableView)
    {
        [super setTableView:[[UITableView alloc] init]];
        _tableViewNeedsLayout = TRUE;
    }
    
    return _tableView;
}

// overrides superclass
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(_searchBarNeedsLayout)
    {
        // In case of iOS 7 & later, make sure to work inside the available view edges only (as apposed to the full layout)
        if([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
            [self setEdgesForExtendedLayout:UIRectEdgeNone];
        
        // set searchBar height
        CGRect searchBarFrame = self.searchBar.frame;
        if(!searchBarFrame.size.height)
        {
            searchBarFrame.size.height = 44.0f;
            self.searchBar.frame = searchBarFrame;
        }
        
        self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
        
        // add searchBar constrainsts
        NSLayoutConstraint *searchBarLeftConstraint =[NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
        NSLayoutConstraint *searchBarRightConstraint =[NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
        NSLayoutConstraint *searchBarTopConstraint =[NSLayoutConstraint constraintWithItem:self.searchBar attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
        [self.view addConstraints:@[searchBarLeftConstraint, searchBarRightConstraint, searchBarTopConstraint]];
        
        _searchBarNeedsLayout = FALSE;
    }
    
    
    if(_tableViewNeedsLayout)
    {
        // In case of iOS 7 & later, make sure to work inside the available view edges only (as apposed to the full layout)
        if([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
            [self setEdgesForExtendedLayout:UIRectEdgeNone];
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
        
        // add tableView constrainsts
        NSLayoutConstraint *tableViewLeftConstraint =[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
        NSLayoutConstraint *tableViewRightConstraint =[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
        NSLayoutConstraint *tableViewTopConstraint =[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.searchBar attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        NSLayoutConstraint *tableViewBottomConstraint =[NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
        [self.view addConstraints:@[tableViewLeftConstraint, tableViewRightConstraint, tableViewTopConstraint, tableViewBottomConstraint]];
        
        _tableViewNeedsLayout = FALSE;
    }
     
}


@end

