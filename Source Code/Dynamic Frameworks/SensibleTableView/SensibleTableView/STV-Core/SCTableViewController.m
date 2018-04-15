/*
 *  SCTableViewController.m
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


#import "SCTableViewController.h"

#import "SCStringDefinition.h"
#import "SCArrayStore.h"
#import "SCUserDefaultsStore.h"
#import "SCTableViewModel.h"
#import "SCGlobals.h"
#import "SCPluginUtilities.h"


@interface SCTableViewController ()
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
    SCTableViewControllerActions *_actions;
    
    SCViewControllerState _state;
    BOOL _hasFocus;
    
    UIBarButtonItem *_nonEditModeLeftBarButtonItem;
    
    BOOL _leftBarButtonItemInitialEnabledState;
    BOOL _rightBarButtonItemInitialEnabledState;
}

/** Receives the ibSTVSectionsString from IB **/
@property (nonatomic, copy) NSString *ibSTVSectionsString;

// Actual Data definitions converted from _STV_ibDataDefinitions NSDictionary objects
@property (nonatomic, retain, readonly) NSDictionary *ibDataDefinitions;

@end



@implementation SCTableViewController

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
@synthesize ibDataDefinitions = _ibDataDefinitions;

- (instancetype)init
{
    if( (self = [super init]) ) 
	{
		[self performInitialization];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    if( (self = [super initWithStyle:style]) )
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
    // Unregister from dynamic type font changes
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    if([SCModelCenter sharedModelCenter].keyboardIssuer == self)
        [SCModelCenter sharedModelCenter].keyboardIssuer = nil;
}

- (void)performInitialization
{
    _delegate = nil;
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
    
    _leftBarButtonItemInitialEnabledState = YES;
    _rightBarButtonItemInitialEnabledState = YES;
    
    _actions = [[SCTableViewControllerActions alloc] init];
}


- (void)set_STV_ibDataDefinitions:(NSArray *)definitions
{
    __STV_ibDataDefinitions = definitions;
    
    NSMutableDictionary *convertedDefinitions = [NSMutableDictionary dictionary];
    for(NSDictionary *defDictionary in definitions)
    {
        SCDataDefinition *convertedDefinition = [SCPluginUtilities objectForPluginDictionary:defDictionary];
        if(convertedDefinition)
            [convertedDefinitions setValue:convertedDefinition forKey:convertedDefinition.ibUniqueID];
    }
    
    for(NSString *key in convertedDefinitions)
    {
        SCDataDefinition *dataDefinition = [convertedDefinitions valueForKey:key];
        [dataDefinition resolveibRelationshipsUsingDictionary:convertedDefinitions];
    }
    
    _ibDataDefinitions = convertedDefinitions;
}

- (NSDictionary *)ibDataDefinitions
{
    // return both local and any remote data definitions
    
    NSMutableDictionary *dataDefinitions = [NSMutableDictionary dictionaryWithDictionary:_ibDataDefinitions];
    
    if(self.tableViewModel.masterModel && [self.tableViewModel.masterModel.viewController isKindOfClass:[SCTableViewController class]])
    {
        SCTableViewController *masterViewController = (SCTableViewController *)self.tableViewModel.masterModel.viewController;
        
        [dataDefinitions addEntriesFromDictionary:masterViewController.ibDataDefinitions];
    }
    
    return dataDefinitions;
}

- (void)setTableView:(UITableView *)tableView
{
    [super setTableView:tableView];
    
    self.tableViewModel.tableView = tableView;
}

- (void)setTableViewModel:(SCTableViewModel *)model
{
    // Preserve the detailViewController when applicable
    if(_tableViewModel.detailViewController && !model.detailViewController)
        model.detailViewController = _tableViewModel.detailViewController;
    // Preserve the theme when applicable
    if(_tableViewModel.theme && !model.theme)
        model.theme = _tableViewModel.theme;
    
    // Disconnect old model from table view
    _tableViewModel.tableView = nil;
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    
    if(model && [self isViewLoaded])
    {
        model.tableView = self.tableView;
        model.editButtonItem = self.editButton;
    }
    
    // Check if new model is an SCArrayOfItemsModel and configure it from any existing SCArrayOfItemsSection
    if([model isKindOfClass:[SCArrayOfItemsModel class]] && _tableViewModel.sectionCount)
    {
        SCArrayOfItemsSection *itemsSection = nil;
        for(NSUInteger i=0; i<_tableViewModel.sectionCount; i++)
        {
            SCTableViewSection *section = [_tableViewModel sectionAtIndex:i];
            if([section isKindOfClass:[SCArrayOfItemsSection class]])
            {
                itemsSection = (SCArrayOfItemsSection *)section;
                break;
            }
        }
        
        if(itemsSection)
        {
            SCArrayOfItemsModel *itemsModel = (SCArrayOfItemsModel *)model;
            [itemsModel configureUsingSection:itemsSection];
        }
    }
    
    _tableViewModel = model;
}

- (void)setPopoverController:(UIPopoverController *)popover
{
    _popoverController = popover;
    
    _popoverController.delegate = self;
}

- (void)setAutoDisableNavigationButtonsUntilViewAppears:(BOOL)autoDisableNavigationButtonsUntilViewAppears
{
    _autoDisableNavigationButtonsUntilViewAppears = autoDisableNavigationButtonsUntilViewAppears;
    
    
    if([self.tableViewModel.detailViewController isKindOfClass:[SCTableViewController class]])
    {
        [(SCTableViewController *)self.tableViewModel.detailViewController setAutoDisableNavigationButtonsUntilViewAppears:autoDisableNavigationButtonsUntilViewAppears];
    }
}


- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    if([parent isKindOfClass:[SCViewController class]])
    {
        SCViewController *parentViewController = (SCViewController *)parent;
        if(!parentViewController.containedViewController)
        {
            // inherit master model configuration
            if(parentViewController.tableViewModel.masterModel)
            {
                self.tableViewModel.masterModel = parentViewController.tableViewModel.masterModel;
                self.tableViewModel.masterBoundObject = parentViewController.tableViewModel.masterBoundObject;
                self.tableViewModel.masterBoundObjectStore = parentViewController.tableViewModel.masterBoundObjectStore;
            }
            
            if(![self isDetailOfSplitViewController:parentViewController])
            {
                [self addStaticContentToModel];
                
                if(!self.tableViewModel.sectionCount)
                    for(NSInteger i=0; i<parentViewController.tableViewModel.sectionCount; i++)
                    {
                        [self.tableViewModel addSection:[parentViewController.tableViewModel sectionAtIndex:i]];
                    }
            }
            
            
            parentViewController.containedViewController = self;
        }
    }
    
    [self setupDetailViewControllerIfNeeded];
}

