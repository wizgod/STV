/*
 *  SCTableViewSection.m
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

#import "SCTableViewSection.h"
#import "SCTableViewModel.h"
#import "SCGlobals.h"
#import "SCClassDefinition.h"
#import "SCStringDefinition.h"
#import "SCArrayStore.h"
#import <objc/runtime.h>




@interface SCTableViewSection ()

@property (nonatomic, strong) NSMutableArray *cells;

@end


@implementation SCTableViewSection

@synthesize ownerTableViewModel = _ownerTableViewModel;
@synthesize cells;
@synthesize boundObject;
@synthesize boundObjectStore;
@synthesize boundPropertyName;
@synthesize commitCellChangesLive;
@synthesize headerTitle;
@synthesize headerHeight;
@synthesize headerView;
@synthesize footerTitle;
@synthesize footerHeight;
@synthesize footerView;
@synthesize sectionActions;
@synthesize cellActions;
@synthesize cellsImageViews;
@synthesize expandCollapseCell;
@synthesize themeStyle;
@synthesize firstCellThemeStyle;
@synthesize evenCellsThemeStyle;
@synthesize oddCellsThemeStyle;
@synthesize lastCellThemeStyle;

+ (instancetype)section
{
	return [[[self class] alloc] init];
}

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle
{
	return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle];
}

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle footerTitle:(NSString *)sectionFooterTitle
{
	return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle footerTitle:sectionFooterTitle];
}

- (instancetype)init
{
	if( (self=[super init]) )
	{
		_ownerTableViewModel = nil;
		boundObject = nil;
        boundObjectStore = nil;
		boundPropertyName = nil;
		commitCellChangesLive = TRUE;
		headerTitle = nil;
		headerHeight = -1;	// This will set the default header height
		headerView = nil;
		footerTitle = nil;
		footerHeight = -1;	// This will set the default footer height
		footerView = nil;
        
        sectionActions = [[SCSectionActions alloc] init];
		cellsImageViews = nil;
		cellActions = [[SCCellActions alloc] init];
		cells = [[NSMutableArray alloc] init];
        
        expandCollapseCell = nil;
        
        detailViewControllerOptions = nil;
        newItemDetailViewControllerOptions = nil;
        
        themeStyle = nil;
        firstCellThemeStyle = nil;
        evenCellsThemeStyle = nil;
        oddCellsThemeStyle = nil;
        lastCellThemeStyle = nil;
	}
	return self;
}

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle
{
	if( (self=[self init]) )
	{
		self.headerTitle = sectionHeaderTitle;
	}
	return self;
}

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle footerTitle:(NSString *)sectionFooterTitle
{
	if( (self=[self init]) )
	{
		self.headerTitle = sectionHeaderTitle;
		self.footerTitle = sectionFooterTitle;
	}
	return self;
}


- (void)setOwnerTableViewModel:(SCTableViewModel *)ownerTableViewModel
{
    _ownerTableViewModel = ownerTableViewModel;
    
    for(SCTableViewCell *cell in self.cells)
        cell.ownerTableViewModel = _ownerTableViewModel;
}

- (void)setExpandCollapseCell:(SCExpandCollapseCell *)cell
{
    if(expandCollapseCell)
    {
        NSUInteger index = [self indexForCell:expandCollapseCell];
        [self removeCellAtIndex:index];
    }
    
    expandCollapseCell = cell;
    if(![self isKindOfClass:[SCArrayOfItemsSection class]])  // SCArrayOfItemsSection automatically handles adding expandCollapseCell
        [self insertCell:expandCollapseCell atIndex:0];
    expandCollapseCell.movable = FALSE;
    expandCollapseCell.editable = TRUE;
    expandCollapseCell.cellEditingStyle = UITableViewCellEditingStyleInsert;
    [expandCollapseCell markCellAsSpecial];
}

- (SCDetailViewControllerOptions *)detailViewControllerOptions
{
    // Conserve resources by lazy loading for only sections that need it
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
    // Conserve resources by lazy loading for only sections that need it
    if(!newItemDetailViewControllerOptions)
        newItemDetailViewControllerOptions = [[SCDetailViewControllerOptions alloc] init];
    
    return newItemDetailViewControllerOptions;
}

- (void)setNewItemDetailViewControllerOptions:(SCDetailViewControllerOptions *)options
{
    newItemDetailViewControllerOptions = options;
}

- (NSComparisonResult)compare:(SCTableViewSection *)section
{
	if(!self.headerTitle)
		return NSOrderedAscending;
	
	if(!section.headerTitle)
		return NSOrderedDescending;
	
	return [self.headerTitle compare:section.headerTitle];
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

- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
    // Does nothing, should be overridden by subclasses
}

- (void)setCommitCellChangesLive:(BOOL)commit
{
	commitCellChangesLive = commit;
	
	for(SCTableViewCell *cell in self.cells)
    {
        if([cell isKindOfClass:[SCTableViewCell class]])
            cell.commitChangesLive = commit;
    }
}

- (NSString *)footerTitle
{
    return footerTitle;
}

- (UIView *)footerView
{
    return footerView;
}

- (NSUInteger)cellCount
{
    NSUInteger count;
    
    if(self.expandCollapseCell && !self.expandCollapseCell.ownerSectionExpanded)
    {
        count = 1;
    }
    else 
    {
        count = self.cells.count;
    }
    
	return count;
}

- (void)addCell:(SCTableViewCell *)cell
{
	cell.ownerTableViewModel = self.ownerTableViewModel;
    cell.ownerSection = self;
	cell.commitChangesLive = self.commitCellChangesLive;
	[self.cells addObject:cell];
}

- (void)insertCell:(SCTableViewCell *)cell atIndex:(NSUInteger)index
{
	cell.ownerTableViewModel = self.ownerTableViewModel;
    cell.ownerSection = self;
	cell.commitChangesLive = self.commitCellChangesLive;
	[self.cells insertObject:cell atIndex:index];
}

- (SCTableViewCell *)cellAtIndex:(NSUInteger)index
{
	if(index < self.cellCount)
		return [self.cells objectAtIndex:index];
	//else
	return nil;
}

- (void)removeCellAtIndex:(NSUInteger)index
{
	// Check if the cell to be removed is the current active cell
	SCTableViewCell *cell = [self.cells objectAtIndex:index];
    if([cell isKindOfClass:[SCTableViewCell class]])
        [cell resignFirstResponder];
    if (self.ownerTableViewModel.activeCell == cell)
	{
        self.ownerTableViewModel.activeCell = nil;
    }
	
	[self.cells removeObjectAtIndex:index];
}

- (void)removeCellIdenticalTo:(SCTableViewCell *)cell
{
    NSUInteger cellIndex = [self indexForCell:cell];
    
    if(cellIndex != NSNotFound)
        [self removeCellAtIndex:cellIndex];
}

- (void)removeAllCells
{
    [self.cells removeAllObjects];
}

- (NSUInteger)indexForCell:(SCTableViewCell *)cell
{
	return [self.cells indexOfObjectIdenticalTo:cell];
}

- (BOOL)valuesAreValid
{
	for(SCTableViewCell *cell in self.cells)
    {
        if([cell isKindOfClass:[SCTableViewCell class]])
        {
            if(!cell.valueIsValid)
                return FALSE;
        }
    }
	
	return TRUE;
}

- (BOOL)needsCommit
{
	for(SCTableViewCell *cell in self.cells)
    {
        if([cell isKindOfClass:[SCTableViewCell class]])
        {
            if(cell.needsCommit)
                return TRUE;
        }
    }
	
	return FALSE;
}

- (void)commitCellChanges
{
	for(SCTableViewCell *cell in self.cells)
    {
        if([cell isKindOfClass:[SCTableViewCell class]])
        {
            [cell commitChanges];
        }
    }
}

- (void)invalidateCellCommits
{
    for(SCTableViewCell *cell in self.cells)
    {
        if([cell isKindOfClass:[SCTableViewCell class]])
        {
            [cell setNeedsCommit:TRUE];
        }
    }
}

- (void)reloadBoundValues
{
	for(SCTableViewCell *cell in self.cells)
    {
        if([cell isKindOfClass:[SCTableViewCell class]])
        {
            [cell reloadBoundValue];
        }
    }
}

- (CGFloat)heightForCellAtIndexPath:(NSIndexPath *)indexPath
{
    SCTableViewCell *cell = [self.ownerTableViewModel cellAtIndexPath:indexPath];
	
    if(!cell.configured)
    {
        // only style the 'height' property for now, then style the whole cell after layoutSubviews
        [self.ownerTableViewModel styleCell:cell atIndexPath:indexPath onlyStylePropertyNamesInSet:[NSSet setWithObject:@"height"]];
        [self.ownerTableViewModel configureCell:cell atIndexPath:indexPath];
    }
    
    CGFloat cellHeight = cell.height;
    // Check if the cell has an image in its section and resize accordingly
    if([self.cellsImageViews count] > indexPath.row)
    {
        UIImageView *imageView = [self.cellsImageViews objectAtIndex:indexPath.row];
        if([imageView isKindOfClass:[UIImageView class]])
        {
            if(cellHeight < imageView.image.size.height)
                cellHeight = imageView.image.size.height;
        }
    }
    
    return cellHeight;
}

- (void)editingModeWillChange
{
    // Do nothing. Should be overridden by subclasses.
}

- (void)editingModeDidChange
{
    // Do nothing. Should be overridden by subclasses.
}

- (void)setExpanded:(BOOL)expanded
{
    if(self.cells.count < 2)
        return;
    
    if(self.ownerTableViewModel.live)
    {
        NSUInteger sectionIndex = [self.ownerTableViewModel indexForSection:self];
        
        NSMutableArray *indexPaths = [NSMutableArray array];
        for(NSUInteger i=1; i<self.cells.count; i++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:sectionIndex];
            [indexPaths addObject:indexPath];
        }
        
        if(expanded)
            [self.ownerTableViewModel.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        else 
            [self.ownerTableViewModel.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
        
        [self.ownerTableViewModel exitLoadingMode];
    }
}


- (UIViewController *)generatedDetailViewControllerForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self cellAtIndex:indexPath.row] generatedDetailViewController:indexPath];
}


- (void)rollbackToInitialCellValues
{
    if([self isKindOfClass:[SCArrayOfItemsSection class]])
        return;
    
    
    for(SCTableViewCell *cell in self.cells)
    {
        if([cell isKindOfClass:[SCTableViewCell class]])
        {
            [cell rollbackToInitialBoundValue];
        }
    }
}


@end





@interface SCObjectSection ()

- (SCTableViewCell *)getCellForPropertyWithDefinition:(SCPropertyDefinition *)propertyDefinition
                                      withBoundObject:(NSObject *)boundObj
                                 withBoundObjectStore:(SCDataStore *)boundObjStore
                                        inEditingMode:(BOOL)editing;

- (void)setEditableStateForCell:(SCTableViewCell *)cell withPropertyDefinition:(SCPropertyDefinition *)propertyDefinition inEditingMode:(BOOL)editing;

@end


@implementation SCObjectSection

@synthesize propertyGroup;

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle boundObject:(NSObject *)object
{
	return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle boundObject:object];
}

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle
                 boundObject:(NSObject *)object
       boundObjectDefinition:(SCDataDefinition *)definition
{
	return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle boundObject:object boundObjectDefinition:definition];
}

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle
                 boundObject:(NSObject *)object
       boundObjectDefinition:(SCDataDefinition *)definition
               propertyGroup:(SCPropertyGroup *)group
{
    return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle boundObject:object boundObjectDefinition:definition propertyGroup:group];
}

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle
                 boundObject:(NSObject *)object
            boundObjectStore:(SCDataStore *)store
               propertyGroup:(SCPropertyGroup *)group
{
    return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle boundObject:object boundObjectStore:store propertyGroup:group];
}


- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle boundObject:(NSObject *)object
{
	return [self initWithHeaderTitle:sectionHeaderTitle boundObject:object boundObjectDefinition:nil propertyGroup:nil];
}

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle
              boundObject:(NSObject *)object
    boundObjectDefinition:(SCDataDefinition *)definition
{
    return [self initWithHeaderTitle:sectionHeaderTitle boundObject:object boundObjectDefinition:definition propertyGroup:nil];
}

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle
              boundObject:(NSObject *)object
    boundObjectDefinition:(SCDataDefinition *)definition
            propertyGroup:(SCPropertyGroup *)group
{
    if(!definition)
        definition = [SCClassDefinition definitionWithClass:[object class] autoGeneratePropertyDefinitions:YES];
    SCDataStore *store = [definition generateCompatibleDataStore];
    
    return [self initWithHeaderTitle:sectionHeaderTitle boundObject:object boundObjectStore:store propertyGroup:group];
}

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle
              boundObject:(NSObject *)object
         boundObjectStore:(SCDataStore *)store 
            propertyGroup:(SCPropertyGroup *)group
{
	if( (self=[self initWithHeaderTitle:sectionHeaderTitle]) )
    {
        boundObject = object;
        boundObjectStore = store;
        
        if(!group)
        {
            SCDataDefinition *objectDefinition = [self.boundObjectStore definitionForObject:self.boundObject];
            [objectDefinition generateDefaultPropertyGroupProperties];
            group = objectDefinition.defaultPropertyGroup;
        }
        
        self.propertyGroup = group;
        
        if(!sectionHeaderTitle)
            self.headerTitle = propertyGroup.headerTitle;
        self.footerTitle = propertyGroup.footerTitle;
        
        [self generateCellsForEditingState:FALSE];
    }
	
	return self;
}

- (void)setBoundObject:(NSObject *)boundObj
{
    boundObject = boundObj;
    
    // Regenerate the cells
    [self generateCellsForEditingState:FALSE];
}

- (void)setBoundObjectStore:(SCDataStore *)store
{
    boundObjectStore = store;
    
    // Regenerate the cells
    [self generateCellsForEditingState:FALSE];
}

- (void)setBoundObject:(NSObject *)boundObj withStore:(SCDataStore *)store autoGenerateCells:(BOOL)autoGenerateCells
{
    boundObject = boundObj;
    boundObjectStore = store;
    
    if(autoGenerateCells)
    {
        [self generateCellsForEditingState:FALSE];
    }
    else
    {
        for(SCTableViewCell *cell in cells)
        {
            if(!cell.boundObject)
            {
                cell.boundObject = boundObject;
                cell.boundObjectStore = store;
            }
        }
    }
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCObjectAttributes class]])
		return;

    // nothing to set
}

// Override super class method
- (void)editingModeWillChange
{
    [super editingModeWillChange];
    
    // Create a dictionary of old cell indexPaths (will need this as the section's structure changes)
    NSUInteger sectionIndex = [self.ownerTableViewModel indexForSection:self];
    NSMutableDictionary *oldCellsIndexPaths = [NSMutableDictionary dictionaryWithCapacity:self.cellCount];
    for(SCTableViewCell *cell in cells)
    {
        NSUInteger index = [self indexForCell:cell];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:sectionIndex];
        NSString *cellKey = [NSString stringWithFormat:@"%p", cell];  // use cell address as key
        [oldCellsIndexPaths setValue:indexPath forKey:cellKey];
    }
    
    BOOL oldEditing = self.ownerTableViewModel.tableView.editing;
    BOOL newEditing = !oldEditing;
    NSInteger oldCellCursor = 0;
    SCDataDefinition *objectDefinition = [self.boundObjectStore definitionForObject:self.boundObject];
    for(NSInteger i=0; i<self.propertyGroup.propertyNameCount; i++)
	{
        SCPropertyDefinition *propertyDefinition = [objectDefinition propertyDefinitionWithName:[self.propertyGroup propertyNameAtIndex:i]];
        
        SCTableViewCell *oldCell = [self getCellForPropertyWithDefinition:propertyDefinition withBoundObject:self.boundObject withBoundObjectStore:self.boundObjectStore inEditingMode:oldEditing];
        SCTableViewCell *newCell = [self getCellForPropertyWithDefinition:propertyDefinition withBoundObject:self.boundObject withBoundObjectStore:self.boundObjectStore inEditingMode:newEditing];
        newCell.tag = i;
            
        if(!oldCell && !newCell)
            continue;
        
        if(!oldCell)
        {
            // Insert new cell
            [self insertCell:newCell atIndex:oldCellCursor];
            [self.ownerTableViewModel.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:oldCellCursor inSection:sectionIndex]] withRowAnimation:UITableViewRowAnimationFade];
            
            oldCellCursor++;
            continue;
        }
        
        NSString *cellKey = [NSString stringWithFormat:@"%p", [self cellAtIndex:oldCellCursor]];
        NSIndexPath *oldCellIndexPath = [oldCellsIndexPaths valueForKey:cellKey];
        
        if(!newCell)
        {
            // Remove old cell
            [self removeCellAtIndex:oldCellCursor];
            [self.ownerTableViewModel.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:oldCellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            continue;
        }
        
        // Both oldCell and newCell exist
        if(![oldCell isKindOfClass:[newCell class]] || propertyDefinition.editingModeAttributes)
        {
            //Replace old cell with new cell
            [self removeCellAtIndex:oldCellCursor];
            [self insertCell:newCell atIndex:oldCellCursor];
            [self.ownerTableViewModel.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:oldCellIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
        else
        {
            [self setEditableStateForCell:[self cellAtIndex:oldCellCursor] withPropertyDefinition:propertyDefinition inEditingMode:newEditing];
        }
        
        oldCellCursor++;
    }
}

- (void)generateCellsForEditingState:(BOOL)editing
{
    [self removeAllCells];
    

    if([self.boundObjectStore isKindOfClass:[SCMissingFrameworkDataStore class]])
    {
        [self addCell:[SCTableViewCell cellWithText:[(SCMissingFrameworkDataStore *)self.boundObjectStore missingFrameworkDataDefinition].missingFrameworkMessage]];
        return;
    }

         
    
    // Generate cells based on the classDefinition's propertyGroup
    SCDataDefinition *objectDefinition = [self.boundObjectStore definitionForObject:self.boundObject];
	for(NSInteger i=0; i<self.propertyGroup.propertyNameCount; i++)
	{
        SCPropertyDefinition *propertyDefinition = [objectDefinition propertyDefinitionWithName:[self.propertyGroup propertyNameAtIndex:i]];
		SCTableViewCell *cell = [self getCellForPropertyWithDefinition:propertyDefinition
													   withBoundObject:self.boundObject withBoundObjectStore:self.boundObjectStore inEditingMode:editing];
		if(cell)
		{
			cell.tag = i;
			[self addCell:cell];
		}
	}
}

- (void)setEditableStateForCell:(SCTableViewCell *)cell withPropertyDefinition:(SCPropertyDefinition *)propertyDefinition inEditingMode:(BOOL)editing
{
    BOOL editable = TRUE;
    if(propertyDefinition.ownerDataStuctureDefinition.requireEditingModeToEditPropertyValues && !editing)
    {
        if(![cell isKindOfClass:[SCExpandCollapseCell class]])
            editable = FALSE;
    }
    
    cell.enabled = editable;
}

- (SCTableViewCell *)getCellForPropertyWithDefinition:(SCPropertyDefinition *)propertyDefinition
									  withBoundObject:(NSObject *)boundObj
                                 withBoundObjectStore:(SCDataStore *)boundObjStore 
                                        inEditingMode:(BOOL)editing
{
	if(!editing && !propertyDefinition.existsInNormalMode)
        return nil;
    
    if(editing && !propertyDefinition.existsInEditingMode)
        return nil;
    
    SCTableViewCell *cell = nil;
    
    NSObject *uiElement = nil;
    if(propertyDefinition.uiElementNibName)
    {
        uiElement = [SCUtilities getFirstNodeInNibWithName:propertyDefinition.uiElementNibName];
    }
    else
    {
        uiElement = [[propertyDefinition.uiElementClass alloc] init];
    }
    
    if([uiElement isKindOfClass:[SCTableViewCell class]])
    {
        cell = (SCTableViewCell *)uiElement;
        if([cell isKindOfClass:[SCCustomCell class]])
        {
            SCCustomCell *customCell = (SCCustomCell *)cell;
            customCell.boundObject = boundObj;
            customCell.boundPropertyName = propertyDefinition.name;
            [customCell.objectBindings addEntriesFromDictionary:propertyDefinition.objectBindings];
            [customCell configureCustomControls];
            customCell.textLabel.text = propertyDefinition.title;
            if(customCell.frame.size.height)
                customCell.height = customCell.frame.size.height;
        }
    }
    
	SCDataType propertyDataType = propertyDefinition.dataType;
    BOOL readOnlyProperty = propertyDefinition.dataReadOnly;
    NSString *propertyName = propertyDefinition.name;
    NSString *propertyTitle = propertyDefinition.title;
    SCPropertyType propertyType = propertyDefinition.type;
    if(editing && propertyDefinition.editingModeType!=SCPropertyTypeUndefined)
    {
        propertyType = propertyDefinition.editingModeType;
    }
    
    if(propertyType == SCPropertyTypeAutoDetect)
    {
        // Auto detect property type
        if(propertyDataType==SCDataTypeNSString || propertyDataType==SCDataTypeDictionaryItem)
        {
            if(readOnlyProperty)
                propertyType = SCPropertyTypeLabel;
            else
                propertyType = SCPropertyTypeTextField;
        }
        else
            if(propertyDataType == SCDataTypeNSNumber)
            {
                if(readOnlyProperty)
                    propertyType = SCPropertyTypeLabel;
                else
                    propertyType = SCPropertyTypeNumericTextField;
            }
            else
                if(propertyDataType == SCDataTypeNSDate)
                {
                    if(readOnlyProperty)
                        propertyType = SCPropertyTypeLabel;
                    else
                        propertyType = SCPropertyTypeDate;
                }
                else
                    if(propertyDataType == SCDataTypeBOOL)
                    {
                        if(readOnlyProperty)
                            propertyType = SCPropertyTypeLabel;
                        else
                            propertyType = SCPropertyTypeSwitch;
                    }
                    else
                        if(propertyDataType==SCDataTypeInt || propertyDataType==SCDataTypeFloat || propertyDataType==SCDataTypeDouble)
                        {
                            if(readOnlyProperty)
                                propertyType = SCPropertyTypeLabel;
                            else
                                propertyType = SCPropertyTypeNumericTextField;
                        }
                        else
                            if(propertyDataType==SCDataTypeNSMutableArray)
                            {
                                propertyType = SCPropertyTypeArrayOfObjects;
                            }
                            else
                                if(propertyDataType==SCDataTypeNSObject)
                                {
                                    propertyType = SCPropertyTypeObject;
                                }
                                else
                                {
                                    // Can't auto detect
                                    return nil;
                                }
    }
    
    // Convert to an equivalent type for simplicity
    if(propertyDataType==SCDataTypeBOOL || propertyDataType==SCDataTypeInt || propertyDataType==SCDataTypeFloat || propertyDataType==SCDataTypeDouble)
    {
        propertyDataType = SCDataTypeNSNumber;
    }
    
    switch (propertyType)
    {
        case SCPropertyTypeLabel:
            if(propertyDataType==SCDataTypeNSString || propertyDataType==SCDataTypeNSNumber
               || propertyDataType==SCDataTypeNSDate
               || propertyDataType==SCDataTypeDictionaryItem
               || propertyDataType==SCDataTypeTransformable)
            {
                if(!cell)
                {
                    cell = [SCLabelCell cellWithText:propertyTitle boundObject:boundObj labelTextPropertyName:propertyName];
                }
            }
            break;
        case SCPropertyTypeTextView:
            if(propertyDataType==SCDataTypeNSString || propertyDataType==SCDataTypeDictionaryItem
               || propertyDataType==SCDataTypeTransformable)
            {
                if(!cell)
                {
                    cell = [SCTextViewCell cellWithText:propertyTitle boundObject:boundObj textViewTextPropertyName:propertyName];
                }
                
                if(readOnlyProperty)
                {
                    // Override attributes (if exist)
                    if([propertyDefinition.attributes isKindOfClass:[SCTextViewAttributes class]])
                    {
                        ((SCTextViewAttributes *)propertyDefinition.attributes).editable = FALSE;
                    }
                    else if([cell isKindOfClass:[SCTextViewCell class]])
                        ((SCTextViewCell *)cell).textView.editable = FALSE;
                }
            }
            break;
        case SCPropertyTypeTextField:
            if(!readOnlyProperty &&
               (propertyDataType==SCDataTypeNSString || propertyDataType==SCDataTypeDictionaryItem
                || propertyDataType==SCDataTypeTransformable))
            {
                if(!cell)
                {
                    cell = [SCTextFieldCell cellWithText:propertyTitle placeholder:nil boundObject:boundObj textFieldTextPropertyName:propertyName];
                }
            }
            break;
        case SCPropertyTypeNumericTextField:
            if(!readOnlyProperty &&
               (propertyDataType==SCDataTypeNSNumber || propertyDataType==SCDataTypeDictionaryItem
                || propertyDataType==SCDataTypeTransformable))
            {
                if(!cell)
                {
                    cell = [SCNumericTextFieldCell cellWithText:propertyTitle placeholder:nil boundObject:boundObj textFieldTextPropertyName:propertyName];
                }
            }
            break;
        case SCPropertyTypeSlider:
            if(!readOnlyProperty &&
               (propertyDataType==SCDataTypeNSNumber || propertyDataType==SCDataTypeDictionaryItem
                || propertyDataType==SCDataTypeTransformable))
            {
                if(!cell)
                {
                    cell = [SCSliderCell cellWithText:propertyTitle boundObject:boundObj sliderValuePropertyName:propertyName];
                }
            }
            break;
        case SCPropertyTypeSegmented:
            if(!readOnlyProperty &&
               (propertyDataType==SCDataTypeNSNumber || propertyDataType==SCDataTypeNSString || propertyDataType==SCDataTypeDictionaryItem
                || propertyDataType==SCDataTypeTransformable))
            {
                if(!cell)
                {
                    if(propertyDataType==SCDataTypeNSString && ![SCUtilities valueForPropertyName:propertyName inObject:boundObj])
                        [SCUtilities setValue:@"" forPropertyName:propertyName inObject:boundObj]; // unselected default
                        
                    cell = [SCSegmentedCell cellWithText:propertyTitle
                                             boundObject:boundObj
                        selectedSegmentIndexPropertyName:propertyName
                                      segmentTitlesArray:nil];
                }
            }
            break;
        case SCPropertyTypeSwitch:
            if(!readOnlyProperty &&
               (propertyDataType==SCDataTypeNSNumber || propertyDataType==SCDataTypeDictionaryItem
                || propertyDataType==SCDataTypeTransformable))
            {
                if(!cell)
                {
                    cell = [SCSwitchCell cellWithText:propertyTitle boundObject:boundObj switchOnPropertyName:propertyName];
                }
            }
            break;
        case SCPropertyTypeDate:
            if(!readOnlyProperty &&
               (propertyDataType==SCDataTypeNSDate || propertyDataType==SCDataTypeDictionaryItem
                || propertyDataType==SCDataTypeTransformable))
            {
                if(!cell)
                {
                    cell = [SCDateCell cellWithText:propertyTitle boundObject:boundObj datePropertyName:propertyName];
                }
            }
            break;
        case SCPropertyTypeImagePicker:
            if(!readOnlyProperty &&
               (propertyDataType==SCDataTypeNSString || propertyDataType==SCDataTypeDictionaryItem
                || propertyDataType==SCDataTypeTransformable))
            {
                if(!cell)
                {
                    cell = [SCImagePickerCell cellWithText:propertyTitle boundObject:boundObj imageNamePropertyName:propertyName];
                }
            }
            break;
        case SCPropertyTypeSelection:
            if(!cell)
            {
                if(!readOnlyProperty && propertyDataType==SCDataTypeNSNumber)
                {
                    if([propertyDefinition.uiElementClass isSubclassOfClass:[SCSelectionCell class]])
                    {
                        cell = [propertyDefinition.uiElementClass cellWithText:propertyTitle boundObject:boundObj selectedIndexPropertyName:propertyName items:nil];
                    }
                    else
                    {
                        cell = [SCSelectionCell cellWithText:propertyTitle boundObject:boundObj selectedIndexPropertyName:propertyName items:nil];
                    }
                }
                else
                    if(!readOnlyProperty && (propertyDataType==SCDataTypeNSString || propertyDataType==SCDataTypeDictionaryItem) )
                    {
                        if([propertyDefinition.uiElementClass isSubclassOfClass:[SCSelectionCell class]])
                        {
                            cell = [propertyDefinition.uiElementClass cellWithText:propertyTitle boundObject:boundObj selectionStringPropertyName:propertyName items:nil];
                        }
                        else
                        {
                            cell = [SCSelectionCell cellWithText:propertyTitle boundObject:boundObj selectionStringPropertyName:propertyName items:nil];
                        }
                    }
                    else
                        if(propertyDataType==SCDataTypeNSMutableSet)
                        {
                            if([propertyDefinition.uiElementClass isSubclassOfClass:[SCSelectionCell class]])
                            {
                                cell = [propertyDefinition.uiElementClass cellWithText:propertyTitle boundObject:boundObj selectedIndexesPropertyName:propertyName items:nil allowMultipleSelection:FALSE];
                            }
                            else
                            {
                                cell = [SCSelectionCell cellWithText:propertyTitle boundObject:boundObj selectedIndexesPropertyName:propertyName items:nil allowMultipleSelection:FALSE];
                            }
                        }
            }
            break;
        case SCPropertyTypeObjectSelection:
            if(!cell)
            {
                cell = [SCObjectSelectionCell cellWithText:propertyTitle boundObject:boundObj selectedObjectPropertyName:propertyName selectionItemsStore:nil];
            }
            break;
        case SCPropertyTypeObject:
        {
            SCDataDefinition *objDef = nil;
            if([propertyDefinition.attributes isKindOfClass:[SCObjectAttributes class]])
            {
                objDef = [(SCObjectAttributes *)propertyDefinition.attributes objectDefinition];
            }
            
            NSObject *object;
            if(boundObjStore)
                object = [boundObjStore valueForPropertyName:propertyName inObject:boundObj];
            else
                object = [SCUtilities valueForPropertyName:propertyName inObject:boundObj];
            
            SCDataStore *objStore = [objDef generateCompatibleDataStore];
            if(!object && objDef)
            {
                // create a new object
                object = [objStore createNewObjectWithDefinition:objDef];
                [objStore insertObject:object];
                
                if(boundObjStore)
                    [boundObjStore setValue:object forPropertyName:propertyName inObject:boundObj];
                else
                    [SCUtilities setValue:object forPropertyName:propertyName inObject:boundObj];
            }
            
            if(!object)
                break;
            
            // If "object" has only a single object-type property, flatten out
            // the hierarchy by directly exposing the cell for this property
            SCPropertyDefinition *objPropertyDef = nil;
            if(objDef.propertyDefinitionCount==1)
                objPropertyDef = [objDef propertyDefinitionAtIndex:0];
            if(objPropertyDef &&
               (objPropertyDef.type==SCPropertyTypeObject || objPropertyDef.type==SCPropertyTypeArrayOfObjects) )
            {
                // Get the cell via recursion
                cell = [self getCellForPropertyWithDefinition:objPropertyDef withBoundObject:object withBoundObjectStore:objStore inEditingMode:editing];
            }
            else
            {
                if(cell && [cell isKindOfClass:[SCObjectCell class]])
                {
                    SCObjectCell *objectCell = (SCObjectCell *)cell;
                    objectCell.boundObject = object;
                    objectCell.boundObjectStore = objStore;
                }
                else
                {
                    cell = [SCObjectCell cellWithBoundObject:object boundObjectStore:objStore];
                }
                if(propertyDefinition.title)
                    ((SCObjectCell *)cell).boundObjectTitleText = propertyDefinition.title;
                
                // Technically, boundPropertyName is not applicable to SCObjectCell, however
                // it is set here so that [self cellForPropertyName] would work
                cell.boundPropertyName = propertyName;
            }
        }
            break;
            
        case SCPropertyTypeArrayOfObjects:
        {
            SCDataDefinition *objectsDefinition = nil;
            if([propertyDefinition.attributes isKindOfClass:[SCArrayOfObjectsAttributes class]])
            {
                objectsDefinition = [(SCArrayOfObjectsAttributes *)propertyDefinition.attributes defaultObjectsDefinition];
            }
            
            SCDataStore *objectsStore = [objectsDefinition generateCompatibleDataStore];
            if(objectsStore)
            {
                if(![objectsStore valueForPropertyName:propertyName inObject:boundObj])
                {
                    if( (propertyDefinition.dataType==SCDataTypeNSMutableArray && !propertyDefinition.dataReadOnly)
                       || propertyDefinition.dataType==SCDataTypeDictionaryItem)
                    {
                        if([objectsStore isKindOfClass:[SCArrayStore class]]) // if statement required to prevent problems with other stores not supporting this kind of initialization
                            [objectsStore setValue:[NSMutableArray array] forPropertyName:propertyName inObject:boundObj];
                    }
                }
                
                SCDataDefinition *boundObjDef = [boundObjStore definitionForObject:boundObj];
                [objectsStore bindStoreToPropertyName:propertyName forObject:boundObj withDefinition:boundObjDef];
            }
            
            if(cell && [cell isKindOfClass:[SCArrayOfObjectsCell class]])
            {
                SCArrayOfObjectsCell *objectsCell = (SCArrayOfObjectsCell *)cell;
                objectsCell.dataStore = objectsStore;
            }
            else
            {
                cell = [SCArrayOfObjectsCell cellWithDataStore:objectsStore];
            }
            
            // Technically, boundPropertyName is not applicable to SCArrayOfObjectsCell, however
            // it is set here so that [self cellForPropertyName] would work 
            cell.boundPropertyName = propertyName;
        }
            break;
            
        case SCPropertyTypeCustom:
            if(!cell)
            {
                cell = [[SCCustomCell alloc] init];
            }
            [cell setIsCustomBoundProperty:TRUE];
            break;
            
        default:
            cell = nil;
            break;
    }
	
	if(cell)
	{
        cell.textLabel.text = propertyDefinition.title;
        if(!cell.boundObjectStore)
            cell.boundObjectStore = boundObjStore;
        if(!cell.boundObject)
            cell.boundObject = boundObject;
        
        [self configureCell:cell forPropertyDefinition:propertyDefinition inEditingMode:editing];
	}
		
	return cell;
}

- (void)configureCell:(SCTableViewCell *)cell forPropertyDefinition:(SCPropertyDefinition *)propertyDefinition inEditingMode:(BOOL)editing
{
    cell.boundPropertyDataType = propertyDefinition.dataType;
    [self setEditableStateForCell:cell withPropertyDefinition:propertyDefinition inEditingMode:editing];
    cell.valueRequired = propertyDefinition.required;
    cell.autoValidateValue = propertyDefinition.autoValidate;
    
    SCPropertyAttributes *propertyAttributes = propertyDefinition.attributes;
    if(editing && propertyDefinition.editingModeType!=SCPropertyTypeUndefined)
    {
        propertyAttributes = propertyDefinition.editingModeAttributes;
    }
    [cell.cellActions setActionsTo:propertyDefinition.cellActions overrideExisting:YES];
    [cell.cellActions setActionsTo:propertyDefinition.ownerDataStuctureDefinition.cellActions overrideExisting:NO];
    [cell setAttributesTo:propertyAttributes];
}

- (SCTableViewCell *)cellForPropertyName:(NSString *)propertyName
{
	for(SCTableViewCell *cell in self.cells)
	{
        if([cell isKindOfClass:[SCTableViewCell class]])
        {
            if([cell.boundPropertyName isEqualToString:propertyName])
                return cell;
        }
	}
	return nil;
}

- (void)reloadCellsIfNeeded
{
    for(SCTableViewCell *cell in self.cells)
    {
        if([cell isKindOfClass:[SCCustomCell class]])
        {
            [(SCCustomCell *)cell reloadControlValuesIfNeeded];
        }
    }
}

@end







@interface SCArrayOfItemsSection ()
{
    NSIndexPath *_backedUpSelectedCellIndexPath;
}

@property (nonatomic, strong) NSMutableArray *mutableItems;

- (void)setActiveDetailModel:(SCTableViewModel *)model;

- (SCTableViewCell *)unconfiguredCellAtIndex:(NSUInteger)index;
- (BOOL)fetchItemsCellExists;
- (BOOL)addNewItemCellExists;
- (BOOL)addNewItemCellExistsForEditingMode:(BOOL)editing;

- (SCTableViewModel *)modelForViewController:(UIViewController *)viewController;
- (BOOL)isViewControllerActive:(UIViewController *)viewController;
- (UIViewController *)getDetailViewControllerForCell:(SCTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath withItem:(NSObject *)item;
- (SCTableViewModel *)getCustomDetailModelForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)presentDetailViewController:(UIViewController *)detailViewController forCell:(SCTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath withPresentationMode:(SCPresentationMode)mode;


- (BOOL)shouldAddItem:(NSObject *)item itemModel:(SCTableViewModel *)itemModel;
- (BOOL)shouldUpdateItem:(NSObject *)item atIndexPath:(NSIndexPath *)indexPath itemModel:(SCTableViewModel *)itemModel;
- (BOOL)shouldDeleteItem:(NSObject *)item atIndexPath:(NSIndexPath *)indexPath;
- (BOOL)itemPassesDataFetchFilter:(NSObject *)item;
- (void)callDelegateForDidRemoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)discardTempItem;

- (void)dataStoreWillDiscardUninsertedObjects;

- (void)handleDetailViewControllerDidLoad:(UIViewController *)detailViewController;
- (void)handleDetailViewControllerWillPresent:(UIViewController *)detailViewController;
- (void)handleDetailViewControllerDidPresent:(UIViewController *)detailViewController;
- (BOOL)handleDetailViewControllerShouldDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;
- (void)handleDetailViewControllerWillDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;
- (void)handleDetailViewControllerDidDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;

- (void)handleDetailViewControllerWillGainFocus:(UIViewController *)detailViewController;
- (void)handleDetailViewControllerDidGainFocus:(UIViewController *)detailViewController;
- (void)handleDetailViewControllerWillLoseFocus:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;
- (void)handleDetailViewControllerDidLoseFocus:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;

- (void)handleDetailViewControllerDidExitEditingMode:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;

@end



@implementation SCArrayOfItemsSection

@synthesize dataStore;
@synthesize dataFetchOptions;
@synthesize autoFetchItems;
@synthesize isFetchingItems = _isFetchingItems;
@synthesize itemsAccessoryType;
@synthesize allowAddingItems;
@synthesize allowDeletingItems;
@synthesize allowMovingItems;
@synthesize allowEditDetailView;
@synthesize allowRowSelection;
@synthesize skipNewItemDetailView;
@synthesize autoSelectNewItemCell;
@synthesize cellIdentifier;
@synthesize addButtonItem;
@synthesize fetchItemsCell;
@synthesize placeholderCell;
@synthesize addNewItemCell;
@synthesize addNewItemCellExistsInNormalMode;
@synthesize addNewItemCellExistsInEditingMode;


+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle dataStore:(SCDataStore *)store
{
    return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle dataStore:store];
}


- (instancetype)init
{
	if( (self=[super init]) )
	{
        dataStore = nil;
        dataFetchOptions = nil;  // will be re-initialized when dataStore is set
        
        _isFetchingItems = FALSE;
        itemsInSync = FALSE;
        autoFetchItems = TRUE;
        
        _autoCommitDetailModelChanges = YES;
        
		activeDetailModel = nil;
		cellReuseIdentifiers = [[NSMutableArray alloc] init];
        itemsAccessoryType = UITableViewCellAccessoryDisclosureIndicator;
		allowAddingItems = TRUE;
		allowDeletingItems = TRUE;
		allowMovingItems = TRUE;
		allowEditDetailView = TRUE;
		allowRowSelection = TRUE;
        skipNewItemDetailView = FALSE;
		autoSelectNewItemCell = FALSE;
        
		// set the cellIndentifier to a unique string
        cellIdentifier = [[[NSUUID UUID] UUIDString] copy];
		
		_selectedCellIndexPath = nil;
        _backedUpSelectedCellIndexPath = nil;
		addButtonItem = nil;
		tempItem = nil;
        
        fetchItemsCell = [[SCFetchItemsCell alloc] initWithText:@"Load more..."];
        fetchItemsCell.textLabel.textAlignment = NSTextAlignmentCenter;
        placeholderCell = nil;
        addNewItemCell = nil;
        addNewItemCellExistsInNormalMode = TRUE;
        addNewItemCellExistsInEditingMode = TRUE;
	}
	
	return self;
}

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle dataStore:(SCDataStore *)store
{
    if( (self=[self initWithHeaderTitle:sectionHeaderTitle]) )
	{
		self.dataStore = store;
	}
	return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // deassociate addButtonItem
    if(self.addButtonItem && self.addButtonItem.target==self)
    {
        [self.addButtonItem setTarget:nil];
        
        if([self.ownerTableViewModel isKindOfClass:[SCArrayOfItemsModel class]])
            [(SCArrayOfItemsModel *)self.ownerTableViewModel setAddButtonItem:self.addButtonItem];
    }
}


// overrides superclass
- (void)setOwnerTableViewModel:(SCTableViewModel *)ownerTableViewModel
{
    _ownerTableViewModel = ownerTableViewModel;
    
    self.placeholderCell.ownerTableViewModel = ownerTableViewModel;
    self.addNewItemCell.ownerTableViewModel = ownerTableViewModel;
    self.fetchItemsCell.ownerTableViewModel = ownerTableViewModel;
}

- (void)setActiveDetailModel:(SCTableViewModel *)model
{
    activeDetailModel = model;
    self.ownerTableViewModel.activeDetailModel = model;
}

- (void)setDataStore:(SCDataStore *)__dataStore
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SCDataStoreWillDiscardAllUninsertedObjectsNotification object:dataStore];
    
    dataStore = __dataStore;
    // Register with store notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataStoreWillDiscardUninsertedObjects) name:SCDataStoreWillDiscardAllUninsertedObjectsNotification object:dataStore];
    
    if(!dataFetchOptions)
        dataFetchOptions = [__dataStore.defaultDataDefinition generateCompatibleDataFetchOptions];
    
    itemsInSync = FALSE;
}

- (void)dataStoreWillDiscardUninsertedObjects
{
    if(tempItem && activeDetailModel)
    {
        // commit pending values into tempItem
        for(NSUInteger i=0; i<activeDetailModel.sectionCount; i++)
        {
            SCTableViewSection *section = [activeDetailModel sectionAtIndex:i];
            [section commitCellChanges];
        }
        
        // Add temp item to the store
        if([self.dataStore validateInsertForObject:tempItem])
        {
            switch (self.dataStore.storeMode)
            {
                case SCStoreModeSynchronous:
                    [self.dataStore insertObject:tempItem];
                    break;
                    
                case SCStoreModeAsynchronous:
                    [self.dataStore asynchronousInsertObject:tempItem success:nil failure:nil noConnection:nil];
                    break;
            }
        }
        else 
        {
            // set all cells as uncommitted
            for(NSUInteger i=0; i<activeDetailModel.sectionCount; i++)
            {
                SCTableViewSection *section = [activeDetailModel sectionAtIndex:i];
                [section invalidateCellCommits];
            }
        }
    }
}

- (void)setDataFetchOptions:(SCDataFetchOptions *)options
{
    dataFetchOptions = options;
    
    if(!options.sortKey && self.dataStore)
    {
        options.sortKey = self.dataStore.defaultDataDefinition.keyPropertyName;
    }
    
    itemsInSync = FALSE;
}


// overrides superclass
- (CGFloat)heightForCellAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = UITableViewAutomaticDimension;
    if(self.sectionActions.customHeightForRowAtIndexPath)
    {
        cellHeight = self.sectionActions.customHeightForRowAtIndexPath(self, indexPath);
    }
    else
        if(self.ownerTableViewModel.sectionActions.customHeightForRowAtIndexPath)
        {
            cellHeight = self.ownerTableViewModel.sectionActions.customHeightForRowAtIndexPath(self, indexPath);
        }
    if(cellHeight != UITableViewAutomaticDimension)
        return cellHeight;
    
    cellHeight = [super heightForCellAtIndexPath:indexPath];
    
    return cellHeight;
}

// overrides superclass
- (void)setExpanded:(BOOL)expanded
{
    itemsInSync = FALSE;
    
    [super setExpanded:expanded];
}

//overrides superclass
- (NSMutableArray *)cells
{
    if([self.dataStore isKindOfClass:[SCMissingFrameworkDataStore class]])
        return [NSMutableArray arrayWithObject:[SCTableViewCell cellWithText:[(SCMissingFrameworkDataStore *)self.dataStore missingFrameworkDataDefinition].missingFrameworkMessage]];
    
    
    if( !itemsInSync && !(self.expandCollapseCell && !(self.expandCollapseCell.ownerSectionExpanded)) )
    {
        if(self.autoFetchItems)
        {
            [self fetchItems:self];
        }
        else 
        {
            [self addSpecialCellsToItems];
        }
    }
     
    itemsInSync = TRUE;             
    return cells;
}

- (void)callDidInsertItemActionWithItem:(NSObject *)item atIndexPath:(NSIndexPath *)indexPath
{
    if(self.sectionActions.didInsertItem)
        self.sectionActions.didInsertItem(self, item, indexPath);
    else if(self.ownerTableViewModel.sectionActions.didInsertItem)
        self.ownerTableViewModel.sectionActions.didInsertItem(self, item, indexPath);
}

- (void)callDidUpdateItemActionWithItem:(NSObject *)item atIndexPath:(NSIndexPath *)indexPath
{
    if(self.sectionActions.didUpdateItem)
        self.sectionActions.didUpdateItem(self, item, indexPath);
    else if(self.ownerTableViewModel.sectionActions.didUpdateItem)
        self.ownerTableViewModel.sectionActions.didUpdateItem(self, item, indexPath);
}

- (void)callDidDeleteItemActionAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.sectionActions.didDeleteItem)
        self.sectionActions.didDeleteItem(self, indexPath);
    else if(self.ownerTableViewModel.sectionActions.didDeleteItem)
        self.ownerTableViewModel.sectionActions.didDeleteItem(self, indexPath);
}

- (NSArray *)items
{
    return self.cells;
}

- (void)fetchItems:(id)sender
{
    if(self.dataFetchOptions.batchSize)
    {
        if(self.dataFetchOptions.batchCurrentOffset == self.dataFetchOptions.batchStartingOffset)
        {
            [cells removeAllObjects];
        }
    }
    
    switch(self.dataStore.storeMode)
    {
        case SCStoreModeSynchronous:
        {
            NSArray *array = [self.dataStore fetchObjectsWithOptions:self.dataFetchOptions];
         
            [self didFetchItems:array sender:sender];
        }
            break;
            
        case SCStoreModeAsynchronous:
            if(!self.mutableItems.count)
            {
                if(self.expandCollapseCell)
                    [self.mutableItems addObject:self.expandCollapseCell];
                if(self.fetchItemsCell)
                {
                    if(!self.expandCollapseCell || self.expandCollapseCell.ownerSectionExpanded)
                    {
                        [self.mutableItems addObject:self.fetchItemsCell];
                        [self.fetchItemsCell startActivityIndicator];
                    }
                }
            }
            
            _isFetchingItems = TRUE;
            [self.dataStore asynchronousFetchObjectsWithOptions:self.dataFetchOptions
            success:^(NSArray *results) 
             {
                 _isFetchingItems = FALSE;
                 [self didFetchItems:results sender:sender];
             } 
            failure:^(NSError *error)
             {
                 _isFetchingItems = FALSE;
                 [self.fetchItemsCell stopActivityIndicator];
                 
                 if(self.sectionActions.fetchItemsFromStoreFailed)
                     self.sectionActions.fetchItemsFromStoreFailed(self, error);
                 else
                     if(self.ownerTableViewModel.sectionActions.fetchItemsFromStoreFailed)
                         self.ownerTableViewModel.sectionActions.fetchItemsFromStoreFailed(self, error);
             }
            noConnection:^BOOL()
             {
                 return NO;  // call failure_block
             }];
            break;
    }
}

- (void)didFetchItems:(NSArray *)fetchedItems sender:(id)sender
{
    NSMutableArray *mutableFetchedItems = [NSMutableArray arrayWithArray:fetchedItems];
    
    if(self.sectionActions.didFetchItemsFromStore)
        self.sectionActions.didFetchItemsFromStore(self, mutableFetchedItems);
    else
        if(self.ownerTableViewModel.sectionActions.didFetchItemsFromStore)
            self.ownerTableViewModel.sectionActions.didFetchItemsFromStore(self, mutableFetchedItems);
    
    
    NSInteger insertionIndex = -1;
    if(self.dataFetchOptions.batchSize)
    {
        [self removeSpecialCellsFromItems];
        insertionIndex = cells.count;
        
        [cells addObjectsFromArray:mutableFetchedItems];
    }
    else 
    {
        cells = [[NSMutableArray alloc] initWithArray:mutableFetchedItems];
    }
    
    BOOL fetchCellExists = [self fetchItemsCellExists];
    [self addSpecialCellsToItems];
    
    
    if(self.fetchItemsCell)
        [self.fetchItemsCell didFetchItems];
    
    // Add rows to owner's tableView
    if(sender!=self || self.dataStore.storeMode==SCStoreModeAsynchronous)
    {
        NSUInteger sectionIndex = [self.ownerTableViewModel indexForSection:self];
        if(insertionIndex <= 0)
        {
            // reload section
            [self.ownerTableViewModel.tableView reloadData];
        }
        else 
        {
            [self.ownerTableViewModel.tableView beginUpdates];
            
            NSMutableArray *indexPaths = [NSMutableArray array];
            for(NSInteger i=insertionIndex; i<insertionIndex+mutableFetchedItems.count; i++)
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:sectionIndex]];
            if(indexPaths.count)
                [self.ownerTableViewModel.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
            
            if(!fetchCellExists)
            {
                // remove fetchItemsCell row if exists
                NSIndexPath *fetchItemsCellIndexPath = [self.ownerTableViewModel.tableView indexPathForCell:self.fetchItemsCell];
                if(fetchItemsCellIndexPath)
                    [self.ownerTableViewModel.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:fetchItemsCellIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
            
            [self.ownerTableViewModel.tableView endUpdates];
        }
    }
}

- (void)addSpecialCellsToItems
{
    if(self.expandCollapseCell)
    {
        [self.mutableItems insertObject:self.expandCollapseCell atIndex:0];
    }
        
    
    if(!self.expandCollapseCell || self.expandCollapseCell.ownerSectionExpanded)
    {
        if(!self.mutableItems.count && self.placeholderCell)
            [self.mutableItems addObject:self.placeholderCell];
        
        if([self fetchItemsCellExists])
        {
            [self.mutableItems addObject:self.fetchItemsCell];
        }
        
        if([self addNewItemCellExists])
            [self.mutableItems addObject:self.addNewItemCell];
    }
    
    if(self.sectionActions.didAddSpecialCells)
        self.sectionActions.didAddSpecialCells(self, cells);
    else 
        if(self.ownerTableViewModel.sectionActions.didAddSpecialCells)
            self.ownerTableViewModel.sectionActions.didAddSpecialCells(self, cells);
}

- (void)removeSpecialCellsFromItems
{
    if(self.expandCollapseCell)
        [self.mutableItems removeObjectIdenticalTo:self.expandCollapseCell];
    if(self.placeholderCell)
        [self.mutableItems removeObjectIdenticalTo:self.placeholderCell];
    if(self.fetchItemsCell)
        [self.mutableItems removeObjectIdenticalTo:self.fetchItemsCell];
    if(self.addNewItemCell)
        [self.mutableItems removeObjectIdenticalTo:self.addNewItemCell];
}

- (NSMutableArray *)mutableItems
{
    return cells;
}

- (void)setMutableItems:(NSMutableArray *)mutableItems
{
    cells = mutableItems;
}

- (void)discardTempItem
{
    [self.dataStore discardUninsertedObject:tempItem];
    tempItem = nil;
}

- (BOOL)fetchItemsCellExists
{
    BOOL exists = FALSE;
    
    if(self.fetchItemsCell && self.dataFetchOptions.batchSize>0)
    {
        if(!self.fetchItemsCell.autoHide 
           || self.mutableItems.count==(self.dataFetchOptions.batchCurrentOffset*self.dataFetchOptions.batchSize))
        {
            exists = TRUE;
        }
    }
    
    return exists;
}

- (BOOL)addNewItemCellExists
{
    return [self addNewItemCellExistsForEditingMode: (self.ownerTableViewModel.tableView.editing && self.ownerTableViewModel.viewController.editing)];
}

- (BOOL)addNewItemCellExistsForEditingMode:(BOOL)editing
{
    return self.addNewItemCell && self.allowAddingItems && ( (!editing && self.addNewItemCellExistsInNormalMode) || (editing && self.addNewItemCellExistsInEditingMode) );
}

- (void)setPlaceholderCell:(SCTableViewCell *)_placeholderCell
{
    placeholderCell = _placeholderCell;
    
    placeholderCell.ownerTableViewModel = self.ownerTableViewModel;
    placeholderCell.ownerSection = self;
    placeholderCell.selectable = FALSE;
    placeholderCell.movable = FALSE;
    placeholderCell.editable = self.addNewItemCell!=nil;
    placeholderCell.cellEditingStyle = UITableViewCellEditingStyleNone;
    placeholderCell.selectionStyle = UITableViewCellSelectionStyleNone;
    [placeholderCell markCellAsSpecial];
    
    itemsInSync = FALSE;
}

- (void)setAddNewItemCell:(SCTableViewCell *)_addNewItemCell
{
    addNewItemCell = _addNewItemCell;
    
    addNewItemCell.ownerTableViewModel = self.ownerTableViewModel;
    addNewItemCell.ownerSection = self;
    addNewItemCell.movable = FALSE;
    addNewItemCell.editable = TRUE;
    addNewItemCell.cellEditingStyle = UITableViewCellEditingStyleInsert;
    addNewItemCell.selectionStyle = UITableViewCellSelectionStyleBlue;
    [addNewItemCell markCellAsSpecial];
    
    placeholderCell.editable = addNewItemCell!=nil;
    
    itemsInSync = FALSE;
}

- (BOOL)shouldAddItem:(NSObject *)item itemModel:(SCTableViewModel *)itemModel
{
    BOOL shouldAdd = TRUE;
    if(self.sectionActions.willInsertItem)
    {
        shouldAdd = self.sectionActions.willInsertItem(self, item, itemModel);
    }
    else
        if(self.ownerTableViewModel.sectionActions.willInsertItem)
        {
            shouldAdd = self.ownerTableViewModel.sectionActions.willInsertItem(self, item, itemModel);
        }
    
    return shouldAdd;
}

- (BOOL)shouldUpdateItem:(NSObject *)item atIndexPath:(NSIndexPath *)indexPath itemModel:(SCTableViewModel *)itemModel
{
    BOOL shouldUpdate = TRUE;
    
    if(self.sectionActions.willUpdateItem)
    {
        shouldUpdate = self.sectionActions.willUpdateItem(self, item, indexPath, itemModel);
    }
    else
        if(self.ownerTableViewModel.sectionActions.willUpdateItem)
        {
            shouldUpdate = self.ownerTableViewModel.sectionActions.willUpdateItem(self, item, indexPath, itemModel);
        }
    
    return shouldUpdate;
}

- (BOOL)shouldDeleteItem:(NSObject *)item atIndexPath:(NSIndexPath *)indexPath
{
    BOOL shouldDelete = TRUE;
    
    if(self.sectionActions.willDeleteItem)
    {
        shouldDelete = self.sectionActions.willDeleteItem(self, item, indexPath);
    }
    else
        if(self.ownerTableViewModel.sectionActions.willDeleteItem)
        {
            shouldDelete = self.ownerTableViewModel.sectionActions.willDeleteItem(self, item, indexPath);
        }
    
	return shouldDelete;
}

- (BOOL)itemPassesDataFetchFilter:(NSObject *)item
{
    BOOL pass = TRUE;
    if(self.dataFetchOptions.filter && self.dataFetchOptions.filterPredicate)
    {
        NSArray *result = [[NSArray arrayWithObject:item] filteredArrayUsingPredicate:self.dataFetchOptions.filterPredicate];
        if(!result.count)
            pass = FALSE;
    }
    
    return pass;
}

- (void)setAddButtonItem:(UIBarButtonItem *)barButtonItem
{
	addButtonItem = barButtonItem;
	
	addButtonItem.target = self;
	addButtonItem.action = @selector(didTapAddButtonItem);
}

// override superclass method
- (void)editingModeWillChange
{
    if(!self.addNewItemCell || (self.addNewItemCellExistsInNormalMode==self.addNewItemCellExistsInEditingMode))
        return;
    
    NSUInteger sectionIndex = [self.ownerTableViewModel indexForSection:self];
    if([self addNewItemCellExists])
    {
        NSUInteger rowIndex = [self.mutableItems indexOfObjectIdenticalTo:self.addNewItemCell];
        [self.mutableItems removeObjectAtIndex:rowIndex];
        [self.ownerTableViewModel.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex]] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else
    {
        if(self.addNewItemCell)
        {
            [self.mutableItems addObject:self.addNewItemCell];
            [self.ownerTableViewModel.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.cellCount-1 inSection:sectionIndex]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

// override superclass method
- (SCTableViewCell *)unconfiguredCellAtIndex:(NSUInteger)index;
{
    if(self.items.count == 0)
        return nil;
    
    NSObject *item = [self.items objectAtIndex:index];
    if([item isKindOfClass:[SCTableViewCell class]])
    {
        SCTableViewCell *cell = (SCTableViewCell *)item;
        
        [cell markCellAsSpecial];
        [self setPropertiesForCell:cell withIndex:index];
        
        return cell;
    }
         
	
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:[self.ownerTableViewModel indexForSection:self]];
    
	// Check if the user provides custom identifiers for cells
	NSString *cellId = nil;
    if(self.sectionActions.reuseIdentifierForRowAtIndexPath)
    {
        cellId = self.sectionActions.reuseIdentifierForRowAtIndexPath(self, indexPath);
    }
    else 
        if(self.ownerTableViewModel.sectionActions.reuseIdentifierForRowAtIndexPath)
        {
            cellId = self.ownerTableViewModel.sectionActions.reuseIdentifierForRowAtIndexPath(self, indexPath);
        }
	if(!cellId)
	{
		cellId = self.cellIdentifier;
	}
	
	SCTableViewCell *cell = (SCTableViewCell *)[self.ownerTableViewModel.tableView 
                                                dequeueReusableCellWithIdentifier:cellId];
	
    if(cell == nil) 
	{
		// Check if the user provides their own custom cell
        if(self.sectionActions.cellForRowAtIndexPath)
        {
            cell = self.sectionActions.cellForRowAtIndexPath(self, indexPath);
        }
        else 
            if(self.ownerTableViewModel.sectionActions.cellForRowAtIndexPath)
            {
                cell = self.ownerTableViewModel.sectionActions.cellForRowAtIndexPath(self, indexPath);
            }
        
        if(cell)
            cell.customCell = TRUE;
        else 
			cell = [self createCellAtIndex:index usingCellId:cellId];
		
		cell.reuseId = cellId;
    }
    
    [self setPropertiesForCell:cell withIndex:index];
    
    return cell;
}

// override superclass method
- (SCTableViewCell *)cellAtIndex:(NSUInteger)index
{
    SCTableViewCell *cell = [self unconfiguredCellAtIndex:index];
	
    if(!cell.configured)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:[self.ownerTableViewModel indexForSection:self]];
        
        // only style the 'height' property for now, then style the whole cell after layoutSubviews
        [self.ownerTableViewModel styleCell:cell atIndexPath:indexPath onlyStylePropertyNamesInSet:[NSSet setWithObject:@"height"]];
        [self.ownerTableViewModel configureCell:cell atIndexPath:indexPath];
    }
    
    return cell;
}

// override superclass method
- (NSUInteger)indexForCell:(SCTableViewCell *)cell
{
	NSIndexPath *indexPath = [self.ownerTableViewModel.tableView indexPathForCell:cell];
	if(indexPath.section == [self.ownerTableViewModel indexForSection:self])
		return indexPath.row;
    //else
	return NSNotFound;
}

// override superclass method
- (void)reloadBoundValues
{
    [self.ownerTableViewModel clearLastReturnedCellData];
    
    itemsInSync = FALSE;
    [self.mutableItems removeAllObjects];
    [self.dataFetchOptions resetBatchOffset];
    
    
    if([self.ownerTableViewModel.viewController isKindOfClass:[SCTableViewController class]])
    {
        SCTableViewController *tableViewController = (SCTableViewController *)self.ownerTableViewModel.viewController;
        NSMutableArray *objectsArray = [tableViewController objectsForSection:(SCArrayOfObjectsSection *)self atIndex:[self.ownerTableViewModel indexForSection:self]];
        if(objectsArray.count && [self.dataStore isKindOfClass:[SCArrayStore class]])
        {
            [(SCArrayStore *)self.dataStore setObjectsArray:objectsArray];
        }
    }
}

- (SCTableViewCell *)createCellAtIndex:(NSUInteger)index usingCellId:(NSString *)cellId
{
	SCTableViewCell *cell = [[SCTableViewCell alloc] initWithStyle:SC_DefaultCellStyle reuseIdentifier:cellId];
	cell.ownerTableViewModel = self.ownerTableViewModel;
    cell.ownerSection = self;
	
	return cell;
}

- (void)setPropertiesForCell:(SCTableViewCell *)cell withIndex:(NSUInteger)index
{
	NSObject *item = [self.items objectAtIndex:index];
    
	cell.ownerTableViewModel = self.ownerTableViewModel;
    cell.ownerSection = self;
    
    if(!cell.isSpecialCell)
    {
        cell.beingReused = TRUE;
        if((NSInteger)cell.cellStyle!=-1 || [cell.textLabel.text length])  // -1 is custom cell style
        {
            cell.textLabel.text = [self textForCellAtIndex:index];
            cell.detailTextLabel.text = [self detailTextForCellAtIndex:index];
        }
        BOOL allowMoving = self.allowMovingItems && [self.dataStore validateOrderChangeForObject:item];
        cell.editable = (self.allowDeletingItems || allowMoving);
        if(self.allowDeletingItems)
            cell.cellEditingStyle = UITableViewCellEditingStyleDelete;
        else
            cell.cellEditingStyle = UITableViewCellEditingStyleNone;
        cell.movable = allowMoving;
        if(self.allowRowSelection && self.allowEditDetailView)
        {
            cell.accessoryType = self.itemsAccessoryType;
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    
    if(![item isKindOfClass:[SCTableViewCell class]])
    {
        cell.boundObject = item;
        cell.boundObjectStore = self.dataStore;
    }
    else
    {
        if(!cell.isSpecialCell)
        {
            cell.boundObject = nil;
            cell.boundObjectStore = nil;
        }
    }
    
    if([SCUtilities isBasicDataTypeClass:[item class]] || [SCUtilities isDictionaryClass:[item class]])
        cell.boundPropertyName = [SCUtilities dataStructureNameForClass:[item class]];
}

- (NSString *)textForCellAtIndex:(NSUInteger)index
{
	NSObject *object = [self.items objectAtIndex:index];
	SCDataDefinition *objectDefinition = [self.dataStore definitionForObject:object];
	
    NSString *cellText;
    
    if(objectDefinition)
    {
        cellText = [objectDefinition titleValueForObject:object];
    }
    else
        if([SCUtilities isDictionaryClass:[object class]])
        {
            NSDictionary *dictionary = (NSDictionary *)object;
            if(dictionary.count)
            {
                NSString *key = [[dictionary allKeys] objectAtIndex:0];
                cellText = [dictionary valueForKey:key];
            }
        }
    
    return cellText;
}

- (NSString *)detailTextForCellAtIndex:(NSUInteger)index
{
	NSObject *object = [self.items objectAtIndex:index];
	SCDataDefinition *objectDefinition = [self.dataStore definitionForObject:object];
	
    NSString *text = nil;
	if(objectDefinition.titlePropertyName)
	{
		text = [objectDefinition descriptionValueForObject:object];
	}
	
	return text;
}

- (void)commitAndProcessChangesForDetailModel:(SCTableViewModel *)detailModel
{
    if(!self.autoCommitDetailModelChanges)
        return;
    
    if(self.selectedCellIndexPath)
    {
        NSObject *item = [self.items objectAtIndex:self.selectedCellIndexPath.row];
        if(![self shouldUpdateItem:item atIndexPath:self.selectedCellIndexPath itemModel:detailModel])
        {
            return;
        }
    }
    
    NSUInteger sectionIndex = [self.ownerTableViewModel indexForSection:self];
    
	[detailModel commitChanges];
    
    if(!self.selectedCellIndexPath && ![self shouldAddItem:tempItem itemModel:detailModel])
    {
        [self.dataStore discardUninsertedObject:tempItem];
        [self discardTempItem];
        
        return;
    }
    
    if(self.selectedCellIndexPath)
	{
        NSObject *item = [self.items objectAtIndex:self.selectedCellIndexPath.row];
        NSIndexPath *indexPath = self.selectedCellIndexPath;
        
        // update the item
        switch (self.dataStore.storeMode)
        {
            case SCStoreModeSynchronous:
                [self.dataStore updateObject:item];
                [self callDidUpdateItemActionWithItem:item atIndexPath:indexPath];
                [self.ownerTableViewModel valueChangedForSectionAtIndex:sectionIndex];
                break;
                
            case SCStoreModeAsynchronous:
                [self.dataStore asynchronousUpdateObject:item
                success:^()
                 {
                     [self callDidUpdateItemActionWithItem:item atIndexPath:indexPath];
                     [self.ownerTableViewModel valueChangedForSectionAtIndex:sectionIndex];
                 }
                failure:^(NSError *error)
                 {
                     if(self.sectionActions.updateItemFailed)
                         self.sectionActions.updateItemFailed(self, item, error);
                     else if(self.ownerTableViewModel.sectionActions.updateItemFailed)
                         self.ownerTableViewModel.sectionActions.updateItemFailed(self, item, error);
                 }
                 noConnection:^BOOL()
                 {
                     BOOL tryAgainLater = NO;
                     
                     if(self.sectionActions.updateItemNoConnection)
                         tryAgainLater = self.sectionActions.updateItemNoConnection(self, item);
                     else if(self.ownerTableViewModel.sectionActions.updateItemNoConnection)
                         self.ownerTableViewModel.sectionActions.updateItemNoConnection(self, item);
                     
                     return tryAgainLater;
                 }
                 ];
                break;
        }
	}
	else	// newly added item
	{
        // Must release tempItem here in case user needs to do a [managedObjectContext save:] operation
		// in itemAddedForSectionAtIndexPath or didInsertRowAtIndexPath (see registerWithManagedObjectContextNotifications)
		NSObject *newItem = tempItem;
		tempItem = nil;
        
        if(newItem)
            [self commitNewItem:newItem detailModel:detailModel];
        
        [self.ownerTableViewModel valueChangedForSectionAtIndex:sectionIndex];
	}
}

- (SCTableViewModel *)modelForViewController:(UIViewController *)viewController
{
    SCTableViewModel *detailModel = nil;
    
    if([viewController isKindOfClass:[SCTableViewController class]])
    {
        detailModel = [(SCTableViewController *)viewController tableViewModel];
    }
    else 
        if([viewController isKindOfClass:[SCViewController class]])
        {
            detailModel = [(SCViewController *)viewController tableViewModel];
        }
    
    return detailModel;
}

- (UITableView *)tableViewForViewController:(UIViewController *)viewController
{
    UITableView *detailTableView = nil;
    
    if([viewController isKindOfClass:[SCTableViewController class]])
    {
        detailTableView = [(SCTableViewController *)viewController tableView];
    }
    else
        if([viewController isKindOfClass:[SCViewController class]])
        {
            detailTableView = [(SCViewController *)viewController tableView];
        }
    
    return detailTableView;
}

- (BOOL)isViewControllerActive:(UIViewController *)viewController
{
    BOOL active = FALSE;
    
    if([viewController isKindOfClass:[SCTableViewController class]])
    {
        active = [(SCTableViewController *)viewController state] == SCViewControllerStateActive;
    }
    else 
        if([viewController isKindOfClass:[SCViewController class]])
        {
            active = [(SCViewController *)viewController state] == SCViewControllerStateActive;
        }
    
    return active;
}

- (BOOL)isViewControllerFocused:(UIViewController *)viewController
{
    BOOL focused = FALSE;
    
    if([viewController isKindOfClass:[SCTableViewController class]])
    {
        focused = [(SCTableViewController *)viewController hasFocus];
    }
    else
        if([viewController isKindOfClass:[SCViewController class]])
        {
            focused = [(SCViewController *)viewController hasFocus];
        }
    
    return focused;
}

- (UIViewController *)getDetailViewControllerForCell:(SCTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath withItem:(NSObject *)item
{
    UIViewController *detailViewController = nil;
    
    BOOL newItem = !cell;
    
    if(self.sectionActions.detailViewControllerForRowAtIndexPath)
    {
        detailViewController = self.sectionActions.detailViewControllerForRowAtIndexPath(self, indexPath);
    }
    else 
        if(self.ownerTableViewModel.sectionActions.detailViewControllerForRowAtIndexPath)
        {
            detailViewController = self.ownerTableViewModel.sectionActions.detailViewControllerForRowAtIndexPath(self, indexPath);
        }
    else
    if(self.ownerTableViewModel.detailViewController && self.selectedCellIndexPath)
    {
        detailViewController = self.ownerTableViewModel.detailViewController;
    }
    
    SCDetailViewControllerOptions *detailOptions;
    if(newItem)
        detailOptions = self.newItemDetailViewControllerOptions;
    else 
        detailOptions = self.detailViewControllerOptions;
    
    if(!detailViewController)
        detailViewController = [[SCTableViewController alloc] initWithStyle:detailOptions.tableViewStyle];
    detailViewController.modalPresentationStyle = detailOptions.modalPresentationStyle;
    if(detailOptions.title)
        detailViewController.title = detailOptions.title;
    else if(!detailViewController.title)
        detailViewController.title = cell.textLabel.text;
    detailViewController.hidesBottomBarWhenPushed = detailOptions.hidesBottomBarWhenPushed;
    detailViewController.preferredContentSize = self.ownerTableViewModel.viewController.preferredContentSize;
    if([detailViewController isKindOfClass:[SCTableViewController class]] && [self.ownerTableViewModel.viewController isKindOfClass:[SCTableViewController class]])
    {
        [(SCTableViewController *)detailViewController setAutoDisableNavigationButtonsUntilViewAppears:[(SCTableViewController *)self.ownerTableViewModel.viewController autoDisableNavigationButtonsUntilViewAppears]];
    }
    
    SCTableViewModel *detailModel = nil;
    detailModel = [self getCustomDetailModelForRowAtIndexPath:indexPath];
    
    if([detailViewController isKindOfClass:[SCTableViewController class]])
    {
        SCTableViewController *viewController = (SCTableViewController *)detailViewController;
        
        if(detailModel)
            viewController.tableViewModel = detailModel;
        else 
            detailModel = viewController.tableViewModel;
    }
    else 
        if([detailViewController isKindOfClass:[SCViewController class]])
        {
            SCViewController *viewController = (SCViewController *)detailViewController;
            
            if(detailModel)
                viewController.tableViewModel = detailModel;
            else 
                detailModel = viewController.tableViewModel;
        }
    
    if(self.sectionActions.detailModelCreated)
    {
        self.sectionActions.detailModelCreated(self, detailModel, indexPath);
    }
    else 
        if(self.ownerTableViewModel.sectionActions.detailModelCreated)
        {
            self.ownerTableViewModel.sectionActions.detailModelCreated(self, detailModel, indexPath);
        }
    
    [self configureDetailViewController:detailViewController item:item newItem:newItem];
    [self.ownerTableViewModel configureDetailModel:detailModel];
	[self buildDetailTableModel:detailModel	forItem:item];
    [self configureDetailTableModel:detailModel forItem:item];
    
    return detailViewController;
}

- (void)configureDetailViewController:(UIViewController *)detailViewController item:(NSObject *)item newItem:(BOOL)newItem
{
    SCDetailViewControllerOptions *detailOptions;
    if(newItem)
        detailOptions = self.newItemDetailViewControllerOptions;
    else
        detailOptions = self.detailViewControllerOptions;
    
    if([detailViewController isKindOfClass:[SCTableViewController class]])
    {
        SCTableViewController *viewController = (SCTableViewController *)detailViewController;
        
        viewController.delegate = self;
        SCNavigationBarType navBarType = [self getDetailViewNavigationBarTypeForItem:item newItem:newItem];
        if(navBarType==SCNavigationBarTypeAuto && viewController.navigationBarType==SCNavigationBarTypeAuto)
            viewController.navigationBarType = SCNavigationBarTypeDoneRightCancelLeft;
        else
            if(viewController.navigationBarType==SCNavigationBarTypeAuto)
                viewController.navigationBarType = navBarType;
        viewController.allowEditingModeCancelButton = detailOptions.allowEditingModeCancelButton;
    }
    else
        if([detailViewController isKindOfClass:[SCViewController class]])
        {
            SCViewController *viewController = (SCViewController *)detailViewController;
            
            viewController.delegate = self;
            SCNavigationBarType navBarType = [self getDetailViewNavigationBarTypeForItem:item newItem:newItem];
            if(navBarType==SCNavigationBarTypeAuto && viewController.navigationBarType==SCNavigationBarTypeAuto)
                viewController.navigationBarType = SCNavigationBarTypeDoneRightCancelLeft;
            else
                if(viewController.navigationBarType==SCNavigationBarTypeAuto)
                    viewController.navigationBarType = navBarType;
            viewController.allowEditingModeCancelButton = detailOptions.allowEditingModeCancelButton;
        }
}

- (SCTableViewModel *)getCustomDetailModelForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SCTableViewModel *detailModel = nil;
    
    if(self.sectionActions.detailTableViewModelForRowAtIndexPath)
    {
        detailModel = self.sectionActions.detailTableViewModelForRowAtIndexPath(self, indexPath);
    }
    else 
        if(self.ownerTableViewModel.sectionActions.detailTableViewModelForRowAtIndexPath)
        {
            detailModel = self.ownerTableViewModel.sectionActions.detailTableViewModelForRowAtIndexPath(self, indexPath);
        }
    
	return detailModel;
}

- (void)presentDetailViewController:(UIViewController *)detailViewController forCell:(SCTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath withPresentationMode:(SCPresentationMode)mode
{
    [self setActiveDetailModel:[self modelForViewController:detailViewController]];
    
    BOOL customPresentation = FALSE;
    if([self isViewControllerActive:detailViewController] && (mode==SCPresentationModeAuto || mode==SCPresentationModePopover) )
    {
        customPresentation = TRUE;
        
        if([detailViewController respondsToSelector:@selector(gainFocus)])
            [(id)detailViewController gainFocus];
    }
    else
        if(self.sectionActions.customPresentDetailModel)
        {
            SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
            detailModel.tableView = [self tableViewForViewController:detailViewController]; // make sure tableView is assigned
            
            self.sectionActions.customPresentDetailModel(self, detailModel, indexPath);
            customPresentation = YES;
        }
        else
            if(self.ownerTableViewModel.sectionActions.customPresentDetailModel)
            {
                SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
                detailModel.tableView = [self tableViewForViewController:detailViewController]; // make sure tableView is assigned
                
                self.ownerTableViewModel.sectionActions.customPresentDetailModel(self, detailModel, indexPath);
                customPresentation = YES;
            }
    
    if(!customPresentation)
    {
        if([self.ownerTableViewModel isKindOfClass:[SCArrayOfItemsModel class]])
        {
            SCArrayOfItemsModel *itemsModel = (SCArrayOfItemsModel *)self.ownerTableViewModel;
            if(itemsModel.searchBar && [itemsModel.searchBar isFirstResponder])
                [itemsModel.searchBar resignFirstResponder];
        }
        
        UINavigationController *navController = self.ownerTableViewModel.viewController.navigationController;
        if(mode == SCPresentationModeAuto)
        {
            if(navController)
                mode = SCPresentationModePush;
            else 
                mode = SCPresentationModeModal;
        }
        if(mode==SCPresentationModePush && !navController)
            mode = SCPresentationModeModal;
        
        UINavigationController *detailNavController = nil;
        if(mode==SCPresentationModeModal || mode==SCPresentationModePopover)
        {
            detailNavController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
            if(navController)
            {
                detailNavController.view.backgroundColor = navController.view.backgroundColor;
                UIBarStyle barStyle = navController.navigationBar.barStyle;
                if(![SCUtilities isViewInsidePopover:self.ownerTableViewModel.viewController.view])
                    detailNavController.navigationBar.barStyle = barStyle;
                else  
                    detailNavController.navigationBar.barStyle = UIBarStyleBlack;
                detailNavController.navigationBar.tintColor = navController.navigationBar.tintColor;
            }
            
            detailNavController.preferredContentSize = detailViewController.preferredContentSize;
            detailNavController.modalPresentationStyle = detailViewController.modalPresentationStyle;
        }
        
        switch (mode) {
            case SCPresentationModePush:
                if(detailViewController.navigationController)  // this case would normally occur in a collaped UISplitViewController
                {
                    if([detailViewController respondsToSelector:@selector(gainFocus)])
                        [(id)detailViewController gainFocus];
                    [navController pushViewController:detailViewController.navigationController animated:YES];
                }
                else
                {
                    [navController pushViewController:detailViewController animated:YES];
                }
                break;
            case SCPresentationModeModal:
            {
                [self.ownerTableViewModel.viewController presentViewController:detailNavController animated:YES completion:nil];
            }
                break;
            case SCPresentationModePopover:
            {
                UIPopoverController *popoverController  = [[UIPopoverController alloc] initWithContentViewController:detailNavController];
                if([detailViewController isKindOfClass:[SCTableViewController class]])
                {
                    [(SCTableViewController *)detailViewController setPopoverController:popoverController];
                }
                else 
                    if([detailViewController isKindOfClass:[SCViewController class]])
                    {
                        [(SCViewController *)detailViewController setPopoverController:popoverController];
                    }
                detailViewController.modalInPopover = YES;
                   
                if(cell)
                {
                    [popoverController presentPopoverFromRect:cell.bounds inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                }
                else 
                {
                    if(self.addButtonItem)
                    {
                        [popoverController presentPopoverFromBarButtonItem:self.addButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                    }
                    else 
                    {
                        UIView *popoverView;
                        CGRect popoverRect;
                        if(self.addNewItemCell)
                        {
                            popoverView = self.addNewItemCell;
                            popoverRect = self.addNewItemCell.frame;
                        }
                        else 
                        {
                            popoverView = self.ownerTableViewModel.tableView;
                            popoverRect = self.ownerTableViewModel.tableView.frame;
                        }
                        [popoverController presentPopoverFromRect:popoverRect inView:popoverView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
                    }
                }
            }
                break;
                
            default:
                // Do nothing
                break;
        }
    }
}

- (void)didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
    if(![[self.ownerTableViewModel cellAtIndexPath:indexPath] isKindOfClass:[SCControlCell class]])
        [self dispatchEventSelectRowAtIndexPath:indexPath];
}

- (void)dispatchEventSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.items.count <= indexPath.row)
        return;
    
    NSObject *item = [self.items objectAtIndex:indexPath.row];
    
    if([item isKindOfClass:[SCTableViewCell class]])
    {
        if(self.addNewItemCell && self.addNewItemCell==item)
        {
            [self dispatchEventAddNewItem];
        }
        
        return;
    }
    
    if(!self.allowEditDetailView)
        return;
    
	self.selectedCellIndexPath = indexPath;
    SCTableViewCell *cell = (SCTableViewCell *)[self.ownerTableViewModel.tableView cellForRowAtIndexPath:indexPath];	
    
    UIViewController *detailViewController = [self generatedDetailViewControllerForCellAtIndexPath:indexPath];
    
    [self presentDetailViewController:detailViewController forCell:cell forRowAtIndexPath:indexPath withPresentationMode:self.detailViewControllerOptions.presentationMode];
}

// overrides superclass
- (UIViewController *)generatedDetailViewControllerForCellAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController *detailViewController;
    
    NSObject *item = [self.items objectAtIndex:indexPath.row];
    SCTableViewCell *cell = (SCTableViewCell *)[self.ownerTableViewModel.tableView cellForRowAtIndexPath:indexPath];
    
    if([cell.ibDetailViewControllerIdentifier length])
    {
        if(self.ownerTableViewModel.detailViewController)
        {
            detailViewController = self.ownerTableViewModel.detailViewController;
        }
        else
        {
            detailViewController = [SCUtilities instantiateViewControllerWithIdentifier:cell.ibDetailViewControllerIdentifier usingStoryboard:self.ownerTableViewModel.viewController.storyboard];
        }
        
        if(detailViewController)
        {
            [self configureDetailViewController:detailViewController item:item newItem:NO];
            SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
            if(self.sectionActions.detailModelCreated)
            {
                self.sectionActions.detailModelCreated(self, detailModel, indexPath);
            }
            else
                if(self.ownerTableViewModel.sectionActions.detailModelCreated)
                {
                    self.ownerTableViewModel.sectionActions.detailModelCreated(self, detailModel, indexPath);
                }
            
            [self.ownerTableViewModel configureDetailModel:detailModel];
            [self configureDetailTableModel:detailModel forItem:item];
        }
        else
            SCDebugLog(@"Warning: Could not instantiate view controller with id '%@' from Storyboard.", cell.ibDetailViewControllerIdentifier);
    }
    else
    {
        detailViewController = [self getDetailViewControllerForCell:cell forRowAtIndexPath:indexPath withItem:item];
    }
    
    return detailViewController;
}


- (void)willDeselectCellAtIndexPath:(NSIndexPath *)indexPath
{
    if(activeDetailModel)
    {
        SCTableViewModel *detailModel = [self modelForViewController:activeDetailModel.viewController];
        if(detailModel)
        {
            [self commitAndProcessChangesForDetailModel:detailModel];
            [self.ownerTableViewModel.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void)didTapAddButtonItem
{
	if(!self.allowAddingItems)
		return;
	
	[self dispatchEventAddNewItem];
}

- (void)dispatchEventAddNewItem
{
    if(_isFetchingItems)
        return;
    
	tempItem = [self createNewItem];
	if(!tempItem)
        return;
    
    // reset selectedCellIndexPath
    _backedUpSelectedCellIndexPath = self.selectedCellIndexPath;
    self.selectedCellIndexPath = nil;
    
	
	NSUInteger index = [self.ownerTableViewModel indexForSection:self];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:index];
	
    if(self.sectionActions.didCreateItem)
    {
        self.sectionActions.didCreateItem(self, tempItem);
    }
    else
        if(self.ownerTableViewModel.sectionActions.didCreateItem)
        {
            self.ownerTableViewModel.sectionActions.didCreateItem(self, tempItem);
        }

	
	if(self.ownerTableViewModel.activeCell.autoResignFirstResponder)
		[self.ownerTableViewModel.activeCell resignFirstResponder];
    
    if(self.skipNewItemDetailView)
    {
        if([self shouldAddItem:tempItem itemModel:nil])
        {
            switch (self.dataStore.storeMode)
            {
                case SCStoreModeSynchronous:
                    [self.dataStore insertObject:tempItem];
                    break;
                    
                case SCStoreModeAsynchronous:
                    [self.dataStore asynchronousInsertObject:tempItem success:nil failure:nil noConnection:nil];
                    break;
            }
            itemsInSync = FALSE;
            
            [self addCellForNewItem:tempItem];
        }
        
        [self discardTempItem];
        
        return;
    }
    
    UIViewController *detailViewController;
    if([self.ibNewItemViewControllerIdentifier length])
    {
        detailViewController = [SCUtilities instantiateViewControllerWithIdentifier:self.ibNewItemViewControllerIdentifier usingStoryboard:self.ownerTableViewModel.viewController.storyboard];
        
        if(detailViewController)
        {
            [self configureDetailViewController:detailViewController item:tempItem newItem:YES];
            SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
            [self.ownerTableViewModel configureDetailModel:detailModel];
            [self configureDetailTableModel:detailModel forItem:tempItem];
            
            // TODO: replace this with actual Storyboard segue presentation data
            detailViewController.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        else
            SCDebugLog(@"Warning: Could not instantiate view controller with id '%@' from Storyboard.", self.ibNewItemViewControllerIdentifier);
    }
    else
    {
        detailViewController = [self getDetailViewControllerForCell:nil forRowAtIndexPath:indexPath withItem:tempItem];
    }
    
    SCPresentationMode presentationMode = self.detailViewControllerOptions.presentationMode;
    if(presentationMode == SCPresentationModeAuto)
        presentationMode = SCPresentationModeModal;
    [self presentDetailViewController:detailViewController forCell:nil forRowAtIndexPath:indexPath withPresentationMode:presentationMode];
}


- (void)commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
		forCellAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleInsert)
    {
        [self dispatchEventAddNewItem];
        return;
    }
	
	[self dispatchEventRemoveRowAtIndexPath:indexPath];
}

- (void)dispatchEventRemoveRowAtIndexPath:(NSIndexPath *)indexPath
{	
    [self.ownerTableViewModel clearLastReturnedCellData];

	
    NSObject *object = [self.items objectAtIndex:indexPath.row];
    
    if(![self shouldDeleteItem:object atIndexPath:indexPath])
         return;
    
	switch (self.dataStore.storeMode)
    {
        case SCStoreModeSynchronous:
            [self.dataStore deleteObject:object];
            break;
            
        case SCStoreModeAsynchronous:
            [self.dataStore asynchronousDeleteObject:object success:nil failure:nil noConnection:nil];
            break;
    }
    
    [self.mutableItems removeObjectAtIndex:indexPath.row];
    if([self.ownerTableViewModel isKindOfClass:[SCArrayOfItemsModel class]])
    {
        // Notify the model of the item deletion
        [(SCArrayOfItemsModel *)self.ownerTableViewModel itemRemoved:object inSection:self];
    }
    
    NSUInteger minCellCount = 0;
    if([self addNewItemCellExists])
        minCellCount = 1;
    UITableViewRowAnimation deleteAnimation = UITableViewRowAnimationRight;
    if(self.items.count==minCellCount && self.placeholderCell)
        deleteAnimation = UITableViewRowAnimationNone;
    [self.ownerTableViewModel.tableView beginUpdates];
	NSArray *indexPaths = [NSArray arrayWithObjects:indexPath, nil];
	[self.ownerTableViewModel.tableView deleteRowsAtIndexPaths:indexPaths 
													 withRowAnimation:deleteAnimation];
    if(self.items.count==minCellCount && self.placeholderCell)
    {
        [self.mutableItems insertObject:self.placeholderCell atIndex:0];
        
        NSIndexPath *placeholderIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
        [self.ownerTableViewModel.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:placeholderIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.ownerTableViewModel.tableView endUpdates];
	
    self.selectedCellIndexPath = nil;
    
    if( (self.selectedCellIndexPath.section==indexPath.section &&  self.selectedCellIndexPath.row==indexPath.row) && activeDetailModel)
	{
		if([activeDetailModel.viewController isKindOfClass:[SCViewController class]])
        {
            SCViewController *viewController = (SCViewController *)activeDetailModel.viewController;
            if(viewController.hasFocus)
                [viewController dismissWithCancelValue:YES doneValue:NO];
        }
        else
            if([activeDetailModel.viewController isKindOfClass:[SCTableViewController class]])
            {
                SCTableViewController *viewController = (SCTableViewController *)activeDetailModel.viewController;
                if(viewController.hasFocus)
                    [viewController dismissWithCancelValue:YES doneValue:NO];
            }
        
       [self setActiveDetailModel:nil];
	}
    
    [self itemRemovedAtIndex:indexPath.row];
	
	// Allow some time for table view animations to finish
    [self performSelector:@selector(callDelegateForDidRemoveRowAtIndexPath:) withObject:indexPath afterDelay:0.2f];
}

- (void)itemRemovedAtIndex:(NSInteger)index
{
    // no implementation in base class
}

- (void)callDelegateForDidRemoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.sectionActions.didDeleteItem)
    {
        self.sectionActions.didDeleteItem(self, indexPath);
    }
    else
        if(self.ownerTableViewModel.sectionActions.didDeleteItem)
        {
            self.ownerTableViewModel.sectionActions.didDeleteItem(self, indexPath);
        }
}

- (NSIndexPath *)targetIndexPathForMoveFromCellAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedIndexPath
{
    if(sourceIndexPath.section != proposedIndexPath.section)
        return sourceIndexPath;
    
    if([self addNewItemCellExists] && proposedIndexPath.row==(self.cellCount-1))
        return [NSIndexPath indexPathForRow:proposedIndexPath.row-1 inSection:proposedIndexPath.section];
    
    return proposedIndexPath;
}

- (void)moveCellAtIndexPath:(NSIndexPath *)fromIndexPath 
				toIndexPath:(NSIndexPath *)toIndexPath 
{
    if(fromIndexPath.section==toIndexPath.section && fromIndexPath.row==toIndexPath.row)
		return;
	
	NSObject *item = [self.items objectAtIndex:fromIndexPath.row];
	
	if(fromIndexPath.section == toIndexPath.section)
	{
		[self.dataStore changeOrderForObject:item toOrder:toIndexPath.row subsetArray:self.items];
        
        [self.mutableItems removeObjectAtIndex:fromIndexPath.row];
        [self.mutableItems insertObject:item atIndex:toIndexPath.row];
	}
	else
	{
        [self.mutableItems removeObjectAtIndex:fromIndexPath.row];
        
        switch (self.dataStore.storeMode)
        {
            case SCStoreModeSynchronous:
                [self.dataStore deleteObject:item];
                break;
                
            case SCStoreModeAsynchronous:
                [self.dataStore asynchronousDeleteObject:item success:nil failure:nil noConnection:nil];
                break;
        }
        
		SCTableViewSection *toSection = [self.ownerTableViewModel sectionAtIndex:toIndexPath.section];
		if([toSection isKindOfClass:[SCArrayOfItemsSection class]])
			[[(SCArrayOfItemsSection *)toSection mutableItems] insertObject:item atIndex:toIndexPath.row];
	}
}

- (NSObject *)createNewItem
{
    NSObject *newItem;
    
	newItem = [self.dataStore createNewObject];
	
	return newItem;
}

- (void)buildDetailTableModel:(SCTableViewModel *)detailTableModel forItem:(NSObject *)item
{
	// Does nothing, override in subclasses
}

- (void)configureDetailTableModel:(SCTableViewModel *)detailTableModel forItem:(NSObject *)item
{
    // Does nothing, override in subclasses
}

- (SCNavigationBarType)getDetailViewNavigationBarTypeForItem:(NSObject *)item newItem:(BOOL)newItem
{
    if(newItem)
        return self.newItemDetailViewControllerOptions.navigationBarType;
    //else
    return self.detailViewControllerOptions.navigationBarType;
}

- (void)commitNewItem:(NSObject *)newItem detailModel:(SCTableViewModel *)detailModel
{
    if([SCUtilities isBasicDataTypeClass:[newItem class]])
    {
        // replace with the new data type object
        SCTableViewCell *cell = [detailModel cellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if([cell isKindOfClass:[SCControlCell class]])
            newItem = [(SCControlCell *)cell controlValue];
    }
    
    if([self.ownerTableViewModel isKindOfClass:[SCArrayOfItemsModel class]])
    {
        // Have model handle the item addition
        [(SCArrayOfItemsModel *)self.ownerTableViewModel addNewItem:newItem];
    }
    else
    {
        switch (self.dataStore.storeMode)
        {
            case SCStoreModeSynchronous:
                [self.dataStore insertObject:newItem];
                
                if([self itemPassesDataFetchFilter:newItem])
                {
                    [self removeSpecialCellsFromItems];
                    [self.mutableItems addObject:newItem];
                    if(self.dataFetchOptions.sort)
                        [self.dataFetchOptions sortMutableArray:self.mutableItems];
                    [self addSpecialCellsToItems];
                    
                    [self addCellForNewItem:newItem];
                }
                break;
                
            case SCStoreModeAsynchronous:
                [self.dataStore asynchronousInsertObject:newItem
                    success:^()
                 {
                     if([self itemPassesDataFetchFilter:newItem])
                     {
                         [self removeSpecialCellsFromItems];
                         [self.mutableItems addObject:newItem];
                         if(self.dataFetchOptions.sort)
                             [self.dataFetchOptions sortMutableArray:self.mutableItems];
                         [self addSpecialCellsToItems];
                         
                         [self addCellForNewItem:newItem];
                     }
                 }
                    failure:^(NSError *error)
                 {
                     if(self.sectionActions.insertItemFailed)
                         self.sectionActions.insertItemFailed(self, newItem, error);
                     else
                         if(self.ownerTableViewModel.sectionActions.insertItemFailed)
                             self.ownerTableViewModel.sectionActions.insertItemFailed(self, newItem, error);
                 }
                    noConnection:^BOOL()
                 {
                     BOOL tryAgainLater = NO;
                     
                     if(self.sectionActions.insertItemNoConnection)
                         tryAgainLater = self.sectionActions.insertItemNoConnection(self, newItem);
                     else if(self.ownerTableViewModel.sectionActions.insertItemNoConnection)
                         self.ownerTableViewModel.sectionActions.insertItemNoConnection(self, newItem);
                     
                     return tryAgainLater;
                 }
                 ];
                break;
        }
    }
}

- (void)addCellForNewItem:(NSObject *)newItem
{
    // make sure object passes filter first
    if(![self itemPassesDataFetchFilter:newItem])
        return;
    
    
	NSUInteger sectionIndex = [self.ownerTableViewModel indexForSection:self];
	NSUInteger newItemIndex = [self.items indexOfObjectIdenticalTo:newItem];
	
	NSIndexPath *newRowIndexPath = [NSIndexPath indexPathForRow:newItemIndex inSection:sectionIndex];
	NSArray *indexPaths = [NSArray arrayWithObject:newRowIndexPath];
    
    // Make sure to expand section if collapsed, otherwise manually add the cell
    if(self.expandCollapseCell && !self.expandCollapseCell.ownerSectionExpanded)
    {
        [self.expandCollapseCell setOwnerSectionExpanded:YES];
    }
    else
    {
        [self.ownerTableViewModel.tableView beginUpdates];
        // Remove the placeholder if exists
        NSUInteger minCellCount = 0;
        if([self addNewItemCellExists])
            minCellCount = 1;
        if(self.placeholderCell && self.items.count==(minCellCount+1))
        {
            NSUInteger placeholderIndex = [self.mutableItems indexOfObjectIdenticalTo:self.placeholderCell];
            if(placeholderIndex != NSNotFound)
            {
                [self.mutableItems removeObjectAtIndex:placeholderIndex];
            }
            NSIndexPath *placeholderIndexPath = [NSIndexPath indexPathForRow:0 inSection:sectionIndex];
            [self.ownerTableViewModel.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:placeholderIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
        UITableViewRowAnimation insertAnimation = UITableViewRowAnimationBottom;
        if(self.items.count == 1)
            insertAnimation = UITableViewRowAnimationNone;
        [self.ownerTableViewModel.tableView insertRowsAtIndexPaths:indexPaths
                                                  withRowAnimation:insertAnimation];
        [self.ownerTableViewModel.tableView endUpdates];
    }
    
	[self.ownerTableViewModel.tableView scrollToRowAtIndexPath:newRowIndexPath 
													 atScrollPosition:UITableViewScrollPositionNone
															 animated:YES];
	
	[self.ownerTableViewModel.tableView selectRowAtIndexPath:newRowIndexPath animated:TRUE 
													 scrollPosition:UITableViewScrollPositionNone];
    
    
	if(!self.autoSelectNewItemCell)
		[self.ownerTableViewModel.tableView deselectRowAtIndexPath:newRowIndexPath animated:TRUE];
	
    if(self.sectionActions.didInsertItem)
    {
        self.sectionActions.didInsertItem(self, newItem, newRowIndexPath);
    }
    else
        if(self.ownerTableViewModel.sectionActions.didInsertItem)
        {
            self.ownerTableViewModel.sectionActions.didInsertItem(self, newItem, newRowIndexPath);
        }
    
    if(self.ownerTableViewModel.detailViewController)
	{
        // Allow some time for detailViewController to become active again
        [self performSelector:@selector(loadRowAtIndexPathInDetailView:) withObject:newRowIndexPath afterDelay:0.5f];
	}
}

- (void)loadRowAtIndexPathInDetailView:(NSIndexPath *)rowIndexPath
{
    if(self.ownerTableViewModel.detailViewController && [self isViewControllerActive:self.ownerTableViewModel.detailViewController])
    {
        [self.ownerTableViewModel.tableView selectRowAtIndexPath:rowIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self dispatchEventSelectRowAtIndexPath:rowIndexPath];
    }
}

- (void)itemModified:(NSObject *)item
{
	if([SCUtilities isBasicDataTypeClass:[item class]])
    {
        // must reload array as item has been replaced (not modified)
        [self reloadBoundValues];
        [self items];
    }
    
    NSUInteger oldObjectIndex = [self.mutableItems indexOfObjectIdenticalTo:item];
    
    if(self.dataFetchOptions.sort)
        [self.dataFetchOptions sortMutableArray:self.mutableItems];
    
	NSUInteger modifiedObjectIndex = [self.mutableItems indexOfObjectIdenticalTo:item];
	
	if(modifiedObjectIndex != oldObjectIndex)
	{
		NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:modifiedObjectIndex 
													   inSection:self.selectedCellIndexPath.section];
        [self.ownerTableViewModel clearLastReturnedCellData];
		[self.ownerTableViewModel.tableView beginUpdates];
		[self.ownerTableViewModel.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:self.selectedCellIndexPath]
														 withRowAnimation:UITableViewRowAnimationLeft];
		[self.ownerTableViewModel.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
														 withRowAnimation:UITableViewRowAnimationLeft];
		[self.ownerTableViewModel.tableView endUpdates];
		
		// update selectedCellIndexPath
		self.selectedCellIndexPath = newIndexPath;
	}
	
    // Update cell
    [self.ownerTableViewModel.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:self.selectedCellIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
	if(self.ownerTableViewModel.detailViewController && [self isViewControllerActive:self.ownerTableViewModel.detailViewController] && [self isViewControllerFocused:self.ownerTableViewModel.detailViewController])
	{
		[self.ownerTableViewModel.tableView selectRowAtIndexPath:self.selectedCellIndexPath animated:NO 
														 scrollPosition:UITableViewScrollPositionNone];
	}
}


- (void)handleDetailViewControllerDidLoad:(UIViewController *)detailViewController
{
    SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
    if(detailModel)  // in case detailViewController is empty in storyboard
    {
        if(detailModel.sectionCount==0)
        {
            [self buildDetailTableModel:detailModel	forItem:detailModel.masterBoundObject];
            [self configureDetailTableModel:detailModel forItem:detailModel.masterBoundObject];
        }
        
        // NOTE: Don't place this code inside [self configureDetailTableModel] since it would be called several times unneccessarily
        if(self.sectionActions.detailModelConfigured)
        {
            self.sectionActions.detailModelConfigured(self, detailModel, self.selectedCellIndexPath);
        }
        else
            if(self.ownerTableViewModel.sectionActions.detailModelConfigured)
            {
                self.ownerTableViewModel.sectionActions.detailModelConfigured(self, detailModel, self.selectedCellIndexPath);
            }

    }
}

- (void)handleDetailViewControllerWillPresent:(UIViewController *)detailViewController
{
    NSIndexPath *indexPath;
    if(self.selectedCellIndexPath)
        indexPath = self.selectedCellIndexPath;
    else 
        indexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:[self.ownerTableViewModel indexForSection:self]];
    
    SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
    if(self.sectionActions.detailModelWillPresent)
    {
        self.sectionActions.detailModelWillPresent(self, detailModel, indexPath);
    }
    else 
        if(self.ownerTableViewModel.sectionActions.detailModelWillPresent)
        {
            self.ownerTableViewModel.sectionActions.detailModelWillPresent(self, detailModel, indexPath);
        }
}

- (void)handleDetailViewControllerDidPresent:(UIViewController *)detailViewController
{
    NSIndexPath *indexPath;
    if(self.selectedCellIndexPath)
        indexPath = self.selectedCellIndexPath;
    else 
        indexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:[self.ownerTableViewModel indexForSection:self]];
    
    SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
    if(self.sectionActions.detailModelDidPresent)
    {
        self.sectionActions.detailModelDidPresent(self, detailModel, indexPath);
    }
    else 
        if(self.ownerTableViewModel.sectionActions.detailModelDidPresent)
        {
            self.ownerTableViewModel.sectionActions.detailModelDidPresent(self, detailModel, indexPath);
        }
}

- (BOOL)handleDetailViewControllerShouldDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    NSIndexPath *indexPath;
    if(self.selectedCellIndexPath)
        indexPath = self.selectedCellIndexPath;
    else 
        indexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:[self.ownerTableViewModel indexForSection:self]];
    
    BOOL shouldDismiss = TRUE;
    if(self.sectionActions.detailModelShouldDismiss)
        shouldDismiss = self.sectionActions.detailModelShouldDismiss(self, [self modelForViewController:detailViewController], indexPath);
    else
        if(self.ownerTableViewModel.sectionActions.detailModelShouldDismiss)
            shouldDismiss = self.ownerTableViewModel.sectionActions.detailModelShouldDismiss(self, [self modelForViewController:detailViewController], indexPath);
    
    return shouldDismiss;
}

- (void)handleDetailViewControllerWillDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    if(cancelTapped && _backedUpSelectedCellIndexPath)
    {
        // restore previously selected cell
        self.selectedCellIndexPath = _backedUpSelectedCellIndexPath;
        _backedUpSelectedCellIndexPath = nil;
    }
    
    NSIndexPath *indexPath;
    if(self.selectedCellIndexPath)
        indexPath = self.selectedCellIndexPath;
    else 
        indexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:[self.ownerTableViewModel indexForSection:self]];
    
    SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
    if(self.sectionActions.detailModelWillDismiss)
    {
        self.sectionActions.detailModelWillDismiss(self, detailModel, indexPath);
    }
    else 
        if(self.ownerTableViewModel.sectionActions.detailModelWillDismiss)
        {
            self.ownerTableViewModel.sectionActions.detailModelWillDismiss(self, detailModel, indexPath);
        }
    
    if(![self.ownerTableViewModel.viewController isKindOfClass:[UITableViewController class]])
    {
        // deselect the selected cell
        if(self.selectedCellIndexPath)
            [self.ownerTableViewModel.tableView deselectRowAtIndexPath:self.selectedCellIndexPath animated:YES];
    }
    
    [self setActiveDetailModel:nil];
    
    
    // The following is required to fix an iOS 8 UISearchController bug not automatically deselecting cells
    if(cancelTapped && [self.ownerTableViewModel isKindOfClass:[SCArrayOfItemsModel class]] && self.selectedCellIndexPath)
    {
        SCArrayOfItemsModel *arrayOfItemsModel = (SCArrayOfItemsModel *)self.ownerTableViewModel;
        if(arrayOfItemsModel.searchController && arrayOfItemsModel.searchController.active)
            [arrayOfItemsModel.tableView deselectRowAtIndexPath:self.selectedCellIndexPath animated:YES];
    }
}

- (void)handleDetailViewControllerDidDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    NSIndexPath *indexPath;
    if(self.selectedCellIndexPath)
        indexPath = self.selectedCellIndexPath;
    else 
        indexPath = [NSIndexPath indexPathForRow:NSNotFound inSection:[self.ownerTableViewModel indexForSection:self]];
    
    SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
    if(self.sectionActions.detailModelDidDismiss)
    {
        self.sectionActions.detailModelDidDismiss(self, detailModel, indexPath);
    }
    else 
        if(self.ownerTableViewModel.sectionActions.detailModelDidDismiss)
        {
            self.ownerTableViewModel.sectionActions.detailModelDidDismiss(self, detailModel, indexPath);
        }
}


- (void)handleDetailViewControllerWillGainFocus:(UIViewController *)detailViewController
{
    [self handleDetailViewControllerDidLoad:detailViewController];
    [self handleDetailViewControllerWillPresent:detailViewController];
}

- (void)handleDetailViewControllerDidGainFocus:(UIViewController *)detailViewController
{
    [self handleDetailViewControllerDidPresent:detailViewController];
}

- (void)handleDetailViewControllerWillLoseFocus:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self handleDetailViewControllerWillDismiss:detailViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

- (void)handleDetailViewControllerDidLoseFocus:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    if(self.selectedCellIndexPath)
    {
        [self.ownerTableViewModel.tableView deselectRowAtIndexPath:self.selectedCellIndexPath animated:YES];
        //self.selectedCellIndexPath = nil;  // don't set here, will be set in didDismiss
    }
        
    [self handleDetailViewControllerDidDismiss:detailViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

- (void)handleDetailViewControllerDidExitEditingMode:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    if(doneTapped)
    {
        [self commitAndProcessChangesForDetailModel:[self modelForViewController:detailViewController]];
    }
}


#pragma mark -
#pragma mark SCTableViewControllerDelegate methods

- (void)tableViewControllerViewDidLoad:(SCTableViewController *)tableViewController
{
    [self handleDetailViewControllerDidLoad:tableViewController];
}

- (void)tableViewControllerWillPresent:(SCTableViewController *)tableViewController
{
    [self handleDetailViewControllerWillPresent:tableViewController];
}

- (void)tableViewControllerDidPresent:(SCTableViewController *)tableViewController
{
    [self handleDetailViewControllerDidPresent:tableViewController];
}

- (BOOL)tableViewControllerShouldDismiss:(SCTableViewController *)tableViewController
					  cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    return [self handleDetailViewControllerShouldDismiss:tableViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

- (void)tableViewControllerWillDismiss:(SCTableViewController *)tableViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self handleDetailViewControllerWillDismiss:tableViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

- (void)tableViewControllerDidDismiss:(SCTableViewController *)tableViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
	[self handleDetailViewControllerDidDismiss:tableViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}


- (void)tableViewControllerWillGainFocus:(SCTableViewController *)tableViewController
{
    [self handleDetailViewControllerWillGainFocus:tableViewController];
}

- (void)tableViewControllerDidGainFocus:(SCTableViewController *)tableViewController
{
    [self handleDetailViewControllerDidGainFocus:tableViewController];
}

- (void)tableViewControllerWillLoseFocus:(SCTableViewController *)tableViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self handleDetailViewControllerWillLoseFocus:tableViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

- (void)tableViewControllerDidLoseFocus:(SCTableViewController *)tableViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self handleDetailViewControllerDidLoseFocus:tableViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

- (void)tableViewControllerDidExitEditingMode:(SCTableViewController *)tableViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self handleDetailViewControllerDidExitEditingMode:tableViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

#pragma mark -
#pragma mark SCViewControllerDelegate methods

- (void)viewControllerViewDidLoad:(SCViewController *)viewController
{
    [self handleDetailViewControllerDidLoad:viewController];
}

- (void)viewControllerWillPresent:(SCViewController *)viewController
{
    [self handleDetailViewControllerWillPresent:viewController];
}

- (void)viewControllerDidPresent:(SCViewController *)viewController
{
    [self handleDetailViewControllerDidPresent:viewController];
}

- (BOOL)viewControllerShouldDismiss:(SCViewController *)viewController
					  cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    return [self handleDetailViewControllerShouldDismiss:viewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

- (void)viewControllerWillDismiss:(SCViewController *)viewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self handleDetailViewControllerWillDismiss:viewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

- (void)viewControllerDidDismiss:(SCViewController *)viewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
	[self handleDetailViewControllerDidDismiss:viewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}


- (void)viewControllerWillGainFocus:(SCViewController *)viewController
{
    [self handleDetailViewControllerWillGainFocus:viewController];
}

- (void)viewControllerDidGainFocus:(SCViewController *)viewController
{
    [self handleDetailViewControllerDidGainFocus:viewController];
}

- (void)viewControllerWillLoseFocus:(SCViewController *)viewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self handleDetailViewControllerWillLoseFocus:viewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

- (void)viewControllerDidLoseFocus:(SCViewController *)viewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self handleDetailViewControllerDidLoseFocus:viewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

- (void)viewControllerDidExitEditingMode:(SCViewController *)viewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self handleDetailViewControllerDidExitEditingMode:viewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

@end










@implementation SCArrayOfObjectsSection


+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle items:(NSMutableArray *)sectionItems itemsDefinition:(SCDataDefinition *)definition
{
	return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle items:sectionItems itemsDefinition:definition];
}


- (instancetype)init
{
	if( (self=[super init]) )
	{
		// initialize here
	}
	
	return self;
}

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle items:(NSMutableArray *)sectionItems itemsDefinition:(SCDataDefinition *)definition
{
    SCArrayStore *arrayStore = [SCArrayStore storeWithObjectsArray:sectionItems defaultDefiniton:definition];
    
    self = [self initWithHeaderTitle:sectionHeaderTitle dataStore:arrayStore];
    
	return self;
}


//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCArrayOfObjectsAttributes class]])
		return;
	
	SCArrayOfObjectsAttributes *objectsArrayAttributes = (SCArrayOfObjectsAttributes *)attributes;
	
    if(objectsArrayAttributes.objectsFetchOptions)
        self.dataFetchOptions = objectsArrayAttributes.objectsFetchOptions;
    
	self.allowAddingItems = objectsArrayAttributes.allowAddingItems;
	self.allowDeletingItems = objectsArrayAttributes.allowDeletingItems;
	self.allowMovingItems = objectsArrayAttributes.allowMovingItems;
	self.allowEditDetailView = objectsArrayAttributes.allowEditingItems;
    if([objectsArrayAttributes.placeholderuiElement isKindOfClass:[SCTableViewCell class]])
        self.placeholderCell = (SCTableViewCell *)objectsArrayAttributes.placeholderuiElement;
    if([objectsArrayAttributes.addNewObjectuiElement isKindOfClass:[SCTableViewCell class]])
        self.addNewItemCell = (SCTableViewCell *)objectsArrayAttributes.addNewObjectuiElement;
    if([objectsArrayAttributes.ibPlaceholderText length] && !objectsArrayAttributes.placeholderuiElement)
        self.placeholderCell = [SCTableViewCell cellWithText:objectsArrayAttributes.ibPlaceholderText textAlignment:objectsArrayAttributes.ibPlaceholderTextAlignment];
    if([objectsArrayAttributes.ibAddNewObjectText length] && !objectsArrayAttributes.addNewObjectuiElement)
        self.addNewItemCell = [SCTableViewCell cellWithText:objectsArrayAttributes.ibAddNewObjectText textAlignment:NSTextAlignmentCenter];
    self.addNewItemCellExistsInNormalMode = objectsArrayAttributes.addNewObjectuiElementExistsInNormalMode;
    self.addNewItemCellExistsInEditingMode = objectsArrayAttributes.addNewObjectuiElementExistsInEditingMode;
    
    [self.sectionActions setActionsTo:objectsArrayAttributes.sectionActions overrideExisting:NO];
}

// override superclass method
- (void)buildDetailTableModel:(SCTableViewModel *)detailTableModel forItem:(NSObject *)item
{
    [detailTableModel clear];
    
    BOOL newObject;
    if(self.selectedCellIndexPath)
        newObject = FALSE;
    else
        newObject = TRUE;
    
    [detailTableModel generateSectionsForObject:item withDataStore:self.dataStore newObject:newObject];
}

- (void)configureDetailTableModel:(SCTableViewModel *)detailTableModel forItem:(NSObject *)item
{
    detailTableModel.masterBoundObject = item;
    detailTableModel.masterBoundObjectStore = self.dataStore;
    
    for(NSUInteger i=0; i<detailTableModel.sectionCount; i++)
    {
        SCTableViewSection *section = [detailTableModel sectionAtIndex:i];
        
        if([section isKindOfClass:[SCObjectSection class]])
        {
            [(SCObjectSection *)section setBoundObject:item withStore:self.dataStore autoGenerateCells:NO]; // we don't want to auto generate since the cells are already generated for the item (either in code or more importantly in IB)
        }
        for(NSUInteger j=0; j<section.cellCount; j++)
        {
            SCTableViewCell *cell = [section cellAtIndex:j];
            
            if(![cell isKindOfClass:[SCObjectCell class]])
            {
                cell.boundObject = item;
                cell.boundObjectStore = self.dataStore;
            }
            
            [cell setDetailViewControllerOptions:self.detailViewControllerOptions];
        }
    }
}

// override superclass method
- (SCNavigationBarType)getDetailViewNavigationBarTypeForItem:(NSObject *)item newItem:(BOOL)newItem
{
    SCDataDefinition *itemDefinition = [self.dataStore definitionForObject:item];
    if(itemDefinition.requireEditingModeToEditPropertyValues)
    {
        if(self.selectedCellIndexPath)
            return SCNavigationBarTypeEditRight;
        else 
            return SCNavigationBarTypeDoneRightCancelLeft;
    }
    //else
    return [super getDetailViewNavigationBarTypeForItem:item newItem:newItem];
}

//override superclass
- (void)handleDetailViewControllerWillPresent:(UIViewController *)detailViewController
{
    if(!self.selectedCellIndexPath)  // newly added item
    {
        if(tempItem)
        {
            SCDataDefinition *tempItemDefinition = [self.dataStore definitionForObject:tempItem];
            if(tempItemDefinition.requireEditingModeToEditPropertyValues)
                [[self modelForViewController:detailViewController] setTableViewEditing:TRUE animated:NO];
        }
    }
    
    [super handleDetailViewControllerWillPresent:detailViewController];
}

//override superclass
- (void)handleDetailViewControllerDidPresent:(UIViewController *)detailViewController
{
    SCTableViewCell *firstCell = [[self modelForViewController:detailViewController] cellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    if(!firstCell.valueIsValid)
        [firstCell becomeFirstResponder];
    
    [super handleDetailViewControllerDidPresent:detailViewController];
}

// override superclass method
- (void)handleDetailViewControllerWillDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
	SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
    
    // Check if tempItem is nil, which would happen if the application enters the background
	// and then comes back to the foreground.
	if(tempItem==nil && !self.selectedCellIndexPath)
	{
		for(NSUInteger i=0; i<detailModel.sectionCount; i++)
		{
			SCTableViewSection *section = [detailModel sectionAtIndex:i];
			if(section.boundObject && [section isKindOfClass:[SCObjectSection class]])
			{
				tempItem = section.boundObject;
				break;
			}
			
		}
		if(!tempItem)
			return;
	}
    
    
    if( cancelTapped
       || (self.selectedCellIndexPath && self.dataStore.defaultDataDefinition.requireEditingModeToEditPropertyValues) )
	{
        [detailModel rollbackToInitialCellValues];
        
		[self.dataStore discardUninsertedObject:tempItem];
        [self discardTempItem];
        
        [super handleDetailViewControllerWillDismiss:detailViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
        
        if(self.ownerTableViewModel.detailViewController)
        {
            NSIndexPath *selectedRowIndexPath = [self.ownerTableViewModel.tableView indexPathForSelectedRow];
            if(selectedRowIndexPath && !self.ownerTableViewModel.detailViewController)
                [self dispatchEventSelectRowAtIndexPath:selectedRowIndexPath];
        }
        
		return;
	}
    
    [self commitAndProcessChangesForDetailModel:[self modelForViewController:detailViewController]];
	
	[self discardTempItem];
    
    
    // call the delegates
    [super handleDetailViewControllerWillDismiss:detailViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}

//override superclass
- (void)handleDetailViewControllerDidDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
	[super handleDetailViewControllerDidDismiss:detailViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
	
	if(!cancelTapped && self.selectedCellIndexPath)
	{
		// Check if the owner model is an SCArrayOfItemsModel
		if([self.ownerTableViewModel isKindOfClass:[SCArrayOfItemsModel class]])
		{
			// Have model handle the item modification
			[(SCArrayOfItemsModel *)self.ownerTableViewModel 
				itemModified:[self.items objectAtIndex:self.selectedCellIndexPath.row]
					inSection:self];
		}
		else 
		{
			[self itemModified:[self.items objectAtIndex:self.selectedCellIndexPath.row]];
		}
	}
}

@end







@implementation SCArrayOfStringsSection


+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle items:(NSMutableArray *)sectionItems
{
    return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle items:sectionItems];
}


- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle items:(NSMutableArray *)sectionItems
{
    SCArrayStore *stringsArrayStore = [SCArrayStore storeWithObjectsArray:sectionItems defaultDefiniton:[SCStringDefinition definition]];
    
    if( (self = [self initWithHeaderTitle:sectionHeaderTitle dataStore:stringsArrayStore]) )
    {
        self.allowEditDetailView = FALSE;
        self.itemsAccessoryType = UITableViewCellAccessoryNone;
    }
    
    return self;
}

@end








@interface SCSelectionSection ()

- (void)buildSelectedItemsIndexesFromString:(NSString *)string;
- (NSString *)buildStringFromSelectedItemsIndexes;

- (void)deselectLastSelectedRow;
- (void)dismissViewController;

@end



@implementation SCSelectionSection

@synthesize allowMultipleSelection;
@synthesize allowNoSelection;
@synthesize maximumSelections;
@synthesize autoDismissViewController;

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle
                 boundObject:(NSObject *)object 
   selectedIndexPropertyName:(NSString *)propertyName 
                       items:(NSArray *)sectionItems
{
	return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle boundObject:object selectedIndexPropertyName:propertyName items:sectionItems];
}

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle
                 boundObject:(NSObject *)object selectedIndexesPropertyName:(NSString *)propertyName 
                       items:(NSArray *)sectionItems allowMultipleSelection:(BOOL)multipleSelection
{
	return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle 
                                         boundObject:object selectedIndexesPropertyName:propertyName 
                                               items:sectionItems 
								allowMultipleSelection:multipleSelection];
}

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle
                 boundObject:(NSObject *)object 
                    selectionStringPropertyName:(NSString *)propertyName 
                       items:(NSArray *)sectionItems
{
	return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle 
                                         boundObject:object 
                         selectionStringPropertyName:propertyName 
                                               items:sectionItems];
}

- (instancetype)init
{
	if( (self=[super init]) )
	{
		boundToNSNumber = FALSE;
		boundToNSString = FALSE;
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
		_selectedItemsIndexes = [[NSMutableSet alloc] init];
        
        _selectedCellTextColor = [UIColor colorWithRed:50.0f/255 green:79.0f/255 blue:133.0f/255 alpha:1];
        _deselectedCellTextColor = [UIColor blackColor];
	}
	
	return self;
}

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle
              boundObject:(NSObject *)object 
                selectedIndexPropertyName:(NSString *)propertyName 
                    items:(NSArray *)sectionItems
{
	if( (self = [self initWithHeaderTitle:sectionHeaderTitle items:[NSMutableArray arrayWithArray:sectionItems]]) )
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

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle
              boundObject:(NSObject *)object selectedIndexesPropertyName:(NSString *)propertyName 
                    items:(NSArray *)sectionItems allowMultipleSelection:(BOOL)multipleSelection
{
	if( (self = [self initWithHeaderTitle:sectionHeaderTitle items:[NSMutableArray arrayWithArray:sectionItems]]) )
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

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle
              boundObject:(NSObject *)object 
                selectionStringPropertyName:(NSString *)propertyName 
                    items:(NSArray *)sectionItems
{
	if( (self = [self initWithHeaderTitle:sectionHeaderTitle items:[NSMutableArray arrayWithArray:sectionItems]]) )
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
            if(([SCUtilities isStringClass:[self.boundValue class]] || !self.boundValue) && self.items)
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

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCSelectionAttributes class]])
		return;
	
	SCSelectionAttributes *selectionAttributes = (SCSelectionAttributes *)attributes;
	
    self.dataFetchOptions = selectionAttributes.selectionItemsFetchOptions;
	self.allowMultipleSelection = selectionAttributes.allowMultipleSelection;
	self.allowNoSelection = selectionAttributes.allowNoSelection;
	self.maximumSelections = selectionAttributes.maximumSelections;
	self.allowAddingItems = selectionAttributes.allowAddingItems;
    self.allowDeletingItems = selectionAttributes.allowDeletingItems;
    self.allowMovingItems = selectionAttributes.allowMovingItems;
    self.allowEditDetailView = selectionAttributes.allowEditingItems;
    self.autoDismissViewController = selectionAttributes.autoDismissDetailView;
    if([selectionAttributes.placeholderuiElement isKindOfClass:[SCTableViewCell class]])
        self.placeholderCell = (SCTableViewCell *)selectionAttributes.placeholderuiElement;
    if([selectionAttributes.addNewObjectuiElement isKindOfClass:[SCTableViewCell class]])
        self.addNewItemCell = (SCTableViewCell *)selectionAttributes.addNewObjectuiElement;
}

// override superclass method
- (SCTableViewCell *)cellAtIndex:(NSUInteger)index
{
	SCTableViewCell *cell = [super cellAtIndex:index];
	
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	
	return cell;
}

- (void)configureCellForDisplay:(SCTableViewCell *)cell atIndex:(NSUInteger)index
{
    if([self.selectedItemsIndexes containsObject:[NSNumber numberWithUnsignedInteger:index]])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = self.selectedCellTextColor;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = self.deselectedCellTextColor;
    }
}

- (void)deselectLastSelectedRow
{
	[self.ownerTableViewModel.tableView deselectRowAtIndexPath:lastSelectedRowIndexPath
															 animated:YES];
}

// override superclass method
- (void)itemRemovedAtIndex:(NSInteger)index
{
    [super itemRemovedAtIndex:index];
    
    // deselect removed row (if selected)
    NSNumber *itemIndex = [NSNumber numberWithInteger:index];
    if([self.selectedItemsIndexes containsObject:itemIndex])
    {
        [self.selectedItemsIndexes removeObject:itemIndex];
    }
    
    // update all indexes below the removed index
    NSMutableSet *oldIndexes = [NSMutableSet setWithSet:self.selectedItemsIndexes];
    [self.selectedItemsIndexes removeAllObjects];
    for(NSNumber *objectIndex in oldIndexes)
    {
        NSInteger intObjectIndex = [objectIndex integerValue];
        if(intObjectIndex > index)
            intObjectIndex--;
        
        [self.selectedItemsIndexes addObject:[NSNumber numberWithInteger:intObjectIndex]];
    }
    
    if(boundToNSNumber)
        self.boundValue = self.selectedItemIndex;
    else
        if(boundToNSString)
            self.boundValue = [self buildStringFromSelectedItemsIndexes];
}

// override superclass method
- (void)moveCellAtIndexPath:(NSIndexPath *)fromIndexPath 
				toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *selectedObjects = [NSMutableArray array];
    for(NSNumber *objectIndex in self.selectedItemsIndexes)
        [selectedObjects addObject:[self.items objectAtIndex:[objectIndex intValue]]];
    
    [super moveCellAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    
    // Update the selectedItemsIndexes with the new index values
    [self.selectedItemsIndexes removeAllObjects];
    for(NSObject *selectedObject in selectedObjects)
    {
        NSInteger index = [self.items indexOfObjectIdenticalTo:selectedObject];
        [self.selectedItemsIndexes addObject:[NSNumber numberWithInteger:index]];
    }
    
    if(boundToNSNumber)
        self.boundValue = self.selectedItemIndex;
    else
        if(boundToNSString)
            self.boundValue = [self buildStringFromSelectedItemsIndexes];
}

// override superclass method
- (void)didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedCellIndexPath = indexPath;
	
    [self dispatchEventSelectRowAtIndexPath:indexPath];
}

// override superclass method
- (void)dispatchEventSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
    if([self addNewItemCellExists] && indexPath.row==(self.cellCount-1))
    {
        [self dispatchEventAddNewItem];
        return;
    }
    
    if(self.allowEditDetailView && self.ownerTableViewModel.tableView.editing)
    {
        [super dispatchEventSelectRowAtIndexPath:indexPath];
        return;
    }
    
	UITableView *tableView = self.ownerTableViewModel.tableView;
	NSNumber *itemIndex = [NSNumber numberWithInteger:indexPath.row];
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
		selectedCell.textLabel.textColor = self.deselectedCellTextColor;
		[self.ownerTableViewModel valueChangedForSectionAtIndex:indexPath.section];
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
		//uncheck old cell
		NSUInteger oldRowIndex =  [(NSNumber *)[self.selectedItemsIndexes anyObject] intValue];
		NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:oldRowIndex inSection:indexPath.section];
		[self.selectedItemsIndexes removeAllObjects];
		UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
		oldCell.accessoryType = UITableViewCellAccessoryNone;
		oldCell.textLabel.textColor = self.deselectedCellTextColor;
	}
	
	//check selected cell
	[self.selectedItemsIndexes addObject:itemIndex];
	if(boundToNSNumber)
		self.boundValue = self.selectedItemIndex;
	else
		if(boundToNSString)
			self.boundValue = [self buildStringFromSelectedItemsIndexes];
	selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
	selectedCell.textLabel.textColor = self.selectedCellTextColor;
	
	[self.ownerTableViewModel valueChangedForSectionAtIndex:indexPath.section];
	
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
	if([self.ownerTableViewModel.viewController isKindOfClass:[SCTableViewController class]])
	{
		[(SCTableViewController *)self.ownerTableViewModel.viewController 
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










@interface SCObjectSelectionSection ()

- (NSMutableSet *)boundMutableSet;
- (void)deselectLastSelectedRow;
- (void)dismissViewController;

- (void)selectedItemsIndexesModified;

@end



@implementation SCObjectSelectionSection

@synthesize selectedItemsIndexes;
@synthesize allowMultipleSelection;
@synthesize allowNoSelection;
@synthesize maximumSelections;
@synthesize autoDismissViewController;
@synthesize intermediateEntityDefinition;


+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle
                 boundObject:(NSObject *)object selectedObjectPropertyName:(NSString *)propertyName
                selectionItemsStore:(SCDataStore *)store
{
    return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle boundObject:object selectedObjectPropertyName:propertyName selectionItemsStore:store];
}

+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle
                 boundObject:(NSObject *)object selectedObjectPropertyName:(NSString *)propertyName
                       items:(NSArray *)sectionItems itemsDefintion:(SCDataDefinition *)definition
{
	return [[[self class] alloc] initWithHeaderTitle:sectionHeaderTitle boundObject:object selectedObjectPropertyName:propertyName items:sectionItems itemsDefintion:definition];
}

- (instancetype)init
{
	if( (self=[super init]) )
	{
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
        
        _selectedCellTextColor = [UIColor colorWithRed:50.0f/255 green:79.0f/255 blue:133.0f/255 alpha:1];
        _deselectedCellTextColor = [UIColor blackColor];
        
        intermediateEntityDefinition = nil;
	}
	
	return self;
}

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle
              boundObject:(NSObject *)object selectedObjectPropertyName:(NSString *)propertyName
            selectionItemsStore:(SCDataStore *)store
{
    if( (self = [self initWithHeaderTitle:sectionHeaderTitle dataStore:store]) )
    {
        boundObject = object;
        
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

- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle
              boundObject:(NSObject *)object selectedObjectPropertyName:(NSString *)propertyName
                    items:(NSArray *)sectionItems itemsDefintion:(SCDataDefinition *)definition
{
	SCArrayStore *store = [SCArrayStore storeWithObjectsArray:[NSMutableArray arrayWithArray:sectionItems] defaultDefiniton:definition];
    
    self = [self initWithHeaderTitle:sectionHeaderTitle boundObject:object selectedObjectPropertyName:propertyName selectionItemsStore:store];
    
    return self;
}




- (NSMutableSet *)boundMutableSet
{
    return (NSMutableSet *)self.boundValue;
}

- (void)selectedItemsIndexesModified
{
    if(self.commitCellChangesLive)
        [self commitCellChanges];
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCObjectSelectionAttributes class]])
		return;
	
	SCObjectSelectionAttributes *objectSelectionAttributes = (SCObjectSelectionAttributes *)attributes;
    
    if(objectSelectionAttributes.selectionItemsStore)
        self.dataStore = objectSelectionAttributes.selectionItemsStore;
    
    self.intermediateEntityDefinition = objectSelectionAttributes.intermediateEntityDefinition;
    
    self.allowMultipleSelection = objectSelectionAttributes.allowMultipleSelection;
	self.allowNoSelection = objectSelectionAttributes.allowNoSelection;
	self.maximumSelections = objectSelectionAttributes.maximumSelections;
	self.allowAddingItems = objectSelectionAttributes.allowAddingItems;
    self.allowDeletingItems = objectSelectionAttributes.allowDeletingItems;
    self.allowMovingItems = objectSelectionAttributes.allowMovingItems;
    self.allowEditDetailView = objectSelectionAttributes.allowEditingItems;
    self.autoDismissViewController = objectSelectionAttributes.autoDismissDetailView;
    if([objectSelectionAttributes.placeholderuiElement isKindOfClass:[SCTableViewCell class]])
        self.placeholderCell = (SCTableViewCell *)objectSelectionAttributes.placeholderuiElement;
    if([objectSelectionAttributes.addNewObjectuiElement isKindOfClass:[SCTableViewCell class]])
        self.addNewItemCell = (SCTableViewCell *)objectSelectionAttributes.addNewObjectuiElement;
    if([objectSelectionAttributes.ibPlaceholderText length] && !objectSelectionAttributes.placeholderuiElement)
        self.placeholderCell = [SCTableViewCell cellWithText:objectSelectionAttributes.ibPlaceholderText textAlignment:objectSelectionAttributes.ibPlaceholderTextAlignment];
    if([objectSelectionAttributes.ibAddNewObjectText length] && !objectSelectionAttributes.addNewObjectuiElement)
        self.addNewItemCell = [SCTableViewCell cellWithText:objectSelectionAttributes.ibAddNewObjectText textAlignment:NSTextAlignmentCenter];
    
    // Synchronize selectedItemsIndexes
    [self reloadBoundValues];
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

- (void)commitCellChanges
{
    [super commitCellChanges];
    
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

// override superclass method
- (SCTableViewCell *)cellAtIndex:(NSUInteger)index
{
	SCTableViewCell *cell = [super cellAtIndex:index];
	
	cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	
	return cell;
}

- (void)configureCellForDisplay:(SCTableViewCell *)cell atIndex:(NSUInteger)index
{
    if([self.selectedItemsIndexes containsObject:[NSNumber numberWithUnsignedInteger:index]])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        cell.textLabel.textColor = self.selectedCellTextColor;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.textColor = self.deselectedCellTextColor;
    }
}

- (void)deselectLastSelectedRow
{
	[self.ownerTableViewModel.tableView deselectRowAtIndexPath:lastSelectedRowIndexPath
															 animated:YES];
}

// override superclass method
- (void)itemRemovedAtIndex:(NSInteger)index
{
    [super itemRemovedAtIndex:index];
    
    // deselect removed row (if selected)
    NSNumber *itemIndex = [NSNumber numberWithInteger:index];
    if([self.selectedItemsIndexes containsObject:itemIndex])
    {
        [self.selectedItemsIndexes removeObject:itemIndex];
    }
    
    // update all indexes below the removed index
    NSMutableSet *oldIndexes = [NSMutableSet setWithSet:self.selectedItemsIndexes];
    [self.selectedItemsIndexes removeAllObjects];
    for(NSNumber *objectIndex in oldIndexes)
    {
        NSInteger intObjectIndex = [objectIndex integerValue];
        if(intObjectIndex > index)
            intObjectIndex--;
        
        [self.selectedItemsIndexes addObject:[NSNumber numberWithInteger:intObjectIndex]];
    }
    
    [self selectedItemsIndexesModified];
}

// override superclass method
- (void)moveCellAtIndexPath:(NSIndexPath *)fromIndexPath 
				toIndexPath:(NSIndexPath *)toIndexPath
{
    NSMutableArray *selectedObjects = [NSMutableArray array];
    for(NSNumber *objectIndex in self.selectedItemsIndexes)
        [selectedObjects addObject:[self.items objectAtIndex:[objectIndex intValue]]];
    
    [super moveCellAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
    
    // Update the selectedItemsIndexes with the new index values
    [self.selectedItemsIndexes removeAllObjects];
    for(NSObject *selectedObject in selectedObjects)
    {
        NSInteger index = [self.items indexOfObjectIdenticalTo:selectedObject];
        [self.selectedItemsIndexes addObject:[NSNumber numberWithInteger:index]];
    }
    [self selectedItemsIndexesModified];
}

// override superclass method
- (void)didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedCellIndexPath = indexPath;
	
    [self dispatchEventSelectRowAtIndexPath:indexPath];
}

// override superclass method
- (void)dispatchEventSelectRowAtIndexPath:(NSIndexPath *)indexPath
{	
    if([self addNewItemCellExists] && indexPath.row==(self.cellCount-1))
    {
        [self dispatchEventAddNewItem];
        return;
    }
    
    if(self.allowEditDetailView && self.ownerTableViewModel.tableView.editing)
    {
        [super dispatchEventSelectRowAtIndexPath:indexPath];
        return;
    }
    
	UITableView *tableView = self.ownerTableViewModel.tableView;
	NSNumber *itemIndex = [NSNumber numberWithInteger:indexPath.row];
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
		selectedCell.textLabel.textColor = self.deselectedCellTextColor;
		[self.ownerTableViewModel valueChangedForSectionAtIndex:indexPath.section];
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
		//uncheck old cell
		NSUInteger oldRowIndex =  [(NSNumber *)[self.selectedItemsIndexes anyObject] intValue];
		NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:oldRowIndex inSection:indexPath.section];
		[self.selectedItemsIndexes removeAllObjects];
		UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
		oldCell.accessoryType = UITableViewCellAccessoryNone;
		oldCell.textLabel.textColor = self.deselectedCellTextColor;
	}
	
	//check selected cell
	[self.selectedItemsIndexes addObject:itemIndex];
	[self selectedItemsIndexesModified];
    
	selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
	selectedCell.textLabel.textColor = self.selectedCellTextColor;
	
	[self.ownerTableViewModel valueChangedForSectionAtIndex:indexPath.section];
	
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
	if([self.ownerTableViewModel.viewController isKindOfClass:[SCTableViewController class]])
	{
		[(SCTableViewController *)self.ownerTableViewModel.viewController 
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








