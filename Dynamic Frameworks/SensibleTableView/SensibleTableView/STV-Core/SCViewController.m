/*
 *  SCViewController.m
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


#import "SCViewController.h"
#import "SCTableViewModel.h"
#import "SCGlobals.h"


@interface SCViewController ()
{
    __weak id _delegate;
    SCTableViewModel *_tableViewModel;
    SCTableViewModel *_noFocusModel;
	SCNavigationBarType _navigationBarType;
	UIBarButtonItem *_addButton;
	UIBarButtonItem *_cancelButton;
	UIBarButtonItem *_doneButton;
	BOOL _cancelButtonTapped;
	BOOL _doneButtonTapped;
    UIPopoverController *_popoverController;
    SCViewControllerActions *_actions;
    SCViewControllerState _state;
    BOOL _hasFocus;
    
    UIBarButtonItem *_nonEditModeLeftBarButtonItem;
}

@end



@implementation SCViewController

@synthesize tableView = _tableView;
@synthesize tableViewModel = _tableViewModel;
@synthesize delegate = _delegate;
@synthesize navigationBarType = _navigationBarType;
@synthesize addButton = _addButton;
@synthesize cancelButton = _cancelButton;
@synthesize allowEditingModeCancelButton = _allowEditingModeCancelButton;
@synthesize doneButton = _doneButton;
@synthesize cancelButtonTapped = _cancelButtonTapped;
@synthesize doneButtonTapped = _doneButtonTapped;
@synthesize popoverController = _popoverController;
@synthesize actions = _actions;
@synthesize state = _state;
@synthesize hasFocus = _hasFocus;


- (instancetype)init
{
	if( (self = [super init]) )
	{
		[self performInitialization];
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if( (self = [super initWithCoder:aDecoder]) ) 
	{
		[self performInitialization];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if( (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) )
	{
		[self performInitialization];
	}
	
	return self;
}

- (void)dealloc
{
    if([SCModelCenter sharedModelCenter].keyboardIssuer == self)
        [SCModelCenter sharedModelCenter].keyboardIssuer = nil;
}

- (void)performInitialization
{
    _delegate = nil;
    _tableView = nil;
    _tableViewModel = [[SCTableViewModel alloc] init];
    _noFocusModel = [[SCTableViewModel alloc] init];
    _navigationBarType = SCNavigationBarTypeAuto;
    _addButton = nil;
    _cancelButton = nil;
    _allowEditingModeCancelButton = TRUE;
    _doneButton = nil;
    
    _popoverController = nil;
    
    _cancelButtonTapped = FALSE;
    _doneButtonTapped = FALSE;
    _state = SCViewControllerStateNew;
    _hasFocus = FALSE;
    
    _actions = [[SCViewControllerActions alloc] init];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
}


- (UITableView *)tableView
{
    if(self.containedViewController)
        return self.containedViewController.tableView;
    //else
    return _tableView;
}

- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    if(!_tableView.superview)
        [self.view addSubview:_tableView];
    
    _tableViewModel.tableView = tableView;
}

- (SCTableViewModel *)tableViewModel
{
    if(self.containedViewController)
        return self.containedViewController.tableViewModel;
    //else
    return _tableViewModel;
}

- (void)setTableViewModel:(SCTableViewModel *)model
{
    // Preserve the detailViewController when applicable
    if(_tableViewModel.detailViewController && !model.detailViewController)
        model.detailViewController = _tableViewModel.detailViewController;
    
    _tableViewModel = model;
    
    _tableViewModel.tableView = _tableView;
    _tableViewModel.editButtonItem = self.editButton;
    if([_tableViewModel isKindOfClass:[SCArrayOfItemsModel class]] && self.addButton)
        [(SCArrayOfItemsModel *)_tableViewModel setAddButtonItem:self.addButton];
}

- (void)setPopoverController:(UIPopoverController *)popover
{
    _popoverController = popover;
    
    _popoverController.delegate = self;
}


- (void)loadView
{
    [super loadView];
    
    self.tableViewModel.tableView = self.tableView;
    [self.tableViewModel styleViews];
    
    // Call viewDidLoad delegate method
    if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
       && [self.delegate respondsToSelector:@selector(viewControllerViewDidLoad:)])
    {
        [self.delegate viewControllerViewDidLoad:self];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(self.actions.viewDidLoad)
        self.actions.viewDidLoad(self);
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
    if(_state != SCViewControllerStateNew)
		_state = SCViewControllerStateActive;
	
    if(_state == SCViewControllerStateNew)
    {
        if(self.tableViewModel.masterModel)
        {
            // Inherit owner's background
            if(self.tableView.style!=UITableViewStylePlain && self.tableViewModel.masterModel.tableView.style!=UITableViewStylePlain)
            {
                self.tableView.backgroundColor = self.tableViewModel.masterModel.tableView.backgroundColor;
            }
        }
        
        [self.tableViewModel styleViews];
    }
	
	_cancelButtonTapped = FALSE;
	_doneButtonTapped = FALSE;
	
    if(self.actions.willAppear)
        self.actions.willAppear(self);
    
	if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
	   && [self.delegate respondsToSelector:@selector(viewControllerWillAppear:)])
	{
		[self.delegate viewControllerWillAppear:self];
	}
    
    if(self.state == SCViewControllerStateNew)
    {
        if(self.actions.willPresent)
            self.actions.willPresent(self);
        
        if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
           && [self.delegate respondsToSelector:@selector(viewControllerWillPresent:)])
        {
            [self.delegate viewControllerWillPresent:self];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
    if(self.tableViewModel)
		self.tableViewModel.commitButton = self.doneButton;
	
    if(self.actions.didAppear)
        self.actions.didAppear(self);
    
	if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
	   && [self.delegate respondsToSelector:@selector(viewControllerDidAppear:)])
	{
		[self.delegate viewControllerDidAppear:self];
	}
    
    if(self.state == SCViewControllerStateNew)
    {
        if(self.actions.didPresent)
            self.actions.didPresent(self);
        
        if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
           && [self.delegate respondsToSelector:@selector(viewControllerDidPresent:)])
        {
            [self.delegate viewControllerDidPresent:self];
        }
    }
    
    _state = SCViewControllerStateActive;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
    if(_state != SCViewControllerStateDismissed)  // could be set by the controller's buttons
    {
        if(self.navigationController)
        {
            if([self.parentViewController isKindOfClass:[UINavigationController class]] && [self.navigationController.viewControllers indexOfObject:self] == NSNotFound)
            {
                // self has been popped from the navigation controller
                _state = SCViewControllerStateDismissed;
            }
            else
            {
                _state = SCViewControllerStateInactive;
            }
        }
        else
        {
            _state = SCViewControllerStateInactive;
        }
    }
    
    if(self.actions.willDisappear)
        self.actions.willDisappear(self);
    
	if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
	   && [self.delegate respondsToSelector:@selector(viewControllerWillDisappear:)])
	{
		[self.delegate viewControllerWillDisappear:self];
	}
    
    if(self.state == SCViewControllerStateDismissed)
    {
        if([self.tableViewModel.detailViewController isKindOfClass:[SCTableViewController class]])
        {
            [(SCTableViewController *)self.tableViewModel.detailViewController loseFocus];
        }
        else
            if([self.tableViewModel.detailViewController isKindOfClass:[SCViewController class]])
            {
                [(SCViewController *)self.tableViewModel.detailViewController loseFocus];
            }
        
        
        if(self.actions.willDismiss)
            self.actions.willDismiss(self);
        
        if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
           && [self.delegate respondsToSelector:@selector(viewControllerWillDismiss:cancelButtonTapped:doneButtonTapped:)])
        {
            [self.delegate viewControllerWillDismiss:self cancelButtonTapped:self.cancelButtonTapped doneButtonTapped:self.doneButtonTapped];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
    if(self.actions.didDisappear)
        self.actions.didDisappear(self);
    
	if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
	   && [self.delegate respondsToSelector:@selector(viewControllerDidDisappear:)])
	{
		[self.delegate viewControllerDidDisappear:self];
	}
    
    if(self.state == SCViewControllerStateDismissed)
    {
        if(self.actions.didDismiss)
            self.actions.didDismiss(self);
        
        if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
           && [self.delegate respondsToSelector:@selector(viewControllerDidDismiss:cancelButtonTapped:doneButtonTapped:)])
        {
            [self.delegate viewControllerDidDismiss:self cancelButtonTapped:self.cancelButtonTapped doneButtonTapped:self.doneButtonTapped];
        }
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIInterfaceOrientationMask interfaceOrientations;
    
    if(self.tableViewModel.masterModel)
    {
        interfaceOrientations = [self.tableViewModel.masterModel.viewController supportedInterfaceOrientations];
    }
    else
    {
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        {
            interfaceOrientations = UIInterfaceOrientationMaskPortrait;
        }
        else
        {
            interfaceOrientations = [super supportedInterfaceOrientations];
        }
    }
    
    return interfaceOrientations;
}



- (void)setNavigationBarType:(SCNavigationBarType)barType
{
    _navigationBarType = barType;
    
    UINavigationItem *navItem = self.navigationItem;
    
    // Reset buttons
    if( (navItem.leftBarButtonItem==self.addButton || navItem.leftBarButtonItem==self.editButton || navItem.leftBarButtonItem==self.doneButton || navItem.leftBarButtonItem==self.cancelButton) && !navItem.backBarButtonItem)
        navItem.leftBarButtonItem = nil;
    if(navItem.rightBarButtonItem==self.addButton || navItem.rightBarButtonItem==self.editButton || navItem.rightBarButtonItem==self.doneButton || navItem.rightBarButtonItem==self.cancelButton)
        navItem.rightBarButtonItem = nil;
    _addButton = nil;
    _cancelButton = nil;
    _doneButton = nil;
    
    // Setup self.editButton
    self.editButton.target = self;
    self.editButton.action = @selector(editButtonAction);
    
    if(navItem && _navigationBarType!=SCNavigationBarTypeNone)
    {
        UIBarButtonItem *tempAddButton = [[UIBarButtonItem alloc]
                                          initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                          target:nil
                                          action:nil];
        UIBarButtonItem *tempCancelButton = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                             target:self
                                             action:@selector(cancelButtonAction)];
        UIBarButtonItem *tempDoneButton = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                           target:self
                                           action:@selector(doneButtonAction)];
        
        switch (_navigationBarType)
        {
            case SCNavigationBarTypeAddLeft:
                if(!navItem.leftBarButtonItem)
                    navItem.leftBarButtonItem = tempAddButton;
                _addButton = tempAddButton;
                break;
            case SCNavigationBarTypeAddRight:
                if(!navItem.rightBarButtonItem)
                    navItem.rightBarButtonItem = tempAddButton;
                _addButton = tempAddButton;
                break;
            case SCNavigationBarTypeEditLeft:
                if(!navItem.leftBarButtonItem)
                    navItem.leftBarButtonItem = self.editButton;
                break;
            case SCNavigationBarTypeEditRight:
                if(!navItem.rightBarButtonItem)
                    navItem.rightBarButtonItem = self.editButton;
                _cancelButton = tempCancelButton;
                _cancelButton.action = @selector(editingModeCancelButtonAction);
                break;
            case SCNavigationBarTypeAddRightEditLeft:
                if(!navItem.rightBarButtonItem)
                    navItem.rightBarButtonItem = tempAddButton;
                _addButton = tempAddButton;
                if(!navItem.leftBarButtonItem)
                    navItem.leftBarButtonItem = self.editButton;
                break;
            case SCNavigationBarTypeAddLeftEditRight:
                if(!navItem.leftBarButtonItem)
                    navItem.leftBarButtonItem = tempAddButton;
                _addButton = tempAddButton;
                if(!navItem.rightBarButtonItem)
                    navItem.rightBarButtonItem = self.editButton;
                break;
            case SCNavigationBarTypeDoneLeft:
                if(!navItem.leftBarButtonItem)
                    navItem.leftBarButtonItem = tempDoneButton;
                _doneButton = tempDoneButton;
                break;
            case SCNavigationBarTypeDoneRight:
                if(!navItem.rightBarButtonItem)
                    navItem.rightBarButtonItem = tempDoneButton;
                _doneButton = tempDoneButton;
                break;
            case SCNavigationBarTypeCancelLeft:
                if(!navItem.leftBarButtonItem)
                    navItem.leftBarButtonItem = tempCancelButton;
                _cancelButton = tempCancelButton;
                break;
            case SCNavigationBarTypeDoneLeftCancelRight:
                if(!navItem.leftBarButtonItem)
                    navItem.leftBarButtonItem = tempDoneButton;
                _doneButton = tempDoneButton;
                if(!navItem.rightBarButtonItem)
                    navItem.rightBarButtonItem = tempCancelButton;
                _cancelButton = tempCancelButton;
                break;
            case SCNavigationBarTypeDoneRightCancelLeft:
                if(!navItem.rightBarButtonItem)
                    navItem.rightBarButtonItem = tempDoneButton;
                _doneButton = tempDoneButton;
                if(!navItem.leftBarButtonItem)
                    navItem.leftBarButtonItem = tempCancelButton;
                _cancelButton = tempCancelButton;
                break;
            case SCNavigationBarTypeAddEditRight:
            {
                _addButton = tempAddButton;
                _addButton.style = UIBarButtonItemStylePlain;
                
                // create an array of the buttons
                NSMutableArray* buttons = [[NSMutableArray alloc] initWithCapacity:2];
                [buttons addObject:self.editButton];
                [buttons addObject:_addButton];
                
                if(!navItem.rightBarButtonItem)
                    navItem.rightBarButtonItems = buttons;
            }
                break;
                
            default:
                break;
        }
    }
}

- (UIBarButtonItem *)editButton
{
	return [self editButtonItem];
}

- (void)cancelButtonAction
{
    BOOL acceptTap = TRUE;
    if(self.actions.cancelButtonTapped)
    {
        acceptTap = self.actions.cancelButtonTapped(self);
    }
    if(!acceptTap)
        return;
    
	[self dismissWithCancelValue:TRUE doneValue:FALSE];
}

- (void)doneButtonAction
{
    BOOL acceptTap = TRUE;
    if(self.actions.doneButtonTapped)
    {
        acceptTap = self.actions.doneButtonTapped(self);
    }
    if(!acceptTap)
        return;
    
	[self dismissWithCancelValue:FALSE doneValue:TRUE];
}

- (void)editButtonAction
{
    if(self.tableViewModel.swipeToDeleteActive)
    {
        [self.tableViewModel setTableViewEditing:NO animated:TRUE];
        return;
    }
    
    BOOL editing = !self.tableView.editing;
    BOOL acceptTap = TRUE;
    if(editing)
    {
        if(self.actions.editButtonTapped)
        {
            acceptTap = self.actions.editButtonTapped(self);
        }
    }
    else
    {
        if(self.actions.doneButtonTapped)
        {
            acceptTap = self.actions.doneButtonTapped(self);
        }
    }
    if(!acceptTap)
        return;
    
    if(self.navigationBarType == SCNavigationBarTypeEditRight)
    {
        if(editing)
        {
            _nonEditModeLeftBarButtonItem = self.navigationItem.leftBarButtonItem;
            [self.navigationItem setHidesBackButton:TRUE animated:FALSE];
            
            SCTableViewSection *section = nil;
            if(self.tableViewModel.sectionCount)
                section = [self.tableViewModel sectionAtIndex:0];
            if(self.allowEditingModeCancelButton && ![section isKindOfClass:[SCArrayOfItemsSection class]])
                self.navigationItem.leftBarButtonItem = self.cancelButton;
            
            self.tableViewModel.commitButton = self.editButton;
        }
        else
        {
            self.tableViewModel.commitButton = nil;
            self.editButton.enabled = TRUE;  // in case user taps 'Cancel' while button disabled
            
            self.navigationItem.leftBarButtonItem = _nonEditModeLeftBarButtonItem;
            [self.navigationItem setHidesBackButton:FALSE animated:FALSE];
            
            if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
               && [self.delegate respondsToSelector:@selector(viewControllerDidExitEditingMode:cancelButtonTapped:doneButtonTapped:)])
            {
                [self.delegate viewControllerDidExitEditingMode:self cancelButtonTapped:NO doneButtonTapped:YES];
            }
        }
    }
    
    [self.tableViewModel setTableViewEditing:editing animated:TRUE];
}

- (void)editingModeCancelButtonAction
{
    BOOL acceptTap = TRUE;
    if(self.actions.cancelButtonTapped)
    {
        acceptTap = self.actions.cancelButtonTapped(self);
    }
    if(!acceptTap)
        return;
    
	self.navigationItem.leftBarButtonItem = _nonEditModeLeftBarButtonItem;
    [self.navigationItem setHidesBackButton:FALSE animated:FALSE];
    
    for(NSInteger i=0; i<self.tableViewModel.sectionCount; i++)
    {
        SCTableViewSection *section = [self.tableViewModel sectionAtIndex:i];
        [section reloadBoundValues];
    }
    [self.tableViewModel setTableViewEditing:FALSE animated:TRUE];
    
    if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
       && [self.delegate respondsToSelector:@selector(viewControllerDidExitEditingMode:cancelButtonTapped:doneButtonTapped:)])
    {
        [self.delegate viewControllerDidExitEditingMode:self cancelButtonTapped:YES doneButtonTapped:NO];
    }
}

- (void)dismissWithCancelValue:(BOOL)cancelValue doneValue:(BOOL)doneValue
{
    _cancelButtonTapped = cancelValue;
    _doneButtonTapped = doneValue;
    
    BOOL shouldDismiss = TRUE;
    if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
	   && [self.delegate respondsToSelector:
		   @selector(viewControllerShouldDismiss:cancelButtonTapped:doneButtonTapped:)])
	{
		shouldDismiss = [self.delegate viewControllerShouldDismiss:self
                                                     cancelButtonTapped:cancelValue
                                                       doneButtonTapped:doneValue];
	}
    if(!shouldDismiss)
    {
        _cancelButtonTapped = NO;
        _doneButtonTapped = NO;
        
        return;
    }
    
    
    if(_hasFocus)
    {
        [self loseFocus];
        
        if(!self.navigationController.navigationController)  // this happens on a collapsed UISplitViewController
            return;
    }
    
    _state = SCViewControllerStateDismissed;
	
	if(self.popoverController)
    {
        self.popoverController.delegate = nil;  // disable delegate methods
        [self.popoverController dismissPopoverAnimated:YES];
        self.popoverController = nil;
    }
    else 
        if(self.navigationController)
        {
            // check if self is the root controller on the navigation stack
            if([self.navigationController.viewControllers objectAtIndex:0] == self)
            {
                if(self.navigationController.navigationController)  // this happens on a collapsed UISplitViewController
                {
                    [self.navigationController.navigationController popToRootViewControllerAnimated:YES];
                }
                else
                {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }
            else
                [self.navigationController popViewControllerAnimated:YES];
        }
        else
            [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)gainFocus
{
    if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
       && [self.delegate respondsToSelector:
           @selector(viewControllerWillGainFocus:)])
    {
        [self.delegate viewControllerWillGainFocus:self];
    }
    
    _hasFocus = TRUE;
    
    // Connect self.tableViewModel and refresh table view
    self.tableView.dataSource = self.tableViewModel;
    self.tableView.delegate = self.tableViewModel;
    [self.tableViewModel reloadBoundValues];
    [self.tableViewModel.tableView reloadData];
    
    
    if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
       && [self.delegate respondsToSelector:
           @selector(viewControllerDidGainFocus:)])
    {
        [self.delegate viewControllerDidGainFocus:self];
    }
}

- (void)loseFocus
{
    if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
       && [self.delegate respondsToSelector:@selector(viewControllerWillLoseFocus:cancelButtonTapped:doneButtonTapped:)])
    {
        [self.delegate viewControllerWillLoseFocus:self cancelButtonTapped:self.cancelButtonTapped doneButtonTapped:self.doneButtonTapped];
    }
    
    _hasFocus = FALSE;
    if(self.navigationBarType != SCNavigationBarTypeNone)
        self.navigationBarType = SCNavigationBarTypeAuto;
    self.title = nil;
    
    // Connect _noFocusModel and refresh table view
    self.tableView.dataSource = _noFocusModel;
    self.tableView.delegate = _noFocusModel;
    [self.tableView reloadData];
    
    if([self.delegate conformsToProtocol:@protocol(SCViewControllerDelegate)]
       && [self.delegate respondsToSelector:@selector(viewControllerDidLoseFocus:cancelButtonTapped:doneButtonTapped:)])
    {
        [self.delegate viewControllerDidLoseFocus:self cancelButtonTapped:self.cancelButtonTapped doneButtonTapped:self.doneButtonTapped];
    }
    
    self.delegate = nil;
}


// overrides superclass
- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}


#pragma mark -
#pragma mark Segue handling methods

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if([sender isKindOfClass:[SCCustomCell class]])
        return NO;  // framework will handle these
    
    return YES;
}


#pragma mark -
#pragma mark UISplitViewControllerDelegate methods


- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation
{
    return NO;
}

- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController
{
    if(self.tableViewModel.masterModel && self.tableViewModel.masterModel.activeDetailModel==self.tableViewModel)
    {
        // There seems to be an iOS 8 bug that is preventing the following code from working properly (the cell actually gets selected the second time the device is rotated but never from the first time). This selection bug is also present in Apple's own "Adaptice Code" project sample.
        // ** Code removed to prevent inconsistency **
        /*
         // Detemine selected cell indexPath and in collaped mode select it in expanded mode
         NSIndexPath *selectedCellIndexPath = nil;
         for(NSInteger i=0; i<self.tableViewModel.masterModel.sectionCount; i++)
         {
         SCTableViewSection *section = [self.tableViewModel.masterModel sectionAtIndex:i];
         if([section isKindOfClass:[SCArrayOfItemsSection class]])
         {
         SCArrayOfItemsSection *itemsSection = (SCArrayOfItemsSection *)section;
         if(itemsSection.selectedCellIndexPath)
         {
         selectedCellIndexPath = itemsSection.selectedCellIndexPath;
         break;
         }
         }
         }
         if(selectedCellIndexPath)
         {
         UITableViewCell *selectedCell = [self.tableViewModel.masterModel.tableView cellForRowAtIndexPath:selectedCellIndexPath];
         selectedCell.selected = YES;
         }
         */
        
        _state = SCViewControllerStateActive;
    }
    else
    {
        [self loseFocus];
    }
    
    return nil;  // use default behavior
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController
{
    if(self.tableViewModel.masterModel && self.hasFocus)
    {
        return NO;
    }
    // else
    _state = SCViewControllerStateInactive;
    return YES;
}


#pragma mark -
#pragma mark UIPopoverControllerDelegate methods

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    BOOL shouldDismiss = TRUE;
    if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
	   && [self.delegate respondsToSelector:
		   @selector(tableViewControllerShouldDismiss:cancelButtonTapped:doneButtonTapped:)])
	{
		shouldDismiss = [self.delegate viewControllerShouldDismiss:self
                                                cancelButtonTapped:FALSE
                                                  doneButtonTapped:TRUE];
	}
    return shouldDismiss;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    // handle dismissal
}

@end