- (void)removeFromParentViewController
{
    if([self.parentViewController isKindOfClass:[SCViewController class]])
    {
        SCViewController *parentViewController = (SCViewController *)self.parentViewController;
        if(parentViewController.containedViewController == self)
            parentViewController.containedViewController = nil;
    }
    
    [super removeFromParentViewController];
}


- (void)loadView
{
    [super loadView];
    
    // Register for dynamic type font changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentSizeCategoryDidChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    
    self.tableViewModel.tableView = self.tableView;
    
    
    if(!self.ibEmbedded && ![self isDetailOfSplitViewController:self])   // addStaticContentToModel will be called at the right time (after master is loaded)
        [self addStaticContentToModel];
    
    
    [self setupDetailViewControllerIfNeeded];
    
    // Call viewDidLoad delegate method
    if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
       && [self.delegate respondsToSelector:@selector(tableViewControllerViewDidLoad:)])
    {
        [self.delegate tableViewControllerViewDidLoad:self];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(self.actions.viewDidLoad)
        self.actions.viewDidLoad(self);
}

- (void)setupDetailViewControllerIfNeeded
{
    // Automatically detect detailViewController presence
    if(!self.tableViewModel.detailViewController && [self isMasterOfSplitViewController:self])
    {
        UIViewController *detailController = nil;
        if(self.splitViewController.viewControllers.count > 1)
        {
            detailController = [self.splitViewController.viewControllers objectAtIndex:1];
        }
        else
            if(self.splitViewController.delegate && self.splitViewController.delegate!=self)
                detailController = (UIViewController *)self.splitViewController.delegate;
        
        if(detailController)
        {
            if([detailController isKindOfClass:[SCTableViewController class]] || [detailController isKindOfClass:[SCViewController class]])
            {
                if([detailController isKindOfClass:[SCTableViewController class]])
                {
                    SCTableViewController *detailTableViewController = (SCTableViewController *)detailController;
                    
                    detailTableViewController.tableViewModel.masterModel = self.tableViewModel;
                    [detailTableViewController addStaticContentToModel];
                    [detailTableViewController configureAllObjectSections];
                    
                    detailTableViewController.autoDisableNavigationButtonsUntilViewAppears = self.autoDisableNavigationButtonsUntilViewAppears;
                    
                    [detailTableViewController loseFocus];
                }
                else
                    if([detailController isKindOfClass:[SCViewController class]])
                    {
                        SCViewController *detailViewController = (SCViewController *)detailController;
                        
                        detailViewController.tableViewModel.masterModel = self.tableViewModel;
                        if(detailViewController.containedViewController)
                        {
                            [detailViewController.containedViewController addStaticContentToModel];
                            [detailViewController.containedViewController configureAllObjectSections];
                        }
                        
                        [detailViewController loseFocus];
                    }
                
                self.tableViewModel.detailViewController = detailController;
                
                if(!detailController.navigationController)
                {
                    UINavigationController *detailNavController = [[UINavigationController alloc] initWithRootViewController:detailController];
                    NSMutableArray *viewControllers = [NSMutableArray arrayWithArray:self.splitViewController.viewControllers];
                    if(viewControllers.count>2)
                        [viewControllers replaceObjectAtIndex:1 withObject:detailNavController];
                    else
                        [viewControllers addObject:detailNavController];
                    self.splitViewController.viewControllers = viewControllers;
                }
            }
        }
    }
}

