/*
 *  SCTableViewModel.m
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

#import <objc/message.h>

#import "SCTableViewModel.h"

#import "SCStringDefinition.h"
#import "SCArrayStore.h"
#import "SCUserDefaultsStore.h"


@interface SCTableViewModel ()
{
    BOOL _loading;
}

- (void)prepareSectionForOwnership:(SCTableViewSection *)section;
- (void)callDidAddSectionActionsForSection:(SCTableViewSection *)section;
- (void)addSectionForObject:(NSObject *)object withDataStore:(SCDataStore *)store usingGroup:(SCPropertyGroup *)group newObject:(BOOL)newObject;
- (SCTableViewSection *)getSectionForPropertyDefinition:(SCPropertyDefinition *)propertyDef withBoundObject:(NSObject *)object withDataStore:(SCDataStore *)store;

- (void)tableAnimationEnded:(NSString*)animationID finished:(NSNumber *)finished contextInfo:(void *)context;

@end




@implementation SCTableViewModel

@synthesize masterModel;
@synthesize activeDetailModel;
@synthesize tableView = _tableView;
@synthesize viewController;
@synthesize editButtonItem;
@synthesize autoResizeForKeyboard;
@synthesize sectionIndexTitles;
@synthesize autoGenerateSectionIndexTitles;
@synthesize autoSortSections;
@synthesize hideSectionHeaderTitles;
@synthesize lockCellSelection;
@synthesize tag;
@synthesize activeCell;
@synthesize activeCellIndexPath;
@synthesize activeCellControl;
@synthesize inputAccessoryView = _inputAccessoryView;
@synthesize commitButton;
@synthesize swipeToDeleteActive;
@synthesize enablePullToRefresh;
@synthesize detailViewController = _detailViewController;
@synthesize modelActions = _modelActions;
@synthesize sectionActions = _sectionActions;
@synthesize cellActions = _cellActions;
@synthesize theme = _theme;


+ (instancetype)modelWithTableView:(UITableView *)tableView
{
	return [[[self class] alloc] initWithTableView:tableView];
}


- (instancetype)init
{
    if( (self=[super init])  )
    {
        _loading = FALSE;
        
        _tableView = nil;
        
        lastReturnedCellIndexPath = nil;
        lastReturnedCell = nil;
        lastVisibleCellIndexPath = nil;
		target = nil;
		action = nil;
		masterModel = nil;
        activeDetailModel = nil;
		
		editButtonItem = nil;
		sectionIndexTitles = nil;
		autoGenerateSectionIndexTitles = FALSE;
		autoSortSections = FALSE;
		hideSectionHeaderTitles = FALSE;
		lockCellSelection = FALSE;
		tag = 0;
        
        enablePullToRefresh = FALSE;
        [self setRefreshControl:[[UIRefreshControl alloc] init]]; // call setter
        
        sections = [[NSMutableArray alloc] init];
		activeCell = nil;
        activeCellIndexPath = nil;
        activeCellControl = nil;
		
		commitButton = nil;
		
		keyboardShown = FALSE;
		keyboardOverlap = 0;
        swipeToDeleteActive = FALSE;
        
        _detailViewController = nil;
        
        _modelActions = [[SCModelActions alloc] init];
        _modelActions.ownerTableViewModel = self;
        _sectionActions = [[SCSectionActions alloc] init];
        _cellActions = [[SCCellActions alloc] init];
        
        _theme = nil;
		
		// Register with the shared model center
		[[SCModelCenter sharedModelCenter] registerModel:self];
    }
    return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView
{
	if( (self=[self init]) )
	{
		[self setTableView:tableView];
	}
	
	return self;
}

- (void)dealloc
{
	// Unregister from the shared model center
    [[SCModelCenter sharedModelCenter] unregisterModel:self];
}


- (void)setTableView:(UITableView *)tableView
{
    _tableView = tableView;
    
    if(_tableView)
    {
        // Remove tableView from any previos model
        if(_tableView.dataSource && _tableView.dataSource!=self && [_tableView.dataSource isKindOfClass:[SCTableViewModel class]])
        {
            [(SCTableViewModel *)_tableView.dataSource setTableView:nil];
        }
        
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.allowsSelectionDuringEditing = TRUE;
    }
    
    if([self.viewController isKindOfClass:[UITableViewController class]])
        self.autoResizeForKeyboard = FALSE;
    else
        self.autoResizeForKeyboard = TRUE;
    
    if(self.enablePullToRefresh && _tableView)
    {
        if([self.viewController isKindOfClass:[UITableViewController class]])
        {
            [(UITableViewController *)self.viewController setRefreshControl:self.refreshControl];
        }
        else
        {
            [_tableView addSubview:self.refreshControl];
        }
    }
    
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 44.0f;
    
    [self styleViews];
}

- (UITableView *)modeledTableView
{
    return [self tableView];
}

- (void)setModeledTableView:(UITableView *)modeledTableView
{
    [self setTableView:modeledTableView];
}

- (UITableView *)trueTableView
{
    return _tableView;
}

- (UIViewController *)viewController
{
    if(!self.trueTableView)
        return nil;
    
    
    id vc = [self.trueTableView nextResponder];
    while(![vc isKindOfClass:[UIViewController class]] && vc!=nil)
    {
        vc = [vc nextResponder];
    }
    
    return vc;
}

- (void)setInputAccessoryView:(SCInputAccessoryView *)accessoryView
{
    _inputAccessoryView = accessoryView;
    _inputAccessoryView.delegate = self;
}

- (void)setEnablePullToRefresh:(BOOL)enable
{
    enablePullToRefresh = enable;
    
    if(enable)
    {
        if([self.viewController isKindOfClass:[UITableViewController class]])
        {
            [(UITableViewController *)self.viewController setRefreshControl:self.refreshControl];
        }
        else
        {
            [self.tableView addSubview:self.refreshControl];
        }
    }    
    else 
    {
        if([self.viewController isKindOfClass:[UITableViewController class]])
        {
            [(UITableViewController *)self.viewController setRefreshControl:nil];
        }
        else
        {
            [self.refreshControl removeFromSuperview];
        }
    }
}

- (void)setRefreshControl:(UIRefreshControl *)refreshControl
{
    _refreshControl = refreshControl;
    
    [self.refreshControl addTarget:self action:@selector(pullToRefreshDidStartLoading) forControlEvents:UIControlEventValueChanged];
    
    if(self.enablePullToRefresh)
        [self setEnablePullToRefresh:TRUE];  // call setter to configure refreshControl
}

- (void)setDetailViewController:(UIViewController *)detailViewController
{
    _detailViewController = detailViewController;
    
    SCTableViewModel *detailModel = nil;
    if([detailViewController isKindOfClass:[SCTableViewController class]])
        detailModel = [(SCTableViewController *)detailViewController tableViewModel];
    else if([detailViewController isKindOfClass:[SCViewController class]])
        detailModel = [(SCViewController *)detailViewController tableViewModel];
    if(detailModel)
    {
        [self configureDetailModel:detailModel];
    }
    else 
    {
        if(self.theme)
        {
            [self.theme styleObject:detailViewController.view usingThemeStyle:nil];
            if(self.detailViewController.navigationController.navigationBar)
                [self.theme styleObject:self.detailViewController.navigationController.navigationBar usingThemeStyle:nil];
        }
    }
}

- (void)setTheme:(SCTheme *)theme
{
    if(self.detailViewController)
    {
        SCTableViewModel *detailModel = nil;
        if([self.detailViewController isKindOfClass:[SCTableViewController class]])
            detailModel = [(SCTableViewController *)viewController tableViewModel];
        else if([self.detailViewController isKindOfClass:[SCViewController class]])
            detailModel = [(SCViewController *)viewController tableViewModel];
        
        if(detailModel)
        {
            if(detailModel.theme == _theme)
                detailModel.theme = theme;
        }
        else 
        {
            if(theme)
            {
                [theme styleObject:self.detailViewController.view usingThemeStyle:nil];
                if(self.detailViewController.navigationController.navigationBar)
                    [theme styleObject:self.detailViewController.navigationController.navigationBar usingThemeStyle:nil];
            }
        }
    }
    
    _theme = theme;
}

- (BOOL)live
{
    BOOL live;
    if([self.tableView.visibleCells count] && !_loading && !(self.tableView.dragging || self.tableView.decelerating))
        live = TRUE;
    else 
        live = FALSE;
    
    return live;
}

- (void)styleSections
{
    for(NSUInteger i=0; i<self.sectionCount; i++)
    {
        SCTableViewSection *section = [self sectionAtIndex:i];
        [self.theme styleObject:section usingThemeStyle:section.themeStyle];
    }
}

- (void)styleViews
{
    if(!self.theme)
        return;
    
    // Style the table view
    if(self.live)
        [self.tableView reloadData];
    
    // Style other views
    if(self.viewController)
        [self.theme styleObject:self.viewController.view usingThemeStyle:nil];
    if(self.viewController.navigationController.navigationBar)
        [self.theme styleObject:self.viewController.navigationController.navigationBar usingThemeStyle:nil];
    if(self.refreshControl)
        [self.theme styleObject:self.refreshControl usingThemeStyle:nil];
}

- (void)enterLoadingMode
{
    _loading = TRUE;
}

- (void)exitLoadingMode
{
    _loading = FALSE;
    [self clearLastReturnedCellData];
}

- (void)clearLastReturnedCellData
{
    if(lastReturnedCellIndexPath)
    {
        lastReturnedCellIndexPath = nil;
        
        lastReturnedCell.configured = FALSE;
        lastReturnedCell = nil;
    }
}

- (void)configureDetailModel:(SCTableViewModel *)detailModel
{
    detailModel.masterModel = self;
    
    detailModel.tag = self.tag + 1;
    
    if(!detailModel.theme)
        detailModel.theme = self.theme;
}

- (NSArray *)sectionIndexTitles
{
	if(!self.autoGenerateSectionIndexTitles)
		return sectionIndexTitles;
	
	// Generate sectionIndexTitles
	NSMutableArray *titles = [NSMutableArray arrayWithCapacity:self.sectionCount];
	for(SCTableViewSection *section in sections)
		if([section.headerTitle length])
		{
			// Add first letter of the header title to section titles
			[titles addObject:[section.headerTitle substringToIndex:1]];
		}
	return titles;
}

- (void)setAutoSortSections:(BOOL)autoSort
{
	autoSortSections = autoSort;
	if(autoSort)
		[sections sortUsingSelector:@selector(compare:)];
}


- (void)rollbackToInitialCellValues
{
    for(SCTableViewSection *section in sections)
    {
        [section rollbackToInitialCellValues];
    }
}

- (void)reloadCellsIfNeeded
{
    for(SCTableViewSection *section in sections)
    {
        if(![section isKindOfClass:[SCObjectSection class]])
            continue;
        
        [(SCObjectSection *)section reloadCellsIfNeeded];
    }
}


- (void)setActiveCell:(SCTableViewCell *)cell
{
	if(activeCell == cell)
		return;
	
    if(activeCell)
    {
        if(activeCell.cellActions.willDeselect)
        {
            cell.cellActions.willDeselect(cell, self.activeCellIndexPath);
        }
        else
            if(activeCell.ownerSection.cellActions.willDeselect)
            {
                activeCell.ownerSection.cellActions.willDeselect(cell, self.activeCellIndexPath);
            }
            else
                if(activeCell.ownerTableViewModel.cellActions.willDeselect)
                {
                    self.cellActions.willDeselect(cell, self.activeCellIndexPath);
                }
        [activeCell willDeselectCell];
        
        [self.tableView deselectRowAtIndexPath:self.activeCellIndexPath animated:NO];
        
        if(activeCell.cellActions.didDeselect)
        {
            cell.cellActions.didDeselect(cell, self.activeCellIndexPath);
        }
        else
            if(activeCell.ownerSection.cellActions.didDeselect)
            {
                activeCell.ownerSection.cellActions.didDeselect(cell, self.activeCellIndexPath);
            }
            else
                if(activeCell.ownerTableViewModel.cellActions.didDeselect)
                {
                    self.cellActions.didDeselect(cell, self.activeCellIndexPath);
                }
        [activeCell didDeselectCell];
    }
	
    activeCell = cell;
    activeCellIndexPath = [self indexPathForCell:activeCell];
	
    if(![activeCell isKindOfClass:[SCCustomCell class]])
        self.activeCellControl = nil;
    
    if(activeCell)
    {
        if(!activeCell.selected)
        {
            if(activeCell.cellActions.willSelect)
            {
                cell.cellActions.willSelect(cell, self.activeCellIndexPath);
            }
            else
                if(activeCell.ownerSection.cellActions.willSelect)
                {
                    activeCell.ownerSection.cellActions.willSelect(cell, self.activeCellIndexPath);
                }
                else
                    if(activeCell.ownerTableViewModel.cellActions.willSelect)
                    {
                        self.cellActions.willSelect(cell, self.activeCellIndexPath);
                    }
            
            activeCell.selected = YES;
            
            if(activeCell.cellActions.didSelect)
            {
                cell.cellActions.didSelect(cell, self.activeCellIndexPath);
            }
            else
                if(activeCell.ownerSection.cellActions.didSelect)
                {
                    activeCell.ownerSection.cellActions.didSelect(cell, self.activeCellIndexPath);
                }
                else
                    if(activeCell.ownerTableViewModel.cellActions.didSelect)
                    {
                        self.cellActions.didSelect(cell, self.activeCellIndexPath);
                    }
        }
        
        [self.tableView scrollToRowAtIndexPath:activeCellIndexPath
                                     atScrollPosition:UITableViewScrollPositionNone
                                             animated:YES];
        [self.tableView selectRowAtIndexPath:activeCellIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)setActiveCellControl:(UIResponder *)control
{
    activeCellControl = control;
}

- (void)setCommitButton:(UIBarButtonItem *)button
{
	commitButton = button;
	
	commitButton.enabled = self.valuesAreValid;
}

- (void)setEditButtonItem:(UIBarButtonItem *)barButtonItem
{
	editButtonItem = barButtonItem;
	
	editButtonItem.target = self;
	editButtonItem.action = @selector(didTapEditButtonItem);
}

- (void)valueChangedForSectionAtIndex:(NSUInteger)index
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if(target)
        [target performSelector:action];
#pragma clang diagnostic pop
    
    SCTableViewSection *section = [self sectionAtIndex:index];
    if(section.sectionActions.valueChanged)
        section.sectionActions.valueChanged(section, index);
    else
        if(self.sectionActions.valueChanged)
            self.sectionActions.valueChanged(section, index);
}

- (void)valueChangedForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(!indexPath)
		return;
	
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
	SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	if(cell != self.activeCell)
	{
		if(self.activeCell.autoResignFirstResponder)
			[self.activeCell resignFirstResponder];
		self.activeCell = cell;
	}
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	if(target)
        [target performSelector:action];
#pragma clang diagnostic pop
	
	if(self.commitButton)
		self.commitButton.enabled = self.valuesAreValid;
    
    if(cell.cellActions.valueChanged)
    {
        cell.cellActions.valueChanged(cell, indexPath);
    }
    else 
    if(section.cellActions.valueChanged)
    {
        section.cellActions.valueChanged(cell, indexPath);
    }
    else 
        if(self.cellActions.valueChanged)
        {
            self.cellActions.valueChanged(cell, indexPath);
        }
}

- (void)setTargetForModelModifiedEvent:(id)_target action:(SEL)_action
{
	target = _target;
	action = _action;
}

- (void)didTapEditButtonItem
{	
	BOOL editing = !self.tableView.editing;		// toggle editing state
	
	[self setTableViewEditing:editing animated:TRUE];
}

- (void)pullToRefreshDidStartLoading
{
    if(self.detailViewController)
    {
        // Clear detail view
        if([self.detailViewController isKindOfClass:[SCTableViewController class]])
        {
            SCTableViewController *detailVC = (SCTableViewController *)self.detailViewController;
            [detailVC loseFocus];
        }
        else
            if([self.detailViewController isKindOfClass:[SCViewController class]])
            {
                SCViewController *detailVC = (SCViewController *)self.detailViewController;
                [detailVC loseFocus];
            }
    }
    
    
    [self reloadBoundValues];
    [self.tableView reloadData];
    
    [self.refreshControl endRefreshing];
    
    if(self.modelActions.didRefresh)
    {
        self.modelActions.didRefresh(self);
    }
}

- (NSUInteger)sectionCount
{
	return sections.count;
}

- (void)prepareSectionForOwnership:(SCTableViewSection *)section
{
    section.ownerTableViewModel = self;
    
    if(self.tableView.editing && [section isKindOfClass:[SCObjectSection class]])
    {
        [(SCObjectSection *)section generateCellsForEditingState:TRUE];
    }
}

- (void)addSection:(SCTableViewSection *)section
{
	[self prepareSectionForOwnership:section];
    
	[sections addObject:section];
    
	
    if(self.modelActions.sortSections)
        self.modelActions.sortSections(self, sections);
    else
		if(self.autoSortSections)
			[sections sortUsingSelector:@selector(compare:)];
    
    [self callDidAddSectionActionsForSection:section];
}

- (void)insertSection:(SCTableViewSection *)section atIndex:(NSUInteger)index
{
	[self prepareSectionForOwnership:section];
    
	[sections insertObject:section atIndex:index];
    
    [self callDidAddSectionActionsForSection:section];
}

- (void)callDidAddSectionActionsForSection:(SCTableViewSection *)section
{
    NSUInteger sectionIndex = [sections indexOfObjectIdenticalTo:section];
    
    if(self.modelActions.didAddSection)
        self.modelActions.didAddSection(self, section, sectionIndex);
    
    if(section.sectionActions.didAddToModel)
    {
        section.sectionActions.didAddToModel(section, sectionIndex);
    }
    else
        if(self.sectionActions.didAddToModel)
        {
            self.sectionActions.didAddToModel(section, sectionIndex);
        }
}

- (SCTableViewSection *)sectionAtIndex:(NSUInteger)index
{
	if(index < self.sectionCount)
		return [sections objectAtIndex:index];
	//else
	return nil;
}

- (SCTableViewSection *)sectionWithHeaderTitle:(NSString *)title
{
	for(SCTableViewSection *section in sections)
		if(title)
		{
			if([section.headerTitle isEqualToString:title])
				return section;
		}
		else
		{
			if(!section.headerTitle)
				return section;
		}
		
	
	return nil;
}

- (NSUInteger)indexForSection:(SCTableViewSection *)section
{
	return [sections indexOfObjectIdenticalTo:section];
}

- (void)removeSectionAtIndex:(NSUInteger)index
{
	[sections removeObjectAtIndex:index];
    
    if(self.modelActions.didRemoveSection)
        self.modelActions.didRemoveSection(self, index);
}

- (void)removeAllSections
{
    activeCell = nil;
    activeCellControl = nil;
    
	[sections removeAllObjects];
}

- (void)generateSectionsForObject:(NSObject *)object withDefinition:(SCDataDefinition *)definition
{
    [self generateSectionsForObject:object withDefinition:definition newObject:NO];
}

- (void)generateSectionsForObject:(NSObject *)object withDefinition:(SCDataDefinition *)definition newObject:(BOOL)newObject
{
    SCDataStore *objStore = [definition generateCompatibleDataStore];
    [self generateSectionsForObject:object withDataStore:objStore newObject:newObject];
}

- (void)generateSectionsForObject:(NSObject *)object withDataStore:(SCDataStore *)store
{
    [self generateSectionsForObject:object withDataStore:store newObject:NO];
}

- (void)generateSectionsForObject:(NSObject *)object withDataStore:(SCDataStore *)store newObject:(BOOL)newObject
{
    SCDataDefinition *definition = [store definitionForObject:object];
    [definition generateDefaultPropertyGroupProperties];
    
    [self addSectionForObject:object withDataStore:store usingGroup:definition.defaultPropertyGroup newObject:newObject];
    
    for(NSInteger i=0; i<definition.propertyGroups.groupCount; i++)
    {
        SCPropertyGroup *propertyGroup = [definition.propertyGroups groupAtIndex:i];
        [self addSectionForObject:object withDataStore:store usingGroup:propertyGroup newObject:newObject];
    }
}

- (void)generateSectionsForUserDefaultsDefinition:(SCUserDefaultsDefinition *)userDefaultsDefinition
{
    SCUserDefaultsStore *store = (SCUserDefaultsStore *)[userDefaultsDefinition generateCompatibleDataStore];
    NSObject *object = store.standardUserDefaultsObject;
    
    [self generateSectionsForObject:object withDataStore:store newObject:FALSE];
}

- (void)addSectionForObject:(NSObject *)object withDataStore:(SCDataStore *)store usingGroup:(SCPropertyGroup *)group newObject:(BOOL)newObject
{
    NSInteger propertyNameCount = group.propertyNameCount;
    if(!propertyNameCount)
        return;
    
    SCDataDefinition *definition = [store definitionForObject:object];
    
    SCPropertyGroup *subGroup = [SCPropertyGroup groupWithHeaderTitle:group.headerTitle footerTitle:group.footerTitle propertyNames:nil];
    for(NSInteger i=0; i<propertyNameCount; i++)
    {
        NSString *propertyName = [group propertyNameAtIndex:i];
        SCPropertyDefinition *propertyDef = [definition propertyDefinitionWithName:propertyName];
        
        if( (newObject && !propertyDef.existsInCreationMode) || (!newObject && !propertyDef.existsInDetailMode) )
            continue;
        
        if(!propertyDef.attributes.expandContentInCurrentView)
        {
            [subGroup addPropertyName:propertyName];
            continue;
        }
        else
        {
            if(subGroup.propertyNameCount)
            {
                SCObjectSection *objectSection = [[SCObjectSection alloc] initWithHeaderTitle:nil boundObject:object boundObjectStore:store propertyGroup:subGroup];
                [self addSection:objectSection];
                
                // reset subGroup
                subGroup = [SCPropertyGroup groupWithHeaderTitle:group.headerTitle footerTitle:group.footerTitle propertyNames:nil];
            }
            
            SCTableViewSection *section = [self getSectionForPropertyDefinition:propertyDef withBoundObject:object withDataStore:store];
            if(section)
            {
                section.headerTitle = group.headerTitle;
                section.footerTitle = group.footerTitle;
                section.detailViewControllerOptions.hidesBottomBarWhenPushed = self.viewController.hidesBottomBarWhenPushed;
                
                [self addSection:section];
            }
        }
    }
    
    if(subGroup.propertyNameCount)
    {
        SCObjectSection *objectSection = [[SCObjectSection alloc] initWithHeaderTitle:nil boundObject:object boundObjectStore:store propertyGroup:subGroup];
        [self addSection:objectSection];
    }
}

- (SCTableViewSection *)getSectionForPropertyDefinition:(SCPropertyDefinition *)propertyDef withBoundObject:(NSObject *)boundObj withDataStore:(SCDataStore *)store
{
    SCTableViewSection *section = nil;
    
    switch (propertyDef.type)
    {
        case SCPropertyTypeObject:
        {
            NSObject *object = [store valueForPropertyName:propertyDef.name inObject:boundObj];
            
            SCDataDefinition *objDef = nil;
            if([propertyDef.attributes isKindOfClass:[SCObjectAttributes class]])
            {
                objDef = [(SCObjectAttributes *)propertyDef.attributes objectDefinition];
            }
            
            if(!objDef)
                break;
            
            SCDataStore *objStore = [objDef generateCompatibleDataStore];
            if(!object)
            {
                // create a new object
                object = [objStore createNewObjectWithDefinition:objDef];
                [objStore insertObject:object];
                
                [store setValue:object forPropertyName:propertyDef.name inObject:boundObj];
            }
            
            if(!object)
                break;
            
            section = [SCObjectSection sectionWithHeaderTitle:nil boundObject:object boundObjectStore:objStore propertyGroup:nil];
        }
            break;
            
        case SCPropertyTypeArrayOfObjects:
        {
            SCDataDefinition *objectsDefinition = nil;
            if([propertyDef.attributes isKindOfClass:[SCArrayOfObjectsAttributes class]])
            {
                objectsDefinition = [(SCArrayOfObjectsAttributes *)propertyDef.attributes defaultObjectsDefinition];
            }
            
            SCDataStore *objectsStore = [objectsDefinition generateCompatibleDataStore];
            if(objectsStore)
            {
                if(![objectsStore valueForPropertyName:propertyDef.name inObject:boundObj])
                {
                    if( (propertyDef.dataType==SCDataTypeNSMutableArray && !propertyDef.dataReadOnly)
                       || propertyDef.dataType==SCDataTypeDictionaryItem)
                    {
                        if([objectsStore isKindOfClass:[SCArrayStore class]]) // if statement required to prevent problems with other stores not supporting this kind of initialization
                            [objectsStore setValue:[NSMutableArray array] forPropertyName:propertyDef.name inObject:boundObj];
                    }
                }
                
                SCDataDefinition *boundObjDef = [store definitionForObject:boundObj];
                [objectsStore bindStoreToPropertyName:propertyDef.name forObject:boundObj withDefinition:boundObjDef];
            }
            
            section = [SCArrayOfObjectsSection sectionWithHeaderTitle:nil dataStore:objectsStore];
        }
            break;
            
        case SCPropertyTypeSelection:
            if(propertyDef.dataType==SCDataTypeNSNumber || propertyDef.dataType==SCDataTypeInt)
            {
                section = [SCSelectionSection sectionWithHeaderTitle:nil boundObject:boundObj selectedIndexPropertyName:propertyDef.name items:nil];
            }
            else
                if(propertyDef.dataType == SCDataTypeNSString)
                {
                    section = [SCSelectionSection sectionWithHeaderTitle:nil boundObject:boundObj selectionStringPropertyName:propertyDef.name items:nil];
                }
                else
                    if(propertyDef.dataType == SCDataTypeNSMutableSet)
                    {
                        section = [SCSelectionSection sectionWithHeaderTitle:nil boundObject:boundObj selectedIndexesPropertyName:propertyDef.name items:nil allowMultipleSelection:FALSE];
                    }
            break;
        case SCPropertyTypeObjectSelection:
            section = [SCObjectSelectionSection sectionWithHeaderTitle:nil boundObject:boundObj selectedObjectPropertyName:propertyDef.name selectionItemsStore:nil];
            break;
            
        default:
            section = nil;
    }
    
    if(section)
    {
        [section setAttributesTo:propertyDef.attributes];
        if(propertyDef.attributes)
            [section.sectionActions setActionsTo:propertyDef.attributes.expandedContentSectionActions overrideExisting:YES];
    }
    
    return  section;
}

- (void)clear
{
	[self removeAllSections];
	activeCell = nil;
    activeCellIndexPath = nil;
}

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animate
{
    if(editing == self.tableView.editing)
        return;
    
    if(self.swipeToDeleteActive)
    {
        [self.tableView setEditing:NO animated:animate];
        swipeToDeleteActive = FALSE;
        return;
    }
    
    [self clearLastReturnedCellData];
    
    BOOL shouldContinue = TRUE;
    if(editing)
	{
        if(self.modelActions.shouldBeginEditing)
            shouldContinue = self.modelActions.shouldBeginEditing(self);
	}
	else
	{
        if(self.modelActions.shouldEndEditing)
            shouldContinue = self.modelActions.shouldEndEditing(self);
	}
    if(!shouldContinue)
        return;
    
    
    [self.tableView beginUpdates];
    
    // Update sections to reflect new state
    for(SCTableViewSection *section in sections)
        [section editingModeWillChange];
    
    // Set editing mode
    [self.viewController setEditing:editing animated:animate];
	[self.tableView setEditing:editing animated:animate];
    
    [self.tableView endUpdates];
    
    // Notify section that editing mode has changed
    for(SCTableViewSection *section in sections)
        [section editingModeDidChange];
    
    
    if(editing)
	{
        if(self.modelActions.didBeginEditing)
            self.modelActions.didBeginEditing(self);
	}
	else
	{
        if(self.modelActions.didEndEditing)
            self.modelActions.didEndEditing(self);
	}
}

- (void)setModeledTableViewEditing:(BOOL)editing animated:(BOOL)animate 
{
    [self setTableViewEditing:editing animated:animate];
}


- (UIViewController *)detailViewControllerForCellAtIndexPath:(NSIndexPath *)indexPath
{
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
    
    return [section generatedDetailViewControllerForCellAtIndexPath:indexPath];
}


- (void)setBoundObjectForAllCells:(NSObject *)boundObject dataDefinition:(SCDataDefinition *)dataDefinition
{
    SCDataStore *dataStore = [dataDefinition generateCompatibleDataStore];
    
    [self setBoundObjectForAllCells:boundObject boundObjectStore:dataStore];
}

- (void)setBoundObjectForAllCells:(NSObject *)boundObject boundObjectStore:(SCDataStore *)boundObjectStore
{
    for(NSUInteger i=0; i<self.sectionCount; i++)
    {
        SCTableViewSection *section = [self sectionAtIndex:i];
        for(NSUInteger j=0; j<section.cellCount; j++)
        {
            SCTableViewCell *cell = [section cellAtIndex:j];
            cell.boundObjectStore = boundObjectStore;
            cell.boundObject = boundObject;
        }
    }
}

- (SCTableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
{
    if(!indexPath || indexPath.row == NSNotFound)
        return nil;
    
    SCTableViewCell *cell = nil;
    
    if(self.live)
    {
        cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    }
    
    if(!cell)
    {
        BOOL needsOptimization = FALSE;
        SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
        if([section isKindOfClass:[SCArrayOfItemsSection class]])
            needsOptimization = TRUE;
        
        if(needsOptimization && lastReturnedCellIndexPath && indexPath.section==lastReturnedCellIndexPath.section && indexPath.row==lastReturnedCellIndexPath.row)
        {
            cell = lastReturnedCell;
        }
        else
        {
            [self clearLastReturnedCellData];
            
            cell = [section cellAtIndex:indexPath.row];
            
            if(needsOptimization)
            {
                lastReturnedCellIndexPath = indexPath;
                lastReturnedCell = cell;
            }
        }
    }
    
	return cell;
}

- (NSIndexPath *)indexPathForCell:(SCTableViewCell *)cell
{
    if(!cell)
        return nil;
    
    if(cell == lastReturnedCell)
        return lastReturnedCellIndexPath;
    
	for(NSUInteger i=0; i<self.sectionCount; i++)
	{
		NSUInteger index = [[self sectionAtIndex:i] indexForCell:cell];
		if(index == NSNotFound)
			continue;
		return [NSIndexPath indexPathForRow:index inSection:i];
	}
	return nil;
}

- (SCTableViewCell *)cellWithBoundPropertyName:(NSString *)boundPropertyName
{
    SCTableViewCell *cell = nil;
    
    for(SCTableViewSection *section in sections)
    {
        if(![section isKindOfClass:[SCObjectSection class]])
            continue;
        
        SCObjectSection *objectSection = (SCObjectSection *)section;
        cell = [objectSection cellForPropertyName:boundPropertyName];
        if(cell)
            break;
    }
    
    return cell;
}

- (NSIndexPath *)indexPathForCellAfterCellAtIndexPath:(NSIndexPath *)indexPath rewind:(BOOL)rewind
{
    if(self.sectionCount==1 && [self sectionAtIndex:0].cellCount==1)
		return nil;		// only one cell in model
	
	SCTableViewSection *cellSection = [self sectionAtIndex:indexPath.section];
	if(indexPath.row+1 < cellSection.cellCount)
		return [NSIndexPath indexPathForRow:indexPath.row+1 inSection:indexPath.section];
	
	if(indexPath.section+1 < self.sectionCount)
		return [NSIndexPath indexPathForRow:0 inSection:indexPath.section+1];
	
	if(!rewind)
		return nil;
	
	return [NSIndexPath indexPathForRow:0 inSection:0];
}

- (NSIndexPath *)indexPathForCellAfterCell:(SCTableViewCell *)cell rewind:(BOOL)rewind
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    
    return [self indexPathForCellAfterCellAtIndexPath:indexPath rewind:rewind];
}

- (SCTableViewCell *)cellAfterCell:(SCTableViewCell *)cell rewind:(BOOL)rewind
{
	NSIndexPath *nextCellIndexPath = [self indexPathForCellAfterCell:cell rewind:rewind];
    
    if(!nextCellIndexPath)
        return nil;
    //else
    return (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:nextCellIndexPath];
}

- (NSIndexPath *)indexPathForCellBeforeCellAtIndexPath:(NSIndexPath *)indexPath rewind:(BOOL)rewind
{
    if(self.sectionCount==1 && [self sectionAtIndex:0].cellCount==1)
		return nil;		// only one cell in model
	
	if(indexPath.row-1 >= 0)
		return [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
	
	if(indexPath.section-1 >= 0)
    {
        SCTableViewSection *prevSection = [self sectionAtIndex:indexPath.section-1];
        return [NSIndexPath indexPathForRow:prevSection.cellCount-1 inSection:indexPath.section-1];
    }
	
	if(!rewind)
		return nil;
	
    NSUInteger lastSectionIndex = self.sectionCount-1;
    SCTableViewSection *lastSection = [self sectionAtIndex:lastSectionIndex];
    if(lastSection.cellCount)
        return [NSIndexPath indexPathForRow:lastSection.cellCount-1 inSection:lastSectionIndex]; // last cell
    //else 
    return nil;
}

- (NSIndexPath *)indexPathForCellBeforeCell:(SCTableViewCell *)cell rewind:(BOOL)rewind
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    
    return [self indexPathForCellAfterCellAtIndexPath:indexPath rewind:rewind];
}

- (SCTableViewCell *)cellBeforeCell:(SCTableViewCell *)cell rewind:(BOOL)rewind
{
    NSIndexPath *prevCellIndexPath = [self indexPathForCellBeforeCell:cell rewind:rewind];
    
    if(!prevCellIndexPath)
        return nil;
    //else
    return (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:prevCellIndexPath];
}

- (void)moveToNextCellControl:(BOOL)rewind
{
    // check that there are no other TextFields/TextViews in the current cell before
    // moving on to the next cell
    if([self.activeCell isKindOfClass:[SCCustomCell class]])
    {
        NSArray *inputControls = [(SCCustomCell *)self.activeCell inputControlsSortedByTag];
        NSUInteger activeControlIndex = [inputControls indexOfObjectIdenticalTo:self.activeCellControl];
        if(activeControlIndex<inputControls.count-1 && activeControlIndex!=NSNotFound)
        {
            [(UIResponder *)[inputControls objectAtIndex:activeControlIndex+1] becomeFirstResponder];
            return;
        }
    }
        
    // get next cell
    NSIndexPath *currentCellIndexPath = self.activeCellIndexPath;
    SCTableViewCell *nextCell = nil;
    NSIndexPath *nextCellIndexPath = nil;
    while( (nextCellIndexPath = [self indexPathForCellAfterCellAtIndexPath:currentCellIndexPath rewind:rewind])) 
    {
        if(!nextCellIndexPath)
        {
            nextCell = nil;
            break;
        }
        
        nextCell = [self cellAtIndexPath:nextCellIndexPath];
        if([nextCell canBecomeFirstResponder])
            break;
        
        //else
        
        // prevent infinite loop
        if(nextCellIndexPath.row==self.activeCellIndexPath.row && nextCellIndexPath.section==self.activeCellIndexPath.section)
        {
            nextCell = nil;
            break;
        }
        
        currentCellIndexPath = nextCellIndexPath;
        nextCell = nil;
        nextCellIndexPath = nil;
    }
    
    if(nextCell)
    {
        self.activeCell = nextCell;
        [self.activeCell becomeFirstResponder];
    }
    else
    {
        [self.activeCell resignFirstResponder];
        self.activeCell = nil;
    }
}

- (void)moveToPreviousCellControl:(BOOL)rewind
{
    // check that there are no other TextFields/TextViews in the current cell before
    // moving on to the previous cell
    if([self.activeCell isKindOfClass:[SCCustomCell class]])
    {
        NSArray *inputControls = [(SCCustomCell *)self.activeCell inputControlsSortedByTag];
        NSUInteger activeControlIndex = [inputControls indexOfObjectIdenticalTo:self.activeCellControl];
        if(activeControlIndex>0 && activeControlIndex!=NSNotFound)
        {
            [(UIResponder *)[inputControls objectAtIndex:activeControlIndex-1] becomeFirstResponder];
            return;
        }
    }
    
    // get previous cell
    NSIndexPath *currentCellIndexPath = self.activeCellIndexPath;
    SCTableViewCell *prevCell = nil;
    NSIndexPath *prevCellIndexPath = nil;
    while( (prevCellIndexPath = [self indexPathForCellBeforeCellAtIndexPath:currentCellIndexPath rewind:rewind])) 
    {
        if(!prevCellIndexPath)
        {
            prevCell = nil;
            break;
        }
        
        prevCell = [self cellAtIndexPath:prevCellIndexPath];
        if([prevCell canBecomeFirstResponder])
            break;
        
        //else
        
        // prevent infinite loop
        if(prevCellIndexPath.row==self.activeCellIndexPath.row && prevCellIndexPath.section==self.activeCellIndexPath.section)
        {
            prevCell = nil;
            break;
        }
        
        currentCellIndexPath = prevCellIndexPath;
        prevCell = nil;
        prevCellIndexPath = nil;
    }
    
    if(prevCell)
    {
        self.activeCell = prevCell;
        [self.activeCell becomeFirstResponder];
    }
    else
    {
        [self.activeCell resignFirstResponder];
        self.activeCell = nil;
    }
}

- (void)dismissAllDetailViewsWithCommit:(BOOL)commit
{
    if(!self.activeDetailModel)
        return;
    
    SCTableViewModel *detailModel = self.activeDetailModel;
    [detailModel dismissAllDetailViewsWithCommit:commit];
    
    BOOL doneValue = commit;
    BOOL cancelValue = !commit;
    if([detailModel.viewController isKindOfClass:[SCViewController class]])
    {
        SCViewController *detailView = (SCViewController *)detailModel.viewController;
        detailView.delegate = nil;  // disable delegates
        [detailView dismissWithCancelValue:cancelValue doneValue:doneValue];
    }
    else 
        if([detailModel.viewController isKindOfClass:[SCTableViewController class]])
        {
            SCTableViewController *detailView = (SCTableViewController *)detailModel.viewController;
            detailView.delegate = nil;  // disable delegates
            [detailView dismissWithCancelValue:cancelValue doneValue:doneValue];
        }
    
    self.activeDetailModel = nil;
}

- (BOOL)valuesAreValid
{
	for(SCTableViewSection *section in sections)
		if(!section.valuesAreValid)
			return FALSE;
	
	return TRUE;
}

- (BOOL)needsCommit
{
	for(SCTableViewSection *section in sections)
		if(section.needsCommit)
			return TRUE;
	
	return FALSE;
}

- (void)commitChanges
{
    for(NSUInteger i=0; i<self.sectionCount; i++)
	{
		SCTableViewSection *section = [self sectionAtIndex:i];
        [section commitCellChanges];
	}
}

- (void)reloadBoundValues
{
    [self clearLastReturnedCellData];
    
    if(self.detailViewController)
    {
        if([self.detailViewController isKindOfClass:[SCViewController class]])
            [(SCViewController *)self.detailViewController loseFocus];
        else 
            if([self.detailViewController isKindOfClass:[SCTableViewController class]])
                [(SCTableViewController *)self.detailViewController loseFocus];
    }
    
	for(SCTableViewSection *section in sections)
		[section reloadBoundValues];
}

- (void)styleCell:(SCTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath onlyStylePropertyNamesInSet:(NSSet *)propertyNames
{
    if(!self.theme)
        return;
    
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
    
    if(cell.cellActions.willStyle)
    {
        cell.cellActions.willStyle(cell, indexPath);
    }
    else 
        if(section.cellActions.willStyle)
        {
            section.cellActions.willStyle(cell, indexPath);
        }
        else 
            if(self.cellActions.willStyle)
            {
                self.cellActions.willStyle(cell, indexPath);
            }
    
    NSString *themeStyle = cell.themeStyle;
    if(!themeStyle)
    {
        if(indexPath.row == 0)
            themeStyle = section.firstCellThemeStyle;
        else 
        if(indexPath.row == section.cellCount-1)
            themeStyle = section.lastCellThemeStyle;
        
        if(!themeStyle)
        {
            if(indexPath.row % 2)
                themeStyle = section.evenCellsThemeStyle;
            else 
                themeStyle = section.oddCellsThemeStyle;
        }
    }
    
    [self.theme styleObject:cell usingThemeStyle:themeStyle onlyStylePropertyNamesInSet:propertyNames];
}

- (void)configureCell:(SCTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
    
    if(cell.cellActions.willConfigure)
    {
        cell.cellActions.willConfigure(cell, indexPath);
    }
    else
        if(section.cellActions.willConfigure)
        {
            section.cellActions.willConfigure(cell, indexPath);
        }
        else 
            if(self.cellActions.willConfigure)
            {
                self.cellActions.willConfigure(cell, indexPath);
            }
    
    cell.configured = TRUE;
}

#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    [self enterLoadingMode];
    
    if(self.theme)
        [self styleSections];
    
	return self.sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
    [self clearLastReturnedCellData];
    
    return [self sectionAtIndex:section].cellCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
   if(self.hideSectionHeaderTitles)
		return nil;
	//else
	return [self sectionAtIndex:section].headerTitle;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [self sectionAtIndex:section].footerTitle;;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return self.sectionIndexTitles;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    if(self.modelActions.sectionForSectionIndexTitle)
    {
        return self.modelActions.sectionForSectionIndexTitle(self, title, index);
    }
    
	if(index < self.sectionCount)
		return index;
	//else return the last section index
	return self.sectionCount-1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self cellAtIndexPath:indexPath].editable;  
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL movable = [self cellAtIndexPath:indexPath].movable;
	return movable;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return [self cellAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
	if([section isKindOfClass:[SCArrayOfItemsSection class]])
		[(SCArrayOfItemsSection *)section commitEditingStyle:editingStyle forCellAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath 
													toIndexPath:(NSIndexPath *)toIndexPath
{
	SCTableViewSection *section = [self sectionAtIndex:fromIndexPath.section];
	if([section isKindOfClass:[SCArrayOfItemsSection class]])
		[(SCArrayOfItemsSection *)section moveCellAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
	
    if(self.modelActions.didMoveCell)
    {
        SCTableViewCell *cell = [self cellAtIndexPath:toIndexPath];
        self.modelActions.didMoveCell(self, cell, fromIndexPath, toIndexPath);
    }
}


#pragma mark -
#pragma mark UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self clearLastReturnedCellData];
    
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
    if([section isKindOfClass:[SCObjectSection class]])
    {
        SCTableViewCell *cell = [section cellAtIndex:indexPath.row];
        if(![cell isKindOfClass:[SCControlCell class]])
        {
            if([cell isKindOfClass:[SCCustomCell class]])
            {
                SCCustomCell *customCell = (SCCustomCell *)cell;
                if(!customCell.needsCommit)
                {
                    [customCell loadBindingsIntoCustomControls];
                }
            }
            
            CGFloat beforeConfigureHeight = cell.height;
            [self configureCell:cell atIndexPath:indexPath];
            
            if(cell.height != beforeConfigureHeight)
                return cell.height;
            //else
            return UITableViewAutomaticDimension;
        }
    }
    
	//else
    
    return [section heightForCellAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    SCTableViewSection *scSection = [self sectionAtIndex:section];
    
    if([scSection isKindOfClass:[SCArrayOfItemsSection class]])
    {
        SCArrayOfItemsSection  *itemsSection = (SCArrayOfItemsSection *)scSection;
        if(itemsSection.hideWhenEmpty && !itemsSection.cellCount)
            return 0.001;  // zero just uses default height
    }
    
    if(scSection.headerHeight >= 0)
        return scSection.headerHeight;
    
    if(scSection.headerView)
        return scSection.headerView.frame.size.height;
    
    // else return default height
    return -1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    SCTableViewSection *scSection = [self sectionAtIndex:section];
    
    if([scSection isKindOfClass:[SCArrayOfItemsSection class]])
    {
        SCArrayOfItemsSection  *itemsSection = (SCArrayOfItemsSection *)scSection;
        if(itemsSection.hideWhenEmpty && !itemsSection.cellCount)
            return 0.001;  // zero just uses default height
    }
	
    if(scSection.footerHeight >= 0)
        return scSection.footerHeight;
    
    if(scSection.footerView)
        return scSection.footerView.frame.size.height;
    
    // else return default height
    return -1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // End optimization here (at end of delegate cycle)
    [self exitLoadingMode];
    
    
    SCTableViewSection *scSection = [self sectionAtIndex:section];
    
    if([scSection isKindOfClass:[SCArrayOfItemsSection class]])
    {
        SCArrayOfItemsSection  *itemsSection = (SCArrayOfItemsSection *)scSection;
        if(itemsSection.hideWhenEmpty && !itemsSection.cellCount)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }

    return scSection.headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    // End optimization here (at end of delegate cycle)
    [self exitLoadingMode];
    
    
    SCTableViewSection *scSection = [self sectionAtIndex:section];
    
    if([scSection isKindOfClass:[SCArrayOfItemsSection class]])
    {
        SCArrayOfItemsSection  *itemsSection = (SCArrayOfItemsSection *)scSection;
        if(itemsSection.hideWhenEmpty && !itemsSection.cellCount)
            return [[UIView alloc] initWithFrame:CGRectZero];
    }

	return scSection.footerView;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    SCTableViewSection *scSection = [self sectionAtIndex:section];
    
    if(scSection.sectionActions.willDisplayHeaderView)
        scSection.sectionActions.willDisplayHeaderView(scSection, section, view);
    else
        if(self.sectionActions.willDisplayHeaderView)
            self.sectionActions.willDisplayHeaderView(scSection, section, view);
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    SCTableViewSection *scSection = [self sectionAtIndex:section];
    
    if(scSection.sectionActions.willDisplayFooterView)
        scSection.sectionActions.willDisplayFooterView(scSection, section, view);
    else
        if(self.sectionActions.willDisplayFooterView)
            self.sectionActions.willDisplayFooterView(scSection, section, view);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellEditingStyle editingStyle = UITableViewCellEditingStyleNone;
    BOOL customEditingStyle = NO;
    
    SCTableViewCell *cell = [self cellAtIndexPath:indexPath];
    
    if(cell.cellActions.customEditingStyle)
    {
        editingStyle = cell.cellActions.customEditingStyle(cell, indexPath);
        customEditingStyle = YES;
    }
    else
        if(cell.ownerSection.cellActions.customEditingStyle)
        {
            editingStyle = cell.ownerSection.cellActions.customEditingStyle(cell, indexPath);
            customEditingStyle = YES;
        }
        else
            if(cell.ownerTableViewModel.cellActions.customEditingStyle)
            {
                editingStyle = cell.ownerTableViewModel.cellActions.customEditingStyle(cell, indexPath);
                customEditingStyle = YES;
            }
    
    if(!customEditingStyle)
        editingStyle = cell.cellEditingStyle;
    
	return editingStyle;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	SCTableViewCell *scCell = (SCTableViewCell *)cell;
	[scCell willDisplay];
	
	// Check if the cell has an image in its section
	SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
	if([section.cellsImageViews count] > indexPath.row)
	{
		UIImageView *imageView = [section.cellsImageViews objectAtIndex:indexPath.row];
		if([imageView isKindOfClass:[UIImageView class]])
			scCell.imageView.image = imageView.image;
	}
    
    if([section isKindOfClass:[SCSelectionSection class]])
    {
        [(SCSelectionSection *)section configureCellForDisplay:scCell atIndex:indexPath.row];
    }
    else
        if([section isKindOfClass:[SCObjectSelectionSection class]])
        {
            [(SCObjectSelectionSection *)section configureCellForDisplay:scCell atIndex:indexPath.row];
        }
    
	
	if(scCell.cellActions.willDisplay)
	{
		scCell.cellActions.willDisplay(scCell, indexPath);
	}
	else
		if(section.cellActions.willDisplay)
        {
            section.cellActions.willDisplay(scCell, indexPath);
        }
        else
            if(self.cellActions.willDisplay)
            {
                self.cellActions.willDisplay(scCell, indexPath);
            }
    
    
    if(!self.tableView.dragging)
    {
        if(!lastVisibleCellIndexPath)
            lastVisibleCellIndexPath = [[self.tableView indexPathsForVisibleRows] lastObject];
        if(indexPath.section==lastVisibleCellIndexPath.section && indexPath.row==lastVisibleCellIndexPath.row)
        {
            [self exitLoadingMode];
            lastVisibleCellIndexPath = nil;
            
            if(self.modelActions.didFinishLoadingCells)
                self.modelActions.didFinishLoadingCells(self);
        }
    }
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *editActions = nil;
    
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
    SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if(cell.cellActions.editActions)
    {
        editActions = cell.cellActions.editActions(cell, indexPath);
    }
    else
        if(section.cellActions.editActions)
        {
            editActions = section.cellActions.editActions(cell, indexPath);
        }
        else
            if(self.cellActions.editActions)
            {
                editActions = self.cellActions.editActions(cell, indexPath);
            }
    
    return editActions;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if(self.lockCellSelection)
		return nil;
    
    if(self.activeDetailModel)
    {
        [self.activeDetailModel dismissAllDetailViewsWithCommit:YES];
    }
    
	SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
	SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	
	if(!cell.selectable || !cell.enabled)
		return nil;
	
    BOOL allowSelection = YES;
	if(cell.cellActions.willSelect)
	{
		allowSelection = cell.cellActions.willSelect(cell, indexPath);
	}
    else 
    if(section.cellActions.willSelect)
    {
        allowSelection = section.cellActions.willSelect(cell, indexPath);
    }
    else 
        if(self.cellActions.willSelect)
        {
            allowSelection = self.cellActions.willSelect(cell, indexPath);
        }
	
    if(allowSelection)
        return indexPath;
    //else
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if(!cell.enabled)
        return;
    
    if(cell != self.activeCell)
	{
		SCTableViewCell *prevCell = self.activeCell;
		self.activeCell = cell;
        if(![self.activeCell becomeFirstResponder])
            [prevCell resignFirstResponder];
	}
	[self.activeCell didSelectCell];
	
	SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
	
	if(cell.cellActions.didSelect)
	{
		cell.cellActions.didSelect(cell, indexPath);
	}
    else 
    if(section.cellActions.didSelect)
    {
        section.cellActions.didSelect(cell, indexPath);
    }
    else 
        if(self.cellActions.didSelect)
        {
            self.cellActions.didSelect(cell, indexPath);
        }
	else
        if(![self.activeCell isKindOfClass:[SCFetchItemsCell class]] && [section isKindOfClass:[SCArrayOfItemsSection class]])
        {
            [(SCArrayOfItemsSection *)section didSelectCellAtIndexPath:indexPath];
        }
        else
            if([cell.ibDetailViewControllerIdentifier length] && !cell.generatesDetailView)
            {
                UIViewController *detailViewController = [SCUtilities instantiateViewControllerWithIdentifier:cell.ibDetailViewControllerIdentifier usingStoryboard:self.viewController.storyboard];
                
                if(detailViewController)
                    [cell presentDetailViewController:detailViewController forCell:cell forRowAtIndexPath:indexPath withPresentationMode:cell.detailViewControllerOptions.presentationMode];
                else
                    SCDebugLog(@"Warning: Could not instantiate view controller with id '%@' from Storyboard.", cell.ibDetailViewControllerIdentifier);
            }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
    SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    BOOL allowDeselect = YES;
	if(cell.cellActions.willDeselect)
    {
        allowDeselect = cell.cellActions.willDeselect(cell, indexPath);
    }
    else 
        if(section.cellActions.willDeselect)
        {
            allowDeselect = section.cellActions.willDeselect(cell, indexPath);
        }
        else 
            if(self.cellActions.willDeselect)
            {
                allowDeselect = self.cellActions.willDeselect(cell, indexPath);
            }
    
    if(allowDeselect)
    {
        [cell willDeselectCell];
        if([section isKindOfClass:[SCArrayOfItemsSection class]])
            [(SCArrayOfItemsSection *)section willDeselectCellAtIndexPath:indexPath];
        
        return indexPath;
    }
    //else
    return nil;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
	SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	[cell didDeselectCell];
    
    if(cell.cellActions.didDeselect)
	{
        cell.cellActions.didDeselect(cell, indexPath);
	}
    else 
    if(section.cellActions.didDeselect)
    {
        section.cellActions.didDeselect(cell, indexPath);
    }
    else 
        if(self.cellActions.didDeselect)
        {
            self.cellActions.didDeselect(cell, indexPath);
        }
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
    SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    BOOL shouldShowMenu = NO;
    if(cell.cellActions.shouldShowMenu)
    {
        shouldShowMenu = cell.cellActions.shouldShowMenu(cell, indexPath);
    }
    else
        if(section.cellActions.shouldShowMenu)
        {
            shouldShowMenu = section.cellActions.shouldShowMenu(cell, indexPath);
        }
        else
            if(self.cellActions.shouldShowMenu)
            {
                shouldShowMenu = self.cellActions.shouldShowMenu(cell, indexPath);
            }
    
    return shouldShowMenu;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)operationAction forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
    SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    BOOL canPerformAction = NO;
    if(cell.cellActions.canPerformAction)
    {
        canPerformAction = cell.cellActions.canPerformAction(cell, indexPath, operationAction, sender);
    }
    else
        if(section.cellActions.shouldShowMenu)
        {
            canPerformAction = section.cellActions.canPerformAction(cell, indexPath, operationAction, sender);
        }
        else
            if(self.cellActions.shouldShowMenu)
            {
                canPerformAction = self.cellActions.canPerformAction(cell, indexPath, operationAction, sender);
            }
    
    return canPerformAction;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)operationAction forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
    SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    if(cell.cellActions.performAction)
    {
        cell.cellActions.performAction(cell, indexPath, operationAction, sender);
    }
    else
        if(section.cellActions.shouldShowMenu)
        {
            section.cellActions.performAction(cell, indexPath, operationAction, sender);
        }
        else
            if(self.cellActions.shouldShowMenu)
            {
                self.cellActions.performAction(cell, indexPath, operationAction, sender);
            }
}

- (void)tableView:(UITableView *)tableView 
					accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
	SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
	
	if(cell.cellActions.accessoryButtonTapped)
	{
		cell.cellActions.accessoryButtonTapped(cell, indexPath);
	}
    else 
    if(section.cellActions.accessoryButtonTapped)
    {
        section.cellActions.accessoryButtonTapped(cell, indexPath);
    }
    else 
        if(self.cellActions.accessoryButtonTapped)
        {
            self.cellActions.accessoryButtonTapped(cell, indexPath);
        }
	else
		{
			[self tableView:tableView didSelectRowAtIndexPath:indexPath];
		}
}

- (NSString *)tableView:(UITableView *)tableView 
	titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *deleteTitle;
	
	deleteTitle = NSLocalizedString(@"Delete", @"Delete Button Title");
	
	return deleteTitle;
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    swipeToDeleteActive = TRUE;
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    swipeToDeleteActive = FALSE;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView cellForRowAtIndexPath:indexPath].shouldIndentWhileEditing;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    NSIndexPath *indexPath = proposedDestinationIndexPath;
    
    SCTableViewSection *section = [self sectionAtIndex:sourceIndexPath.section];
    if([section isKindOfClass:[SCArrayOfItemsSection class]])
        indexPath = [(SCArrayOfItemsSection *)section targetIndexPathForMoveFromCellAtIndexPath:sourceIndexPath toProposedIndexPath:proposedDestinationIndexPath];
    
    return indexPath;
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self clearLastReturnedCellData];
    
    if(self.activeCell)
    {
        [self.activeCell resignFirstResponder];
        [self.tableView deselectRowAtIndexPath:self.activeCellIndexPath animated:YES];
        self.activeCell = nil;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(self.modelActions.didScroll)
        self.modelActions.didScroll(self);
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
   if (!decelerate)
	{
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for(NSIndexPath *indexPath in visiblePaths)
        {
            SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
            SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            
            if(cell.cellActions.lazyLoad)
            {
                cell.cellActions.lazyLoad(cell, indexPath);
            }
            else
                if(section.cellActions.lazyLoad)
                {
                    section.cellActions.lazyLoad(cell, indexPath);
                }
                else
                    if(self.cellActions.lazyLoad)
                    {
                        self.cellActions.lazyLoad(cell, indexPath);
                    }
        }
    }
    
    if(self.modelActions.didEndDragging)
        self.modelActions.didEndDragging(self);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self clearLastReturnedCellData];
    
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for(NSIndexPath *indexPath in visiblePaths)
    {
        SCTableViewSection *section = [self sectionAtIndex:indexPath.section];
        SCTableViewCell *cell = (SCTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        if(cell.cellActions.lazyLoad)
        {
            cell.cellActions.lazyLoad(cell, indexPath);
        }
        else
            if(section.cellActions.lazyLoad)
            {
                section.cellActions.lazyLoad(cell, indexPath);
            }
            else
                if(self.cellActions.lazyLoad)
                {
                    self.cellActions.lazyLoad(cell, indexPath);
                }
    }
    
    if(self.modelActions.didEndDecelerating)
        self.modelActions.didEndDecelerating(self);
}

#pragma mark -
#pragma SCInputAccessoryViewDelegate methods

- (void)inputAccessoryViewPreviousTapped:(SCInputAccessoryView *)inputAccessoryView
{
    [self moveToPreviousCellControl:inputAccessoryView.rewind];
}

- (void)inputAccessoryViewNextTapped:(SCInputAccessoryView *)inputAccessoryView
{
    [self moveToNextCellControl:inputAccessoryView.rewind];
}

- (void)inputAccessoryViewClearTapped:(SCInputAccessoryView *)inputAccessoryView
{
    if([self.activeCell isKindOfClass:[SCControlCell class]])
    {
        [(SCControlCell *)self.activeCell clearControl];
    }
    else 
        if(self.activeCellControl)
        {
            if([self.activeCellControl respondsToSelector:@selector(setText:)])
            {
                [self.activeCellControl performSelector:@selector(setText:) withObject:nil];
            }
        }
}

- (void)inputAccessoryViewDoneTapped:(SCInputAccessoryView *)inputAccessoryView
{
    if(self.activeCellControl)
        [self.activeCellControl resignFirstResponder];
    else 
        [self.activeCell resignFirstResponder];
    
    self.activeCell = nil;
}


#pragma mark -
#pragma mark Keyboard methods

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    if(!self.autoResizeForKeyboard || keyboardShown) 
		return;
	
	keyboardShown = YES;
	
    // Get the keyboard size
    UIScrollView *tableView;
    if([self.tableView.superview isKindOfClass:[UIScrollView class]])
        tableView = (UIScrollView *)self.tableView.superview;
    else
        tableView = self.tableView;
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    // Get the keyboard's animation details
    NSTimeInterval animationDuration;
	[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
	UIViewAnimationCurve animationCurve;
	[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
	
	// Determine how much overlap exists between tableView and the keyboard
    CGRect tableFrame = tableView.frame;
    CGFloat tableLowerYCoord = tableFrame.origin.y + tableFrame.size.height;
	keyboardOverlap = tableLowerYCoord - keyboardRect.origin.y;
	if(self.inputAccessoryView && keyboardOverlap>0)
    {
        CGFloat accessoryHeight = self.inputAccessoryView.frame.size.height;
        keyboardOverlap -= accessoryHeight;
        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
    }
    
	if(keyboardOverlap < 0)
		keyboardOverlap = 0;
	
	if(keyboardOverlap != 0)
	{
		tableFrame.size.height -= keyboardOverlap;
		
		NSTimeInterval delay = 0;
		if(keyboardRect.size.height)
		{
			delay = (1 - keyboardOverlap/keyboardRect.size.height)*animationDuration;
			animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
		}
		
        [UIView animateWithDuration:animationDuration delay:delay 
							options:UIViewAnimationOptionBeginFromCurrentState 
						 animations:^{ tableView.frame = tableFrame; } 
						 completion:^(BOOL finished){ [self tableAnimationEnded:nil finished:nil contextInfo:nil]; }];
	}
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
	if(!self.autoResizeForKeyboard || !keyboardShown)
		return;
	
	keyboardShown = NO;
    
    UIScrollView *tableView;
    if([self.tableView.superview isKindOfClass:[UIScrollView class]])
        tableView = (UIScrollView *)self.tableView.superview;
    else
        tableView = self.tableView;
    if(self.inputAccessoryView)
    {
        tableView.contentInset = UIEdgeInsetsZero;
        tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
	
	if(keyboardOverlap == 0)
		return;
    
	// Get the size & animation details of the keyboard
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
	
    NSTimeInterval animationDuration;
	[[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
	UIViewAnimationCurve animationCurve;
	[[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
	
	CGRect tableFrame = tableView.frame; 
	tableFrame.size.height += keyboardOverlap;
	
	if(keyboardRect.size.height)
		animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
	
    [UIView animateWithDuration:animationDuration delay:0 
						options:UIViewAnimationOptionBeginFromCurrentState 
					 animations:^{ tableView.frame = tableFrame; } 
					 completion:nil];
}

- (void) tableAnimationEnded:(NSString*)animationID finished:(NSNumber *)finished contextInfo:(void *)context
{
	// Scroll to the active cell
	if(self.activeCell)
	{
		[self.tableView scrollToRowAtIndexPath:self.activeCellIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
        [self.tableView selectRowAtIndexPath:self.activeCellIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
}


@end







@interface SCArrayOfItemsModel ()
{
    NSMutableDictionary *_sectionsCellIdentifiers;
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_8_0
// We're creating that here since it was disabled in the header file
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@property (nonatomic, strong) UISearchDisplayController *searchDisplayController;
#pragma clang diagnostic pop
#endif

- (void)generateSections;
- (NSArray *)getSectionHeaderTitles;
- (NSString *)getHeaderTitleForItemAtIndex:(NSUInteger)index;

- (void)addNewItemToRespectiveSection:(NSObject *)newItem;

- (NSString *)safeSearchStringFromString:(NSString *)searchString;

@end



@implementation SCArrayOfItemsModel

@synthesize dataStore;
@synthesize dataFetchOptions;
@synthesize autoFetchItems;
@synthesize itemsAccessoryType;
@synthesize allowAddingItems;
@synthesize allowDeletingItems;
@synthesize allowMovingItems;
@synthesize allowEditDetailView;
@synthesize allowRowSelection;
@synthesize autoSelectNewItemCell;
@synthesize addButtonItem;
@synthesize searchBar;


- (instancetype)init
{
	if( (self=[super init]) )
	{
		tempSection = nil;
        
		dataStore = nil;
        dataFetchOptions = nil;  // will be re-initialized when dataStore is set
        
        _loadingContents = FALSE;
        sectionsInSync = FALSE;
        items = nil;
        autoFetchItems = TRUE;
        itemsInSync = FALSE;
		itemsAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
		allowAddingItems = TRUE;
		allowDeletingItems = TRUE;
		allowMovingItems = FALSE;
		allowEditDetailView = TRUE;
		allowRowSelection = TRUE;
		autoSelectNewItemCell = FALSE;
		addButtonItem = nil;
		
		filteredArray = nil;
		searchBar = nil;
        _enableSearchController = FALSE;
        _searchDisplayController = nil;
        
        detailViewControllerOptions = nil;
        newItemDetailViewControllerOptions = nil;
        
        _sectionsCellIdentifiers = [NSMutableDictionary dictionary];
	}
	
	return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView dataStore:(SCDataStore *)store
{
	if( (self=[self initWithTableView:tableView]) )
	{
		self.dataStore = store;
	}
	return self;
}


// overrides superclass
- (UITableView *)tableView
{
    if(self.searchController && self.searchController.active && [self.searchController.searchResultsController isKindOfClass:[UITableViewController class]])
        return [(UITableViewController *)self.searchController.searchResultsController tableView];
    //else
    if(self.searchDisplayController.active)
        return self.searchDisplayController.searchResultsTableView;
    //else
    return [super tableView];
}


- (void)setDataStore:(SCDataStore *)__dataStore
{
    dataStore =  __dataStore;
    
    if(!dataFetchOptions)
        dataFetchOptions = [__dataStore.defaultDataDefinition generateCompatibleDataFetchOptions];
    
    itemsInSync = FALSE;
    sectionsInSync = FALSE;
}

- (void)setDataFetchOptions:(SCDataFetchOptions *)options
{
    dataFetchOptions = options;
    
    if(!options.sortKey && self.dataStore)
    {
        options.sortKey = self.dataStore.defaultDataDefinition.keyPropertyName;
    }
    
    itemsInSync = FALSE;
    sectionsInSync = FALSE;
}

- (SCDetailViewControllerOptions *)detailViewControllerOptions
{
    // Conserve resources by lazy loading for only models that need it
    if(!detailViewControllerOptions)
        detailViewControllerOptions = [[SCDetailViewControllerOptions alloc] init];
    
    return detailViewControllerOptions;
}

- (void)setDetailViewControllerOptions:(SCDetailViewControllerOptions *)options
{
    detailViewControllerOptions = options;
}

- (SCDetailViewControllerOptions *)newItemDetailViewControllerOptions
{
    // Conserve resources by lazy loading for only models that need it
    if(!newItemDetailViewControllerOptions)
        newItemDetailViewControllerOptions = [[SCDetailViewControllerOptions alloc] init];
    
    return newItemDetailViewControllerOptions;
}

- (void)setNewItemDetailViewControllerOptions:(SCDetailViewControllerOptions *)options
{
    newItemDetailViewControllerOptions = options;
}


- (NSArray *)items
{
   if(!itemsInSync && self.autoFetchItems)
    {
        switch (self.dataStore.storeMode)
        {
            case SCStoreModeSynchronous:
                items = [[NSMutableArray alloc] initWithArray:[self.dataStore fetchObjectsWithOptions:self.dataFetchOptions]];
                itemsInSync = TRUE;
                sectionsInSync = FALSE;
                
                if(self.modelActions.didFetchItemsFromStore)
                    self.modelActions.didFetchItemsFromStore(self, items);
                break;
                
            case SCStoreModeAsynchronous:
                itemsInSync = TRUE;
                SCFetchItemsCell *fetchItemsCell = [SCFetchItemsCell cell];
                [fetchItemsCell startActivityIndicator];
                items = [NSMutableArray arrayWithObject:fetchItemsCell];
                
                _loadingContents = TRUE;
                [self.dataStore asynchronousFetchObjectsWithOptions:self.dataFetchOptions
                success:^(NSArray *results)
                     {
                         _loadingContents = FALSE;
                         
                         items = [NSMutableArray arrayWithArray:results];
                         sectionsInSync = FALSE;
                         [self.tableView reloadData];
                     }
                failure:^(NSError *error)
                     {
                         _loadingContents = FALSE;
                     }
                 noConnection:^BOOL()
                    {
                        return NO;
                    }
                 ];
                break;
        }
    }
    
    return items;
}

- (NSMutableArray *)mutableItems
{
    return items;
}

- (void)setMutableItems:(NSMutableArray *)mutableItems
{
    items = mutableItems;
}

//override superclass
- (void)reloadBoundValues
{
    [self clearLastReturnedCellData];
    itemsInSync = FALSE;
    sectionsInSync = FALSE;
    
	if(filteredArray)
    {
        [self searchBar:self.searchBar textDidChange:self.searchBar.text];
    }
    else
    {
        [self generateSections];
    }
}

- (void)generateSections
{
	[self removeAllSections];
	
	NSArray *itemsArray;
	if(filteredArray)
		itemsArray = filteredArray;
	else
		itemsArray = self.items;
	
    NSArray *sectionHeaderTitles = [self getSectionHeaderTitles];
    for(NSString *sectionHeaderTitle in sectionHeaderTitles)
    {
        SCArrayOfItemsSection *section = [self createSectionWithHeaderTitle:sectionHeaderTitle];
        [self setPropertiesForSection:section];
        [self addSection:section];
    }
    
    for(NSUInteger i=0; i<itemsArray.count; i++)
	{
		NSString *headerTitle = [self getHeaderTitleForItemAtIndex:i];
		SCArrayOfItemsSection *section = (SCArrayOfItemsSection *)[self sectionWithHeaderTitle:headerTitle];
		if(!section)
		{
			section = [self createSectionWithHeaderTitle:headerTitle];
			if(!section)
				continue;
            
            // set the section's cellIdentifier to a unique string
            NSString *stringIndex = [NSString stringWithFormat:@"%lu", (unsigned long)i];
            NSString *sectionCellId = [_sectionsCellIdentifiers valueForKey:stringIndex];
            if(!sectionCellId)
            {
                sectionCellId = [[[NSUUID UUID] UUIDString] copy];
                [_sectionsCellIdentifiers setValue:sectionCellId forKey:stringIndex];
            }
            section.cellIdentifier = sectionCellId;
            
			[self setPropertiesForSection:section];
			[self addSection:section];
		}
		[[section mutableItems] addObject:[itemsArray objectAtIndex:i]];
	}
    
    for(SCArrayOfItemsSection *section in sections)
    {
        NSMutableArray *mutableItems = [section mutableItems];
        
        [section.dataFetchOptions sortMutableArray:mutableItems];
                
        if(section.sectionActions.didFetchItemsFromStore)
            section.sectionActions.didFetchItemsFromStore(section, mutableItems);
        else
            if(self.sectionActions.didFetchItemsFromStore)
                self.sectionActions.didFetchItemsFromStore(section, mutableItems);
    }
    
    sectionsInSync = TRUE;
}

- (NSArray *)getSectionHeaderTitles
{
    NSArray *sectionHeaderTitles = nil;
    if(self.modelActions.sectionHeaderTitles)
        sectionHeaderTitles = self.modelActions.sectionHeaderTitles(self);
    
    return sectionHeaderTitles;
}

- (NSString *)getHeaderTitleForItemAtIndex:(NSUInteger)index
{
	NSArray *itemsArray;
	if(filteredArray)
		itemsArray = filteredArray;
	else
		itemsArray = self.items;
	
    NSObject *item = [itemsArray objectAtIndex:index];
    
    if([item isKindOfClass:[SCFetchItemsCell class]])
        return nil;
    
	NSString *headerTitleName = nil;
    if(self.modelActions.sectionHeaderTitleForItem)
    {
        headerTitleName = self.modelActions.sectionHeaderTitleForItem(self, item, index);
    }
	
	return headerTitleName;
}

- (NSUInteger)getSectionIndexForItem:(NSObject *)item
{
    NSArray *itemsArray;
	if(filteredArray)
		itemsArray = filteredArray;
	else
		itemsArray = self.items;
    
	NSUInteger itemIndex = [itemsArray indexOfObjectIdenticalTo:item];
	NSString *sectionHeader = [self getHeaderTitleForItemAtIndex:itemIndex];
	
    if(!sectionHeader)
        return 0;
	
	NSUInteger sectionIndex = NSNotFound;
	for(NSUInteger i=0; i<self.sectionCount; i++)
		if([[self sectionAtIndex:i].headerTitle isEqualToString:sectionHeader])
		   {
			   sectionIndex = i;
			   break;
		   }
	 
	return sectionIndex;
}

- (SCArrayOfItemsSection *)createSectionWithHeaderTitle:(NSString *)title
{
	SCArrayOfObjectsSection *section = [SCArrayOfObjectsSection sectionWithHeaderTitle:title dataStore:self.dataStore];
    section.autoFetchItems = FALSE;
    [section setMutableItems:[NSMutableArray array]];
    
    return section;
}

- (void)setSearchBar:(UISearchBar *)sbar
{
	searchBar = sbar;
    if(!self.searchController)
        searchBar.delegate = self;
    
    if(_searchDisplayController && [SCUtilities systemVersion] < 8.0)
    {
        // reinitialize _searchDisplayController to include the searchBar
        [self initDisplayController];
    }
}

- (void)setEnableSearchController:(BOOL)enable
{
    _enableSearchController = enable;
    
    if(enable)
    {
        if([SCUtilities systemVersion] >= 8.0)
        {
            if(!_searchController)
                [self initDisplayController];
        }
        else
        {
            if(!_searchDisplayController)
                [self initDisplayController];
        }
    }
    else
    {
        if(_searchController)
            self.searchBar = nil;
        
        _searchController = nil;
        _searchDisplayController = nil;
    }
}

- (void)initDisplayController
{
    if([SCUtilities systemVersion] >= 8.0)
    {
        SCTableViewController *resultsViewController = [[SCTableViewController alloc] initWithStyle:self.tableView.style];
        resultsViewController.edgesForExtendedLayout = UIRectEdgeNone;
        resultsViewController.tableView.dataSource = self;
        resultsViewController.tableView.delegate = self;
        _searchController = [[UISearchController alloc] initWithSearchResultsController:resultsViewController];
        _searchController.searchResultsUpdater = self;
        [_searchController.searchBar sizeToFit];
        self.trueTableView.tableHeaderView = _searchController.searchBar;
        
        // We need this set to yes since viewController's navigation controller will be the one pushing resultsViewController detail views on its stack
        self.viewController.definesPresentationContext = YES;
    }
    else
    {
        if(!self.searchBar)
        {
            self.searchBar = [[UISearchBar alloc] init];
            [self.searchBar sizeToFit];
            self.tableView.tableHeaderView = self.searchBar;
        }
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        _searchDisplayController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self.viewController];
#pragma clang diagnostic pop
        _searchDisplayController.searchResultsDataSource = self;
        _searchDisplayController.searchResultsDelegate = self;
    }
}

- (void)setPropertiesForSection:(SCArrayOfItemsSection *)section
{
    section.dataFetchOptions = self.dataFetchOptions;
    
    section.itemsAccessoryType = self.itemsAccessoryType;
	section.allowAddingItems = self.allowAddingItems;
	section.allowDeletingItems = self.allowDeletingItems;
	section.allowMovingItems = self.allowMovingItems;
	section.allowEditDetailView = self.allowEditDetailView;
	section.allowRowSelection = self.allowRowSelection;
	section.autoSelectNewItemCell = self.autoSelectNewItemCell;
    section.addButtonItem = self.addButtonItem;
	
    section.ibNewItemViewControllerIdentifier = self.ibNewItemViewControllerIdentifier;
    [section setDetailViewControllerOptions:self.detailViewControllerOptions];
    [section setNewItemDetailViewControllerOptions:self.newItemDetailViewControllerOptions];
}

- (void)configureUsingSection:(SCArrayOfItemsSection *)section
{
    if(section.dataStore)
        self.dataStore = section.dataStore;
    self.dataFetchOptions = section.dataFetchOptions;
    
    self.itemsAccessoryType = section.itemsAccessoryType;
    self.allowAddingItems = section.allowAddingItems;
    self.allowDeletingItems = section.allowDeletingItems;
    self.allowMovingItems = section.allowMovingItems;
    self.allowEditDetailView = section.allowEditDetailView;
    self.allowRowSelection = section.allowRowSelection;
    self.autoSelectNewItemCell = section.autoSelectNewItemCell;
    self.addButtonItem = section.addButtonItem;
    
    self.ibNewItemViewControllerIdentifier = section.ibNewItemViewControllerIdentifier;
    [self setDetailViewControllerOptions:section.detailViewControllerOptions];
    [self setNewItemDetailViewControllerOptions:section.newItemDetailViewControllerOptions];
    
    self.sectionActions.cellForRowAtIndexPath = section.sectionActions.cellForRowAtIndexPath;
}

// override superclass
- (void)setItemsAccessoryType:(UITableViewCellAccessoryType)type
{
	itemsAccessoryType = type;
	for(NSUInteger i=0; i<self.sectionCount; i++)
		((SCArrayOfItemsSection *)[self sectionAtIndex:i]).itemsAccessoryType = type;
}

// override superclass
- (void)setAllowAddingItems:(BOOL)allow
{
	allowAddingItems = allow;
	for(NSUInteger i=0; i<self.sectionCount; i++)
		((SCArrayOfItemsSection *)[self sectionAtIndex:i]).allowAddingItems = allow;
}

// override superclass
- (void)setAllowDeletingItems:(BOOL)allow
{
	allowDeletingItems = allow;
	for(NSUInteger i=0; i<self.sectionCount; i++)
		((SCArrayOfItemsSection *)[self sectionAtIndex:i]).allowDeletingItems = allow;
}

// override superclass
- (void)setAllowMovingItems:(BOOL)allow
{
	allowMovingItems = allow;
	for(NSUInteger i=0; i<self.sectionCount; i++)
		((SCArrayOfItemsSection *)[self sectionAtIndex:i]).allowMovingItems = allow;
}

// override superclass
- (void)setAllowEditDetailView:(BOOL)allow
{
	allowEditDetailView = allow;
	for(NSUInteger i=0; i<self.sectionCount; i++)
		((SCArrayOfItemsSection *)[self sectionAtIndex:i]).allowEditDetailView = allow;
}

// override superclass
- (void)setAllowRowSelection:(BOOL)allow
{
	allowRowSelection = allow;
	for(NSUInteger i=0; i<self.sectionCount; i++)
		((SCArrayOfItemsSection *)[self sectionAtIndex:i]).allowRowSelection = allow;
}

// override superclass
- (void)setAutoSelectNewItemCell:(BOOL)allow
{
	autoSelectNewItemCell = allow;
	for(NSUInteger i=0; i<self.sectionCount; i++)
		((SCArrayOfItemsSection *)[self sectionAtIndex:i]).autoSelectNewItemCell = allow;
}

- (void)setAddButtonItem:(UIBarButtonItem *)barButtonItem
{
	addButtonItem = barButtonItem;
	
	addButtonItem.target = self;
	addButtonItem.action = @selector(didTapAddButtonItem);
}

- (void)didTapAddButtonItem
{
    if(self.allowAddingItems)
        [self dispatchEventAddNewItem];
}

- (void)dispatchEventAddNewItem
{
    if(_loadingContents)
        return;
    
    // Game plan: delegate presenting the add detail view to SCArrayOfItemsSection
	
	//cancel any search in progress
	if([self.searchBar.text length])
		self.searchBar.text = nil;
	
	SCArrayOfItemsSection *section;
	if(self.sectionCount)
	{
		section = (SCArrayOfItemsSection *)[self sectionAtIndex:0];
	}
	else
	{
		if(!tempSection)
		{
			tempSection = [self createSectionWithHeaderTitle:nil];
			tempSection.ownerTableViewModel = self;
			[self setPropertiesForSection:tempSection];
		}
		section = tempSection;
	}
	
	[section dispatchEventAddNewItem];
}

- (void)dispatchEventSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [(SCArrayOfItemsSection *)[self sectionAtIndex:indexPath.section] dispatchEventSelectRowAtIndexPath:indexPath];
}

- (void)dispatchEventRemoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    [(SCArrayOfItemsSection *)[self sectionAtIndex:indexPath.section] dispatchEventRemoveRowAtIndexPath:indexPath];
}

- (void)addNewItem:(NSObject *)newItem
{
    switch (self.dataStore.storeMode)
    {
        case SCStoreModeSynchronous:
            [self.dataStore insertObject:newItem];
            
            [items addObject:newItem];
            [self addNewItemToRespectiveSection:newItem];
            break;
            
        case SCStoreModeAsynchronous:
            [self.dataStore asynchronousInsertObject:newItem
                    success:^()
                    {
                        [items addObject:newItem];
                        [self addNewItemToRespectiveSection:newItem];
                    }
                    failure:^(NSError *error)
                    {
                    }
                    noConnection:^BOOL()
                    {
                        return NO;
                    }
             ];
            break;
    }
}

- (void)addNewItemToRespectiveSection:(NSObject *)newItem
{
    NSUInteger itemIndex = [self.items indexOfObjectIdenticalTo:newItem];
	
	NSString *headerTitle = [self getHeaderTitleForItemAtIndex:itemIndex];
	SCArrayOfItemsSection *section = (SCArrayOfItemsSection *)[self sectionWithHeaderTitle:headerTitle];
	if(!section)
	{
		// Add new section
		section = [self createSectionWithHeaderTitle:headerTitle];
		[self setPropertiesForSection:section];
		[self addSection:section];
		NSUInteger sectionIndex = [self indexForSection:section];
		
		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] 
							 withRowAnimation:UITableViewRowAnimationLeft];
		if(self.autoGenerateSectionIndexTitles)
		{
			[self.tableView reloadData]; // reloadSectionIndexTitles not working!
		}
	}
	
    [[section mutableItems] addObject:newItem];
    if(section.dataFetchOptions.sort)
        [section.dataFetchOptions sortMutableArray:[section mutableItems]];
	[section addCellForNewItem:newItem];
}

- (void)itemModified:(NSObject *)item inSection:(SCArrayOfItemsSection *)section
{
    [self clearLastReturnedCellData];
    
	NSUInteger oldSectionIndex = [self indexForSection:section];
	NSUInteger newSectionIndex = [self getSectionIndexForItem:item];
	
	if(oldSectionIndex == newSectionIndex)
	{
		[section itemModified:item];
	}
	else
	{
        if(filteredArray)
        {
            // re-evaluate filter and refresh table view
            [self searchBar:self.searchBar textDidChange:self.searchBar.text];
        }
        else
        {
            // remove item from old section
            NSIndexPath *oldIndexPath =
            [NSIndexPath indexPathForRow:[[section mutableItems] indexOfObjectIdenticalTo:item]
                               inSection:oldSectionIndex];
            [[section mutableItems] removeObjectAtIndex:oldIndexPath.row];
            section.selectedCellIndexPath = nil;
            NSArray *sectionHeaderTitles = [self getSectionHeaderTitles];
            if( [section mutableItems].count || (sectionHeaderTitles && [sectionHeaderTitles indexOfObject:section.headerTitle]!=NSNotFound) )
            {
                self.activeCell = nil;
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:oldIndexPath] withRowAnimation:UITableViewRowAnimationRight];
            }
            else
            {
                // Remove the empty section
                
                // Connect the addButton back to the model's target & action
                if(section.addButtonItem)
                    self.addButtonItem = section.addButtonItem;
                section.addButtonItem = nil;
                
                self.activeCell.ownerSection = nil;
                self.activeCell = nil;
                [self removeSectionAtIndex:oldSectionIndex];
                section.ownerTableViewModel = nil;
                
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:oldSectionIndex]
                              withRowAnimation:UITableViewRowAnimationRight];
            }
            
            // add to respective section
            [self addNewItemToRespectiveSection:item];
        }
	}
}

- (void)itemRemoved:(NSObject *)item inSection:(SCArrayOfItemsSection *)section
{
    [(NSMutableArray *)self.items removeObjectIdenticalTo:item];
}

- (void)invalidateItems
{
    itemsInSync = FALSE;
    sectionsInSync = FALSE;
}


// Overrides superclass
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(!sectionsInSync)
        [self generateSections];
    
    return [super numberOfSectionsInTableView:tableView];
}

// Overrides superclass
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
	forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self clearLastReturnedCellData];
    
	SCArrayOfItemsSection *section = (SCArrayOfItemsSection *)[self sectionAtIndex:indexPath.section];
    
    // Have the respective section remove the item
	[super tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
	
	// Remove the section if empty
	NSArray *sectionHeaderTitles = [self getSectionHeaderTitles];
    if(![section mutableItems].count && (!sectionHeaderTitles || [sectionHeaderTitles indexOfObject:section.headerTitle]==NSNotFound) )
	{
		[self removeSectionAtIndex:indexPath.section];
		[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]
							 withRowAnimation:UITableViewRowAnimationRight];
		if(self.autoGenerateSectionIndexTitles)
		{
			[self.tableView reloadData]; // reloadSectionIndexTitles not working!
		}
	}
}


- (NSString *)safeSearchStringFromString:(NSString *)searchString
{
    NSString *safeSearchString = [searchString stringByReplacingOccurrencesOfString:@"'" withString:@""];
    safeSearchString = [safeSearchString stringByReplacingOccurrencesOfString:@"\\" withString:@""]; // don't allow escape characters
    
    return safeSearchString;
}


#pragma mark -
#pragma mark UISearchBarDelegate methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    if(self.lockCellSelection)
        return FALSE;
    
    if(self.activeDetailModel)
    {
        [self.activeDetailModel dismissAllDetailViewsWithCommit:YES];
    }
    
    BOOL shouldBegin = TRUE;
    
    if(shouldBegin)
        [SCModelCenter sharedModelCenter].keyboardIssuer = self.viewController;
        
    return shouldBegin;
}

- (void)searchBar:(UISearchBar *)sBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
	
}

- (void)searchBarBookmarkButtonClicked:(UISearchBar *)sBar
{
	
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)sBar
{
	[self.searchBar resignFirstResponder];
	self.searchBar.text = nil;
	
	filteredArray = nil;
    self.addButtonItem.enabled = TRUE;
	
    sectionsInSync = FALSE;
	[self.tableView reloadData];
}

- (void)searchBarResultsListButtonClicked:(UISearchBar *)sBar
{
	
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)sBar
{
	
}


#pragma mark - UISearchResultsUpdating Methods

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    // Call the correspoding searchBar delegate
    [self searchBar:searchController.searchBar textDidChange:searchController.searchBar.text];
}

@end










@implementation SCArrayOfObjectsModel

@synthesize searchPropertyName;


+ (instancetype)modelWithTableView:(UITableView *)tableView
                            items:(NSMutableArray *)items
                  itemsDefinition:(SCDataDefinition *)definition
{
	return [[[self class] alloc] initWithTableView:tableView items:items itemsDefinition:definition];
}


- (instancetype)init
{
	if( (self=[super init]) )
	{
		searchPropertyName = nil;
	}
	
	return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView
                  items:(NSMutableArray *)__items
        itemsDefinition:(SCDataDefinition *)definition
{
    SCArrayStore *store = [SCArrayStore storeWithObjectsArray:__items defaultDefiniton:definition];
    
	self = [self initWithTableView:tableView dataStore:store];
    
	return self;
}




#pragma mark -
#pragma mark UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)sbar textDidChange:(NSString *)searchText
{
	NSArray *resultsArray = nil;
    
	if([sbar.text length] && self.items.count)
	{
        NSString *safeSearchString = [self safeSearchStringFromString:sbar.text];
        
		SCDataDefinition *objDef = [self.dataStore definitionForObject:[self.items objectAtIndex:0]]; // any object
		if(!self.searchPropertyName)
			self.searchPropertyName = objDef.titlePropertyName;
		
		NSArray *searchProperties;
		if([self.searchPropertyName isEqualToString:@"*"])
		{
			searchProperties = [NSMutableArray arrayWithCapacity:objDef.propertyDefinitionCount];
			for(NSUInteger i=0; i<objDef.propertyDefinitionCount; i++)
				[(NSMutableArray *)searchProperties addObject:[objDef propertyDefinitionAtIndex:i].name];
		}
		else
		{
			searchProperties = [self.searchPropertyName componentsSeparatedByString:@";"];
		}

		NSMutableString *predicateFormat = [NSMutableString string];
		for(NSUInteger i=0; i<searchProperties.count; i++)
		{
			NSString *property = [searchProperties objectAtIndex:i];
			if(i==0)
				[predicateFormat appendFormat:@"%@ contains[cd] '%@'", property, safeSearchString];
			else
				[predicateFormat appendFormat:@" OR %@ contains[cd] '%@'", property, safeSearchString];
		}
		NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
		
		@try 
		{
			resultsArray = [self.items filteredArrayUsingPredicate:predicate];
		}
		@catch (NSException * e) 
		{
			// handle any unexpected property-name behavior gracefully
			resultsArray = [NSArray array]; //empty array
            
            SCDebugLog(@"Warning: Invalid search predicate: %@.", predicate);
		}
		
		// Check for custom results
		NSArray *customResultsArray = nil;
        if(self.modelActions.didComputeSearchResults)
            customResultsArray = self.modelActions.didComputeSearchResults(self, searchText, resultsArray);
        if(customResultsArray)
            resultsArray = customResultsArray;
	}
	
	filteredArray = resultsArray;
    self.addButtonItem.enabled = !filteredArray;
	
    sectionsInSync = FALSE;
    
    [self.tableView reloadData];  // self.tableView automatically returns the correct tableView in case a UISearchController is action
}

@end







@implementation SCArrayOfStringsModel

+ (instancetype)modelWithTableView:(UITableView *)tableView items:(NSMutableArray *)items
{
    return [[[self class] alloc] initWithTableView:tableView items:items];
}


- (instancetype)initWithTableView:(UITableView *)tableView items:(NSMutableArray *)__items
{
    SCArrayStore *stringsArrayStore = [SCArrayStore storeWithObjectsArray:__items defaultDefiniton:[SCStringDefinition definition]];
    
    self = [self initWithTableView:tableView dataStore:stringsArrayStore];
    
    return self;
}

#pragma mark -
#pragma mark UISearchBarDelegate methods

- (void)searchBar:(UISearchBar *)sbar textDidChange:(NSString *)searchText
{
	NSArray *resultsArray = nil;
	
	if([sbar.text length])
	{
        NSString *safeSearchString = [self safeSearchStringFromString:sbar.text];
        
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[cd] %@", safeSearchString];
		resultsArray = [self.items filteredArrayUsingPredicate:predicate];
		
		// Check for custom results
        NSArray *customResultsArray = nil;
        if(self.modelActions.didComputeSearchResults)
            customResultsArray = self.modelActions.didComputeSearchResults(self, searchText, resultsArray);
        if(customResultsArray)
            resultsArray = customResultsArray;
	}
    
	filteredArray = resultsArray;
    self.addButtonItem.enabled = !filteredArray;
	
    sectionsInSync = FALSE;
	
    [self.tableView reloadData];  // self.tableView automatically returns the correct tableView in case a UISearchController is action
}

@end













@interface SCSelectionModel ()

- (NSUInteger)itemIndexForCell:(SCTableViewCell *)cell;
- (NSUInteger)itemIndexForCellAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForItemIndex:(NSInteger)itemIndex;
- (void)buildSelectedItemsIndexesFromString:(NSString *)string;
- (NSString *)buildStringFromSelectedItemsIndexes;

- (void)deselectLastSelectedRow;
- (void)dismissViewController;

@end



@implementation SCSelectionModel

@synthesize boundObject;
@synthesize boundObjectStore;
@synthesize boundPropertyName;
@synthesize allowMultipleSelection;
@synthesize allowNoSelection;
@synthesize maximumSelections;
@synthesize autoDismissViewController;


- (instancetype)init
{
	if( (self=[super init]) )
	{
        boundObject = nil;
        boundObjectStore = nil;
		boundPropertyName = nil;
        
		boundToNSNumber = FALSE;
		boundToNSString = FALSE;
		lastSelectedRowIndexPath = nil;
		allowAddingItems = FALSE;
		allowDeletingItems = FALSE;
		allowMovingItems = FALSE;
		allowEditDetailView = FALSE;
		
		allowMultipleSelection = FALSE;
		allowNoSelection = FALSE;
		maximumSelections = 0;
		autoDismissViewController = FALSE;
		_selectedItemsIndexes = [[NSMutableSet alloc] init];
	}
	
	return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView
            boundObject:(NSObject *)object 
    selectedIndexPropertyName:(NSString *)propertyName 
                  items:(NSArray *)sectionItems
{
	if( (self = [self initWithTableView:tableView items:[NSMutableArray arrayWithArray:sectionItems]]) )
	{
		boundObject = object;
		
		// Only bind property name if property exists
		if([SCUtilities propertyName:propertyName existsInObject:self.boundObject])
			boundPropertyName = [propertyName copy];
		
		boundToNSNumber = TRUE;
		allowMultipleSelection = FALSE;
		
		[self reloadBoundValues];
	}
	return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView
            boundObject:(NSObject *)object 
    selectedIndexesPropertyName:(NSString *)propertyName 
                  items:(NSArray *)sectionItems 
 allowMultipleSelection:(BOOL)multipleSelection
{
	if( (self = [self initWithTableView:tableView items:[NSMutableArray arrayWithArray:sectionItems]]) )
	{
		boundObject = object;
		
		// Only bind property name if property exists
		if([SCUtilities propertyName:propertyName existsInObject:self.boundObject])
			boundPropertyName = [propertyName copy];
		
		allowMultipleSelection = multipleSelection;
		
		[self reloadBoundValues];
	}
	return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView
            boundObject:(NSObject *)object 
    selectionStringPropertyName:(NSString *)propertyName 
                  items:(NSArray *)sectionItems
{
	if( (self = [self initWithTableView:tableView items:[NSMutableArray arrayWithArray:sectionItems]]) )
	{
		boundObject = object;
		
		// Only bind property name if property exists
		if([SCUtilities propertyName:propertyName existsInObject:self.boundObject])
			boundPropertyName = [propertyName copy];
		
		boundToNSString = TRUE;
		
		[self reloadBoundValues];
	}
	return self;
}


- (void)setBoundValue:(id)value
{
	if(self.boundObject && self.boundPropertyName)
	{
        if(self.boundObjectStore)
            [self.boundObjectStore setValue:value forPropertyName:self.boundPropertyName inObject:self.boundObject];
        else 
            [SCUtilities setValue:value forPropertyName:self.boundPropertyName inObject:self.boundObject];
	}
}

- (NSObject *)boundValue
{
	if(self.boundObject && self.boundPropertyName)
	{
        if(self.boundObjectStore)
            return [self.boundObjectStore valueForPropertyName:self.boundPropertyName inObject:self.boundObject];
        else 
            return [SCUtilities valueForPropertyName:self.boundPropertyName inObject:self.boundObject];
	}
	//else
	return nil;
}

- (NSUInteger)itemIndexForCell:(SCTableViewCell *)cell
{
    return [self.items indexOfObject:cell.textLabel.text];
}

- (NSUInteger)itemIndexForCellAtIndexPath:(NSIndexPath *)indexPath
{
    SCTableViewCell *cell = [self cellAtIndexPath:indexPath];
    return [self itemIndexForCell:cell];
}

- (NSIndexPath *)indexPathForItemIndex:(NSInteger)itemIndex
{
    for(NSUInteger i=0; i<self.sectionCount; i++)
    {
        SCTableViewSection *section = [self sectionAtIndex:i];
        for(NSUInteger j=0; j<section.cellCount; j++)
        {
            SCTableViewCell *cell = [section cellAtIndex:j];
            if([self.items indexOfObject:cell.textLabel.text] == itemIndex)
                return [NSIndexPath indexPathForRow:j inSection:i];
        }
    }
    return nil;
}

- (void)buildSelectedItemsIndexesFromString:(NSString *)string
{
	NSArray *selectionStrings = [string componentsSeparatedByString:@";"];
	
	[self.selectedItemsIndexes removeAllObjects];
	for(NSString *selectionString in selectionStrings)
	{
		NSUInteger index = [self.items indexOfObject:selectionString];
		if(index != NSNotFound)
			[self.selectedItemsIndexes addObject:[NSNumber numberWithUnsignedInteger:index]];
	}
}

- (NSString *)buildStringFromSelectedItemsIndexes
{
	NSMutableArray *selectionStrings = [NSMutableArray arrayWithCapacity:[self.selectedItemsIndexes count]];
	for(NSNumber *index in self.selectedItemsIndexes)
	{
		[selectionStrings addObject:[self.items objectAtIndex:[index intValue]]];
	}
	
	return [selectionStrings componentsJoinedByString:@";"];
}

// override superclass
- (void)reloadBoundValues
{
    [super reloadBoundValues];
    
    if(boundToNSNumber)
    {
        if(self.boundValue)
			[self.selectedItemsIndexes addObject:self.boundValue];
		
		if(self.boundObject && !self.boundValue)
			self.boundValue = [NSNumber numberWithInt:-1];
    }
    else
        if(boundToNSString)
        {
            if([SCUtilities isStringClass:[self.boundValue class]] && self.items)
            {
                [self buildSelectedItemsIndexesFromString:(NSString *)self.boundValue];
            }
        }
        else
        {
            if(self.boundObject && !self.boundValue)
                self.boundValue = [NSMutableSet set];   //Empty set
        }
}

// override superclass method
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([self.selectedItemsIndexes containsObject:[NSNumber numberWithUnsignedInteger:[self itemIndexForCellAtIndexPath:indexPath]]])
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		cell.textLabel.textColor = [UIColor colorWithRed:50.0f/255 green:79.0f/255 blue:133.0f/255 alpha:1];
	}
	else
	{
        cell.accessoryType = UITableViewCellAccessoryNone;
		cell.textLabel.textColor = [UIColor blackColor];
	}
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
}

- (void)deselectLastSelectedRow
{
	[self.tableView deselectRowAtIndexPath:lastSelectedRowIndexPath animated:YES];
}

// override superclass method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    NSNumber *itemIndex = [NSNumber numberWithUnsignedInteger:[self itemIndexForCellAtIndexPath:indexPath]];
	UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
	
	lastSelectedRowIndexPath = indexPath;
	
	if([self.selectedItemsIndexes containsObject:itemIndex])
	{
		if(!self.allowNoSelection && self.selectedItemsIndexes.count==1)
		{
			[self performSelector:@selector(deselectLastSelectedRow) withObject:nil afterDelay:0.05];
			
			if(self.autoDismissViewController)
				[self performSelector:@selector(dismissViewController) withObject:nil afterDelay:0.4];
			return;
		}
		
		//uncheck cell and exit method
		[self.selectedItemsIndexes removeObject:itemIndex];
		if(boundToNSNumber)
			self.boundValue = self.selectedItemIndex;
		else
			if(boundToNSString)
				self.boundValue = [self buildStringFromSelectedItemsIndexes];
		selectedCell.accessoryType = UITableViewCellAccessoryNone;
		selectedCell.textLabel.textColor = [UIColor blackColor];
		[self valueChangedForSectionAtIndex:indexPath.section];
		[self performSelector:@selector(deselectLastSelectedRow) withObject:nil afterDelay:0.05];
		return;
	}
	
	// Make sure not to exceed maximumSelections
	if(self.allowMultipleSelection && self.maximumSelections!=0 && self.selectedItemsIndexes.count==self.maximumSelections)
	{
		[self performSelector:@selector(deselectLastSelectedRow) withObject:nil afterDelay:0.05];
		
		if(self.autoDismissViewController)
			[self performSelector:@selector(dismissViewController) withObject:nil afterDelay:0.4];
		return;
	}
	
	if(!self.allowMultipleSelection && self.selectedItemsIndexes.count)
	{
		NSIndexPath *oldIndexPath = [self indexPathForItemIndex:[(NSNumber *)[self.selectedItemsIndexes anyObject] intValue]];
        [self.selectedItemsIndexes removeAllObjects];
		UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
		oldCell.accessoryType = UITableViewCellAccessoryNone;
		oldCell.textLabel.textColor = [UIColor blackColor];
	}
	
	//check selected cell
	[self.selectedItemsIndexes addObject:itemIndex];
	if(boundToNSNumber)
		self.boundValue = self.selectedItemIndex;
	else
		if(boundToNSString)
			self.boundValue = [self buildStringFromSelectedItemsIndexes];
	selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
	selectedCell.textLabel.textColor = [UIColor colorWithRed:50.0f/255 green:79.0f/255 blue:133.0f/255 alpha:1];
	
	[self valueChangedForSectionAtIndex:indexPath.section];
	
	[self performSelector:@selector(deselectLastSelectedRow) withObject:nil afterDelay:0.1];
	
	if(self.autoDismissViewController)
	{
		if(!self.allowMultipleSelection || self.maximumSelections==0 
		   || self.maximumSelections==self.selectedItemsIndexes.count || self.items.count==self.selectedItemsIndexes.count)
			[self performSelector:@selector(dismissViewController) withObject:nil afterDelay:0.4];
	}
    
}

- (void)dismissViewController
{
	if([self.viewController isKindOfClass:[SCTableViewController class]])
	{
		[(SCTableViewController *)self.viewController
		 dismissWithCancelValue:FALSE doneValue:TRUE];
	}
    else
        if([self.viewController isKindOfClass:[SCViewController class]])
        {
            [(SCViewController *)self.viewController 
		 dismissWithCancelValue:FALSE doneValue:TRUE];
        }
}

- (NSMutableSet *)selectedItemsIndexes
{
	if(self.boundObject && !(boundToNSNumber || boundToNSString))
		return (NSMutableSet *)self.boundValue;
	//else
	return _selectedItemsIndexes;
}

- (void)setSelectedItemIndex:(NSNumber *)number
{
	NSNumber *num = [number copy];
	
	if(boundToNSNumber)
		self.boundValue = num;
	
	[self.selectedItemsIndexes removeAllObjects];
	if([number intValue] >= 0)
		[self.selectedItemsIndexes addObject:num];
}

- (NSNumber *)selectedItemIndex
{
	NSNumber *index = [self.selectedItemsIndexes anyObject];
	
	if(index)
		return index;
	//else
	return [NSNumber numberWithInt:-1];
}

@end
















@interface SCObjectSelectionModel ()

- (NSMutableSet *)boundMutableSet;

- (void)selectedItemsIndexesModified;

- (NSInteger)itemIndexForCell:(SCTableViewCell *)cell;
- (NSInteger)itemIndexForCellAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForItemIndex:(NSInteger)itemIndex;

- (void)deselectLastSelectedRow;
- (void)dismissViewController;

@end



@implementation SCObjectSelectionModel

@synthesize boundObject;
@synthesize boundObjectStore;
@synthesize boundPropertyName;
@synthesize selectedItemsIndexes;
@synthesize allowMultipleSelection;
@synthesize allowNoSelection;
@synthesize maximumSelections;
@synthesize autoDismissViewController;


- (instancetype)init
{
	if( (self=[super init]) )
	{
        boundObject = nil;
        boundObjectStore = nil;
		boundPropertyName = nil;
        
		lastSelectedRowIndexPath = nil;
		itemsAccessoryType = UITableViewCellAccessoryCheckmark;
		allowAddingItems = FALSE;
		allowDeletingItems = FALSE;
		allowMovingItems = FALSE;
		allowEditDetailView = FALSE;
		
		allowMultipleSelection = FALSE;
		allowNoSelection = FALSE;
		maximumSelections = 0;
		autoDismissViewController = FALSE;
		selectedItemsIndexes = [[NSMutableSet alloc] init];
	}
	
	return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView
              boundObject:(NSObject *)object selectedObjectPropertyName:(NSString *)propertyName
      selectionItemsStore:(SCDataStore *)store
{
    if( (self = [self initWithTableView:tableView]) )
    {
        boundObject = object;
        dataStore = store;
        
        // Only bind property name if property exists
		if([SCUtilities propertyName:propertyName existsInObject:self.boundObject])
			boundPropertyName = [propertyName copy];
        
        if([self.boundValue isKindOfClass:[NSMutableSet class]])
            allowMultipleSelection = TRUE;
        else
            allowMultipleSelection = FALSE;
        
        // Synchronize selectedItemsIndexes
        [self reloadBoundValues];
    }
    return self;
}

- (instancetype)initWithTableView:(UITableView *)tableView
            boundObject:(NSObject *)object selectedObjectPropertyName:(NSString *)propertyName
                  items:(NSArray *)selectionItems itemsDefintion:(SCDataDefinition *)definition
{
	SCArrayStore *store = [SCArrayStore storeWithObjectsArray:[NSMutableArray arrayWithArray:selectionItems] defaultDefiniton:definition];
    
    self = [self initWithTableView:tableView boundObject:object selectedObjectPropertyName:propertyName selectionItemsStore:store];
    
    return self;
}


- (void)setBoundValue:(id)value
{
	if(self.boundObject && self.boundPropertyName)
	{
        if(self.boundObjectStore)
            [self.boundObjectStore setValue:value forPropertyName:self.boundPropertyName inObject:self.boundObject];
        else
            [SCUtilities setValue:value forPropertyName:self.boundPropertyName inObject:self.boundObject];
	}
}

- (NSObject *)boundValue
{
	if(self.boundObject && self.boundPropertyName)
	{
        if(self.boundObjectStore)
            return [self.boundObjectStore valueForPropertyName:self.boundPropertyName inObject:self.boundObject];
        else
            return [SCUtilities valueForPropertyName:self.boundPropertyName inObject:self.boundObject];
	}
	//else
	return nil;
}

- (NSMutableSet *)boundMutableSet
{
    return (NSMutableSet *)self.boundValue;
}


// override superclass method
- (void)reloadBoundValues
{
    [super reloadBoundValues];
    
    // Synchronize selectedItemsIndexes
    [self.selectedItemsIndexes removeAllObjects];
    if(self.allowMultipleSelection)
    {
        NSMutableSet *boundSet = [self boundMutableSet];  //optimize
        for(NSObject *obj in boundSet)
        {
            NSUInteger index = [self.items indexOfObjectIdenticalTo:obj];
            if(index != NSNotFound)
                [self.selectedItemsIndexes addObject:[NSNumber numberWithUnsignedInteger:index]];
        }
    }
    else
    {
        NSObject *selectedObject = [SCUtilities valueForPropertyName:self.boundPropertyName inObject:self.boundObject];
        NSUInteger index = [self.items indexOfObjectIdenticalTo:selectedObject];
        if(index != NSNotFound)
            [self.selectedItemsIndexes addObject:[NSNumber numberWithUnsignedInteger:index]];
    }
}

- (void)selectedItemsIndexesModified
{
    if(self.allowMultipleSelection)
    {
        NSMutableSet *boundValueSet = [self boundMutableSet];
        [boundValueSet removeAllObjects];
        for(NSNumber *index in self.selectedItemsIndexes)
        {
            [boundValueSet addObject:[self.items objectAtIndex:[index intValue]]];
        }
    }
	else
	{
		NSObject *selectedObject = nil;
		int index = [self.selectedItemIndex intValue];
		if(index >= 0)
			selectedObject = [self.items objectAtIndex:index];
		
		self.boundValue = selectedObject;
	}
}


- (NSInteger)itemIndexForCell:(SCTableViewCell *)cell
{
    return [self.items indexOfObjectIdenticalTo:cell.boundObject];
}

- (NSInteger)itemIndexForCellAtIndexPath:(NSIndexPath *)indexPath
{
    SCTableViewCell *cell = [self cellAtIndexPath:indexPath];
    return [self itemIndexForCell:cell];
}

- (NSIndexPath *)indexPathForItemIndex:(NSInteger)itemIndex
{
    for(NSUInteger i=0; i<self.sectionCount; i++)
    {
        SCTableViewSection *section = [self sectionAtIndex:i];
        for(NSUInteger j=0; j<section.cellCount; j++)
        {
            SCTableViewCell *cell = [section cellAtIndex:j];
            if([self.items indexOfObjectIdenticalTo:cell.boundObject] == itemIndex)
                return [NSIndexPath indexPathForRow:j inSection:i];
        }
    }
    return nil;
}


// override superclass method
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if([self.selectedItemsIndexes containsObject:[NSNumber numberWithUnsignedInteger:[self itemIndexForCellAtIndexPath:indexPath]]])
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		cell.textLabel.textColor = [UIColor colorWithRed:50.0f/255 green:79.0f/255 blue:133.0f/255 alpha:1];
	}
	else
	{
        cell.accessoryType = UITableViewCellAccessoryNone;
		cell.textLabel.textColor = [UIColor blackColor];
	}
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
}

- (void)deselectLastSelectedRow
{
	[self.tableView deselectRowAtIndexPath:lastSelectedRowIndexPath animated:YES];
}

// override superclass method
- (void)dispatchEventRemoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super dispatchEventRemoveRowAtIndexPath:indexPath];
    
    //deselect removed row
    NSNumber *itemIndex = [NSNumber numberWithInteger:indexPath.row];
    [self.selectedItemsIndexes removeObject:itemIndex];
    [self selectedItemsIndexesModified];
}

// override superclass method
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *itemIndex = [NSNumber numberWithUnsignedInteger:[self itemIndexForCellAtIndexPath:indexPath]];
	UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
	
	lastSelectedRowIndexPath = indexPath;
	
	if([self.selectedItemsIndexes containsObject:itemIndex])
	{
		if(!self.allowNoSelection && self.selectedItemsIndexes.count==1)
		{
			[self performSelector:@selector(deselectLastSelectedRow) withObject:nil afterDelay:0.05];
			
			if(self.autoDismissViewController)
				[self performSelector:@selector(dismissViewController) withObject:nil afterDelay:0.4];
			return;
		}
		
		//uncheck cell and exit method
		[self.selectedItemsIndexes removeObject:itemIndex];
		[self selectedItemsIndexesModified];
        
		selectedCell.accessoryType = UITableViewCellAccessoryNone;
		selectedCell.textLabel.textColor = [UIColor blackColor];
		[self valueChangedForSectionAtIndex:indexPath.section];
		[self performSelector:@selector(deselectLastSelectedRow) withObject:nil afterDelay:0.05];
        
		return;
	}
	
	// Make sure not to exceed maximumSelections
	if(self.allowMultipleSelection && self.maximumSelections!=0 && self.selectedItemsIndexes.count==self.maximumSelections)
	{
		[self performSelector:@selector(deselectLastSelectedRow) withObject:nil afterDelay:0.05];
		
		if(self.autoDismissViewController)
			[self performSelector:@selector(dismissViewController) withObject:nil afterDelay:0.4];
		return;
	}
	
	if(!self.allowMultipleSelection && self.selectedItemsIndexes.count)
	{
		NSIndexPath *oldIndexPath = [self indexPathForItemIndex:[(NSNumber *)[self.selectedItemsIndexes anyObject] intValue]];
        [self.selectedItemsIndexes removeAllObjects];
		UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
		oldCell.accessoryType = UITableViewCellAccessoryNone;
		oldCell.textLabel.textColor = [UIColor blackColor];
	}
	
	//check selected cell
	[self.selectedItemsIndexes addObject:itemIndex];
	[self selectedItemsIndexesModified];
    
	selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
	selectedCell.textLabel.textColor = [UIColor colorWithRed:50.0f/255 green:79.0f/255 blue:133.0f/255 alpha:1];
	
	[self valueChangedForSectionAtIndex:indexPath.section];
	
	[self performSelector:@selector(deselectLastSelectedRow) withObject:nil afterDelay:0.1];
	
	if(self.autoDismissViewController)
	{
		if(!self.allowMultipleSelection || self.maximumSelections==0
		   || self.maximumSelections==self.selectedItemsIndexes.count || self.items.count==self.selectedItemsIndexes.count)
			[self performSelector:@selector(dismissViewController) withObject:nil afterDelay:0.4];
	}
    
}

- (void)dismissViewController
{
	if([self.viewController isKindOfClass:[SCTableViewController class]])
	{
		[(SCTableViewController *)self.viewController
		 dismissWithCancelValue:FALSE doneValue:TRUE];
	}
    else
        if([self.viewController isKindOfClass:[SCViewController class]])
        {
            [(SCViewController *)self.viewController
             dismissWithCancelValue:FALSE doneValue:TRUE];
        }
}

- (void)setSelectedItemIndex:(NSNumber *)number
{
	NSNumber *num = [number copy];
	
	[self.selectedItemsIndexes removeAllObjects];
	if([number intValue] >= 0)
		[self.selectedItemsIndexes addObject:num];
}

- (NSNumber *)selectedItemIndex
{
	NSNumber *index = [self.selectedItemsIndexes anyObject];
	
	if(index)
		return index;
	//else
	return [NSNumber numberWithInt:-1];
}

@end