- (void)invalidateStaticContent
{
    _staticContentAddedToModel = NO;
}

- (void)addStaticContentToModel
{
    if(self.staticContentAddedToModel)
        return;
    
    // Check if there is any static table view content and add it to the model
    NSUInteger sectionNumber = [self numberOfSectionsInTableView:self.tableView];
    
    NSMutableDictionary *STVSections = nil;
    if(sectionNumber && [self.ibSTVSectionsString length])
    {
        // prepare the STVSections dictionary
        STVSections = [NSMutableDictionary dictionary];
        
        NSArray *sectionStrings = [self.ibSTVSectionsString componentsSeparatedByString:@"⬛︎"];
        for(NSString *sectionString in sectionStrings)
        {
            NSMutableDictionary *sectionDictionary = [NSMutableDictionary dictionary];
            
            NSArray *valuePairs = [sectionString componentsSeparatedByString:@"・"];
            for(NSString *pairString in valuePairs)
            {
                NSArray *pair = [pairString componentsSeparatedByString:@"➡︎"];
                if(pair.count!=2)
                    continue;
                [sectionDictionary setValue:[pair objectAtIndex:1] forKey:[pair objectAtIndex:0]];
            }
            
            NSString *index = [sectionDictionary valueForKey:kSectionIndexKey];
            if(index)
                [STVSections setValue:sectionDictionary forKey:index];
        }
    }
    
    BOOL addButtonConnected = FALSE;
    
    for(NSUInteger sectionIndex=0; sectionIndex<sectionNumber; sectionIndex++)
    {
        NSString *stringIndex = [NSString stringWithFormat:@"%lu",(unsigned long)sectionIndex];
        NSDictionary *sectionDictionary = [STVSections valueForKey:stringIndex];
        
        SCTableViewSection *section = nil;
        
        if(sectionDictionary)  // current section is an STV section
        {
            NSString *sectionType = [sectionDictionary valueForKey:kSectionTypeKey];
            
            NSString *dataDefinitionID = [sectionDictionary valueForKey:kSectionDataDefIdKey];
            
            SCDataDefinition *dataDefinition = [self.ibDataDefinitions valueForKey:dataDefinitionID];
            
            if(!dataDefinition && [sectionType isEqualToString:@"SCArrayOfStringsSection"])
                dataDefinition = [SCStringDefinition definition];
            
            if(!dataDefinition)
                SCDebugLog(@"Warning: %@ - No valid data definition selected for %@ at index %lu", [self class], sectionType, (unsigned long)sectionIndex);
            
            SCDataStore *dataStore = [dataDefinition generateCompatibleDataStore];
            
            if([sectionType isEqualToString:@"SCObjectSection"])
            {
                NSString *groupIndexString = [sectionDictionary valueForKey:kSectionDataDefGroupIndexKey];
                NSInteger groupIndex = [groupIndexString integerValue];
                if(groupIndex < 0)
                    groupIndex = 0;
                
                SCPropertyGroup *propertyGroup = nil;
                if(groupIndex < dataDefinition.propertyGroups.groupCount)
                    propertyGroup = [dataDefinition.propertyGroups groupAtIndex:groupIndex];
                SCObjectSection *objectSection = [SCObjectSection sectionWithHeaderTitle:nil boundObject:nil boundObjectStore:nil propertyGroup:propertyGroup];
                
                NSObject *object = nil;
                SEL defaultiCloudKeyValueObjectSelector = NSSelectorFromString(@"defaultiCloudKeyValueObject");
                if(self.tableViewModel.masterBoundObject)
                {
                    object = self.tableViewModel.masterBoundObject;
                }
                else
                    if([dataStore isKindOfClass:[SCUserDefaultsStore class]])
                    {
                        object = [(SCUserDefaultsStore *)dataStore standardUserDefaultsObject];
                    }
                    else
                        if([dataStore respondsToSelector:defaultiCloudKeyValueObjectSelector])
                        {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                            object = [dataStore performSelector:defaultiCloudKeyValueObjectSelector];
#pragma clang diagnostic pop
                        }
                        else
                        {
                            object = [self objectForSection:objectSection atIndex:sectionIndex];
                        }
                
                NSInteger numberOfRows = [self tableView:self.tableView numberOfRowsInSection:sectionIndex];
                BOOL autoGenerateCells = (numberOfRows == 0);
                [objectSection setBoundObject:object withStore:dataStore autoGenerateCells:autoGenerateCells];
                
                // If available, use custom provided user cells
                for(NSInteger i=0; i<numberOfRows; i++)
                {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:sectionIndex];
                    UITableViewCell *ibCell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
                    CGFloat cellHeight = [self tableView:self.tableView heightForRowAtIndexPath:indexPath];
                    
                    SCCustomCell *customCell;
                    if([ibCell isKindOfClass:[SCCustomCell class]])
                    {
                        customCell = (SCCustomCell *)ibCell;
                    }
                    else
                    {
                        customCell = [SCCustomCell cellWithCell:ibCell];
                    }
                    customCell.cellCreatedInIB = YES;
                    customCell.height = cellHeight;
                    customCell.boundObjectStore = objectSection.boundObjectStore;
                    customCell.boundObject = objectSection.boundObject;
                    SCPropertyDefinition *propertyDefinition = nil;
                    if(customCell.boundPropertyName)
                        propertyDefinition = [objectSection.boundObjectStore.defaultDataDefinition propertyDefinitionWithName:customCell.boundPropertyName];
                    if(propertyDefinition && !propertyDefinition.existsInNormalMode)
                        continue;  // don't add cell
                    
                    // We'll configure the cell in viewWillAppear instead to include any custom user added actions in viewDidLoad
                    //if(propertyDefinition)
                    //    [objectSection configureCell:customCell forPropertyDefinition:propertyDefinition inEditingMode:NO];
                    
                    [objectSection addCell:customCell];
                }
                
                section = objectSection;
            }
            else
                if([sectionType isEqualToString:@"SCArrayOfObjectsSection"] || [sectionType isEqualToString:@"SCArrayOfStringsSection"])
                {
                    NSString *predicateString = [sectionDictionary valueForKey:kSectionPredicateStringKey];
                    NSString *placeholderText = [sectionDictionary valueForKey:kSectionPlaceholderTextKey];
                    NSString *placeholderTextAlignmentString = [sectionDictionary valueForKey:kSectionPlaceholderTextAlignmentKey];
                    NSString *addNewItemText = [sectionDictionary valueForKey:kSectionAddNewItemTextKey];
                    NSString *masterBoundPropertyName = [sectionDictionary valueForKey:kSectionMasterBoundPropertyName];
                    
                    NSString *hideWhenEmptyString = [sectionDictionary valueForKey:kSectionHideWhenEmptyKey];
                    BOOL hideWhenEmpty = ([hideWhenEmptyString isEqualToString:kYesString]) ? YES : NO;
                    NSString *allowAddingString = [sectionDictionary valueForKey:kSectionAllowAddingKey];
                    BOOL allowAdding = ([allowAddingString isEqualToString:kYesString]) ? YES : NO;
                    NSString *allowDeletingString = [sectionDictionary valueForKey:kSectionAllowDeletingKey];
                    BOOL allowDeleting = ([allowDeletingString isEqualToString:kYesString]) ? YES : NO;
                    NSString *allowMovingString = [sectionDictionary valueForKey:kSectionAllowMovingKey];
                    BOOL allowMoving = ([allowMovingString isEqualToString:kYesString]) ? YES : NO;
                    NSString *allowEditingString = [sectionDictionary valueForKey:kSectionAllowEditingKey];
                    BOOL allowEditing = ([allowEditingString isEqualToString:kYesString]) ? YES : NO;
                    
                    NSString *batchSizeString = [sectionDictionary valueForKey:kSectionBatchSizeKey];
                    NSInteger batchSize = 0;
                    if(batchSizeString)
                        batchSize = [batchSizeString integerValue];
                    
                    NSString *stringsArrayString = [sectionDictionary valueForKey:kSectionStringsArrayKey];
                    NSMutableArray *stringsArray = nil;
                    if([stringsArrayString length])
                    {
                        stringsArray = [NSMutableArray arrayWithArray:[stringsArrayString componentsSeparatedByString:@"⦿"]];
                    }
                    
                    
                    SCArrayOfObjectsSection *objectsSection = nil;
                    
                    if([sectionType isEqualToString:@"SCArrayOfObjectsSection"])
                        objectsSection = [SCArrayOfObjectsSection sectionWithHeaderTitle:nil dataStore:dataStore];
                    else if([sectionType isEqualToString:@"SCArrayOfStringsSection"])
                        objectsSection = [SCArrayOfStringsSection sectionWithHeaderTitle:nil dataStore:dataStore];
                    
                    if(self.tableViewModel.masterBoundObject && [masterBoundPropertyName length])
                    {
                        [dataStore bindStoreToPropertyName:masterBoundPropertyName forObject:self.tableViewModel.masterBoundObject withDefinition:[self.tableViewModel.masterBoundObjectStore definitionForObject:self.tableViewModel.masterBoundObject]];
                    }
                    else
                        if([dataStore isKindOfClass:[SCArrayStore class]])
                        {
                            SCArrayStore *arrayStore = (SCArrayStore *)dataStore;
                            
                            if([stringsArray count] && [objectsSection isKindOfClass:[SCArrayOfStringsSection class]])
                                arrayStore.objectsArray = stringsArray;
                            
                            NSMutableArray *objectsArray = [self objectsForSection:objectsSection atIndex:sectionIndex];
                            if([objectsArray count])
                                arrayStore.objectsArray = objectsArray;
                        }
                    
                    if([predicateString length])
                        objectsSection.dataFetchOptions.filterPredicate = [NSPredicate predicateWithFormat:predicateString];
                    if(batchSize)
                        objectsSection.dataFetchOptions.batchSize = batchSize;
                    if([placeholderText length])
                    {
                        NSTextAlignment placeholderTextAlignment = (NSTextAlignment)[placeholderTextAlignmentString integerValue];
                        objectsSection.placeholderCell = [SCTableViewCell cellWithText:placeholderText textAlignment:placeholderTextAlignment];
                    }
                    if([addNewItemText length])
                        objectsSection.addNewItemCell = [SCTableViewCell cellWithText:addNewItemText textAlignment:NSTextAlignmentCenter];
                    objectsSection.hideWhenEmpty = hideWhenEmpty;
                    objectsSection.allowAddingItems = allowAdding;
                    objectsSection.allowDeletingItems = allowDeleting;
                    objectsSection.allowMovingItems = allowMoving;
                    objectsSection.allowEditDetailView = allowEditing;
                    
                    // Further dictionary assignments
                    objectsSection.ibNewItemViewControllerIdentifier = [sectionDictionary valueForKey:kSectionibNewItemViewControllerIdentifier];
                    
                    
                    // Use first IB provided cell (if exists) as a custom cell
                    if([self tableView:self.tableView numberOfRowsInSection:sectionIndex])
                    {
                        NSIndexPath *firstCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:sectionIndex];
                        CGFloat cellHeight = [self tableView:self.tableView heightForRowAtIndexPath:firstCellIndexPath];
                        UITableViewCell *ibCell = [self tableView:self.tableView cellForRowAtIndexPath:firstCellIndexPath];
                        
                        // Set objectsSection's itemsAccessoryType to ibCell's
                        if(ibCell.accessoryType != UITableViewCellAccessoryNone)
                            objectsSection.itemsAccessoryType = ibCell.accessoryType;
                        
                        // Configure ibCell for dynamic type (needed due to an IB bug, we believe)
                        UIFont *textLabelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                        if([ibCell.textLabel.font.fontName isEqualToString:textLabelFont.fontName] && ibCell.textLabel.font.pointSize==16)
                            ibCell.textLabel.font = textLabelFont;
                        UIFont *detailTextLabelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
                        if([ibCell.detailTextLabel.font.fontName isEqualToString:detailTextLabelFont.fontName] && ibCell.detailTextLabel.font.pointSize==11)
                            ibCell.detailTextLabel.font = detailTextLabelFont;
                        
                        objectsSection.sectionActions.cellForRowAtIndexPath = ^SCCustomCell*(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath)
                        {
                            SCCustomCell *customCell;
                            if([ibCell isKindOfClass:[SCCustomCell class]])
                            {
                                customCell = [[ibCell class] cellWithCell:ibCell];
                            }
                            else
                            {
                                customCell = [SCCustomCell cellWithCell:ibCell];
                            }
                            customCell.cellCreatedInIB = YES;
                            customCell.height = cellHeight;
                            
                            return customCell;
                        };
                    }
                    
                    // create and connect add button if does not exist
                    if(!addButtonConnected && !self.tableViewModel.masterModel && self.navigationBarType==SCNavigationBarTypeAuto)  // initial state
                    {
                        if(objectsSection.allowAddingItems)
                        {
                            self.navigationBarType = SCNavigationBarTypeAddRightEditLeft;
                            objectsSection.addButtonItem = self.addButton;
                            
                            addButtonConnected = YES;
                        }
                        else
                        {
                            self.navigationBarType = SCNavigationBarTypeEditRight;
                        }
                    }
                    
                    section = objectsSection;
                }
        }
        else  // current section is a standard iOS section
        {
            section = [SCTableViewSection section];
            
            NSUInteger cellCount = [self tableView:self.tableView numberOfRowsInSection:sectionIndex];
            for(NSUInteger cellIndex=0; cellIndex<cellCount; cellIndex++)
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:cellIndex inSection:sectionIndex];
                UITableViewCell *ibCell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
                SCTableViewCell *STVCell;
                if([ibCell isKindOfClass:[SCTableViewCell class]])
                    STVCell = (SCTableViewCell *)ibCell;
                else
                    STVCell = [SCCustomCell cellWithCell:ibCell];
                STVCell.cellCreatedInIB = YES;
                STVCell.height = [self tableView:self.tableView heightForRowAtIndexPath:indexPath];
                [section addCell:STVCell];
            }
        }
        
        section.headerTitle = [self tableView:self.tableView titleForHeaderInSection:sectionIndex];
        section.footerTitle = [self tableView:self.tableView titleForFooterInSection:sectionIndex];
        section.headerView = [self tableView:self.tableView viewForHeaderInSection:sectionIndex];
        section.footerView = [self tableView:self.tableView viewForFooterInSection:sectionIndex];
        
        // The "if" check is important since UITableViewController auto provides a single empty section when not using a Storyboard.
        if([section isKindOfClass:[SCArrayOfItemsSection class]] || section.cellCount || section.headerTitle || section.footerTitle || section.headerView || section.footerView)
            [self.tableViewModel addSection:section];
    }
    
    _staticContentAddedToModel = YES;
}

- (BOOL)isMasterOfSplitViewController:(UIViewController *)viewController
{
    if([viewController isKindOfClass:[SCTableViewController class]])
    {
        SCTableViewController *tableViewController = (SCTableViewController *)viewController;
        if(tableViewController.ibEmbedded && tableViewController.parentViewController)
            viewController = tableViewController.parentViewController;
    }
    
    if(viewController.navigationController && [[viewController.navigationController viewControllers] objectAtIndex:0]==viewController)
        viewController = viewController.navigationController;
    
    return (viewController.splitViewController!=nil && viewController.splitViewController.viewControllers.count && [viewController.splitViewController.viewControllers objectAtIndex:0]==viewController);
}

- (BOOL)isDetailOfSplitViewController:(UIViewController *)viewController
{
    if(viewController.navigationController && [[viewController.navigationController viewControllers] objectAtIndex:0]==viewController)
        viewController = viewController.navigationController;
    
    return (viewController.splitViewController!=nil && viewController.splitViewController.viewControllers.count>1 && [viewController.splitViewController.viewControllers objectAtIndex:1]==viewController);
}

- (SCDataDefinition *)dataDefinitionWithIBName:(NSString *)ibName
{
    for(NSString *key in self.ibDataDefinitions)
    {
        SCDataDefinition *dataDefinition = [self.ibDataDefinitions valueForKey:key];
        if([dataDefinition.ibName isEqualToString:ibName])
            return dataDefinition;
    }
    
    return nil;
}

- (NSObject *)objectForSection:(SCObjectSection *)objectSection atIndex:(NSUInteger)index
{
    return nil;  // should be implemented by subclasses
}

- (NSMutableArray *)objectsForSection:(SCArrayOfObjectsSection *)objectsSection atIndex:(NSUInteger)index
{
    return nil;  // should be implemented by subclasses
}

- (void)connectAddButtonToModelObjectsIfNeeded
{
    if(!self.addButton)
        return;
    
    
    if([self.tableViewModel isKindOfClass:[SCArrayOfItemsModel class]])
    {
        SCArrayOfItemsModel *itemsModel = (SCArrayOfItemsModel *)self.tableViewModel;
        if(!itemsModel.addButtonItem)
            itemsModel.addButtonItem = self.addButton;
    }
    else
    {
        BOOL addButtonConnected = NO;
        
        SCArrayOfItemsSection *candidateSection = nil;
        for(NSInteger i=0; i<self.tableViewModel.sectionCount; i++)
        {
            SCTableViewSection *section = [self.tableViewModel sectionAtIndex:i];
            if(![section isKindOfClass:[SCArrayOfItemsSection class]])
                continue;
            
            SCArrayOfItemsSection *itemsSection = (SCArrayOfItemsSection *)section;
            if(itemsSection.addButtonItem == self.addButton)
            {
                addButtonConnected = YES;
                break;
            }
            if(!candidateSection && itemsSection.addButtonItem==nil && itemsSection.addNewItemCell==nil)
                candidateSection = itemsSection;
        }
        
        if(!addButtonConnected)
            candidateSection.addButtonItem = self.addButton;
    }
}

- (void)configureAllObjectSections
{
    for(NSInteger sectionIndex=0; sectionIndex<self.tableViewModel.sectionCount; sectionIndex++)
    {
        SCTableViewSection *section = [self.tableViewModel sectionAtIndex:sectionIndex];
        if(![section isKindOfClass:[SCObjectSection class]])
            continue;
        
        SCObjectSection *objectSection = (SCObjectSection *)section;
        for(NSInteger cellIndex=0; cellIndex<objectSection.cellCount; cellIndex++)
        {
            SCTableViewCell *cell = [objectSection cellAtIndex:cellIndex];
            
            SCPropertyDefinition *propertyDefinition = nil;
            if(cell.boundPropertyName)
                propertyDefinition = [objectSection.boundObjectStore.defaultDataDefinition propertyDefinitionWithName:cell.boundPropertyName];
            if(propertyDefinition)
                [objectSection configureCell:cell forPropertyDefinition:propertyDefinition inEditingMode:NO];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    if(_state != SCViewControllerStateNew)
		_state = SCViewControllerStateActive;
	
    if(_state == SCViewControllerStateNew)
    {
        // Configure object sections here so that all custom user cellActions added in viewDidLoad are synched
        [self configureAllObjectSections];
        
        if(self.tableViewModel.masterModel)
        {
            // Inherit owner's background
            if(self.tableView.style!=UITableViewStylePlain && self.tableViewModel.masterModel.tableView.style!=UITableViewStylePlain)
            {
                self.tableView.backgroundColor = self.tableViewModel.masterModel.tableView.backgroundColor;
            }
        }
        
        [self.tableViewModel styleViews];
        
        [self connectAddButtonToModelObjectsIfNeeded];
    }
    
	_cancelButtonTapped = FALSE;
	_doneButtonTapped = FALSE;
    
    
    [self smoothlyDeselectRowsInTableView:self.tableView];
    
	
    if(self.actions.willAppear)
        self.actions.willAppear(self);
    
	if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
	   && [self.delegate respondsToSelector:@selector(tableViewControllerWillAppear:)])
	{
		[self.delegate tableViewControllerWillAppear:self];
	}
    
    if(self.state == SCViewControllerStateNew)
    {
        if(self.actions.willPresent)
            self.actions.willPresent(self);
        
        if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
           && [self.delegate respondsToSelector:@selector(tableViewControllerWillPresent:)])
        {
            [self.delegate tableViewControllerWillPresent:self];
        }
    }
    
    if(self.autoDisableNavigationButtonsUntilViewAppears)
        [self disableNavigationBarButtons];  // temporarily disable navigation bar buttons until the view controller animations are finished
}

- (void)smoothlyDeselectRowsInTableView:(UITableView *)tableView
{
    NSArray<NSIndexPath *> *selectedIndexPaths = [tableView indexPathsForSelectedRows];
    if (self.transitionCoordinator)
    {
        [self.transitionCoordinator animateAlongsideTransitionInView:self.parentViewController.view animation:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context)
        {
            for (NSIndexPath *indexPath in selectedIndexPaths)
            {
                [tableView deselectRowAtIndexPath:indexPath animated:context.isAnimated];
            }
            
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context)
        {
            if (context.isCancelled)
            {
                for (NSIndexPath *indexPath in selectedIndexPaths)
                {
                    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                }
            }
        }];
    }
    else
    {
        for (NSIndexPath *indexPath in selectedIndexPaths)
        {
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    
	
    if(self.tableViewModel && self.doneButton)
        self.tableViewModel.commitButton = self.doneButton;
	
    if(self.autoDisableNavigationButtonsUntilViewAppears)
        [self enableNavigationBarButtons];
    
    if(self.actions.didAppear)
        self.actions.didAppear(self);
    
	if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
	   && [self.delegate respondsToSelector:@selector(tableViewControllerDidAppear:)])
	{
		[self.delegate tableViewControllerDidAppear:self];
	}
    
    if(self.state == SCViewControllerStateNew)
    {
        if(self.actions.didPresent)
            self.actions.didPresent(self);
        
        if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
           && [self.delegate respondsToSelector:@selector(tableViewControllerDidPresent:)])
        {
            [self.delegate tableViewControllerDidPresent:self];
        }
    }
    
    _state = SCViewControllerStateActive;
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self.tableView reloadData];
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
    
	if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
	   && [self.delegate respondsToSelector:@selector(tableViewControllerWillDisappear:)])
	{
		[self.delegate tableViewControllerWillDisappear:self];
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
        
        if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
           && [self.delegate respondsToSelector:@selector(tableViewControllerWillDismiss:cancelButtonTapped:doneButtonTapped:)])
        {
            [self.delegate tableViewControllerWillDismiss:self cancelButtonTapped:self.cancelButtonTapped doneButtonTapped:self.doneButtonTapped];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    	
    if(self.actions.didDisappear)
        self.actions.didDisappear(self);
    
	if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
	   && [self.delegate respondsToSelector:@selector(tableViewControllerDidDisappear:)])
	{
		[self.delegate tableViewControllerDidDisappear:self];
	}
    
    if(self.state == SCViewControllerStateDismissed)
    {
        if(self.actions.didDismiss)
            self.actions.didDismiss(self);
        
        if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
           && [self.delegate respondsToSelector:@selector(tableViewControllerDidDismiss:cancelButtonTapped:doneButtonTapped:)])
        {
            [self.delegate tableViewControllerDidDismiss:self cancelButtonTapped:self.cancelButtonTapped doneButtonTapped:self.doneButtonTapped];
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

- (void)disableNavigationBarButtons
{
    if(!self.navigationItem)
        return;
    
    if(self.navigationItem.leftBarButtonItem)
    {
        _leftBarButtonItemInitialEnabledState = self.navigationItem.leftBarButtonItem.enabled;
        self.navigationItem.leftBarButtonItem.enabled = NO;
    }
    if(self.navigationItem.rightBarButtonItem)
    {
        _rightBarButtonItemInitialEnabledState = self.navigationItem.rightBarButtonItem.enabled;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (void)enableNavigationBarButtons
{
    if(!self.navigationItem)
        return;
    
    if(self.navigationItem.leftBarButtonItem)
    {
        self.navigationItem.leftBarButtonItem.enabled = _leftBarButtonItemInitialEnabledState;
    }
    if(self.navigationItem.rightBarButtonItem)
    {
        self.navigationItem.rightBarButtonItem.enabled = _rightBarButtonItemInitialEnabledState;
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
            
            if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
               && [self.delegate respondsToSelector:@selector(tableViewControllerDidEnterEditingMode:)])
            {
                [self.delegate tableViewControllerDidEnterEditingMode:self];
            }
        }
        else
        {
            self.tableViewModel.commitButton = nil;
            self.editButton.enabled = TRUE;  // in case user taps 'Cancel' while button disabled
            
            self.navigationItem.leftBarButtonItem = _nonEditModeLeftBarButtonItem;
            BOOL selfIsRootVC = NO;
            if([self.navigationController.viewControllers objectAtIndex:0]==self)
                selfIsRootVC = YES;
            if(!_nonEditModeLeftBarButtonItem && !selfIsRootVC)
                [self.navigationItem setHidesBackButton:FALSE animated:FALSE];
            
            if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
               && [self.delegate respondsToSelector:@selector(tableViewControllerDidExitEditingMode:cancelButtonTapped:doneButtonTapped:)])
            {
                [self.delegate tableViewControllerDidExitEditingMode:self cancelButtonTapped:NO doneButtonTapped:YES];
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
    
    if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
       && [self.delegate respondsToSelector:@selector(tableViewControllerDidExitEditingMode:cancelButtonTapped:doneButtonTapped:)])
    {
        [self.delegate tableViewControllerDidExitEditingMode:self cancelButtonTapped:YES doneButtonTapped:NO];
    }
}

- (void)dismissWithCancelValue:(BOOL)cancelValue doneValue:(BOOL)doneValue
{
    _cancelButtonTapped = cancelValue;
    _doneButtonTapped = doneValue;
    
    BOOL shouldDismiss = TRUE;
    if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
	   && [self.delegate respondsToSelector:
		   @selector(tableViewControllerShouldDismiss:cancelButtonTapped:doneButtonTapped:)])
	{
		shouldDismiss = [self.delegate tableViewControllerShouldDismiss:self
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
    if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
       && [self.delegate respondsToSelector:
           @selector(tableViewControllerWillGainFocus:)])
    {
        [self.delegate tableViewControllerWillGainFocus:self];
    }
    
    _hasFocus = TRUE;
    
    // Connect self.tableViewModel and refresh table view
    self.tableView.dataSource = self.tableViewModel;
    self.tableView.delegate = self.tableViewModel;
    [self.tableViewModel reloadBoundValues];
    [self.tableViewModel.tableView reloadData];
    
    if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
       && [self.delegate respondsToSelector:
           @selector(tableViewControllerDidGainFocus:)])
    {
        [self.delegate tableViewControllerDidGainFocus:self];
    }
}

- (void)loseFocus
{
    if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
       && [self.delegate respondsToSelector:
           @selector(tableViewControllerWillLoseFocus:cancelButtonTapped:doneButtonTapped:)])
    {
        [self.delegate tableViewControllerWillLoseFocus:self cancelButtonTapped:self.cancelButtonTapped doneButtonTapped:self.doneButtonTapped];
    }
    
    _hasFocus = FALSE;
    if(self.navigationBarType != SCNavigationBarTypeNone)
        self.navigationBarType = SCNavigationBarTypeAuto;
    self.title = nil;
    
    // Connect _noFocusModel and refresh table view
    self.tableView.dataSource = _noFocusModel;
    self.tableView.delegate = _noFocusModel;
    [self.tableView reloadData];
    
    if([self.delegate conformsToProtocol:@protocol(SCTableViewControllerDelegate)]
       && [self.delegate respondsToSelector:
           @selector(tableViewControllerDidLoseFocus:cancelButtonTapped:doneButtonTapped:)])
    {
        [self.delegate tableViewControllerDidLoseFocus:self cancelButtonTapped:self.cancelButtonTapped doneButtonTapped:self.doneButtonTapped];
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
		shouldDismiss = [self.delegate tableViewControllerShouldDismiss:self
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

