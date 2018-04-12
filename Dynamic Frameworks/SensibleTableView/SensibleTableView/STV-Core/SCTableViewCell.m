/*
 *  SCTableViewCell.m
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

#import "SCTableViewCell.h"

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "SCGlobals.h"
#import "SCTableViewModel.h"
#import "SCStringDefinition.h"
#import "SCArrayStore.h"
#import "SCImageView.h"



// Encoding constants

#define kBoundPropertyNameKey @"boundPropertyName"
#define KibDetailViewControllerIdentifier    @"ibDetailViewControllerIdentifier"


@interface SCTableViewCell()

@property (nonatomic, strong) NSObject *initialBoundValue;


- (void)setActiveDetailModel:(SCTableViewModel *)model;

- (void)didLayoutSubviews;

- (SCTableViewModel *)modelForViewController:(UIViewController *)viewController;
- (BOOL)isViewControllerActive:(UIViewController *)viewController;
- (SCTableViewModel *)getCustomDetailModelForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)presentDetailViewController:(UIViewController *)detailViewController forCell:(SCTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath withPresentationMode:(SCPresentationMode)mode;

- (void)handleDetailViewControllerWillPresent:(UIViewController *)detailViewController;
- (void)handleDetailViewControllerDidPresent:(UIViewController *)detailViewController;
- (BOOL)handleDetailViewControllerShouldDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;
- (void)handleDetailViewControllerWillDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;
- (void)handleDetailViewControllerDidDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;

- (void)handleDetailViewControllerWillGainFocus:(UIViewController *)detailViewController;
- (void)handleDetailViewControllerDidGainFocus:(UIViewController *)detailViewController;
- (void)handleDetailViewControllerWillLoseFocus:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;
- (void)handleDetailViewControllerDidLoseFocus:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped;


@end


@implementation SCTableViewCell

@synthesize ownerTableViewModel;
@synthesize ownerSection;
@synthesize cellActions = _cellActions;
@synthesize boundPropertyDataType;
@synthesize height = _height;
@synthesize editable;
@synthesize movable;
@synthesize selectable;
@synthesize enabled;
@synthesize detailCellsImageViews;
@synthesize badgeView;
@synthesize autoDeselect;
@synthesize autoResignFirstResponder;
@synthesize cellEditingStyle;
@synthesize valueRequired;
@synthesize autoValidateValue;
@synthesize commitChangesLive;
@synthesize needsCommit;
@synthesize beingReused;
@synthesize customCell;
@synthesize reuseId;
@synthesize configured;
@synthesize isSpecialCell;
@synthesize themeStyle;

+ (instancetype)cell
{
	return [[[self class] alloc] initWithStyle:SC_DefaultCellStyle reuseIdentifier:nil]; 
}

+ (instancetype)cellWithStyle:(UITableViewCellStyle)style
{
    return [[[self class] alloc] initWithStyle:style reuseIdentifier:nil]; 
}

+ (instancetype)cellWithText:(NSString *)cellText
{
	return [[[self class] alloc] initWithText:cellText];
}

+ (instancetype)cellWithText:(NSString *)cellText textAlignment:(NSTextAlignment)textAlignment
{
    return [[[self class] alloc] initWithText:cellText textAlignment:textAlignment];
}

+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object boundPropertyName:(NSString *)propertyName;
{
	return [[[self class] alloc] initWithText:cellText boundObject:object boundPropertyName:propertyName];
}

+ (instancetype)cellWithCell:(UITableViewCell *)cell
{
	// Game plan: since UITableViewCell doesn't support NSCopying, simply archive it then unarchive it back into our object
    
    // backup original class value before modifying
    Class originalCellClass = [NSKeyedUnarchiver classForClassName:NSStringFromClass([cell class])];
    [NSKeyedUnarchiver setClass:[self class] forClassName:NSStringFromClass([cell class])];
    
    NSData *cellData = [NSKeyedArchiver archivedDataWithRootObject:cell];
    id STVCell = [NSKeyedUnarchiver unarchiveObjectWithData:cellData];
    
    // Required to fix a suspected iOS bug where the cell's image in not correctly archived/unarchived
    [(UITableViewCell *)STVCell imageView].image = cell.imageView.image;
    
    // Restore original class value
    [NSKeyedUnarchiver setClass:originalCellClass forClassName:NSStringFromClass([cell class])];
    
    return STVCell;
}


- (void)performInitialization
{
	self.shouldIndentWhileEditing = TRUE;
	
	_cellActions = [[SCCellActions alloc] init];
	boundPropertyDataType = SCDataTypeUnknown;
    _isCustomBoundProperty = FALSE;
	if(!_height)
        _height = UITableViewAutomaticDimension;
	selectable = TRUE;
    enabled = TRUE;
    _disabledTextColor = [UIColor blackColor];
	
	autoResignFirstResponder = TRUE;
	cellEditingStyle = UITableViewCellEditingStyleDelete;
	autoValidateValue = TRUE;
	commitChangesLive = TRUE;
	needsCommit = FALSE;
	beingReused = FALSE;
	customCell = FALSE;
    isSpecialCell = FALSE;
    configured = FALSE;
    
    // Setup the badgeView
	badgeView = [[SCBadgeView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
	[self.contentView addSubview:badgeView];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        [self performInitialization];
        
        // The following decodings are required to be able to utilize the method [self cellWithCell:] with cells created in IB (only properties used in IB need to be here)
        
        self.boundPropertyName = [aDecoder decodeObjectForKey:kBoundPropertyNameKey];
        self.ibDetailViewControllerIdentifier = [aDecoder decodeObjectForKey:KibDetailViewControllerIdentifier];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    // The following encodings are required to be able to utilize the method [self cellWithCell:] with cells created in IB (only properties used in IB need to be here)
    
    [aCoder encodeObject:self.boundPropertyName forKey:kBoundPropertyNameKey];
    [aCoder encodeObject:self.ibDetailViewControllerIdentifier forKey:KibDetailViewControllerIdentifier];
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if( (self=[super initWithStyle:style reuseIdentifier:reuseIdentifier]) )
	{
		[self performInitialization];
        
        if(reuseIdentifier)
            reuseId = [reuseIdentifier copy];
	}
	return self;
}

- (instancetype)initWithText:(NSString *)cellText
{
	if( (self=[self initWithStyle:SC_DefaultCellStyle reuseIdentifier:nil]) )
	{
		self.textLabel.text = cellText;
	}
	return self;
}

- (instancetype)initWithText:(NSString *)cellText textAlignment:(NSTextAlignment)textAlignment
{
    if( (self=[self initWithText:cellText]) )
    {
        self.textLabel.textAlignment = textAlignment;
    }
    return self;
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object boundPropertyName:(NSString *)propertyName
{
	if( (self=[self initWithStyle:SC_DefaultCellStyle reuseIdentifier:nil]) )
	{
		self.textLabel.text = cellText;
		
		self.boundObject = object;
		self.boundPropertyName = propertyName;
	}
	return self;
}


- (void)setBoundObject:(NSObject *)boundObject
{
    _boundObject = boundObject;
    
    [self resetInitialBoundValue];
}

- (void)setBoundPropertyName:(NSString *)boundPropertyName
{
    _boundPropertyName = boundPropertyName;
    
    [self resetInitialBoundValue];
}

- (void)resetInitialBoundValue
{
    self.initialBoundValue = nil;
}

- (void)rollbackToInitialBoundValue
{
    if(!self.initialBoundValue)
        return;
    
    NSObject *initialValue = self.initialBoundValue;
    if([initialValue isKindOfClass:[NSNull class]])
        initialValue = nil;
    
    self.boundValue = initialValue;
}


- (CGFloat)height
{
    if(_height!=UITableViewAutomaticDimension && _height!=44)
        return _height;
    
    CGFloat calculatedHeight = 44;
    
    switch (self.cellStyle)
    {
        case UITableViewCellStyleDefault:
        case UITableViewCellStyleValue1:
        case UITableViewCellStyleValue2:
        {
            if([self.textLabel.text length])
                calculatedHeight = self.textLabel.font.lineHeight + 10;
        }
            break;
        
        case UITableViewCellStyleSubtitle:
        {
            CGFloat textLabelHeight = 0;
            CGFloat detailTextLabelHeight = 0;
            if([self.textLabel.text length])
                textLabelHeight = self.textLabel.font.lineHeight;
            if([self.detailTextLabel.text length])
                detailTextLabelHeight = self.detailTextLabel.font.lineHeight;
            
            calculatedHeight = textLabelHeight + detailTextLabelHeight + 10;
        }
            break;
    }
    
    if(calculatedHeight < 46)  // stay within standard height even if we're off by two points
        calculatedHeight = 44;
    
    return calculatedHeight;
}


- (void)setDisabledTextColor:(UIColor *)disabledTextColor
{
    _disabledTextColor = disabledTextColor;
    
    if(!self.enabled)
    {
        // Make sure to apply new color
        self.enabled = FALSE;
    }
}

- (void)setIsCustomBoundProperty:(BOOL)custom
{
    _isCustomBoundProperty = custom;
}

- (void)setNeedsCommit:(BOOL)needs
{
    needsCommit = needs;
}

- (void)setActiveDetailModel:(SCTableViewModel *)model
{
    activeDetailModel = model;
    self.ownerTableViewModel.activeDetailModel = model;
}

- (SCDetailViewControllerOptions *)detailViewControllerOptions
{
    // Conserve resources by lazy loading for only cells that need it
    if(!detailViewControllerOptions)
        detailViewControllerOptions = [[SCDetailViewControllerOptions alloc] init];
    
    return detailViewControllerOptions;
}

- (void)setDetailViewControllerOptions:(SCDetailViewControllerOptions *)options
{
    detailViewControllerOptions = options;
}

- (void)didLayoutSubviews
{
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    
    [self.ownerTableViewModel styleCell:self atIndexPath:indexPath onlyStylePropertyNamesInSet:[NSSet setWithObjects:@"frame", @"bounds", nil]];
    
    if(self.cellActions.didLayoutSubviews)
    {
        self.cellActions.didLayoutSubviews(self, indexPath);
    }
    else 
        if(self.ownerSection.cellActions.didLayoutSubviews)
        {
            self.ownerSection.cellActions.didLayoutSubviews(self, indexPath);
        }
        else 
            if(self.ownerTableViewModel.cellActions.didLayoutSubviews)
            {
                self.ownerTableViewModel.cellActions.didLayoutSubviews(self, indexPath);
            }
}

//overrides superclass
- (NSString *)reuseIdentifier
{
	return self.reuseId;
}

// overrides superclass
- (UITableViewCellSelectionStyle)selectionStyle
{
    if(self.enabled)
        return [super selectionStyle];
    //else
    return UITableViewCellSelectionStyleNone;
}
 
//overrides superclass
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
	[super setHighlighted:highlighted animated:animated];
	[self.badgeView setNeedsDisplay];
}

//overrides superclass
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
	[super setSelected:selected animated:animated];
	[self.badgeView setNeedsDisplay];
}

- (UITableViewCellStyle)cellStyle
{
    // The only available way to determine the cell style is the availability and font sizes of textLabel & detailTextLabel (can't use label locations as they're not guaranteed to be set when this method gets called)
    
    BOOL textLabelPresent = (self.textLabel.text!=nil);
    BOOL detailTextLabelPresent = (self.detailTextLabel!=nil);
    
    if(!textLabelPresent && !detailTextLabelPresent)
        return -1;  //  -1 is 'Custom' cell style
    
    if(!detailTextLabelPresent)
        return UITableViewCellStyleDefault;
    
    if(self.textLabel.font.pointSize != self.detailTextLabel.font.pointSize)
        return UITableViewCellStyleSubtitle;
    
    if([self.detailTextLabel.textColor isEqual:[UIColor blackColor]])  // obviously not the best but there are no other clues
        return UITableViewCellStyleValue2;
    
    return UITableViewCellStyleValue1;  // the only remaining option
}

//overrides superclass
- (void)layoutSubviews
{
	[super layoutSubviews];
    
    // Resize textLabel & detailTextLabel to take full width (when applicable)
    UITableViewCellStyle style = self.cellStyle;
    if( (style==UITableViewCellStyleDefault || style==UITableViewCellStyleSubtitle) && ![self isKindOfClass:[SCControlCell class]] )
    {
        if(self.textLabel.text)
        {
            CGRect textLabelFrame = self.textLabel.frame;
            textLabelFrame.size.width = self.contentView.frame.size.width - textLabelFrame.origin.x - 15;
            self.textLabel.frame = textLabelFrame;
        }
        if(self.detailTextLabel.text)
        {
            CGRect detailTextLabelFrame = self.detailTextLabel.frame;
            detailTextLabelFrame.size.width = self.contentView.frame.size.width - detailTextLabelFrame.origin.x - 15;
            self.detailTextLabel.frame = detailTextLabelFrame;
        }
    }
    
	if(self.badgeView.text)
	{
		// Set the badgeView frame
		CGFloat margin;
        if(self.accessoryType == UITableViewCellAccessoryNone)
            margin = 10;
        else
            margin = 2;
        [self.badgeView sizeToFit];
		CGFloat badgeHeight = self.badgeView.frame.size.height;
        CGFloat badgeWidth = self.badgeView.frame.size.width;
		CGRect badgeFrame = CGRectMake(self.contentView.frame.size.width - badgeWidth - margin,
									   (self.contentView.frame.size.height - badgeHeight)/2 - 0.5,
									   badgeWidth, badgeHeight);
		self.badgeView.frame = badgeFrame;
		[self.badgeView setNeedsDisplay];
		
		// Resize textLabel if needed
		if((self.textLabel.frame.origin.x + self.textLabel.frame.size.width) >= badgeFrame.origin.x)
		{
			CGFloat badgeWidth = self.textLabel.frame.size.width - badgeFrame.size.width - margin;
			
			self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, 
                                              badgeWidth, self.textLabel.frame.size.height);
		}
		
		// Resize detailTextLabel if needed
		if((self.detailTextLabel.frame.origin.x + self.detailTextLabel.frame.size.width) >= badgeFrame.origin.x)
		{
			CGFloat badgeWidth = self.detailTextLabel.frame.size.width - badgeFrame.size.width - margin;
			
			self.detailTextLabel.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y, 
													badgeWidth, self.detailTextLabel.frame.size.height);
		}
	}
	
	[self didLayoutSubviews];
}

//overrides superclass
- (void)setBackgroundColor:(UIColor *)color
{
	[super setBackgroundColor:color];
	
    if(self.cellCreatedInIB)
        return;
    
	if(self.selectionStyle==UITableViewCellSelectionStyleNone && !self.backgroundView)
	{
		// This is much more optimized than [UIColor clearColor]
		self.textLabel.backgroundColor = color;
		self.detailTextLabel.backgroundColor = color;
	}
	else
	{
		self.textLabel.backgroundColor = [UIColor clearColor];
		self.detailTextLabel.backgroundColor = [UIColor clearColor];
	}
}

//overrides superclass
- (void)setBackgroundView:(UIView *)backgroundView
{
    [super setBackgroundView:backgroundView];
    
    if(self.cellCreatedInIB)
        return;
    
    if(backgroundView)
    {
        self.textLabel.backgroundColor = [UIColor clearColor];
		self.detailTextLabel.backgroundColor = [UIColor clearColor];
    }
}

- (void)setBoundValue:(NSObject *)value
{
	if(self.boundObject && [self.boundPropertyName length])
	{
        if([self.boundPropertyName characterAtIndex:0] == '~')
            return;  // boundPropertyName not an actual property but rather a placeholder for a custom cell
        
		if(self.cellActions.willCommitBoundValue)
        {
            NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
            value = self.cellActions.willCommitBoundValue(self, indexPath, value);
        }
        else
            if(self.ownerSection.cellActions.willCommitBoundValue)
            {
                NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
                value = self.ownerSection.cellActions.willCommitBoundValue(self, indexPath, value);
            }
            else
                if(self.ownerTableViewModel.cellActions.willCommitBoundValue)
                {
                    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
                    value = self.ownerTableViewModel.cellActions.willCommitBoundValue(self, indexPath, value);
                }
        
        if(!self.initialBoundValue)
        {
            NSObject *initialValue = self.boundValue;
            if(initialValue)
                self.initialBoundValue = initialValue;
            else
                self.initialBoundValue = [NSNull null];
        }
        
        if(self.boundObjectStore)
            [self.boundObjectStore setValue:value forPropertyName:self.boundPropertyName inObject:self.boundObject];
        else 
            [SCUtilities setValue:value forPropertyName:self.boundPropertyName inObject:self.boundObject];
        
        if([SCUtilities isBasicDataTypeClass:[self.boundObject class]])
            self.boundObject = value;
	}
}

- (NSObject *)boundValue
{
    NSObject *value = nil;
    
    if(self.cellActions.calculatedValue)
    {
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
        value = self.cellActions.calculatedValue(self, indexPath);
    }
    else
        if(self.ownerSection.cellActions.calculatedValue)
        {
            NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
            value = self.ownerSection.cellActions.calculatedValue(self, indexPath);
        }
        else
            if(self.ownerTableViewModel.cellActions.calculatedValue)
            {
                NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
                value = self.ownerTableViewModel.cellActions.calculatedValue(self, indexPath);
            }
    if(value)
        return value;  // return the calculated value if present
    
        
    if([self.boundPropertyName length] && [self.boundPropertyName characterAtIndex:0] == '~')
        return nil;  // boundPropertyName not an actual property but rather a placeholder for a custom cell
    
    if([SCUtilities isBasicDataTypeClass:[self.boundObject class]])
    {
        value = self.boundObject;
    }
    else
        if(self.boundObject && self.boundPropertyName && !_isCustomBoundProperty)
        {
            if(self.boundObjectStore)
                value = [self.boundObjectStore valueForPropertyName:self.boundPropertyName inObject:self.boundObject];
            else
                value = [SCUtilities valueForPropertyName:self.boundPropertyName inObject:self.boundObject];
        }
    
    if(self.cellActions.didLoadBoundValue)
    {
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
        value = self.cellActions.didLoadBoundValue(self, indexPath, value);
    }
    else
        if(self.ownerSection.cellActions.didLoadBoundValue)
        {
            NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
            value = self.ownerSection.cellActions.didLoadBoundValue(self, indexPath, value);
        }
        else
            if(self.ownerTableViewModel.cellActions.didLoadBoundValue)
            {
                NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
                value = self.ownerTableViewModel.cellActions.didLoadBoundValue(self, indexPath, value);
            }
    
    return value;
}

- (BOOL)valueIsValid
{
    if(!self.enabled)
        return YES;
    
    if(self.cellActions.valueIsValid)
    {
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
        return self.cellActions.valueIsValid(self, indexPath);
    }
    //else
    if(self.ownerSection.cellActions.valueIsValid)
    {
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
        return self.ownerSection.cellActions.valueIsValid(self, indexPath);
    }
    //else
    if(self.ownerTableViewModel.cellActions.valueIsValid)
    {
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
        return self.ownerTableViewModel.cellActions.valueIsValid(self, indexPath);
    }
    
	if(self.autoValidateValue)
		return [self getValueIsValid];
	
	BOOL valid = TRUE;
	
	return valid;
}

- (BOOL)getValueIsValid
{
	// Should be overridden by subclasses
	return TRUE;
}

- (BOOL)generatesDetailView
{
    // Should be overridden by subclasses
    return NO;
}

- (void)cellValueChanged
{
	needsCommit = TRUE;
	
	if(self.commitChangesLive)
		[self commitChanges];
    
	NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
	if(activeDetailModel) // a custom detail view is defined
	{
		NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
        [self.ownerTableViewModel.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
	}
    
	[self.ownerTableViewModel valueChangedForRowAtIndexPath:indexPath];
}

- (void)willDisplay
{
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    [self.ownerTableViewModel styleCell:self atIndexPath:indexPath onlyStylePropertyNamesInSet:nil];
}

- (void)didSelectCell
{
	if(self.autoDeselect)
    {
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
        [self.ownerTableViewModel.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)willDeselectCell
{
	if(activeDetailModel)
	{
		UITableView *detailTableView = activeDetailModel.tableView;
		[self setActiveDetailModel:nil];
		detailTableView.dataSource = nil;
		detailTableView.delegate = nil;
		[detailTableView reloadData];
	}
}

- (void)didDeselectCell
{
    // Does nothing
}

- (void)markCellAsSpecial
{
    isSpecialCell = TRUE;
}

- (void)commitChanges
{
	needsCommit = FALSE;
}

- (void)reloadBoundValue
{
	// Does nothing, should be overridden by subclasses
}

- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	self.imageView.image = attributes.imageView.image;
	self.detailCellsImageViews = attributes.imageViewArray;
}

- (void)prepareCellForDetailViewAppearing
{
	// disable ownerViewControllerDelegate
	if([self.ownerTableViewModel.viewController isKindOfClass:[SCTableViewController class]])
	{
		SCTableViewController *tViewController = (SCTableViewController *)self.ownerTableViewModel.viewController;
		ownerViewControllerDelegate = tViewController.delegate;
		tViewController.delegate = nil;
	}
	else
		if([self.ownerTableViewModel.viewController isKindOfClass:[SCViewController class]])
		{
			SCViewController *vController = (SCViewController *)self.ownerTableViewModel.viewController;
			ownerViewControllerDelegate = vController.delegate;
			vController.delegate = nil;
		}
	
	// lock master cell selection (in case a custom detail view is provided)
	if(self.ownerTableViewModel.masterModel)
		self.ownerTableViewModel.masterModel.lockCellSelection = TRUE;
}

- (void)prepareCellForDetailViewDisappearing
{
	// enable ownerViewControllerDelegate
	if([self.ownerTableViewModel.viewController isKindOfClass:[SCTableViewController class]])
	{
		SCTableViewController *tViewController = (SCTableViewController *)self.ownerTableViewModel.viewController;
		tViewController.delegate = ownerViewControllerDelegate;
	}
	else
		if([self.ownerTableViewModel.viewController isKindOfClass:[SCViewController class]])
		{
			SCViewController *vController = (SCViewController *)self.ownerTableViewModel.viewController;
			vController.delegate = ownerViewControllerDelegate;
		}
	
	// resume cell selection
	if(self.ownerTableViewModel.masterModel)
		self.ownerTableViewModel.masterModel.lockCellSelection = FALSE;
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

- (SCNavigationBarType)defaultDetailViewControllerNavigationBarType
{
    return self.detailViewControllerOptions.navigationBarType;
}

- (void)buildDetailModel:(SCTableViewModel *)detailModel
{
    // should be overridden by subclasses
}

- (void)configureDetailModel:(SCTableViewModel *)detailModel
{
    detailModel.masterBoundObject = self.boundObject;
    detailModel.masterBoundObjectStore = self.boundObjectStore;
}

- (void)commitDetailModelChanges:(SCTableViewModel *)detailModel
{
    // should be overridden by subclasses
}

- (UIViewController *)getDetailViewControllerForCell:(SCTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath allowUITableViewControllerSubclass:(BOOL)allowUITableViewController
{
    UIViewController *detailViewController = nil;
    
    if(self.cellActions.detailViewController)
    {
        detailViewController = self.cellActions.detailViewController(self, indexPath);
    }
    else 
        if(self.ownerSection.cellActions.detailViewController)
        {
            detailViewController = self.ownerSection.cellActions.detailViewController(self, indexPath);
        }
        else 
            if(self.ownerTableViewModel.cellActions.detailViewController)
            {
                detailViewController = self.ownerTableViewModel.cellActions.detailViewController(self, indexPath);
            }
    else
    if(self.ownerTableViewModel.detailViewController)
    {
        detailViewController = self.ownerTableViewModel.detailViewController;
    }
    
    if(!detailViewController)
    {
        if(allowUITableViewController)
            detailViewController = [[SCTableViewController alloc] initWithStyle:self.detailViewControllerOptions.tableViewStyle];
        else 
            detailViewController = [[SCViewController alloc] init];
    }
        
    detailViewController.modalPresentationStyle = self.detailViewControllerOptions.modalPresentationStyle;
    if(self.detailViewControllerOptions.title)
        detailViewController.title = self.detailViewControllerOptions.title;
    else 
        detailViewController.title = cell.textLabel.text;
    detailViewController.hidesBottomBarWhenPushed = self.detailViewControllerOptions.hidesBottomBarWhenPushed;
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
    
    if(self.cellActions.detailModelCreated)
    {
        self.cellActions.detailModelCreated(self, indexPath, detailModel);
    }
    else
        if(self.ownerSection.cellActions.detailModelCreated)
        {
            self.ownerSection.cellActions.detailModelCreated(self, indexPath, detailModel);
        }
        else
            if(self.ownerTableViewModel.cellActions.detailModelCreated)
            {
                self.ownerTableViewModel.cellActions.detailModelCreated(self, indexPath, detailModel);
            }
    
    [self configureDetailViewController:detailViewController];
    [self.ownerTableViewModel configureDetailModel:detailModel];
	[self buildDetailModel:detailModel];
    [self configureDetailModel:detailModel];
	
    if(self.cellActions.detailModelConfigured)
    {
        self.cellActions.detailModelConfigured(self, indexPath, detailModel);
    }
    else
        if(self.ownerSection.cellActions.detailModelConfigured)
        {
            self.ownerSection.cellActions.detailModelConfigured(self, indexPath, detailModel);
        }
        else
            if(self.ownerTableViewModel.cellActions.detailModelConfigured)
            {
                self.ownerTableViewModel.cellActions.detailModelConfigured(self, indexPath, detailModel);
            }
    
    
    return detailViewController;
}

- (void)configureDetailViewController:(UIViewController *)detailViewController
{
    if([detailViewController isKindOfClass:[SCTableViewController class]])
    {
        SCTableViewController *viewController = (SCTableViewController *)detailViewController;
        
        viewController.delegate = self;
        SCNavigationBarType navBarType = [self defaultDetailViewControllerNavigationBarType];
        if(navBarType==SCNavigationBarTypeAuto && viewController.navigationBarType==SCNavigationBarTypeAuto)
            viewController.navigationBarType = SCNavigationBarTypeDoneRightCancelLeft;
        else
            if(viewController.navigationBarType==SCNavigationBarTypeAuto)
                viewController.navigationBarType = navBarType;
        viewController.allowEditingModeCancelButton = self.detailViewControllerOptions.allowEditingModeCancelButton;
    }
    else
        if([detailViewController isKindOfClass:[SCViewController class]])
        {
            SCViewController *viewController = (SCViewController *)detailViewController;
            
            viewController.delegate = self;
            SCNavigationBarType navBarType = [self defaultDetailViewControllerNavigationBarType];
            if(navBarType==SCNavigationBarTypeAuto && viewController.navigationBarType==SCNavigationBarTypeAuto)
                viewController.navigationBarType = SCNavigationBarTypeDoneRightCancelLeft;
            else
                if(viewController.navigationBarType==SCNavigationBarTypeAuto)
                    viewController.navigationBarType = navBarType;
            viewController.allowEditingModeCancelButton = self.detailViewControllerOptions.allowEditingModeCancelButton;
        }
}

- (SCTableViewModel *)getCustomDetailModelForRowAtIndexPath:(NSIndexPath *)indexPath
{
	SCTableViewModel *detailModel = nil;
    
    if(self.cellActions.detailTableViewModel)
    {
        detailModel = self.cellActions.detailTableViewModel(self, indexPath);
    }
    else 
        if(self.ownerSection.cellActions.detailTableViewModel)
        {
            detailModel = self.ownerSection.cellActions.detailTableViewModel(self, indexPath);
        }
        else 
            if(self.ownerTableViewModel.cellActions.detailTableViewModel)
            {
                detailModel = self.ownerTableViewModel.cellActions.detailTableViewModel(self, indexPath);
            }
    
	return detailModel;
}

- (void)presentDetailViewController:(UIViewController *)detailViewController forCell:(SCTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath withPresentationMode:(SCPresentationMode)mode
{
    if(!detailViewController)
        return;
    
    [self prepareCellForDetailViewAppearing];
    
    [self setActiveDetailModel:[self modelForViewController:detailViewController]];
    
    BOOL customPresentation = FALSE;
    if([self isViewControllerActive:detailViewController] && mode==SCPresentationModeAuto)
    {
        customPresentation = TRUE;
        
        if([detailViewController respondsToSelector:@selector(gainFocus)])
            [(id)detailViewController gainFocus];
    }
    
    if(!customPresentation)
    {
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
                [navController pushViewController:detailViewController animated:YES];
                break;
            case SCPresentationModeModal:
            {
                [self.ownerTableViewModel.viewController presentViewController:detailNavController animated:YES completion:nil];
            }
                break;
            case SCPresentationModePopover:
            {
                UIPopoverController *popoverController  = [[UIPopoverController alloc] initWithContentViewController:self.ownerTableViewModel.viewController];
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
                
                [popoverController presentPopoverFromRect:cell.bounds inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
                break;
                
            default:
                // Do nothing
                break;
        }
    }
}

- (void)handleDetailViewControllerWillPresent:(UIViewController *)detailViewController
{
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
    
    if(self.cellActions.detailModelWillPresent)
    {
        self.cellActions.detailModelWillPresent(self, indexPath, detailModel);
    }
    else
        if(self.ownerSection.cellActions.detailModelWillPresent)
        {
            self.ownerSection.cellActions.detailModelWillPresent(self, indexPath, detailModel);
        }
        else
            if(self.ownerTableViewModel.cellActions.detailModelWillPresent)
            {
                self.ownerTableViewModel.cellActions.detailModelWillPresent(self, indexPath, detailModel);
            }
}

- (void)handleDetailViewControllerDidPresent:(UIViewController *)detailViewController
{
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
    
    if(self.cellActions.detailModelDidPresent)
    {
        self.cellActions.detailModelDidPresent(self, indexPath, detailModel);
    }
    else
        if(self.ownerSection.cellActions.detailModelDidPresent)
        {
            self.ownerSection.cellActions.detailModelDidPresent(self, indexPath, detailModel);
        }
        else
            if(self.ownerTableViewModel.cellActions.detailModelDidPresent)
            {
                self.ownerTableViewModel.cellActions.detailModelDidPresent(self, indexPath, detailModel);
            }
}

- (BOOL)handleDetailViewControllerShouldDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    
    BOOL shouldDismiss = TRUE;
    if(self.cellActions.detailModelShouldDismiss)
        shouldDismiss = self.cellActions.detailModelShouldDismiss(self, indexPath, [self modelForViewController:detailViewController]);
    else
        if(self.ownerSection.cellActions.detailModelShouldDismiss)
            self.ownerSection.cellActions.detailModelShouldDismiss(self, indexPath, [self modelForViewController:detailViewController]);
        else
            if(self.ownerTableViewModel.cellActions.detailModelShouldDismiss)
                self.ownerTableViewModel.cellActions.detailModelShouldDismiss(self, indexPath, [self modelForViewController:detailViewController]);
    
    return shouldDismiss;
}

- (void)handleDetailViewControllerWillDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self prepareCellForDetailViewDisappearing];
    
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
    
    if(self.cellActions.detailModelWillDismiss)
    {
        self.cellActions.detailModelWillDismiss(self, indexPath, detailModel);
    }
    else
        if(self.ownerSection.cellActions.detailModelWillDismiss)
        {
            self.ownerSection.cellActions.detailModelWillDismiss(self, indexPath, detailModel);
        }
        else
            if(self.ownerTableViewModel.cellActions.detailModelWillDismiss)
            {
                self.ownerTableViewModel.cellActions.detailModelWillDismiss(self, indexPath, detailModel);
            }
}

- (void)handleDetailViewControllerDidDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
    [self setActiveDetailModel:nil];
	
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
    
    if(!cancelTapped)
        [self commitDetailModelChanges:detailModel];
    
    if(self.cellActions.detailModelDidDismiss)
    {
        self.cellActions.detailModelDidDismiss(self, indexPath, detailModel);
    }
    else
        if(self.ownerSection.cellActions.detailModelDidDismiss)
        {
            self.ownerSection.cellActions.detailModelDidDismiss(self, indexPath, detailModel);
        }
        else
            if(self.ownerTableViewModel.cellActions.detailModelDidDismiss)
            {
                self.ownerTableViewModel.cellActions.detailModelDidDismiss(self, indexPath, detailModel);
            }
}


- (void)handleDetailViewControllerWillGainFocus:(UIViewController *)detailViewController
{
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
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    [self.ownerTableViewModel.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self handleDetailViewControllerDidDismiss:detailViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];
}


- (UIViewController *)generatedDetailViewController:(NSIndexPath *)indexPath
{
    return nil;  // should be implemented by subclasses
}



#pragma mark -
#pragma mark SCTableViewControllerDelegate methods

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

#pragma mark -
#pragma mark SCViewControllerDelegate methods

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

@end










@interface SCCustomCell ()
{
    NSMutableDictionary *_initialControlValues;  // used during rollback operations
    
    SCCustomCell *_operationsCell;  // used for cell resizing operations
}

// determines if the custom control is bound to either an object or a key
- (BOOL)controlWithTagIsBound:(NSUInteger)controlTag;

@end


#define kAutoResizeKey  @"autoResize"


@implementation SCCustomCell

@synthesize objectBindings = _objectBindings;
@synthesize autoResize = _autoResize;
@synthesize showClearButtonInInputAccessoryView = _showClearButtonInInputAccessoryView;


+ (instancetype)cellWithText:(NSString *)cellText objectBindings:(NSDictionary *)bindings nibName:(NSString *)nibName
{
    return [self cellWithText:cellText boundObject:nil objectBindings:bindings nibName:nibName];
}

+ (instancetype)cellWithText:(NSString *)cellText objectBindingsString:(NSString *)bindingsString nibName:(NSString *)nibName
{
    NSDictionary *bindings = [SCUtilities bindingsDictionaryForBindingsString:bindingsString];
    
    return [self cellWithText:cellText boundObject:nil objectBindings:bindings nibName:nibName];
}

+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object objectBindings:(NSDictionary *)bindings
	   nibName:(NSString *)nibName
{
	SCCustomCell *cell;
	if(nibName)
	{
		cell = (SCCustomCell *)[SCUtilities getFirstNodeInNibWithName:nibName];
        if(![cell isKindOfClass:[SCCustomCell class]] && [cell isKindOfClass:[UITableViewCell class]])
            cell = [SCCustomCell cellWithCell:cell];
		
        if([cell isKindOfClass:[SCCustomCell class]])
        {
            cell.reuseId = nibName;
            cell.height = cell.frame.size.height;
        }
        else 
        {
            SCDebugLog(@"Warning: Unexpected cell type! Expecting 'SCCustomCell' but got '%@' instead.", NSStringFromClass([cell class]));
            
            cell = nil;
        }
		
	}
	else
	{
		cell = [[[self class] alloc] initWithStyle:SC_DefaultCellStyle reuseIdentifier:nil];
	}
	cell.textLabel.text = cellText;
	[cell setBoundObject:object];
	[cell.objectBindings addEntriesFromDictionary:bindings];
	[cell configureCustomControls];
	
	return cell;
}

//overrides superclass
- (void)performInitialization
{
    [super performInitialization];
    
    _pauseControlEvents = FALSE;
    _objectBindings = [[NSMutableDictionary alloc] init];
    _autoResize = TRUE;
    _showClearButtonInInputAccessoryView = FALSE;
    
    _initialControlValues = [NSMutableDictionary dictionary];
}

// overrides superclass
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        // The following decodings are required to be able to utilize the method [self cellWithCell:] with cells created in IB (only properties used in IB need to be here)
        if([aDecoder containsValueForKey:kAutoResizeKey])
            self.autoResize = [aDecoder decodeBoolForKey:kAutoResizeKey];
        
        [self configureCustomControls];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    // The following encodings are required to be able to utilize the method [self cellWithCell:] with cells created in IB (only IB published properties need to be here)
    [aCoder encodeBool:self.autoResize forKey:kAutoResizeKey];
}


// overrides superclass
- (void)setBoundObject:(NSObject *)boundObject
{
    [super setBoundObject:boundObject];
    
    [_initialControlValues removeAllObjects];
}

// overrides superclass
- (void)setBoundPropertyName:(NSString *)boundPropertyName
{
    [super setBoundPropertyName:boundPropertyName];
    
    [_initialControlValues removeAllObjects];
}



- (NSString *)objectBindingsString
{
    return [SCUtilities bindingsStringForBindingsDictionary:self.objectBindings];
}

- (void)setObjectBindingsString:(NSString *)objectBindingsString
{
    [self.objectBindings addEntriesFromDictionary:[SCUtilities bindingsDictionaryForBindingsString:objectBindingsString]];
}

- (void)setObjectBindingsPropertyName:(NSString *)propertyName forControlWithTag:(NSInteger)controlTag
{
    [self.objectBindings setValue:propertyName forKey:[NSString stringWithFormat:@"%i", (int)controlTag]];
}

//overrides superclass
- (BOOL)canBecomeFirstResponder
{
    return (self.inputControlsSortedByTag.count > 0);
}

//overrides superclass
- (BOOL)becomeFirstResponder
{
    NSArray *inputControls = self.inputControlsSortedByTag; // optimization
    if(inputControls.count)
    {
        [[inputControls objectAtIndex:0] becomeFirstResponder];
        
        return TRUE;
    }
    //else 
    return FALSE;
}

//overrides superclass
- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    
    BOOL resign = FALSE;
    if(self == self.ownerTableViewModel.activeCell)
    {
        [self.ownerTableViewModel.activeCellControl resignFirstResponder];
        
        resign = TRUE;
    }
        
    return resign;
}

- (void)callDidBecomeFirstResponderActions
{
    if(self.cellActions.didBecomeFirstResponder)
    {
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
        self.cellActions.didBecomeFirstResponder(self, indexPath);
    }
    else
        if(self.ownerSection.cellActions.didBecomeFirstResponder)
        {
            NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
            self.ownerSection.cellActions.didBecomeFirstResponder(self, indexPath);
        }
        else
            if(self.ownerTableViewModel.cellActions.didBecomeFirstResponder)
            {
                NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
                self.ownerTableViewModel.cellActions.didBecomeFirstResponder(self, indexPath);
            }
}

- (void)callDidResignFirstResponderActions
{
    if(self.cellActions.didResignFirstResponder)
    {
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
        self.cellActions.didResignFirstResponder(self, indexPath);
    }
    else
        if(self.ownerSection.cellActions.didResignFirstResponder)
        {
            NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
            self.ownerSection.cellActions.didResignFirstResponder(self, indexPath);
        }
        else
            if(self.ownerTableViewModel.cellActions.didResignFirstResponder)
            {
                NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
                self.ownerTableViewModel.cellActions.didResignFirstResponder(self, indexPath);
            }
}


- (NSArray *)inputControlsSortedByTag
{
    NSMutableArray *inputControls = [NSMutableArray array];
    
    for(UIView *customControl in self.contentView.subviews)
    {
        if([customControl isKindOfClass:[UITextField class]] 
           || [customControl isKindOfClass:[UITextView class]])
        {
            [inputControls addObject:customControl];
        }
    }
    
    // sort based on the controls' tag
    [inputControls sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2)
     {
         if([(UIView *)obj1 tag] > [(UIView *)obj2 tag]) 
             return (NSComparisonResult)NSOrderedDescending;
         
         if([(UIView *)obj1 tag] < [(UIView *)obj2 tag]) 
             return (NSComparisonResult)NSOrderedAscending;
         
         return (NSComparisonResult)NSOrderedSame;
     }];
    
    return inputControls;
}

- (UIView *)controlWithTag:(NSInteger)controlTag
{
	if(controlTag < 1)
		return nil;
	
	for(UIView *customControl in self.contentView.subviews)
		if(customControl.tag == controlTag)
			return customControl;
	
	return nil;
}

//overrides superclass
- (void)setEnabled:(BOOL)_enabled
{
    [super setEnabled:_enabled];
    
    for(UIControl *customControl in self.contentView.subviews)
    {
        if([customControl isKindOfClass:[UITextView class]])
            [(UITextView *)customControl setEditable:_enabled];
        else
            if(![customControl isKindOfClass:[UILabel class]])
                customControl.enabled = _enabled;
    }
}

//overrides superclass
- (CGFloat)height
{
    // Make sure the cell's height fits its controls
    if(!self.needsCommit)
    {
        [self loadBindingsIntoCustomControls];
    }
    
    if((NSInteger)self.cellStyle!=-1 || !self.autoResize || [self isKindOfClass:[SCControlCell class]])  // -1 is 'Custom' cell style set in IB
        return [super height];
    
    CGFloat staticHeight = _height;
    if(staticHeight == UITableViewAutomaticDimension)
        staticHeight = 44;
    
    if(!_operationsCell)
    {
        _operationsCell = [[self class] cellWithCell:self];
        _operationsCell.boundObject = self.boundObject;
        _operationsCell.boundObjectStore = self.boundObjectStore;
        _operationsCell.boundPropertyName = self.boundPropertyName;
    }
    
    [_operationsCell loadBindingsIntoCustomControls];
    
    // Make sure _operationsCell bounds are correct (in case of UI size change)
    CGFloat conversion = 0;
    if([SCUtilities systemVersion] >= 8.0)
        conversion = 10; // conversion is a needed conversion between the tableView width and the cell width starting iOS 8 (note that we can never depend on self.bounds.width here!)
    _operationsCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.ownerTableViewModel.tableView.bounds)-conversion, staticHeight);
    
    // Make sure all frames all calculated
    [_operationsCell setNeedsLayout];
    [_operationsCell layoutIfNeeded];
    
    CGFloat calculatedheight = [_operationsCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 1; // +1 since contentView is one point less in height than cell (due to separator)
    
    if(calculatedheight == 1)  // no autolayout constraints were used
        calculatedheight = staticHeight;
    
    if(calculatedheight < 44)
        calculatedheight = 44;
    
    return calculatedheight;
}

//overrides superclass
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Make sure all subviews have their frames set
    [self.contentView setNeedsLayout];
    [self.contentView layoutIfNeeded];
    
    // Set the correct preferredMaxLayoutWidth for all custom cell labels
    for(UIView *customControl in self.contentView.subviews)
    {
        if([customControl isKindOfClass:[UILabel class]])
        {
            UILabel *label = (UILabel *)customControl;
            label.preferredMaxLayoutWidth = CGRectGetWidth(label.frame);
        }
    }

    [self didLayoutSubviews];
}

//override superclass
- (void)willDisplay
{
	[super willDisplay];
	
	if(!self.needsCommit)
	{
		[self loadBindingsIntoCustomControls];
	}
    
}

//override superclass
- (void)reloadBoundValue
{
	[super reloadBoundValue];
    
    [self loadBindingsIntoCustomControls];
}

//override superclass
- (void)commitChanges
{
	if(!self.needsCommit || !self.valueIsValid)
		return;
	
	for(UIView *customControl in self.contentView.subviews)
	{
		if(customControl.tag < 1)
			continue;
		
		if([customControl isKindOfClass:[UITextView class]])
		{
			UITextView *textView = (UITextView *)customControl;
			[self commitValueForControlWithTag:textView.tag value:textView.text];
		}
		else
			if([customControl isKindOfClass:[UITextField class]])
			{
				UITextField *textField = (UITextField *)customControl;
				[self commitValueForControlWithTag:textField.tag value:textField.text];
			}
			else
				if([customControl isKindOfClass:[UISlider class]])
				{
					UISlider *slider = (UISlider *)customControl;
					[self commitValueForControlWithTag:slider.tag 
												 value:[NSNumber numberWithFloat:slider.value]];
				}
				else
					if([customControl isKindOfClass:[UISegmentedControl class]])
					{
						UISegmentedControl *segmented = (UISegmentedControl *)customControl;
						[self commitValueForControlWithTag:segmented.tag 
													 value:[NSNumber numberWithInteger:segmented.selectedSegmentIndex]];
					}
					else
						if([customControl isKindOfClass:[UISwitch class]])
						{
							UISwitch *switchControl = (UISwitch *)customControl;
							[self commitValueForControlWithTag:switchControl.tag
														 value:[NSNumber numberWithBool:switchControl.on]];
						}
	}
	
	[super commitChanges];
    
    
    [self.ownerTableViewModel reloadCellsIfNeeded];  // needed to make sure calculated cells are in sync
}

- (void)reloadControlValuesIfNeeded
{
    [self loadBindingsIntoCustomControls];
}

// overrides superclass
- (void)rollbackToInitialBoundValue
{
    [super rollbackToInitialBoundValue];
    
    for(NSString *propertyName in _initialControlValues)
    {
        NSObject *initialValue = [_initialControlValues valueForKey:propertyName];
        
        if(!initialValue)
            continue;
        
        if([initialValue isKindOfClass:[NSNull class]])
            initialValue = nil;
        
        // rollback initalValue
        if(self.boundObjectStore)
            [self.boundObjectStore setValue:initialValue forPropertyName:propertyName inObject:self.boundObject];
        else
            [SCUtilities setValue:initialValue forPropertyName:propertyName inObject:self.boundObject];
    }
}

- (BOOL)controlWithTagIsBound:(NSUInteger)controlTag
{
    BOOL isBound = FALSE;
    
    if(self.boundObject)
	{
		if([self.objectBindings valueForKey:[NSString stringWithFormat:@"%i", (int)controlTag]])
            isBound = TRUE;
    }
	
    return isBound;
}

- (NSObject *)boundValueForControlWithTag:(NSInteger)controlTag
{
	NSObject *controlValue = nil;
	
	if(self.boundObject)
	{
		NSString *propertyName = [self.objectBindings valueForKey:[NSString stringWithFormat:@"%i", (int)controlTag]];
		if(!propertyName)
			return nil;
		
        if([SCUtilities propertyName:propertyName existsInObject:self.boundObject])
        {
            if(self.boundObjectStore)
                controlValue = [self.boundObjectStore valueForPropertyName:propertyName inObject:self.boundObject];
            else 
                controlValue = [SCUtilities valueForPropertyName:propertyName inObject:self.boundObject];
        }
	}
	
	return controlValue;
}

- (void)commitValueForControlWithTag:(NSInteger)controlTag value:(NSObject *)controlValue
{
	if(self.boundObject)
	{
        NSString *stringControlTag = [NSString stringWithFormat:@"%i", (int)controlTag];
        
		NSString *propertyName = [self.objectBindings valueForKey: stringControlTag];
		if(!propertyName)
			return;
		
        // set the initial value (if not exists) to provide rollback
        [self setInitialControlValueIfNeeded:[self boundValueForControlWithTag:controlTag] propertyName:propertyName];
        
        SCDataType propertyDataType = SCDataTypeUnknown;  
        if(self.boundObjectStore)
        {
            SCDataDefinition *boundObjectDef = [self.boundObjectStore definitionForObject:self.boundObject];
            if(boundObjectDef)
                propertyDataType = [boundObjectDef propertyDataTypeForPropertyWithName:propertyName];
        }
        controlValue = [SCUtilities getValueCompatibleWithDataType:propertyDataType fromValue:controlValue];
        
        if(self.boundObjectStore)
            [self.boundObjectStore setValue:controlValue forPropertyName:propertyName inObject:self.boundObject];
        else 
            [SCUtilities setValue:controlValue forPropertyName:propertyName inObject:self.boundObject];
	}
}

- (NSString *)curlyBraceBoundPropertyNameForControl:(UIView *)customControl
{
    if([customControl isKindOfClass:[SCImageView class]])
    {
        return [(SCImageView *)customControl boundPropertyName];
    }
    
    
    NSString *propertyName = nil;
    
    NSString *curlyBraceText = nil;
    if([customControl isKindOfClass:[UITextView class]])
    {
        UITextView *textView = (UITextView *)customControl;
        curlyBraceText = textView.text;
    }
    else
        if([customControl isKindOfClass:[UITextField class]])
        {
            UITextField *textField = (UITextField *)customControl;
            curlyBraceText = textField.text;
        }
        else
            if([customControl isKindOfClass:[UILabel class]])
            {
                UILabel *label = (UILabel *)customControl;
                curlyBraceText = label.text;
            }
    
    if(!curlyBraceText)
        return nil;
    
    NSRange leftBraceRange = [curlyBraceText rangeOfString:@"{"];
    if(leftBraceRange.location == NSNotFound)
        return nil;
    NSRange rightBraceRange = [curlyBraceText rangeOfString:@"}"];
    if(rightBraceRange.location == NSNotFound)
        return nil;
    NSRange propertyNameRange = (NSRange){.location = leftBraceRange.location+1, .length = rightBraceRange.location-leftBraceRange.location-1};
    propertyName = [curlyBraceText substringWithRange:propertyNameRange];
    propertyName = [propertyName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if([customControl isKindOfClass:[UILabel class]])
    {
        // Configure label's prefix and suffix
        
        UILabel *label = (UILabel *)customControl;
        if(leftBraceRange.location > 0)
            label.prefix = [curlyBraceText substringToIndex:leftBraceRange.location];
        if(rightBraceRange.location < [curlyBraceText length]-1)
            label.suffix = [curlyBraceText substringFromIndex:rightBraceRange.location+1];
    }
    
    if(![propertyName length])
        return nil;
    //else
    return propertyName;
}

- (void)configureCustomControls
{
    // Parse controls for bindings with curly braces and auto generate bindings
    NSInteger maxTag = 0;
    for(UIView *customControl in self.contentView.subviews)
        maxTag = MAX(customControl.tag, maxTag);
    if(maxTag < kSTVTagStartRange)
        maxTag = kSTVTagStartRange;
    for(UIView *customControl in self.contentView.subviews)
    {
        maxTag++;
        
        NSString *propertyName = [self curlyBraceBoundPropertyNameForControl:customControl];
        if(propertyName)
        {
            if(!customControl.tag)
            {
                customControl.tag = maxTag;
            }
            [self.objectBindings setValue:propertyName forKey:[NSString stringWithFormat: @"%li", (long)customControl.tag]];
        }
    }
    
    
    // Connect controls' targets and actions
	for(UIView *customControl in self.contentView.subviews)
	{
		if(customControl.tag < 1)
			continue;
		
		if([customControl isKindOfClass:[UITextView class]])
		{
			UITextView *textView = (UITextView *)customControl;
			textView.delegate = self;
		}
		else
			if([customControl isKindOfClass:[UITextField class]])
			{
				UITextField *textField = (UITextField *)customControl;
				textField.delegate = self;
				[textField addTarget:self action:@selector(textFieldEditingChanged:) 
					forControlEvents:UIControlEventEditingChanged];
			}
			else
				if([customControl isKindOfClass:[UISlider class]])
				{
					UISlider *slider = (UISlider *)customControl;
					[slider addTarget:self action:@selector(sliderValueChanged:) 
                     forControlEvents:UIControlEventValueChanged];
				}
				else
					if([customControl isKindOfClass:[UISegmentedControl class]])
					{
						UISegmentedControl *segmented = (UISegmentedControl *)customControl;
						[segmented addTarget:self action:@selector(segmentedControlValueChanged:) 
                            forControlEvents:UIControlEventValueChanged];
					}
					else
						if([customControl isKindOfClass:[UISwitch class]])
						{
							UISwitch *switchControl = (UISwitch *)customControl;
							[switchControl addTarget:self action:@selector(switchControlChanged:) 
                                    forControlEvents:UIControlEventValueChanged];
						}
						else
							if([customControl isKindOfClass:[UIButton class]])
							{
								UIButton *customButton = (UIButton *)customControl;
								[customButton addTarget:self action:@selector(customButtonTapped:) 
                                       forControlEvents:UIControlEventTouchUpInside];
							}
	}
}

- (void)loadBindingsIntoCustomControls
{
	_pauseControlEvents = TRUE;
	
	for(UIView *customControl in self.contentView.subviews)
	{
		if(customControl.tag<1 || ![self controlWithTagIsBound:customControl.tag])
			continue;
		
		NSObject *controlValue = [self boundValueForControlWithTag:customControl.tag];
		
		if([customControl isKindOfClass:[UILabel class]])
		{
            if(!controlValue)
				controlValue = @"";
            
            if([controlValue isKindOfClass:[NSDate class]])
            {
                // Convert date into string using formatter from data definition (if possible)
                NSString *propertyName = [self.objectBindings valueForKey:[NSString stringWithFormat:@"%i", (int)customControl.tag]];
                SCPropertyDefinition *propertyDefinition = [[self.boundObjectStore definitionForObject:self.boundObject] propertyDefinitionWithName:propertyName];
                if([propertyDefinition.attributes isKindOfClass:[SCDateAttributes class]])
                {
                    SCDateAttributes *dateAttributes = (SCDateAttributes *)propertyDefinition.attributes;
                    controlValue = [dateAttributes.dateFormatter stringFromDate:(NSDate *)controlValue];
                }
            }
            
            UILabel *label = (UILabel *)customControl;
            
            NSString *prefixString = label.prefix;
            NSString *suffixString = label.suffix;
            NSString *labelString = [NSString stringWithFormat:@"%@%@%@", prefixString, controlValue, suffixString];
            if([controlValue isKindOfClass:[NSNumber class]])
            {
                // determine if suffix has any float formatters (float formatting syntax is ".00", where the number of zeros is the number of decimal places)
                NSUInteger numberOfDecimalPlaces = 0;
                NSRange zeroMarkRange = [suffixString rangeOfString:@"."];
                if(zeroMarkRange.location==0) // has to be the very first character in suffix
                {
                    numberOfDecimalPlaces = 0;
                    for(NSInteger i=1; i<[suffixString length]; i++)
                        if([suffixString characterAtIndex:i] == '0')
                            numberOfDecimalPlaces++;
                    
                    // Create formatString
                    NSString *floatSpecifier = [NSString stringWithFormat:@"%@%luf", @"%.", (unsigned long)numberOfDecimalPlaces];
                    NSString *formatString = [NSString stringWithFormat:@"%@%@%@", @"%@", floatSpecifier, @"%@"];
                    
                    // Remove floatFormatter from suffixString
                    suffixString = [suffixString substringFromIndex:numberOfDecimalPlaces+1];
                    
                    // Update labelString
                    float floatValue = [(NSNumber *)controlValue floatValue];
                    labelString = [NSString stringWithFormat:formatString, prefixString, floatValue, suffixString];
                }
            }
            label.text = labelString;
		}
		else
			if([customControl isKindOfClass:[UITextView class]])
			{
                controlValue = [SCUtilities getValueCompatibleWithDataType:SCDataTypeNSString fromValue:controlValue];
                
				if(!controlValue)
					controlValue = @"";
				UITextView *textView = (UITextView *)customControl;
				textView.text = (NSString *)controlValue;
			}
			else
				if([customControl isKindOfClass:[UITextField class]])
				{
                    controlValue = [SCUtilities getValueCompatibleWithDataType:SCDataTypeNSString fromValue:controlValue];
                    
					if(!controlValue)
						controlValue = @"";
					UITextField *textField = (UITextField *)customControl;
					textField.text = (NSString *)controlValue;
				}
				else
					if([customControl isKindOfClass:[UISlider class]])
					{
                        controlValue = [SCUtilities getValueCompatibleWithDataType:SCDataTypeNSNumber fromValue:controlValue];
                        
						if(!controlValue)
							controlValue = [NSNumber numberWithInt:0];
						UISlider *slider = (UISlider *)customControl;
						slider.value = [(NSNumber *)controlValue floatValue];
					}
					else
						if([customControl isKindOfClass:[UISegmentedControl class]])
						{
                            controlValue = [SCUtilities getValueCompatibleWithDataType:SCDataTypeNSNumber fromValue:controlValue];
                            
							if(!controlValue)
								controlValue = [NSNumber numberWithInt:-1];
							UISegmentedControl *segmented = (UISegmentedControl *)customControl;
							segmented.selectedSegmentIndex = [(NSNumber *)controlValue intValue];
						}
						else
							if([customControl isKindOfClass:[UISwitch class]])
							{
                                controlValue = [SCUtilities getValueCompatibleWithDataType:SCDataTypeNSNumber fromValue:controlValue];
                                
								if(!controlValue)
									controlValue = [NSNumber numberWithBool:FALSE];
								UISwitch *switchControl = (UISwitch *)customControl;
								switchControl.on = [(NSNumber *)controlValue boolValue];
							}
							else
								if([customControl isKindOfClass:[UIButton class]])
								{
									controlValue = [SCUtilities getValueCompatibleWithDataType:SCDataTypeNSString fromValue:controlValue];
                                    
                                    if(controlValue)
									{
										UIButton *customButton = (UIButton *)customControl;
										NSString *buttonTitle = (NSString *)controlValue;
										[customButton setTitle:buttonTitle forState:UIControlStateNormal];
									}
								}
                                else 
                                    if([customControl isKindOfClass:[UIImageView class]])
                                    {
                                        UIImageView *imageView = (UIImageView *)customControl;
                                        
                                        if([controlValue isKindOfClass:[UIImage class]])
                                        {
                                            imageView.image = (UIImage *)controlValue;
                                        }
                                        else
                                        if([controlValue isKindOfClass:[NSString class]])
                                        {
                                            if([SCUtilities isURLValid:(NSString *)controlValue])
                                            {
                                                NSURL *imageURL = [NSURL URLWithString:(NSString *)controlValue];
                                                
                                                // Load image asynchronously
                                                dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
                                                dispatch_async(queue, ^{
                                                    NSData * imageData = [NSData dataWithContentsOfURL:imageURL];
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        UIImage *image = [UIImage imageWithData:imageData];
                                                        [imageView setImage:image];
                                                    });
                                                });
                                            }
                                            else
                                            {
                                                // assume string contains simple image name
                                                imageView.image = [UIImage imageNamed:(NSString *)controlValue];
                                            }
                                        }
                                    }
	}
	
	_pauseControlEvents = FALSE;
}

- (void)setInitialControlValueIfNeeded:(id)value propertyName:(NSString *)propertyName
{
    if(![_initialControlValues valueForKey:propertyName])
    {
        if(!value)
            value = [NSNull null];
        [_initialControlValues setValue:value forKey:propertyName];
    }
}

#pragma mark -
#pragma mark UITextView methods

- (BOOL)textViewShouldBeginEditing:(UITextView *)_textView
{
    if(!_textView.inputAccessoryView)
        _textView.inputAccessoryView = self.ownerTableViewModel.inputAccessoryView;
    if([_textView.inputAccessoryView isKindOfClass:[SCInputAccessoryView class]])
        [(SCInputAccessoryView *)_textView.inputAccessoryView setShowClearButton:self.showClearButtonInInputAccessoryView];
    
	BOOL shouldBegin = TRUE;
    
    if(shouldBegin)
    {
        [SCModelCenter sharedModelCenter].keyboardIssuer = self.ownerTableViewModel.viewController;
        
        self.ownerTableViewModel.activeCell = self;
        self.ownerTableViewModel.activeCellControl = _textView;
    }
    
	return shouldBegin;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self callDidBecomeFirstResponderActions];
    
    [self scrollToFocusCaretForTextView:textView];
}

- (BOOL)textViewShouldEndEditing:(UITextView *)_textView
{
	[SCModelCenter sharedModelCenter].keyboardIssuer = self.ownerTableViewModel.viewController;
	return TRUE;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self callDidResignFirstResponderActions];
}

- (void)textViewDidChange:(UITextView *)_textView
{
	if(_pauseControlEvents)
		return;
	
	[self cellValueChanged];
}

- (void)scrollToFocusCaretForTextView:(UITextView *)textView
{
    CGRect caretRect = [textView caretRectForPosition:textView.selectedTextRange.start];
    
    CGRect convertedCaretRect = [self.ownerTableViewModel.tableView convertRect:caretRect fromView:textView];
    
    // Determine if convertedCaretRect is visible
    CGRect visibleRect;
    visibleRect.origin = self.ownerTableViewModel.tableView.contentOffset;
    visibleRect.origin.y += self.ownerTableViewModel.tableView.contentInset.top;
    visibleRect.size = self.ownerTableViewModel.tableView.bounds.size;
    visibleRect.size.height -= self.ownerTableViewModel.tableView.contentInset.top + self.ownerTableViewModel.tableView.contentInset.bottom;
    
    if (!CGRectContainsRect(visibleRect, convertedCaretRect))
    {
        convertedCaretRect.size.height += 8; // add some space underneath the caret
        [self.ownerTableViewModel.tableView scrollRectToVisible:convertedCaretRect animated:YES];
    }
}

#pragma mark -
#pragma mark UITextField methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)_textField
{
    if(!_textField.inputAccessoryView)
        _textField.inputAccessoryView = self.ownerTableViewModel.inputAccessoryView;
    if([_textField.inputAccessoryView isKindOfClass:[SCInputAccessoryView class]])
        [(SCInputAccessoryView *)_textField.inputAccessoryView setShowClearButton:self.showClearButtonInInputAccessoryView];
    
    BOOL shouldBegin = TRUE;
    
    if(shouldBegin)
    {
        [SCModelCenter sharedModelCenter].keyboardIssuer = self.ownerTableViewModel.viewController;
        
        self.ownerTableViewModel.activeCell = self;
        self.ownerTableViewModel.activeCellControl = _textField;
    }
    
	return shouldBegin;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self callDidBecomeFirstResponderActions];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    BOOL shouldChange = YES;
    
    if(self.cellActions.shouldChangeCharactersInRange)
    {
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
        shouldChange = self.cellActions.shouldChangeCharactersInRange(self, indexPath, textField, range, string);
    }
    else
        if(self.ownerSection.cellActions.shouldChangeCharactersInRange)
        {
            NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
            shouldChange = self.ownerSection.cellActions.shouldChangeCharactersInRange(self, indexPath, textField, range, string);
        }
        else
            if(self.ownerTableViewModel.cellActions.shouldChangeCharactersInRange)
            {
                NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
                shouldChange = self.ownerTableViewModel.cellActions.shouldChangeCharactersInRange(self, indexPath, textField, range, string);
            }
    
    return shouldChange;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)_textField
{
	[SCModelCenter sharedModelCenter].keyboardIssuer = self.ownerTableViewModel.viewController;
	return TRUE;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self callDidResignFirstResponderActions];
}

- (void)textFieldEditingChanged:(id)sender
{
	if(_pauseControlEvents)
		return;
	
	[self cellValueChanged];
}

- (BOOL)textFieldShouldReturn:(UITextField *)_textField
{
	if(self.cellActions.returnButtonTapped)
	{
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
		self.cellActions.returnButtonTapped(self, indexPath);
        
		return TRUE;
	}
    // else
    if(self.ownerSection.cellActions.returnButtonTapped)
	{
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
		self.ownerSection.cellActions.returnButtonTapped(self, indexPath);
        
		return TRUE;
	}
    // else
    if(self.ownerTableViewModel.cellActions.returnButtonTapped)
	{
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
		self.ownerTableViewModel.cellActions.returnButtonTapped(self, indexPath);
        
		return TRUE;
	}
	
	BOOL handeledReturn;
	switch (_textField.returnKeyType)
	{
		case UIReturnKeyDefault:
		case UIReturnKeyNext:
			[self.ownerTableViewModel moveToNextCellControl:TRUE];
			handeledReturn = TRUE;
			break;
			
		case UIReturnKeyDone: 
			[_textField resignFirstResponder];
			handeledReturn = TRUE;
			break;
			
		default:
			handeledReturn = FALSE;
			break;
	}
	
	return handeledReturn;
}

#pragma mark -
#pragma mark UISlider methods

- (void)sliderValueChanged:(id)sender
{	
	if(_pauseControlEvents)
		return;
	
	self.ownerTableViewModel.activeCellControl = sender;
	
	[self cellValueChanged];
}

#pragma mark -
#pragma mark UISegmentedControl methods

- (void)segmentedControlValueChanged:(id)sender
{
	if(_pauseControlEvents)
		return;
	
	self.ownerTableViewModel.activeCellControl = sender;
	
	[self cellValueChanged];
}

#pragma mark -
#pragma mark UISwitch methods

- (void)switchControlChanged:(id)sender
{
	if(_pauseControlEvents)
		return;
	
	self.ownerTableViewModel.activeCellControl = sender;
	
	[self cellValueChanged];
}

#pragma mark -
#pragma mark UIButton methods

- (void)customButtonTapped:(id)sender
{
    if(self.cellActions.customButtonTapped)
    {
        NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
        self.cellActions.customButtonTapped(self, indexPath, sender);
    }
    else 
        if(self.ownerSection.cellActions.customButtonTapped)
        {
            NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
            self.ownerSection.cellActions.customButtonTapped(self, indexPath, sender);
        }
        else 
            if(self.ownerTableViewModel.cellActions.customButtonTapped)
            {
                NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
                self.ownerTableViewModel.cellActions.customButtonTapped(self, indexPath, sender);
            }
}


@end









#define kControlIndexInContentViewKey     @"controlIndexInContentView"
#define kControlCreatedInIBKey  @"controlCreatedInIB"



@interface SCControlCell ()

@property (nonatomic, strong) NSObject *lastLoadedControlValue;

@end



@implementation SCControlCell

@synthesize maxTextLabelWidth;
@synthesize controlIndentation;
@synthesize controlMargin;


- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if(self)
    {
        // The following decodings are required to be able to utilize the method [self cellWithCell:] with cells created in IB (only IB published properties need to be here)
        
        if([aDecoder containsValueForKey:kControlCreatedInIBKey])
            _controlCreatedInIB = [aDecoder decodeBoolForKey:kControlCreatedInIBKey];
        
        if([aDecoder containsValueForKey:kControlIndexInContentViewKey])
        {
            NSInteger controlIndexInContentView = [aDecoder decodeIntegerForKey:kControlIndexInContentViewKey];
            if(controlIndexInContentView!=-1 && controlIndexInContentView<self.contentView.subviews.count)
                self.control = [self.contentView.subviews objectAtIndex:controlIndexInContentView];
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    // The following encodings are required to be able to utilize the method [self cellWithCell:] with cells created in IB (only IB published properties need to be here)
    
    [aCoder encodeBool:self.controlCreatedInIB forKey:kControlCreatedInIBKey];
    
    NSInteger controlIndexInContentView = -1;
    if(self.control)
        controlIndexInContentView = [self.contentView.subviews indexOfObject:self.control];
    [aCoder encodeInteger:controlIndexInContentView forKey:kControlIndexInContentViewKey];
}

//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
    
    maxTextLabelWidth = SC_DefaultMaxTextLabelWidth;
	controlIndentation = SC_DefaultControlIndentation;
	controlMargin = kDefaultControlMargin;
    
    if(!self.controlCreatedInIB)
        self.textLabel.font = [UIFont fontWithName:self.textLabel.font.fontName size:kDefaultTitleLabelFontSize];
}

//overrides superclass
- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if(self.control)
        _controlCreatedInIB = YES;
}


//overrides superclass
- (void)commitChanges
{
    self.lastLoadedControlValue = self.boundValue;   // make sure self doesn't get reloaded when reloading calculated cells
    
    [super commitChanges];
}

//overrides superclass
- (void)reloadControlValuesIfNeeded
{
    [super reloadControlValuesIfNeeded];
    
    if(self.lastLoadedControlValue != self.boundValue)
    {
        _boundValueLoaded = NO;
        [self loadBoundValueIntoControl];
    }
}


- (UILabel *)ibControlLabel
{
    UILabel *controlLabel = nil;
    UIView *view = [self.contentView viewWithTag:kSTVTagStartRange];
    if([view isKindOfClass:[UILabel class]])
        controlLabel = (UILabel *)view;
    
    return controlLabel;
}


//overrides superclass
- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    
    if(self.cellCreatedInIB)
        return;
    
    for(UIView *subview in self.contentView.subviews)
    {
        if([subview isKindOfClass:[UIControl class]] || [subview isKindOfClass:[UITextView class]] || [subview isKindOfClass:[UILabel class]])
        {
            if(!self.backgroundView)
                [(UIControl *)subview setBackgroundColor:backgroundColor];
        }
    }
}

//overrides superclass
- (void)setBackgroundView:(UIView *)backgroundView
{
    [super setBackgroundView:backgroundView];
    
    if(self.cellCreatedInIB)
        return;
    
    if(backgroundView)
    {
        for(UIView *subview in self.contentView.subviews)
        {
            if([subview isKindOfClass:[UIControl class]] || [subview isKindOfClass:[UITextView class]] || [subview isKindOfClass:[UILabel class]])
            {
                [(UIControl *)subview setBackgroundColor:[UIColor clearColor]];
            }
        }
    }
}


//overrides superclass
- (CGFloat)height
{
    if(!self.needsCommit)
    {
        [self loadBoundValueIntoControl];
    }
    
    return [super height];
}

//overrides superclass
- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if(!self.controlCreatedInIB)
    {
        CGRect textLabelFrame;
        if([self.textLabel.text length])
            textLabelFrame = self.textLabel.frame;
        else
            textLabelFrame = CGRectMake(0, kYMargin, 0, kDefaultTitleLabelHeight);
        
        // Modify the textLabel frame to take only it's text width instead of the full cell width
        if([self.textLabel.text length])
        {
            CGSize constraintSize = CGSizeMake(self.maxTextLabelWidth, MAXFLOAT);
            CGFloat textLabelFrameWidth = [self.textLabel.text boundingRectWithSize:constraintSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.textLabel.font} context:nil].size.width;
            textLabelFrame.size.width = ceilf(textLabelFrameWidth);  // ceilf is needed starting iOS 7
        }
        
        self.textLabel.frame = textLabelFrame;
        
        // Layout the control next to self.textLabel, with it's same yCoord & height
        CGFloat indentation = self.controlIndentation;
        if(textLabelFrame.size.width == 0)
        {
            indentation = 0;
            if(self.imageView.image)
                textLabelFrame = self.imageView.frame;
        }
        
        CGSize contentViewSize = self.contentView.bounds.size;
        CGFloat controlXCoord = textLabelFrame.origin.x+textLabelFrame.size.width+self.controlMargin;
        if(controlXCoord < indentation)
            controlXCoord = indentation;
        CGRect controlFrame = CGRectMake(controlXCoord,
                                         textLabelFrame.origin.y, 
                                         contentViewSize.width - controlXCoord - self.controlMargin, 
                                         textLabelFrame.size.height);
        self.control.frame = controlFrame;
    }
	
	[self didLayoutSubviews];
}

//override superclass
- (void)willDisplay
{
	[super willDisplay];
	
	if(!self.needsCommit)
	{
		[self loadBoundValueIntoControl];
	}
		
}

//override superclass
- (void)reloadBoundValue
{
    [super reloadBoundValue];
    
    _boundValueLoaded = NO;
    
	[self loadBoundValueIntoControl];
}


- (void)setControl:(UIView *)control
{
    if(control && ![control isKindOfClass:self.expectedControlClass])
    {
        SCDebugLog(@"Warning: Control not assigned in control cell:%@. Expecting a control of class '%@' but got '%@' instead.", self, self.expectedControlClass, [control class]);
        return;
    }
    
    if(_control)
        [_control removeFromSuperview];
    
    _control = control;
    if(_control && !_control.superview)
        [self.contentView addSubview:_control];
    
    [self configureControl];
}

- (Class)expectedControlClass
{
    // should be overridden by subclasses
    return [UIView class];
}

- (void)configureControl
{
    // does nothig, must be overridden by subclasses
}

- (NSObject *)controlValue
{
	// must be overridden by subclasses
    return nil;
}

- (void)loadBoundValueIntoControl
{
    // does nothing, should be overridden by subclasses
}

- (void)clearControl
{
    // does nothing, should be overridden by subclasses
}

@end







@implementation SCLabelCell


+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object labelTextPropertyName:(NSString *)propertyName
{
	return [[[self class] alloc] initWithText:cellText boundObject:object labelTextPropertyName:propertyName];
}


//overrides superclass
- (void)performInitialization
{
	[super performInitialization];

	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
    UILabel *label = [[UILabel alloc] init];
    label.textAlignment = NSTextAlignmentRight;
    label.textColor = [UIColor colorWithRed:50.0f/255 green:79.0f/255 blue:133.0f/255 alpha:1];
    label.font = [UIFont fontWithName:label.font.fontName size:kDefaultControlFontSize];
    label.backgroundColor = self.backgroundColor;
    self.control = label;
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object labelTextPropertyName:(NSString *)propertyName
{
	return [self initWithText:cellText boundObject:object boundPropertyName:propertyName];
}


// overrides superclass
- (Class)expectedControlClass
{
    return [UILabel class];
}

// overrides superclass
- (void)setControl:(UIView *)control
{
    [super setControl:control];
    
    _initialControlColor = self.label.textColor;
}

// overrides superclass
- (void)configureControl
{
    if(!self.control)
        return;
    
    // no additional configuration
}

//overrides superclass
- (void)setEnabled:(BOOL)_enabled
{
    [super setEnabled:_enabled];
    
    if(_enabled)
        self.label.textColor = _initialControlColor;
    else
        self.label.textColor = self.disabledTextColor;
}

//overrides superclass
- (void)layoutSubviews
{
	[super layoutSubviews];
	
    if(!self.controlCreatedInIB)
    {
        // Adjust label position
        CGRect labelFrame = self.label.frame;
        labelFrame.size.height -= 1;
        self.label.frame = labelFrame;
    }
    
    [self didLayoutSubviews];
}

//overrides superclass
- (NSObject *)controlValue
{
	return self.label.text;
}

//overrides superclass
- (void)loadBoundValueIntoControl
{
    if(_boundValueLoaded)
        return;
    
    [self loadBoundValueIntoLabel];
    
    self.lastLoadedControlValue = self.boundValue;
}

- (void)loadBoundValueIntoLabel
{
    if(self.boundPropertyName)
    {
        NSObject *val = self.boundValue;
        if(!val)
            val = @"";
        self.label.text = [NSString stringWithFormat:@"%@", val];
        
        _boundValueLoaded = YES;
    }
}

- (UILabel *)label
{
	return (UILabel *)self.control;
}

@end









@implementation SCTextViewCell

@synthesize minimumHeight;
@synthesize maximumHeight;


+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object textViewTextPropertyName:(NSString *)propertyName
{
	return [[[self class] alloc] initWithText:cellText boundObject:object textViewTextPropertyName:propertyName];
}


//overrides superclass
- (void)performInitialization
{
    [super performInitialization];
	
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    minimumHeight = kMinTextViewHeight;
    maximumHeight = kMaxTextViewHeight;
	
    UITextView *textView = [[UITextView alloc] init];
    textView.font = [UIFont fontWithName:self.textView.font.fontName size:kDefaultControlFontSize];
    textView.textColor = [UIColor colorWithRed:50.0f/255 green:79.0f/255 blue:133.0f/255 alpha:1];
    self.control = textView;
}	

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object textViewTextPropertyName:(NSString *)propertyName
{
	return [self initWithText:cellText boundObject:object boundPropertyName:propertyName];
}


// overrides superclass
- (Class)expectedControlClass
{
    return [UITextView class];
}

// overrides superclass
- (void)setControl:(UIView *)control
{
    [super setControl:control];
    
    self.textView.scrollEnabled = !self.autoResize;
    
    _initialControlColor = self.textView.textColor;
}

// overrides superclass
- (void)configureControl
{
    if(!self.control)
        return;
    
    self.textView.delegate = self;
}

- (void)setAutoResize:(BOOL)autoResize
{
    _autoResize = autoResize;
    
    self.textView.scrollEnabled = !autoResize;
}

//overrides superclass
- (void)setEnabled:(BOOL)_enabled
{
    [super setEnabled:_enabled];
    
    if(_enabled)
        self.textView.textColor = _initialControlColor;
    else
        self.textView.textColor = self.disabledTextColor;
}

- (CGFloat)textLabelYCoord
{
    if(self.controlCreatedInIB)
        return 0;  // no textLabel
    
    CGFloat yCoord;
    
    BOOL textLabelExists = [self.textLabel.text length]!=0;
    if(textLabelExists)
    {
        yCoord = kYMargin;
    }
    else
    {
        yCoord = 0;
    }
    
    return yCoord;
}

- (CGFloat)textLabelHeight
{
    if(self.controlCreatedInIB || [self.textLabel.text length]==0)
        return 0;  // no textLabel
    
    CGFloat textLabelHeight = [self.textLabel.text sizeWithAttributes:@{NSFontAttributeName:self.textLabel.font}].height;
    
    return ceil(textLabelHeight);
}

- (CGFloat)textViewXCoord
{
    CGFloat xCoord;
    
    if(self.controlCreatedInIB)
    {
        [self.contentView layoutIfNeeded];  // make sure text view has the correct frame
        
        xCoord = self.textView.frame.origin.x;
    }
    else
    {
        xCoord = kTextViewXMargin + 1;      // +1 is a needed fix for runtime generation
    }
    
    return xCoord;
}

- (CGFloat)textViewYCoord
{
    CGFloat yCoord;
    
    if(self.controlCreatedInIB)
    {
        yCoord = self.textView.frame.origin.y;
    }
    else
    {
        yCoord = [self textLabelYCoord] + [self textLabelHeight];
    }
    
    return yCoord;
}

- (CGFloat)textViewWidth
{
    CGFloat textViewWidth;
    
    if(self.controlCreatedInIB)
    {
        textViewWidth = self.textView.frame.size.width;
    }
    else
    {
        textViewWidth = self.ownerTableViewModel.tableView.frame.size.width - [self textViewXCoord] - kTextViewMargin;
    }
    
    return ceil(textViewWidth);
}

- (CGFloat)textViewHeight
{
    if(!self.autoResize)
        return self.minimumHeight;
    
    [self loadBoundValueIntoControl];  // make sure to fill textView with its contents
    CGFloat textViewHeight = [self.textView sizeThatFits:CGSizeMake([self textViewWidth], MAXFLOAT)].height;
    
    if(textViewHeight < self.minimumHeight)
    {
        textViewHeight = self.minimumHeight;
    }
    
    return ceil(textViewHeight);
}

//overrides superclass
- (CGFloat)height
{
    CGFloat cellHeight = [self textViewYCoord] + [self textViewHeight] + kTextViewMargin;
    
    return ceil(cellHeight);
}

//overrides superclass
- (BOOL)canBecomeFirstResponder
{
    return TRUE;
}

//overrides superclass
- (BOOL)becomeFirstResponder
{
	[self.textView becomeFirstResponder];
    
    return TRUE;
}

//overrides superclass
- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    
	[self.textView resignFirstResponder];
    
    return TRUE;
}

//overrides superclass
- (void)layoutSubviews
{	
	[super layoutSubviews];
	
    // don't check for self.controlCreatedInIB here as it's already taken care of in the textView size methods
    
    self.textView.frame = CGRectMake([self textViewXCoord], [self textViewYCoord], [self textViewWidth], [self textViewHeight]);
    
    if([self.textLabel.text length])
    {
        CGRect textLabelFrame = self.textLabel.frame;
        textLabelFrame.origin.y = [self textLabelYCoord];
        self.textLabel.frame = textLabelFrame;
    }
    
	[self didLayoutSubviews];
}


//overrides superclass
- (NSObject *)controlValue
{
	return self.textView.text;
}

//overrides superclass
- (void)loadBoundValueIntoControl
{
    if(_boundValueLoaded)
        return;
    
	if(self.boundPropertyName && (!self.boundValue || [SCUtilities isStringClass:[self.boundValue class]]) )
	{
		_pauseControlEvents = TRUE;
		self.textView.text = (NSString *)self.boundValue;
		_pauseControlEvents = FALSE;
        
        _boundValueLoaded = YES;
        
        self.lastLoadedControlValue = self.boundValue;
	}
}

//overrides superclass
- (void)commitChanges
{
	if(!self.needsCommit || !self.valueIsValid)
		return;
	
	self.boundValue = self.textView.text;
	
    [super commitChanges];
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCTextViewAttributes class]])
		return;
	
	SCTextViewAttributes *textViewAttributes = (SCTextViewAttributes *)attributes;
	self.autoResize = textViewAttributes.autoResize;
    if(textViewAttributes.minimumHeight > 0)
    {
        self.minimumHeight = textViewAttributes.minimumHeight;
        if(!self.autoResize)
            self.height = self.minimumHeight;
    }
	if(textViewAttributes.maximumHeight > 0)
		self.maximumHeight = textViewAttributes.maximumHeight;
    
    if(!self.controlCreatedInIB)
    {
        self.textView.editable = textViewAttributes.editable;
    }
}

//overrides superclass
- (BOOL)getValueIsValid
{
	if(![self.textView.text length] && self.valueRequired)
		return FALSE;
	//else
	return TRUE;
}

- (UITextView *)textView
{
	return (UITextView *)self.control;
}

- (void)clearControl
{
    self.textView.text = nil;
}

#pragma mark -
#pragma mark UITextViewDelegate methods

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    BOOL shouldChange = YES;
    
    if([self textViewHeight] > self.maximumHeight)
    {
        shouldChange = NO;
        
        // remove last added character (usually a return key)
        self.textView.text = [self.textView.text substringToIndex:[self.textView.text length] - 1];
    }
    
    return shouldChange;
}

- (void)textViewDidChange:(UITextView *)_textView
{		
	if(_pauseControlEvents)
		return;
	
	if(_textView != self.textView)
	{
		[super textViewDidChange:_textView];
		return;
	}
	
	[self cellValueChanged];
    
    
    // Resize cell if needed
    if(self.autoResize)
    {
        [self.ownerTableViewModel.tableView beginUpdates];
        [self.ownerTableViewModel.tableView endUpdates];
        
        [self scrollToFocusCaretForTextView:self.textView];
    }
}

@end






@implementation SCTextFieldCell


+ (instancetype)cellWithText:(NSString *)cellText placeholder:(NSString *)placeholder boundObject:(NSObject *)object textFieldTextPropertyName:(NSString *)propertyName
{
	return [[[self class] alloc] initWithText:cellText placeholder:placeholder boundObject:object textFieldTextPropertyName:propertyName];
}


//overrides superclass
- (void)performInitialization
{
	[super performInitialization];

	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
    UITextField *textField = [[UITextField alloc] init];
    textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.textColor = [UIColor colorWithRed:50.0f/255 green:79.0f/255 blue:133.0f/255 alpha:1];
    textField.font = [UIFont fontWithName:self.textField.font.fontName size:kDefaultControlFontSize];
    self.control = textField;
}

- (instancetype)initWithText:(NSString *)cellText placeholder:(NSString *)placeholder boundObject:(NSObject *)object textFieldTextPropertyName:(NSString *)propertyName
{
	if( (self=[self initWithText:cellText boundObject:object boundPropertyName:propertyName]) )
	{
		self.textField.placeholder = placeholder;
	}
	return self;
}


// overrides superclass
- (Class)expectedControlClass
{
    return [UITextField class];
}

// overrides superclass
- (void)setControl:(UIView *)control
{
    [super setControl:control];
    
    _initialControlColor = self.textField.textColor;
}

// overrides superclass
- (void)configureControl
{
    if(!self.control)
        return;
    
    self.textField.delegate = self;
    [self.textField addTarget:self action:@selector(textFieldEditingChanged:)
             forControlEvents:UIControlEventEditingChanged];
}


//overrides superclass
- (void)setEnabled:(BOOL)_enabled
{
    [super setEnabled:_enabled];
    
    if(_enabled)
        self.textField.textColor = _initialControlColor;
    else
        self.textField.textColor = self.disabledTextColor;
}

//overrides superclass
- (BOOL)canBecomeFirstResponder
{
    return TRUE;
}

//overrides superclass
- (BOOL)becomeFirstResponder
{
	[self.textField becomeFirstResponder];
    
    return TRUE;
}

//overrides superclass
- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    
	[self.textField resignFirstResponder];
    
    return TRUE;
}

//override's superclass
- (void)layoutSubviews
{
	[super layoutSubviews];
	
	// Adjust height & yCoord
    if(!self.controlCreatedInIB)
    {
        CGRect textFieldFrame = self.textField.frame;
        textFieldFrame.origin.y = ceilf((self.contentView.frame.size.height - SC_DefaultTextFieldHeight)/2);
        textFieldFrame.size.height = SC_DefaultTextFieldHeight;
        self.textField.frame = textFieldFrame;
    }
	
	[self didLayoutSubviews];
}

//overrides superclass
- (NSObject *)controlValue
{
	return self.textField.text;
}

//overrides superclass
- (void)loadBoundValueIntoControl
{
    if(_boundValueLoaded)
        return;

	if(self.boundPropertyName && (!self.boundValue || [SCUtilities isStringClass:[self.boundValue class]]) )
	{
		_pauseControlEvents = TRUE;
		self.textField.text = (NSString *)self.boundValue;
		_pauseControlEvents = FALSE;
        
        _boundValueLoaded = YES;
        
        self.lastLoadedControlValue = self.boundValue;
	}
}

//overrides superclass
- (void)commitChanges
{
	if(!self.needsCommit || !self.valueIsValid)
		return;
	
	self.boundValue = self.controlValue;
	
	[super commitChanges];
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCTextFieldAttributes class]])
		return;
	
	SCTextFieldAttributes *textFieldAttributes = (SCTextFieldAttributes *)attributes;
    
    if(!self.controlCreatedInIB)
    {
        if(textFieldAttributes.placeholder)
            self.textField.placeholder = textFieldAttributes.placeholder;
        self.textField.secureTextEntry = textFieldAttributes.secureTextEntry;
        self.textField.autocorrectionType = textFieldAttributes.autocorrectionType;
        self.textField.autocapitalizationType = textFieldAttributes.autocapitalizationType;
    }
}

//overrides superclass
- (BOOL)getValueIsValid
{
	if(![self.textField.text length] && self.valueRequired)
		return FALSE;
	//else
	return TRUE;
}

- (UITextField *)textField
{
	return (UITextField *)self.control;
}

- (void)clearControl
{
    self.textField.text = nil;
}

@end





@implementation SCNumericTextFieldCell

@synthesize minimumValue;
@synthesize maximumValue;
@synthesize allowFloatValue;
@synthesize displayZeroAsBlank;
@synthesize numberFormatter;



//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
	
	self.textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
	
	minimumValue = nil;
	maximumValue = nil;
	allowFloatValue = TRUE;
	displayZeroAsBlank = FALSE;
    
    numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
}


//overrides superclass
- (NSObject *)controlValue
{
    NSObject *value = nil;
    if([self.textField.text length])
    {
        [numberFormatter setMinimum:self.minimumValue];
        [numberFormatter setMaximum:self.maximumValue];
        [numberFormatter setAllowsFloats:self.allowFloatValue];
        
        value = [numberFormatter numberFromString:self.textField.text];
    }
    
	return value;
}

//overrides superclass
- (void)loadBoundValueIntoControl
{
    if(_boundValueLoaded)
        return;

	if( self.boundPropertyName && (!self.boundValue || [self.boundValue isKindOfClass:[NSNumber class]]))
	{
		_pauseControlEvents = TRUE;
		
		NSNumber *numericValue = (NSNumber *)self.boundValue;
		if(numericValue)
		{
			if([numericValue floatValue]==0.0f && self.displayZeroAsBlank)
				self.textField.text = nil;
			else
            {
                [numberFormatter setMinimum:self.minimumValue];
                [numberFormatter setMaximum:self.maximumValue];
                [numberFormatter setAllowsFloats:self.allowFloatValue];
                
                self.textField.text = [numberFormatter stringFromNumber:numericValue];
            }
		}
		else
		{
			self.textField.text = nil;
		}
		
		_pauseControlEvents = FALSE;
        
        _boundValueLoaded = YES;
        
        self.lastLoadedControlValue = self.boundValue;
	}
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCNumericTextFieldAttributes class]])
		return;
	
	SCNumericTextFieldAttributes *numericTextFieldAttributes = 
											(SCNumericTextFieldAttributes *)attributes;
	if(numericTextFieldAttributes.minimumValue)
		self.minimumValue = numericTextFieldAttributes.minimumValue;
	if(numericTextFieldAttributes.maximumValue)
		self.maximumValue = numericTextFieldAttributes.maximumValue;
	self.allowFloatValue = numericTextFieldAttributes.allowFloatValue;
    if(numericTextFieldAttributes.numberFormatter)
    {
        numberFormatter = numericTextFieldAttributes.numberFormatter;
    }
}

//overrides superclass
- (BOOL)getValueIsValid
{	
	if(![self.textField.text length])
	{
		if(self.valueRequired)
			return FALSE;
		//else
		return TRUE;
	}
		
	[numberFormatter setMinimum:self.minimumValue];
	[numberFormatter setMaximum:self.maximumValue];
	[numberFormatter setAllowsFloats:self.allowFloatValue];
	BOOL valid;
	if([numberFormatter numberFromString:self.textField.text])
		valid = TRUE;
	else
		valid = FALSE;
		
	return valid;
}


@end







@implementation SCSliderCell


+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object sliderValuePropertyName:(NSString *)propertyName
{
	return [[[self class] alloc] initWithText:cellText boundObject:object sliderValuePropertyName:propertyName];
}


//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
	
	self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UISlider *slider = [[UISlider alloc] init];
    slider.continuous = FALSE;
    self.control = slider;
}

//overrides superclass
- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object sliderValuePropertyName:(NSString *)propertyName
{
	return [self initWithText:cellText boundObject:object boundPropertyName:propertyName];
}

//overrides superclass
- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object boundPropertyName:(NSString *)propertyName
{
	self = [super initWithText:cellText boundObject:object boundPropertyName:propertyName];
	
	if(self.boundObject && !self.boundValue && self.commitChangesLive)
		self.boundValue = [NSNumber numberWithFloat:self.slider.value];
	
	return self;
}


// overrides superclass
- (Class)expectedControlClass
{
    return [UISlider class];
}

// overrides superclass
- (void)configureControl
{
    if(!self.control)
        return;
    
    [self.slider addTarget:self action:@selector(sliderValueChanged:)
          forControlEvents:UIControlEventValueChanged];
}


//overrides superclass
- (NSObject *)controlValue
{
    return [NSNumber numberWithFloat:self.slider.value];
}

//overrides superclass
- (void)loadBoundValueIntoControl
{
    if(_boundValueLoaded)
        return;

	if(self.boundPropertyName && [self.boundValue isKindOfClass:[NSNumber class]])
	{
		_pauseControlEvents = TRUE;
		self.slider.value = [(NSNumber *)self.boundValue floatValue];
		_pauseControlEvents = FALSE;
        
        _boundValueLoaded = YES;
        
        self.lastLoadedControlValue = self.boundValue;
	}
}

//overrides superclass
- (void)commitChanges
{
	if(!self.needsCommit || !self.valueIsValid)
		return;
	
	self.boundValue = self.controlValue;
	
    [super commitChanges];
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCSliderAttributes class]])
		return;
	
	SCSliderAttributes *sliderAttributes = (SCSliderAttributes *)attributes;
    
    if(!self.controlCreatedInIB)
    {
        if(sliderAttributes.minimumValue >= 0)
            self.slider.minimumValue = sliderAttributes.minimumValue;
        if(sliderAttributes.maximumValue >= 0)
            self.slider.maximumValue = sliderAttributes.maximumValue;
    }
}

- (UISlider *)slider
{
	return (UISlider *)self.control;
}

@end






@implementation SCSegmentedCell


+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object selectedSegmentIndexPropertyName:(NSString *)propertyName segmentTitlesArray:(NSArray *)cellSegmentTitlesArray
{
	return [[[self class] alloc] initWithText:cellText boundObject:object selectedSegmentIndexPropertyName:propertyName
						segmentTitlesArray:cellSegmentTitlesArray];
}


//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
	
	self.selectionStyle = UITableViewCellSelectionStyleNone;
	
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] init];
    self.control = segmentedControl;
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object selectedSegmentIndexPropertyName:(NSString *)propertyName segmentTitlesArray:(NSArray *)cellSegmentTitlesArray
{
	if( (self=[self initWithText:cellText boundObject:object boundPropertyName:propertyName]) )
	{
		[self createSegmentsUsingArray:cellSegmentTitlesArray];
	}
	return self;
}


//overrides superclass
- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object boundPropertyName:(NSString *)propertyName
{
	self = [super initWithText:cellText boundObject:object boundPropertyName:propertyName];
	
	if(self.boundObject && !self.boundValue)
		self.boundValue = [NSNumber numberWithInt:-1];
	
	return self;
}


// overrides superclass
- (Class)expectedControlClass
{
    return [UISegmentedControl class];
}

// overrides superclass
- (void)configureControl
{
    if(!self.control)
        return;
    
    [self.segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
}


//override's superclass
- (void)layoutSubviews
{
	[super layoutSubviews];
	
	// Adjust height & yCoord
    if(!self.controlCreatedInIB)
    {
        CGRect segmentedFrame = self.segmentedControl.frame;
        segmentedFrame.origin.y = (self.contentView.frame.size.height - kDefaultSegmentedHeight)/2;
        segmentedFrame.size.height = kDefaultSegmentedHeight;
        self.segmentedControl.frame = segmentedFrame;
    }
	
	[self didLayoutSubviews];
}

//overrides superclass
- (NSObject *)controlValue
{
    if(self.boundPropertyDataType == SCDataTypeNSString)
        return [self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex];
    //else
    return [NSNumber numberWithUnsignedInteger:self.segmentedControl.selectedSegmentIndex];
}

//override's superclass
- (void)loadBoundValueIntoControl
{
    if(_boundValueLoaded)
        return;

    if(self.boundPropertyName)
    {
        _pauseControlEvents = TRUE;
        
        if([self.boundValue isKindOfClass:[NSNumber class]])
        {
            self.segmentedControl.selectedSegmentIndex = [(NSNumber *)self.boundValue intValue];
        }
        else if([self.boundValue isKindOfClass:[NSString class]])
        {
            NSMutableArray *segmentTitles = [NSMutableArray array];
            for(NSInteger i=0; i<self.segmentedControl.numberOfSegments; i++)
                [segmentTitles addObject:[self.segmentedControl titleForSegmentAtIndex:i]];
            NSInteger selectedIndex = [segmentTitles indexOfObject:self.boundValue];
            if(selectedIndex != NSNotFound)
                self.segmentedControl.selectedSegmentIndex = selectedIndex;
        }
        
        _pauseControlEvents = FALSE;
        
        _boundValueLoaded = YES;
        
        self.lastLoadedControlValue = self.boundValue;
    }
}

//override's superclass
- (void)commitChanges
{
	if(!self.needsCommit || !self.valueIsValid)
		return;
	
	self.boundValue = self.controlValue;
    
	[super commitChanges];
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCSegmentedAttributes class]])
		return;
	
	SCSegmentedAttributes *segmentedAttributes = (SCSegmentedAttributes *)attributes;
    
    if(!self.controlCreatedInIB || self.segmentedControl.numberOfSegments<2)
    {
        if(segmentedAttributes.segmentTitlesArray)
            [self createSegmentsUsingArray:segmentedAttributes.segmentTitlesArray];
    }
}

//overrides superclass
- (BOOL)getValueIsValid
{
	if( (self.segmentedControl.selectedSegmentIndex==-1) && self.valueRequired )
		return FALSE;
	//else
	return TRUE;
}

- (UISegmentedControl *)segmentedControl
{
	return (UISegmentedControl *)self.control;
}

- (void)createSegmentsUsingArray:(NSArray *)segmentTitlesArray
{
	[self.segmentedControl removeAllSegments];
	if(segmentTitlesArray)
	{
		for(NSUInteger i=0; i<segmentTitlesArray.count; i++)
		{
			NSString *segmentTitle = (NSString *)[segmentTitlesArray objectAtIndex:i];
			[self.segmentedControl insertSegmentWithTitle:segmentTitle atIndex:i 
												 animated:FALSE];
		}
	}
}


@end






@implementation SCSwitchCell


+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object switchOnPropertyName:(NSString *)propertyName
{
	return [[[self class] alloc] initWithText:cellText boundObject:object switchOnPropertyName:propertyName];
}


//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
	
	self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UISwitch *switchControl = [[UISwitch alloc] init];
    self.control = switchControl;
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object switchOnPropertyName:(NSString *)propertyName
{
	return [self initWithText:cellText boundObject:object boundPropertyName:propertyName];
}

//overrides superclass
- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object boundPropertyName:(NSString *)propertyName
{
	self = [super initWithText:cellText boundObject:object boundPropertyName:propertyName];
	
	if(self.boundObject && !self.boundValue && self.commitChangesLive)
		self.boundValue = [NSNumber numberWithBool:self.switchControl.on];
	
	return self;
}


// overrides superclass
- (Class)expectedControlClass
{
    return [UISwitch class];
}

// overrides superclass
- (void)configureControl
{
    if(!self.control)
        return;
    
    [self.switchControl addTarget:self action:@selector(switchControlChanged:) forControlEvents:UIControlEventValueChanged];
}


//overrides superclass
- (void)layoutSubviews
{
	[super layoutSubviews];
	
    if(!self.controlCreatedInIB)
    {
        CGSize contentViewSize = self.contentView.bounds.size;
        CGRect switchFrame = self.switchControl.frame;
        switchFrame.origin.x = contentViewSize.width - switchFrame.size.width - 10;
        switchFrame.origin.y = (contentViewSize.height-switchFrame.size.height)/2;
        self.switchControl.frame = switchFrame;
    }
	
	[self didLayoutSubviews];
}

//overrides superclass
- (NSObject *)controlValue
{
    return [NSNumber numberWithBool:self.switchControl.on];
}

//overrides superclass
- (void)loadBoundValueIntoControl
{
    if(_boundValueLoaded)
        return;

	if(self.boundPropertyName && [self.boundValue isKindOfClass:[NSNumber class]])
	{
		_pauseControlEvents = TRUE;
		self.switchControl.on = [(NSNumber *)self.boundValue boolValue];
		_pauseControlEvents = FALSE;
        
        _boundValueLoaded = YES;
        
        self.lastLoadedControlValue = self.boundValue;
	}
}

//overrides superclass
- (void)commitChanges
{
	if(!self.needsCommit || !self.valueIsValid)
		return;
	
	self.boundValue = self.controlValue;
	
    [super commitChanges];
}

- (UISwitch *)switchControl
{
	return (UISwitch *)self.control;
}

@end





#define kDefaultEmbeddedDatePickerHeight    163


@interface SCDateCell ()
{
    BOOL _embeddedPickerVisible;
    BOOL _dateCleared;
}

- (void)pickerValueChanged;
- (void)deviceOrientationDidChange:(NSNotification *)notification;

@end



@implementation SCDateCell

@synthesize datePicker;
@synthesize dateFormatter;
@synthesize displaySelectedDate;


+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object datePropertyName:(NSString *)propertyName
{
	return [[[self class] alloc] initWithText:cellText boundObject:object datePropertyName:propertyName];
}


//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
    
    _dateCleared = FALSE;
    _activePickerDetailViewController = nil;
	
	datePicker = [[UIDatePicker alloc] init];
	[datePicker addTarget:self action:@selector(pickerValueChanged) 
		 forControlEvents:UIControlEventValueChanged];
	
	_pickerField = [[UITextField alloc] initWithFrame:CGRectZero];
	_pickerField.delegate = self;
	_pickerField.inputView = datePicker;
	[self.contentView addSubview:_pickerField];
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MMM d  hh:mm a"];
	displaySelectedDate = TRUE;
	_displayDatePickerAsInputAccessoryView = FALSE;
    self.showClearButtonInInputAccessoryView = TRUE;
    
    // Track device orientation changes to correctly show/hide the date picker
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object:nil];
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object datePropertyName:(NSString *)propertyName
{
	return [self initWithText:cellText boundObject:object boundPropertyName:propertyName];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}


//overrides superclass
- (BOOL)canBecomeFirstResponder
{
    if(self.displayDatePickerAsInputAccessoryView)
        return TRUE;
    //else
    return FALSE;
}

//overrides superclass
- (BOOL)becomeFirstResponder
{
    if(self.displayDatePickerAsInputAccessoryView)
    {
        [_pickerField becomeFirstResponder];
        [self callDidBecomeFirstResponderActions];
        
        return TRUE;
    }

    return FALSE;
}

//overrides superclass
- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    
    BOOL response = YES;
    
    if(self.displayDatePickerAsInputAccessoryView)
    {
        response = [_pickerField resignFirstResponder];
    }
    else
    {
        response = NO;
    }
    
    [self callDidResignFirstResponderActions];
    
	return response;
}

- (void)showEmbeddedDatePicker
{
    if(_embeddedPickerVisible)
        return;
    
    _embeddedPickerVisible = YES;
    
    [self.ownerTableViewModel.tableView reloadData];
    
    if(!self.datePicker.superview)
        [self.contentView addSubview:self.datePicker];
}

- (void)hideEmbeddedDatePicker
{
    if(!_embeddedPickerVisible)
        return;
    
    _embeddedPickerVisible = NO;
    
    if(self.datePicker.superview == self.contentView)
        [self.datePicker removeFromSuperview];
    
    [self.ownerTableViewModel.tableView reloadData];
}

//overrides superclass
- (NSObject *)controlValue
{
    NSDate *value = nil;
    if(self.label.text && ![self.label.text isEqualToString:self.placeholder])  // a date has been selected
        value = self.datePicker.date;
    
    if(self.datePicker.datePickerMode == UIDatePickerModeDate)
        value = [SCUtilities stripTimeFromDate:value];
    
    return value;
}

//overrides superclass
- (void)loadBoundValueIntoLabel
{
    // Set the picker's frame before setting its value (required for iPad compatability)
	CGRect pickerFrame = CGRectZero;

	if([SCUtilities is_iPad])
		pickerFrame.size.width = self.ownerTableViewModel.viewController.preferredContentSize.width;
	else
		pickerFrame.size.width = self.ownerTableViewModel.viewController.view.frame.size.width;
	pickerFrame.size.height = 216;
	self.datePicker.frame = pickerFrame;
	
	NSDate *date = nil;
	if(self.boundPropertyName && [self.boundValue isKindOfClass:[NSDate class]])
	{
		date = (NSDate *)self.boundValue;
		self.datePicker.date = date;
	}
	
    if(date)
        self.label.text = [dateFormatter stringFromDate:date];
    else
        self.label.text = self.placeholder;
	
    self.label.hidden = !self.displaySelectedDate;
    
    _boundValueLoaded = YES;
}

//override superclass
- (CGFloat)height
{
    CGFloat cellHeight = [super height];
    
    if(_embeddedPickerVisible)
        cellHeight += kDefaultEmbeddedDatePickerHeight;
    
    return cellHeight;
}

//override superclass
- (void)layoutSubviews
{
	[super layoutSubviews];
	
	if(_embeddedPickerVisible)
    {
        CGRect pickerFrame = CGRectMake(kDefaultControlMargin, [super height], self.ownerTableViewModel.tableView.frame.size.width - 2*kDefaultControlMargin, kDefaultEmbeddedDatePickerHeight);
        self.datePicker.frame = pickerFrame;
        
        if(!self.controlCreatedInIB)
        {
            if([self.textLabel.text length])
            {
                CGRect textLabelFrame = self.textLabel.frame;
                textLabelFrame.origin.y = kYMargin + 1;
                self.textLabel.frame = textLabelFrame;
            }
            
            CGRect labelFrame = self.label.frame;
            labelFrame.origin.y = kYMargin + 1;
            self.label.frame = labelFrame;
        }
        
        [self didLayoutSubviews];
    }
}

//override superclass
- (void)cellValueChanged
{
    if(!_dateCleared)
        self.label.text = [dateFormatter stringFromDate:self.datePicker.date];
    else
        _dateCleared = FALSE; // reset flag
	
	[super cellValueChanged];
}

//overrides superclass
- (void)commitDetailModelChanges:(SCTableViewModel *)detailModel
{
	[self cellValueChanged];
}

//overrides superclass
- (void)commitChanges
{
	if(!self.needsCommit || !self.valueIsValid)
		return;
	
	if(self.label.text)	// if a date value have been selected
		self.boundValue = self.datePicker.date;
    else
        self.boundValue = nil;
    
	[super commitChanges];
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCDateAttributes class]])
		return;
	
	SCDateAttributes *dateAttributes = (SCDateAttributes *)attributes;
	if(dateAttributes.dateFormatter)
		self.dateFormatter = dateAttributes.dateFormatter;
	self.datePicker.datePickerMode = dateAttributes.datePickerMode;
    if(!self.displayDatePickerAsInputAccessoryView)
        self.displayDatePickerAsInputAccessoryView = dateAttributes.displayDatePickerAsInputAccessoryView;
}

//overrides superclass
- (BOOL)getValueIsValid
{
	if(!self.label.text && self.valueRequired)
		return FALSE;
	//else
	return TRUE;
}

// overrides superclass
- (void)setEnabled:(BOOL)isEnabled
{
    if(!isEnabled && !self.displayDatePickerAsInputAccessoryView)
        [self hideEmbeddedDatePicker];
    
    [super setEnabled:isEnabled];
}

//override parent's
- (void)didSelectCell
{
	if(self.displayDatePickerAsInputAccessoryView)
	{
		if(![_pickerField isFirstResponder])
		{
			[_pickerField becomeFirstResponder];
            [self callDidBecomeFirstResponderActions];
		}
	}
    else
    {
        if(_embeddedPickerVisible)
            [self hideEmbeddedDatePicker];
        else
            [self showEmbeddedDatePicker];
    }
    
    self.ownerTableViewModel.activeCell = self;
    
    [super didSelectCell];
}

- (void)willDeselectCell
{	
	if(_embeddedPickerVisible)
	{
		[self hideEmbeddedDatePicker];
	}
    
    [super willDeselectCell];
}

- (void)pickerValueChanged
{
	[self cellValueChanged];
}

- (void)clearControl
{
    self.label.text = nil;
    _dateCleared = TRUE;
    
    [self cellValueChanged];
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    [self resignFirstResponder];
}

@end






@interface SCImagePickerCell ()
{
    UIImageView *_detailImageView;
}

@property (nonatomic, readonly) UIImageView *effectiveImageView;

- (NSString *)selectedImagePath;
- (void)setCachedImage;
- (void)displayImagePicker;
- (void)displayImageInDetailView;
- (void)addImageViewToDetailView:(UIViewController *)detailView;
- (void)didTapClearImageButton;

@end



@implementation SCImagePickerCell

@synthesize imagePickerController;
@synthesize placeholderImageName;
@synthesize placeholderImageTitle;
@synthesize displayImageNameAsCellText;
@synthesize askForSourceType;
@synthesize selectedImageName;
@synthesize clearImageButton;
@synthesize displayClearImageButtonInDetailView;
@synthesize autoPositionClearImageButton;
@synthesize textLabelFrame;
@synthesize imageViewFrame;

+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object imageNamePropertyName:(NSString *)propertyName
{
	return [[[self class] alloc] initWithText:cellText boundObject:object imageNamePropertyName:propertyName];
}


//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
	
	cachedImage = nil;

	popover = nil;
	
	imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.delegate = self;
	
	placeholderImageName = nil;
	placeholderImageTitle = nil;
	displayImageNameAsCellText = TRUE;
	askForSourceType = TRUE;
	selectedImageName = nil;
	autoPositionImageView = TRUE;
	
	clearImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
	clearImageButton.frame = CGRectMake(0, 0, 120, 25);
	[clearImageButton setTitle:NSLocalizedString(@"Clear Image", @"Clear Image Button Title") forState:UIControlStateNormal];
	[clearImageButton addTarget:self action:@selector(didTapClearImageButton) 
			   forControlEvents:UIControlEventTouchUpInside];
	clearImageButton.backgroundColor = [UIColor grayColor];
	clearImageButton.layer.cornerRadius = 8.0f;
	clearImageButton.layer.masksToBounds = YES;
	clearImageButton.layer.borderWidth = 1.0f;
	displayClearImageButtonInDetailView = TRUE;
	autoPositionClearImageButton = TRUE;
	
	textLabelFrame = CGRectMake(0, 0, 0, 0);
	imageViewFrame = CGRectMake(0, 0, 0, 0);
	
	// Add rounded corners to the image view
	self.effectiveImageView.layer.masksToBounds = YES;
	self.effectiveImageView.layer.cornerRadius = 8.0f;
    
    _pinchZoomScrollView = [[UIScrollView alloc] init];
    _pinchZoomScrollView.minimumZoomScale = 0.5f;
    _pinchZoomScrollView.maximumZoomScale = 3.0f;
    _pinchZoomScrollView.delegate = self;
	
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object imageNamePropertyName:(NSString *)propertyName
{
	if( (self=[self initWithText:cellText boundObject:object boundPropertyName:propertyName]) )
	{
		self.selectedImageName = (NSString *)self.boundValue;
		[self setCachedImage];
	}
	return self;
}


- (UIImageView *)effectiveImageView
{
    if(self.customImageView)
        return self.customImageView;
    //else
    return self.imageView;
}


//overrides superclass
- (void)setEnabled:(BOOL)_enabled
{
    return;  // does nothing, image picker cells should not be disabled since their reviel viewer when not in edit mode.
}

- (void)resetClearImageButtonStyles
{
	clearImageButton.backgroundColor = [UIColor clearColor];
	clearImageButton.layer.cornerRadius = 0.0f;
	clearImageButton.layer.masksToBounds = NO;
	clearImageButton.layer.borderWidth = 0.0f;
}

- (UIImage *)selectedImage
{
	if(self.selectedImageName && !cachedImage)
		[self setCachedImage];
	
	return cachedImage;
}

- (void)setCachedImage
{
	cachedImage = nil;
	
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    NSString *imagePath = [self selectedImagePath];
    UIImage *image;
    if(self.cellActions.loadImage)
        image = self.cellActions.loadImage(self, indexPath, imagePath);
    else
        if(self.ownerSection.cellActions.loadImage)
            image = self.ownerSection.cellActions.loadImage(self, indexPath, imagePath);
        else
            if(self.ownerTableViewModel.cellActions.loadImage)
                image = self.ownerTableViewModel.cellActions.loadImage(self, indexPath, imagePath);
    else
        image = [self loadImageFromPath:imagePath];
    
	if(image)
	{
		cachedImage = image;
	}
}

- (NSString *)selectedImagePath
{
	if(!self.selectedImageName)
		return nil;
	
	NSString *fullName = [NSString stringWithFormat:@"Documents/%@", self.selectedImageName];
	
	return [NSHomeDirectory() stringByAppendingPathComponent:fullName];
}

//overrides superclass
- (void)layoutSubviews
{
	// call before [super layoutSubviews]
	if(self.selectedImageName)
	{
		if(self.displayImageNameAsCellText)
			self.textLabel.text = self.selectedImageName;
		
		if(!cachedImage)
			[self setCachedImage];
		
		self.effectiveImageView.image = cachedImage;
		
		if(cachedImage)
		{
            if(!self.customImageView)
            {
                // Set the correct frame for imageView
                CGRect imgframe = self.imageView.frame;
                imgframe.origin.x = 2;
                imgframe.origin.y = 3;
                imgframe.size.height -= 4;
                self.imageView.frame = imgframe;
            }
			
			self.effectiveImageView.image = cachedImage;
		}
	}
	else
	{
		if(self.displayImageNameAsCellText)
			self.textLabel.text = @"";
		
		if(self.placeholderImageName)
			self.effectiveImageView.image = [UIImage imageNamed:self.placeholderImageName];
		else
			self.effectiveImageView.image = nil;
	}
	
	[super layoutSubviews];
	
	if(self.textLabelFrame.size.height)
	{
		self.textLabel.frame = self.textLabelFrame;
	}
	if(self.imageViewFrame.size.height && !self.customImageView)
	{
		self.imageView.frame = self.imageViewFrame;
	}
}

//overrides superclass
- (void)commitChanges
{
	if(!self.needsCommit)
		return;
	
	self.boundValue = self.selectedImageName;
	
	[super commitChanges];
}

//overrides superclass
- (BOOL)getValueIsValid
{
	if(!self.selectedImageName && self.valueRequired)
		return FALSE;
	//else
	return TRUE;
}

//override parent's
- (void)didSelectCell
{
    [super didSelectCell];
    
	self.ownerTableViewModel.activeCell = self;

	if(!self.ownerTableViewModel.tableView.editing && self.selectedImage)
	{
		[self displayImageInDetailView];
		return;
	}
	
	BOOL actionSheetDisplayed = FALSE;
	
	if(self.askForSourceType)
	{
		if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		{
			UIActionSheet *actionSheet = [[UIActionSheet alloc]
										 initWithTitle:nil
										 delegate:self
										 cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel Button Title")
										 destructiveButtonTitle:nil
										 otherButtonTitles:NSLocalizedString(@"Take Photo", @"Take Photo Button Title"),
										  NSLocalizedString(@"Choose Photo", @"Choose Photo Button Title"),nil];
			[actionSheet showInView:self.ownerTableViewModel.viewController.view];
			
			actionSheetDisplayed = TRUE;
		}
		else
		{
			self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		}
	}
	
	if(!actionSheetDisplayed)
		[self displayImagePicker];
}	

- (void)displayImageInDetailView
{
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    
    UIViewController *detailViewController = [self generatedDetailViewController:indexPath];
    
    
    [self presentDetailViewController:detailViewController forCell:self forRowAtIndexPath:indexPath withPresentationMode:self.detailViewControllerOptions.presentationMode];
}

// overrides superclass
- (UIViewController *)generatedDetailViewController:(NSIndexPath *)indexPath
{
    UIViewController *detailViewController = [self getDetailViewControllerForCell:self forRowAtIndexPath:indexPath allowUITableViewControllerSubclass:NO];
    if([detailViewController isKindOfClass:[SCViewController class]])
    {
        [(SCViewController *)detailViewController setNavigationBarType:SCNavigationBarTypeNone];
    }
    
    if(!self.detailViewControllerOptions.title)
        detailViewController.title = self.textLabel.text;
    if([SCUtilities is_iPad])
        detailViewController.view.backgroundColor = [UIColor colorWithRed:32.0f/255 green:35.0f/255 blue:42.0f/255 alpha:1];
    else
        detailViewController.view.backgroundColor = [UIColor colorWithRed:41.0f/255 green:42.0f/255 blue:57.0f/255 alpha:1];
    
    return detailViewController;
}

// overrides superclass
- (BOOL)generatesDetailView
{
    return YES;
}

- (void)addImageViewToDetailView:(UIViewController *)detailView
{
    if(_detailImageView)
        [_detailImageView removeFromSuperview];
    
    _detailImageView = [[UIImageView alloc] initWithImage:self.selectedImage];
    
    CGRect frame = detailView.view.frame;
    frame.origin.y = 0; // make sure it takes full height
	self.pinchZoomScrollView.frame = frame;
    self.pinchZoomScrollView.contentSize = self.selectedImage.size;
    [self.pinchZoomScrollView addSubview:_detailImageView];
    [detailView.view addSubview:self.pinchZoomScrollView];
    
    // The the zoom scale to display the whole image
    if(self.pinchZoomScrollView.contentSize.width && self.pinchZoomScrollView.contentSize.height)
    {
        CGRect scrollViewFrame = self.pinchZoomScrollView.frame;
        CGFloat scaleWidth = scrollViewFrame.size.width / self.pinchZoomScrollView.contentSize.width;
        CGFloat scaleHeight = scrollViewFrame.size.height / self.pinchZoomScrollView.contentSize.height;
        CGFloat minScale = fmin(scaleWidth, scaleHeight);
        self.pinchZoomScrollView.minimumZoomScale = minScale;
        self.pinchZoomScrollView.zoomScale = minScale;
    }
    
    // Modify _detailImageView frame to be displayed in the center of the scroll view
    CGSize boundsSize = self.pinchZoomScrollView.bounds.size;
    CGRect contentsFrame = _detailImageView.frame;
    if(contentsFrame.size.width < boundsSize.width)
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0;
        else
            contentsFrame.origin.x = 0.0;
    if(contentsFrame.size.height < boundsSize.height)
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0;
        else
            contentsFrame.origin.y = 0.0;
    //_detailImageView.frame = contentsFrame;
	
    
	//Add clearImageButton
	if(self.displayClearImageButtonInDetailView)
	{
		if(self.autoPositionClearImageButton)
		{
            CGSize detailViewSize = detailView.view.frame.size;
			CGRect btnFrame = self.clearImageButton.frame;
            CGFloat navBarHeight = 0;
            if(detailView.navigationController)
                navBarHeight = detailView.navigationController.navigationBar.frame.size.height;
			self.clearImageButton.frame = CGRectMake(detailViewSize.width - btnFrame.size.width - 10,
													 detailViewSize.height - btnFrame.size.height - navBarHeight - 30,
													 btnFrame.size.width, btnFrame.size.height);
		}
        
		[detailView.view addSubview:self.clearImageButton];
	}
}

- (void)didTapClearImageButton
{
	self.selectedImageName = nil;
	cachedImage = nil;
	[_detailImageView removeFromSuperview];
    _detailImageView = nil;
	
	[self cellValueChanged];
}

- (void)displayImagePicker
{	
	if([SCUtilities is_iPad])
	{
		popover = [[UIPopoverController alloc] initWithContentViewController:self.imagePickerController];
		[popover presentPopoverFromRect:self.frame inView:self.ownerTableViewModel.viewController.view
			   permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
	else
	{
        [self prepareCellForDetailViewAppearing];
        
		[self.ownerTableViewModel.viewController presentViewController:self.imagePickerController animated:TRUE completion:nil];
	}
}


- (void)saveImage:(UIImage *)image toPath:(NSString *)imagePath
{
    [UIImageJPEGRepresentation(image, 80) writeToFile:imagePath atomically:YES];
}

- (UIImage *)loadImageFromPath:(NSString *)imagePath
{
    return [UIImage imageWithContentsOfFile:imagePath];
}


#pragma mark -
#pragma mark UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet
	clickedButtonAtIndex:(NSInteger)buttonIndex
{
	BOOL cancelTapped = FALSE;
	switch (buttonIndex)
	{
		case 0:  // Take Photo
			self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
			break;
		case 1:  // Choose Photo
			self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
			break;	
		default:
			cancelTapped = TRUE;
			break;
	}
	
	if(!cancelTapped)
    {
        // Add on main queue so as to wait until the action sheet is dismissed
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self displayImagePicker];
        }];
    }
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate methods

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self.imagePickerController dismissViewControllerAnimated:TRUE completion:nil];
	
	[self prepareCellForDetailViewDisappearing];
    
    [self handleDetailViewControllerDidDismiss:self.imagePickerController cancelButtonTapped:YES doneButtonTapped:NO];
}

- (void)imagePickerController:(UIImagePickerController *)picker 
	didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self.imagePickerController dismissViewControllerAnimated:TRUE completion:nil];
	
	if([SCUtilities is_iPad])
	{
		[popover dismissPopoverAnimated:TRUE];
	}
	else
	{
		[self prepareCellForDetailViewDisappearing];
	}
	
	cachedImage = nil;
    
    
    // Fetch the image asset then call [self imageAssetFetched] to finalize image selection
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *imageAsset)
    {
        [self imageAssetFetched:imageAsset mediaInfo:info];
    };
    ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
    NSURL *mediaUrl = info[UIImagePickerControllerReferenceURL];
    if(mediaUrl)
    {
        [assetslibrary assetForURL:mediaUrl resultBlock:resultblock failureBlock:nil];  // asynchronous call
    }
    else
    {
        // photo was just taken with the camera and no mediaUrl is available
        [self imageAssetFetched:nil mediaInfo:info];
    }
    
    
    [self handleDetailViewControllerDidDismiss:self.imagePickerController cancelButtonTapped:NO doneButtonTapped:YES];
}

- (void)imageAssetFetched:(ALAsset *)imageAsset mediaInfo:(NSDictionary *)info
{
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    
    if(self.cellActions.didFinishPickingMedia)
    {
        self.cellActions.didFinishPickingMedia(self, indexPath, info, imageAsset);
    }
    else
        if(self.ownerSection.cellActions.didFinishPickingMedia)
        {
            self.ownerSection.cellActions.didFinishPickingMedia(self, indexPath, info, imageAsset);
        }
        else
            if(self.ownerTableViewModel.cellActions.didFinishPickingMedia)
            {
                self.ownerTableViewModel.cellActions.didFinishPickingMedia(self, indexPath, info, imageAsset);
            }
    
    
    UIImage *image = nil;
    if(self.imagePickerController.allowsEditing)
        image = [info valueForKey:UIImagePickerControllerEditedImage];
    if(!image)
        image = [info valueForKey:UIImagePickerControllerOriginalImage];
    if(image)
    {
        cachedImage = image;
        
        if(self.cellActions.imageName)
            self.selectedImageName = self.cellActions.imageName(self, indexPath);
        else
            if(self.ownerSection.cellActions.imageName)
                self.selectedImageName = self.ownerSection.cellActions.imageName(self, indexPath);
            else
                if(self.ownerTableViewModel.cellActions.imageName)
                    self.selectedImageName = self.ownerTableViewModel.cellActions.imageName(self, indexPath);
                else
                {
                    // default to the original image file name if possible
                    if(imageAsset)
                    {
                        ALAssetRepresentation *imageRep = [imageAsset defaultRepresentation];
                        self.selectedImageName = [imageRep filename];
                    }
                }
        if(!self.selectedImageName)
            self.selectedImageName = [NSString stringWithFormat:@"%@", [NSDate date]];
        
        // Save the image
        NSString *imagePath = [self selectedImagePath];
        if(self.cellActions.saveImage)
            self.cellActions.saveImage(self, indexPath, imagePath);
        else
            if(self.ownerSection.cellActions.saveImage)
                self.ownerSection.cellActions.saveImage(self, indexPath, imagePath);
            else
                if(self.ownerTableViewModel.cellActions.saveImage)
                    self.ownerTableViewModel.cellActions.saveImage(self, indexPath, imagePath);
                else
                    [self saveImage:image toPath:imagePath];
        
        [self layoutSubviews];
        
        
        // reload cell
        if(indexPath)
        {
            NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
            [self.ownerTableViewModel.tableView reloadRowsAtIndexPaths:indexPaths
                                                      withRowAnimation:UITableViewRowAnimationNone];
        }
        
        [self cellValueChanged];
    }
}


- (void)handleDetailViewControllerWillPresent:(UIViewController *)detailViewController
{
	[self addImageViewToDetailView:detailViewController];
	
	[super handleDetailViewControllerWillPresent:detailViewController];
}

#pragma mark -
#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _detailImageView;
}

// Make sure _detailImageView is always centered
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat offsetX = MAX((scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5, 0.0);
    CGFloat offsetY = MAX((scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5, 0.0);
    
    _detailImageView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,
                                 scrollView.contentSize.height * 0.5 + offsetY);
}

@end







@interface SCSelectionCell ()
{
    @protected
    NSArray *items;
    BOOL itemsInSync;
    BOOL _loadingContents;
    UIActivityIndicatorView *_activityIndicator;
    BOOL _commitingDetailModel;
}

- (void)buildSelectedItemsIndexesFromBoundValue;
- (void)buildSelectedItemsIndexesFromString:(NSString *)string;
- (NSString *)buildStringFromSelectedItemsIndexes;

- (NSString *)getTitleForItemAtIndex:(NSUInteger)index;

@end

@implementation SCSelectionCell

@synthesize selectionItemsStore;
@synthesize selectionItemsFetchOptions;
@synthesize allowMultipleSelection;
@synthesize allowNoSelection;
@synthesize maximumSelections;
@synthesize autoDismissDetailView;
@synthesize hideDetailViewNavigationBar;
@synthesize allowAddingItems;
@synthesize allowDeletingItems;
@synthesize allowMovingItems;
@synthesize allowEditDetailView;
@synthesize displaySelection;
@synthesize delimeter;
@synthesize selectedItemsIndexes;
@synthesize placeholderCell;
@synthesize addNewItemCell;


+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object selectedIndexPropertyName:(NSString *)propertyName items:(NSArray *)cellItems
{
	return [[[self class] alloc] initWithText:cellText boundObject:object selectedIndexPropertyName:propertyName items:cellItems];
}

+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object selectedIndexesPropertyName:(NSString *)propertyName items:(NSArray *)cellItems allowMultipleSelection:(BOOL)multipleSelection;
{
	return [[[self class] alloc] initWithText:cellText boundObject:object selectedIndexesPropertyName:propertyName items:cellItems allowMultipleSelection:multipleSelection];
}

+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object selectionStringPropertyName:(NSString *)propertyName items:(NSArray *)cellItems
{
	return [[[self class] alloc] initWithText:cellText boundObject:object selectionStringPropertyName:propertyName items:cellItems];
}


//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
	
	selectionItemsStore = nil;
    selectionItemsFetchOptions = nil;  // will be re-initialized when selectionItemsStore is set
    items = nil;
    itemsInSync = FALSE;
    _loadingContents = FALSE;
    _activityIndicator = nil;
    _commitingDetailModel = FALSE;
    
	allowMultipleSelection = FALSE;
	allowNoSelection = FALSE;
	maximumSelections = 0;
	autoDismissDetailView = FALSE;
	hideDetailViewNavigationBar = FALSE;
    allowAddingItems = FALSE;
	allowDeletingItems = FALSE;
	allowMovingItems = FALSE;
	allowEditDetailView = FALSE;
	displaySelection = TRUE;
	delimeter = @", ";
	selectedItemsIndexes = [[NSMutableSet alloc] init];
    placeholderCell = nil;
    
    addNewItemCell = nil;
    _addNewItemCellExistsInNormalMode = FALSE;
    _addNewItemCellExistsInEditingMode = TRUE;
	
	self.detailViewControllerOptions.tableViewStyle = UITableViewStyleGrouped;
	self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	self.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object selectedIndexPropertyName:(NSString *)propertyName items:(NSArray *)cellItems
{	
	if( (self=[self initWithText:cellText boundObject:object boundPropertyName:propertyName]) )
	{
		self.boundPropertyDataType = SCDataTypeNSNumber;
        self.allowMultipleSelection = FALSE;
        
        self.selectionItemsStore = [SCArrayStore storeWithObjectsArray:[NSMutableArray arrayWithArray:cellItems] defaultDefiniton:[SCStringDefinition definition]];
		
		[self buildSelectedItemsIndexesFromBoundValue];
		
		if(self.boundObject && !self.boundValue && self.commitChangesLive)
			self.boundValue = [NSNumber numberWithInt:-1];
	}
	return self;
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object selectedIndexesPropertyName:(NSString *)propertyName items:(NSArray *)cellItems allowMultipleSelection:(BOOL)multipleSelection
{
	if( (self=[self initWithText:cellText boundObject:object boundPropertyName:propertyName]) )
	{
		self.selectionItemsStore = [SCArrayStore storeWithObjectsArray:[NSMutableArray arrayWithArray:cellItems] defaultDefiniton:[SCStringDefinition definition]];
        
		self.allowMultipleSelection = multipleSelection;
		
		[self buildSelectedItemsIndexesFromBoundValue];
		
		if(self.boundObject && !self.boundValue && self.commitChangesLive)
			self.boundValue = [NSMutableSet set];   //Empty set
	}
	return self;
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object selectionStringPropertyName:(NSString *)propertyName items:(NSArray *)cellItems
{
	if( (self=[self initWithText:cellText boundObject:object boundPropertyName:propertyName]) )
	{
		self.boundPropertyDataType = SCDataTypeNSString;
		self.allowMultipleSelection = FALSE;
        
        self.selectionItemsStore = [SCArrayStore storeWithObjectsArray:[NSMutableArray arrayWithArray:cellItems] defaultDefiniton:[SCStringDefinition definition]];
		
		[self buildSelectedItemsIndexesFromBoundValue];
	}
	return self;
}


- (NSArray *)items
{
    if(!itemsInSync)
    {
        if(!items)
            items = [NSArray array];
        switch (self.selectionItemsStore.storeMode)
        {
            case SCStoreModeSynchronous:
                items = [self.selectionItemsStore fetchObjectsWithOptions:self.selectionItemsFetchOptions];
                itemsInSync = TRUE;
                break;
                
            case SCStoreModeAsynchronous:
            {
                BOOL skipBuildingFromBoundValue = _commitingDetailModel;
                _loadingContents = TRUE;
                self.selectable = FALSE;
                if(!_activityIndicator)
                {
                    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    _activityIndicator.frame = self.contentView.bounds;
                    [self.contentView addSubview:_activityIndicator];
                }
                [_activityIndicator startAnimating];
                [self.selectionItemsStore asynchronousFetchObjectsWithOptions:self.selectionItemsFetchOptions
                success:^(NSArray *results)
                 {
                     items = results;
                     
                     if(!skipBuildingFromBoundValue)
                         [self buildSelectedItemsIndexesFromBoundValue];
                     
                     _boundValueLoaded = NO;
                     [self loadBoundValueIntoControl];
                     
                     _loadingContents = FALSE;
                     [_activityIndicator stopAnimating];
                     self.selectable = TRUE;
                 }
                failure:^(NSError *error)
                 {
                     _loadingContents = FALSE;
                     [_activityIndicator stopAnimating];
                     itemsInSync = FALSE;
                     self.selectable = TRUE;
                 }
                 noConnection:^BOOL()
                 {
                     return NO;
                 }];
                itemsInSync = TRUE;
            }
                break;
        }
    }
    
    return items;
}

- (void)setItems:(NSArray *)customItems
{
    if([self.selectionItemsStore isKindOfClass:[SCArrayStore class]])
        [(SCArrayStore *)self.selectionItemsStore setObjectsArray:[NSMutableArray arrayWithArray:customItems]];
    
    items = customItems;
    itemsInSync = TRUE;
}

- (void)setSelectionItemsStore:(SCDataStore *)store
{
    selectionItemsStore = store;
    
    selectionItemsFetchOptions = [store.defaultDataDefinition generateCompatibleDataFetchOptions];
    
    
    itemsInSync = FALSE;
    
    [self buildSelectedItemsIndexesFromBoundValue];
    
    _boundValueLoaded = NO;
    [self loadBoundValueIntoControl];
}

- (void)setSelectionItemsFetchOptions:(SCDataFetchOptions *)fetchOptions
{
    selectionItemsFetchOptions = fetchOptions;
    
    itemsInSync = FALSE;
    
    [self buildSelectedItemsIndexesFromBoundValue];
    
    _boundValueLoaded = NO;
    [self loadBoundValueIntoControl];
}

//overrides superclass
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if(_activityIndicator)
        _activityIndicator.frame = self.contentView.bounds;
}

//overrides superclass
- (void)setEnabled:(BOOL)_enabled
{
    [super setEnabled:_enabled];
    
    if(_enabled)
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
        self.accessoryType = UITableViewCellAccessoryNone;
}

- (void)buildSelectedItemsIndexesFromBoundValue
{
	[self.selectedItemsIndexes removeAllObjects];
	
	if([self.boundValue isKindOfClass:[NSNumber class]])
	{
		[self.selectedItemsIndexes addObject:self.boundValue];
	}
	else
		if([self.boundValue isKindOfClass:[NSMutableSet class]])
		{
			NSMutableSet *boundSet = (NSMutableSet *)self.boundValue;
			for(NSNumber *index in boundSet)
				[self.selectedItemsIndexes addObject:index];
		}
		else
			if([SCUtilities isStringClass:[self.boundValue class]] && self.items)
			{
				[self buildSelectedItemsIndexesFromString:(NSString *)self.boundValue];
			}
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

//override superclass
- (void)cellValueChanged
{
    _boundValueLoaded = NO;
	[self loadBoundValueIntoControl];
	
	[super cellValueChanged];
}

- (NSString *)getTitleForItemAtIndex:(NSUInteger)index
{
    return [self.items objectAtIndex:index];
}

//override superclass
- (void)loadBoundValueIntoLabel
{
    NSArray *indexesArray = [[self.selectedItemsIndexes allObjects]
                             sortedArrayUsingSelector:@selector(compare:)];
    if(self.items.count && self.displaySelection && indexesArray.count)
    {
        NSMutableString *selectionString = [[NSMutableString alloc] init];
        for(NSUInteger i=0; i<indexesArray.count; i++)
        {
            NSUInteger index = [(NSNumber *)[indexesArray objectAtIndex:i] intValue];
            if(index > (self.items.count-1))
                continue;
            
            NSString *itemTitle = [self getTitleForItemAtIndex:index];
            if(!itemTitle)
                continue;
            if(i==0)
                [selectionString appendString:itemTitle];
            else
                [selectionString appendFormat:@"%@%@", self.delimeter, itemTitle];
        }
        self.label.text = selectionString;
    }
    else
        self.label.text = nil;
    
    _boundValueLoaded = YES;
}

- (void)reloadBoundValue
{
    itemsInSync = FALSE;
    _boundValueLoaded = NO;
    
	[self buildSelectedItemsIndexesFromBoundValue];
	[self loadBoundValueIntoControl];
}
			 
- (void)buildDetailModel:(SCTableViewModel *)detailModel
{
    [detailModel clear];
    
    if([detailModel isKindOfClass:[SCSelectionModel class]])
    {
        SCSelectionModel *selectionModel = (SCSelectionModel *)detailModel;
        
        selectionModel.dataStore = self.selectionItemsStore;
        selectionModel.dataFetchOptions = self.selectionItemsFetchOptions;
        
        selectionModel.boundObjectStore = self.boundObjectStore;
        selectionModel.allowNoSelection = self.allowNoSelection;
        selectionModel.maximumSelections = self.maximumSelections;
        selectionModel.allowMultipleSelection = self.allowMultipleSelection;
        selectionModel.autoDismissViewController = self.autoDismissDetailView;
        
        selectionModel.allowAddingItems = self.allowAddingItems;
        selectionModel.allowDeletingItems = self.allowDeletingItems;
        selectionModel.allowMovingItems = self.allowMovingItems;
        selectionModel.allowEditDetailView = self.allowEditDetailView;
        
        [selectionModel setDetailViewControllerOptions:self.detailViewControllerOptions];
    }
    else 
    {
        SCSelectionSection *selectionSection = [SCSelectionSection sectionWithHeaderTitle:nil dataStore:self.selectionItemsStore];
        
        selectionSection.dataFetchOptions = self.selectionItemsFetchOptions;
        
        if(self.boundPropertyDataType == SCDataTypeNSNumber)
        {
            selectionSection.selectedItemIndex = self.selectedItemIndex;
        }
        else
        {
            for(NSNumber *index in self.selectedItemsIndexes)
                [selectionSection.selectedItemsIndexes addObject:index];
        }
        
        selectionSection.boundObjectStore = self.boundObjectStore;
        selectionSection.allowNoSelection = self.allowNoSelection;
        selectionSection.maximumSelections = self.maximumSelections;
        selectionSection.allowMultipleSelection = self.allowMultipleSelection;
        selectionSection.autoDismissViewController = self.autoDismissDetailView;
        selectionSection.cellsImageViews = self.detailCellsImageViews;
        
        selectionSection.allowAddingItems = self.allowAddingItems;
        selectionSection.allowDeletingItems = self.allowDeletingItems;
        selectionSection.allowMovingItems = self.allowMovingItems;
        selectionSection.allowEditDetailView = self.allowEditDetailView;
        
        selectionSection.placeholderCell = self.placeholderCell;
        selectionSection.addNewItemCell = self.addNewItemCell;
        selectionSection.addNewItemCellExistsInNormalMode = self.addNewItemCellExistsInNormalMode;
        selectionSection.addNewItemCellExistsInEditingMode = self.addNewItemCellExistsInEditingMode;
        
        [selectionSection setDetailViewControllerOptions:self.detailViewControllerOptions];
        
        [detailModel addSection:selectionSection];
    }
}

- (void)commitDetailModelChanges:(SCTableViewModel *)detailModel
{
    _commitingDetailModel = TRUE;
    
    // The detail model my have added/modified/removed items
    itemsInSync = FALSE;
    
    NSSet *selectedIndexes = nil;
    if([detailModel isKindOfClass:[SCSelectionModel class]])
    {
        selectedIndexes = [(SCSelectionModel *)detailModel selectedItemsIndexes];
    }
    else 
    {
        for(NSUInteger i=0; i<detailModel.sectionCount; i++)
        {
            SCTableViewSection *section = [detailModel sectionAtIndex:i];
            if([section isKindOfClass:[SCSelectionSection class]])
            {
                selectedIndexes = [(SCSelectionSection *)section selectedItemsIndexes];
                break;
            }
        }
    }
    
    if(selectedIndexes)
    {
        [self.selectedItemsIndexes removeAllObjects];
        for(NSNumber *index in selectedIndexes)
            [self.selectedItemsIndexes addObject:index];
        
        [self cellValueChanged];
    }
    
    _commitingDetailModel = FALSE;
}

//override superclass
- (SCNavigationBarType)defaultDetailViewControllerNavigationBarType
{
    if(self.detailViewControllerOptions.navigationBarType != SCNavigationBarTypeAuto)
        return self.detailViewControllerOptions.navigationBarType;
    
    
    SCNavigationBarType navBarType;
    if(self.allowAddingItems || self.allowDeletingItems || self.allowMovingItems || self.allowEditDetailView)
        navBarType = SCNavigationBarTypeEditRight;
    else
        navBarType = SCNavigationBarTypeDoneRightCancelLeft;
    
    return navBarType;
}

//override superclass
- (void)didSelectCell
{
    [super didSelectCell];
    
	self.ownerTableViewModel.activeCell = self;

	if(!self.items)
		return;
    
    if(_loadingContents)
        return;
	
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    
    UIViewController *detailViewController = [self generatedDetailViewController:indexPath];
    
    
    [self presentDetailViewController:detailViewController forCell:self forRowAtIndexPath:indexPath withPresentationMode:self.detailViewControllerOptions.presentationMode];
}

// overrides superclass
- (UIViewController *)generatedDetailViewController:(NSIndexPath *)indexPath
{
    UIViewController *detailViewController = nil;
    if([self.ibDetailViewControllerIdentifier length])
    {
        detailViewController = [SCUtilities instantiateViewControllerWithIdentifier:self.ibDetailViewControllerIdentifier usingStoryboard:self.ownerTableViewModel.viewController.storyboard];
        
        if(detailViewController)
        {
            [self configureDetailViewController:detailViewController];
            SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
            [self.ownerTableViewModel configureDetailModel:detailModel];
            [self configureDetailModel:detailModel];
        }
        else
            SCDebugLog(@"Warning: Could not instantiate view controller with id '%@' from Storyboard.", self.ibDetailViewControllerIdentifier);
    }
    else
    {
        detailViewController = [self getDetailViewControllerForCell:self forRowAtIndexPath:indexPath allowUITableViewControllerSubclass:YES];
    }
    
    return detailViewController;
}

// overrides superclass
- (BOOL)generatesDetailView
{
    return YES;
}

// overrides superclass
- (void)commitChanges
{
	if(!self.needsCommit || !self.valueIsValid)
		return;
	
	if(self.boundPropertyDataType == SCDataTypeNSNumber)
	{
		self.boundValue = self.selectedItemIndex;
	}
	else
	if(self.boundPropertyDataType==SCDataTypeNSString || self.boundPropertyDataType==SCDataTypeDictionaryItem)
	{
		self.boundValue = [self buildStringFromSelectedItemsIndexes];
	}
	else
	{
		if([self.boundValue isKindOfClass:[NSMutableSet class]])
		{
			NSMutableSet *boundValueSet = (NSMutableSet *)self.boundValue;
			[boundValueSet removeAllObjects];
			for(NSNumber *index in self.selectedItemsIndexes)
				[boundValueSet addObject:index];
		}
	}
	
	[super commitChanges];
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCSelectionAttributes class]])
		return;
	
	SCSelectionAttributes *selectionAttributes = (SCSelectionAttributes *)attributes;
    
	if(selectionAttributes.selectionItemsStore)
    {
        self.selectionItemsStore = selectionAttributes.selectionItemsStore;	
        self.selectionItemsFetchOptions = selectionAttributes.selectionItemsFetchOptions;
    }
		
	self.allowMultipleSelection = selectionAttributes.allowMultipleSelection;
	self.allowNoSelection = selectionAttributes.allowNoSelection;
	self.maximumSelections = selectionAttributes.maximumSelections;
	self.autoDismissDetailView = selectionAttributes.autoDismissDetailView;
	self.hideDetailViewNavigationBar = selectionAttributes.hideDetailViewNavigationBar;
    self.allowAddingItems = selectionAttributes.allowAddingItems;
    self.allowDeletingItems = selectionAttributes.allowDeletingItems;
    self.allowMovingItems = selectionAttributes.allowMovingItems;
    self.allowEditDetailView = selectionAttributes.allowEditingItems;
    if([selectionAttributes.placeholderuiElement isKindOfClass:[SCTableViewCell class]])
        self.placeholderCell = (SCTableViewCell *)selectionAttributes.placeholderuiElement;
    if([selectionAttributes.addNewObjectuiElement isKindOfClass:[SCTableViewCell class]])
        self.addNewItemCell = (SCTableViewCell *)selectionAttributes.addNewObjectuiElement;
}

//overrides superclass
- (BOOL)getValueIsValid
{
	if(![self.selectedItemsIndexes count] && !self.allowNoSelection && self.valueRequired)
		return FALSE;
	//else
	return TRUE;
}

- (void)setSelectedItemIndex:(NSNumber *)number
{
	[self.selectedItemsIndexes removeAllObjects];
	if([number intValue] >= 0)
	{
		NSNumber *num = [number copy];
		[self.selectedItemsIndexes addObject:num];
	}
}

- (NSNumber *)selectedItemIndex
{
	NSNumber *index = [self.selectedItemsIndexes anyObject];
	
	if(index)
		return index;
	//else
	return [NSNumber numberWithInt:-1];
}


- (void)handleDetailViewControllerWillPresent:(UIViewController *)detailViewController
{
	if(self.autoDismissDetailView && self.hideDetailViewNavigationBar)
		[self.ownerTableViewModel.viewController.navigationController setNavigationBarHidden:YES animated:YES];
	
	[super handleDetailViewControllerWillPresent:detailViewController];
}

- (void)handleDetailViewControllerWillDismiss:(UIViewController *)detailViewController cancelButtonTapped:(BOOL)cancelTapped doneButtonTapped:(BOOL)doneTapped
{
	[self.ownerTableViewModel.viewController.navigationController setNavigationBarHidden:FALSE animated:YES];
	
	[super handleDetailViewControllerWillDismiss:detailViewController cancelButtonTapped:cancelTapped doneButtonTapped:doneTapped];	
}

@end








@interface SCObjectSelectionCell ()

- (NSMutableSet *)boundMutableSet;

@end


@implementation SCObjectSelectionCell

@synthesize intermediateEntityDefinition;


+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object selectedObjectPropertyName:(NSString *)propertyName selectionItemsStore:(SCDataStore *)store
{
    return [[[self class] alloc] initWithText:cellText boundObject:object selectedObjectPropertyName:propertyName selectionItemsStore:store];
}

+ (instancetype)cellWithText:(NSString *)cellText boundObject:(NSObject *)object selectedObjectPropertyName:(NSString *)propertyName selectionItems:(NSArray *)items itemsDefintion:(SCDataDefinition *)definition
{
	return [[[self class] alloc] initWithText:cellText boundObject:object selectedObjectPropertyName:propertyName selectionItems:items itemsDefintion:definition];
}

//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
    
    intermediateEntityDefinition = nil;
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object selectedObjectPropertyName:(NSString *)propertyName selectionItemsStore:(SCDataStore *)store
{
    if( (self=[self initWithText:cellText boundObject:object boundPropertyName:propertyName]) )
	{
		self.selectionItemsStore = store;
        
        [self buildSelectedItemsIndexesFromBoundValue];
	}
	return self;
}

- (instancetype)initWithText:(NSString *)cellText boundObject:(NSObject *)object selectedObjectPropertyName:(NSString *)propertyName selectionItems:(NSArray *)selitems itemsDefintion:(SCDataDefinition *)definition
{
	SCArrayStore *store = [SCArrayStore storeWithObjectsArray:[NSMutableArray arrayWithArray:selitems] defaultDefiniton:definition];
    
    self = [self initWithText:cellText boundObject:object selectedObjectPropertyName:propertyName selectionItemsStore:store];
    
    return self;
}


- (NSMutableSet *)boundMutableSet
{
    if(self.boundPropertyDataType == SCDataTypeNSString)
        return nil;
    
    NSMutableSet *set = nil;
    if([self.boundObject respondsToSelector:@selector(mutableSetValueForKey:)])
    {
        SCPropertyDefinition *boundPropertyDef = [[self.boundObjectStore definitionForObject:self.boundObject] propertyDefinitionWithName:self.boundPropertyName];
        
        if(boundPropertyDef.dataType == SCDataTypeNSMutableSet)
        {
            set = [self.boundObject mutableSetValueForKey:self.boundPropertyName];
        }
        else
            if(boundPropertyDef.dataType == SCDataTypeNSMutableOrderedSet)
            {
                set = (NSMutableSet *)[self.boundObject mutableOrderedSetValueForKey:self.boundPropertyName];
            }
    }
    else 
    {
        set = (NSMutableSet *)self.boundValue;
    }
    
    return set;
}

//overrides superclass
- (void)buildSelectedItemsIndexesFromBoundValue
{
    [self.selectedItemsIndexes removeAllObjects];
    
    if(self.boundPropertyDataType == SCDataTypeNSString)
    {
        NSString *stringBoundValue = (NSString *)self.boundValue;
        NSArray *objectTitles = [stringBoundValue componentsSeparatedByString:@";"];
        SCDataDefinition *definition = [self.selectionItemsStore defaultDataDefinition];
        for(NSString *title in objectTitles)
        {
            NSObject *obj = [definition objectWithTitle:title inObjectsArray:self.items];
            NSUInteger index = [self.items indexOfObjectIdenticalTo:obj];
            if(index != NSNotFound)
                [self.selectedItemsIndexes addObject:[NSNumber numberWithUnsignedInteger:index]];
        }
        
        return;
    }
    
    
    if(self.allowMultipleSelection)
    {
        if(!self.intermediateEntityDefinition)
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
            // TODO - Future implementation

            /*
            NSEntityDescription *boundObjEntity = [(NSManagedObject *)self.boundObject entity];
            NSEntityDescription *intermediateEntity = self.intermediateEntityClassDefinition.entity;
            NSEntityDescription *itemsEntity = self.itemsClassDefinition.entity;
            
            // Determine the boundObjEntity relationship name that connects to intermediateEntity
            NSString *intermediatesRel = nil;
            NSArray *relationships = [boundObjEntity relationshipsWithDestinationEntity:intermediateEntity];
            if(relationships.count)
                intermediatesRel = [(NSRelationshipDescription *)[relationships objectAtIndex:0] name];
            
            // Determine the intermediateEntity relationship name that connects to itemsEntity
            NSString *itemRel = nil;
            relationships = [intermediateEntity relationshipsWithDestinationEntity:itemsEntity];
            if(relationships.count)
                itemRel = [(NSRelationshipDescription *)[relationships objectAtIndex:0] name];
            
            if(intermediatesRel && itemRel)
            {
                NSMutableSet *intermediatesSet = [(NSManagedObject *)self.boundObject mutableSetValueForKey:intermediatesRel];
                for(NSManagedObject *intermediateObj in intermediatesSet)
                {
                    NSManagedObject *itemObj = [intermediateObj valueForKey:itemRel];
                    int index = [self.items indexOfObjectIdenticalTo:itemObj];
                    if(index != NSNotFound)
                        [self.selectedItemsIndexes addObject:[NSNumber numberWithInt:index]];
                }
            }
             */
                                     
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

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCObjectSelectionAttributes class]])
		return;
	
	SCObjectSelectionAttributes *objectSelectionAttributes = (SCObjectSelectionAttributes *)attributes;

    if([objectSelectionAttributes.ibPlaceholderText length] && !objectSelectionAttributes.placeholderuiElement)
        self.placeholderCell = [SCTableViewCell cellWithText:objectSelectionAttributes.ibPlaceholderText textAlignment:objectSelectionAttributes.ibPlaceholderTextAlignment];
    if([objectSelectionAttributes.ibAddNewObjectText length] && !objectSelectionAttributes.addNewObjectuiElement)
        self.addNewItemCell = [SCTableViewCell cellWithText:objectSelectionAttributes.ibAddNewObjectText textAlignment:NSTextAlignmentCenter];
    self.intermediateEntityDefinition = objectSelectionAttributes.intermediateEntityDefinition;
    
    [self buildSelectedItemsIndexesFromBoundValue];
}

// override superclass
- (NSString *)getTitleForItemAtIndex:(NSUInteger)index
{
    NSObject *item = [self.items objectAtIndex:index];
    SCDataDefinition *itemDefinition = [self.selectionItemsStore definitionForObject:item];
    if(itemDefinition.titlePropertyName)
	{
		return [itemDefinition titleValueForObject:[self.items objectAtIndex:index]];
	}
	//else
	return nil;
}

// override superclass
- (void)buildDetailModel:(SCTableViewModel *)detailModel
{
    [detailModel clear];
    
	if([detailModel isKindOfClass:[SCObjectSelectionModel class]])
    {
        SCObjectSelectionModel *selectionModel = (SCObjectSelectionModel *)detailModel;
        selectionModel.autoFetchItems = FALSE;
        [selectionModel setMutableItems:[NSMutableArray arrayWithArray:self.items]];
        
        // Override object's bound value since it might not yet be committed
        [selectionModel.selectedItemsIndexes removeAllObjects];
        for(NSNumber *index in self.selectedItemsIndexes)
            [selectionModel.selectedItemsIndexes addObject:index];
        
        selectionModel.boundObject = self.boundObject;
        selectionModel.boundObjectStore = self.boundObjectStore;
        selectionModel.boundPropertyName = self.boundPropertyName;
        selectionModel.dataStore = self.selectionItemsStore;
        selectionModel.dataFetchOptions = self.selectionItemsFetchOptions;
        
        selectionModel.allowNoSelection = self.allowNoSelection;
        selectionModel.maximumSelections = self.maximumSelections;
        selectionModel.allowMultipleSelection = self.allowMultipleSelection;
        selectionModel.autoDismissViewController = self.autoDismissDetailView;
        
        selectionModel.allowAddingItems = self.allowAddingItems;
        selectionModel.allowDeletingItems = self.allowDeletingItems;
        selectionModel.allowMovingItems = self.allowMovingItems;
        selectionModel.allowEditDetailView = self.allowEditDetailView;
        
        [selectionModel setDetailViewControllerOptions:self.detailViewControllerOptions];
    }
    else
    {
        SCObjectSelectionSection *selectionSection = [SCObjectSelectionSection sectionWithHeaderTitle:nil boundObject:self.boundObject selectedObjectPropertyName:self.boundPropertyName selectionItemsStore:self.selectionItemsStore];
        selectionSection.dataFetchOptions = self.selectionItemsFetchOptions;
        selectionSection.autoFetchItems = FALSE;
        [selectionSection setMutableItems:[NSMutableArray arrayWithArray:self.items]];
        
        selectionSection.intermediateEntityDefinition = self.intermediateEntityDefinition;
        
        // Override object's bound value since it might not yet be committed
        [selectionSection.selectedItemsIndexes removeAllObjects];
        for(NSNumber *index in self.selectedItemsIndexes)
            [selectionSection.selectedItemsIndexes addObject:index];
        
        selectionSection.boundObjectStore = self.boundObjectStore;
        selectionSection.commitCellChangesLive = FALSE;
        selectionSection.allowNoSelection = self.allowNoSelection;
        selectionSection.maximumSelections = self.maximumSelections;
        selectionSection.allowMultipleSelection = self.allowMultipleSelection;
        selectionSection.autoDismissViewController = self.autoDismissDetailView;
        selectionSection.cellsImageViews = self.detailCellsImageViews;
        
        selectionSection.allowAddingItems = self.allowAddingItems;
        selectionSection.allowDeletingItems = self.allowDeletingItems;
        selectionSection.allowMovingItems = self.allowMovingItems;
        selectionSection.allowEditDetailView = self.allowEditDetailView;
        
        selectionSection.placeholderCell = self.placeholderCell;
        selectionSection.addNewItemCell = self.addNewItemCell;
        selectionSection.addNewItemCellExistsInNormalMode = self.addNewItemCellExistsInNormalMode;
        selectionSection.addNewItemCellExistsInEditingMode = self.addNewItemCellExistsInEditingMode;
        
        [selectionSection setDetailViewControllerOptions:self.detailViewControllerOptions];
        
        [detailModel addSection:selectionSection];
    }
}

// overrides superclass
- (void)commitDetailModelChanges:(SCTableViewModel *)detailModel
{
    _commitingDetailModel = TRUE;
    
    // The detail model my have added/modified/removed items
    itemsInSync = FALSE;
    
    NSSet *detailIndexes;
    if([detailModel isKindOfClass:[SCObjectSelectionModel class]])
    {
        detailIndexes = [(SCObjectSelectionModel *)detailModel selectedItemsIndexes];
    }
    else
    {
        SCObjectSelectionSection *selectionSection = (SCObjectSelectionSection *)[detailModel sectionAtIndex:0];
        detailIndexes = selectionSection.selectedItemsIndexes;
    }
    
	[self.selectedItemsIndexes removeAllObjects];
	for(NSNumber *index in detailIndexes)
		[self.selectedItemsIndexes addObject:index];
    
    [self cellValueChanged];
    
    _commitingDetailModel = FALSE;
}

// overrides superclass
- (void)commitChanges
{
	if(!self.needsCommit || !self.valueIsValid)
		return;
	
    if(self.boundPropertyDataType == SCDataTypeNSString)
    {
        SCDataDefinition *definition = [self.selectionItemsStore defaultDataDefinition];
        
        NSMutableString *objectTitles = [NSMutableString string];
        BOOL addSeparator = FALSE;
        for(NSNumber *index in self.selectedItemsIndexes)
        {
            NSObject *obj = [self.items objectAtIndex:(NSUInteger)[index intValue]];
            NSString *objTitle = [definition titleValueForObject:obj];
            if(!addSeparator)
            {
                [objectTitles appendString:objTitle];
                addSeparator = TRUE;
            }
            else
            {
                [objectTitles appendFormat:@";%@", objTitle];
            }
        }
        
        self.boundValue = objectTitles;
        
        return;
    }
    
	if(self.allowMultipleSelection)
    {
        if(!self.intermediateEntityDefinition)
        {
            NSMutableSet *boundValueSet = [self boundMutableSet];
            [boundValueSet removeAllObjects];
            for(NSNumber *index in self.selectedItemsIndexes)
            {
                NSObject *obj = [self.items objectAtIndex:(NSUInteger)[index intValue]];
                [boundValueSet addObject:obj];
            }
        }
        else
        {
            // TODO - Future implementation
#ifdef _COREDATADEFINES_H 
            /*
            NSEntityDescription *boundObjEntity = [(NSManagedObject *)self.boundObject entity];
            NSEntityDescription *intermediateEntity = self.intermediateEntityDefinition.entity;
            NSEntityDescription *itemsEntity = self.itemsClassDefinition.entity;
            
            // Determine the boundObjEntity relationship name that connects to intermediateEntity
            NSString *intermediatesRel = nil;
            NSArray *relationships = [boundObjEntity relationshipsWithDestinationEntity:intermediateEntity];
            if(relationships.count)
                intermediatesRel = [(NSRelationshipDescription *)[relationships objectAtIndex:0] name];
            
            // Determine the intermediateEntity relationship name that connects to itemsEntity
            NSString *itemRel = nil;
            NSString *invItemRel = nil;
            relationships = [intermediateEntity relationshipsWithDestinationEntity:itemsEntity];
            if(relationships.count)
            {
                itemRel = [(NSRelationshipDescription *)[relationships objectAtIndex:0] name];
                invItemRel = [[(NSRelationshipDescription *)[relationships objectAtIndex:0] inverseRelationship] name];
            }
                
            
            if(intermediatesRel && itemRel && invItemRel)
            {
                NSMutableSet *intermediatesSet = [(NSManagedObject *)self.boundObject mutableSetValueForKey:intermediatesRel];
                
                // remove all intermediate objects
                for(NSManagedObject *intermediateObj in intermediatesSet)
                {
                    [self.intermediateEntityClassDefinition.managedObjectContext deleteObject:intermediateObj];
                }
                
                // add new intermediate objects
                for(NSNumber *index in self.selectedItemsIndexes)
                {
                    NSManagedObject *itemObj = [self.items objectAtIndex:[index intValue]];
                    
                    NSManagedObject *intermediateObj = [NSEntityDescription insertNewObjectForEntityForName:[intermediateEntity name] inManagedObjectContext:self.intermediateEntityClassDefinition.managedObjectContext];
                    [intermediatesSet addObject:intermediateObj];
                    [[itemObj mutableSetValueForKey:invItemRel] addObject:intermediateObj];
                }
            }
             */
#endif            
        }
    }
	else
	{
		NSObject *selectedObject = nil;
		NSInteger index = [self.selectedItemIndex intValue];
		if(index >= 0)
			selectedObject = [self.items objectAtIndex:index];
		
		self.boundValue = selectedObject;
	}
}

@end










@interface SCObjectCell ()

- (void)setCellTextAndDetailText;

@end



@implementation SCObjectCell

@synthesize boundObjectTitleText;


+ (instancetype)cellWithBoundObject:(NSObject *)object
{
	return [[[self class] alloc] initWithBoundObject:object];
}

+ (instancetype)cellWithBoundObject:(NSObject *)object boundObjectDefinition:(SCDataDefinition *)definition
{
	return [[[self class] alloc] initWithBoundObject:object boundObjectDefinition:definition];
}

+ (instancetype)cellWithBoundObject:(NSObject *)object boundObjectStore:(SCDataStore *)store
{
    return [[[self class] alloc] initWithBoundObject:object boundObjectStore:store];
}

//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
	
	boundObjectTitleText = nil;
	self.detailViewControllerOptions.tableViewStyle = UITableViewStyleGrouped;
	
	self.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (instancetype)initWithBoundObject:(NSObject *)object
{
	return [self initWithBoundObject:object boundObjectDefinition:nil];
}

- (instancetype)initWithBoundObject:(NSObject *)object boundObjectDefinition:(SCDataDefinition *)definition
{
	SCDataStore *store = [definition generateCompatibleDataStore];
    
    return [self initWithBoundObject:object boundObjectStore:store];
}

- (instancetype)initWithBoundObject:(NSObject *)object boundObjectStore:(SCDataStore *)store
{
    if( (self=[self initWithStyle:SC_DefaultCellStyle reuseIdentifier:nil]) )
	{
		self.boundObject = object;
		
		self.boundObjectStore = store;
	}
	return self;
}


- (SCDataDefinition *)objectDefinition
{
    return [self.boundObjectStore definitionForObject:self.boundObject];
}

- (void)setObjectDefinition:(SCDataDefinition *)objectDefinition
{
    [self.boundObjectStore setDefaultDataDefinition:objectDefinition];
}

- (void)setBoundObjectTitleText: (NSString*)input 
{ 
    boundObjectTitleText = [input copy];
    
    [self setCellTextAndDetailText];
}

//overrides superclass
- (void)setEnabled:(BOOL)_enabled
{
    [super setEnabled:_enabled];
    
    if(_enabled && self.boundObject)
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
        self.accessoryType = UITableViewCellAccessoryNone;
}

//override superclass
- (void)willDisplay
{
	[super willDisplay];
	
	if(self.boundObject && self.enabled)
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	else
		self.accessoryType = UITableViewCellAccessoryNone;
	
	[self setCellTextAndDetailText];
}

//override superclass
- (void)cellValueChanged
{
	[self setCellTextAndDetailText];
	
	[super cellValueChanged];
}

- (void)buildDetailModel:(SCTableViewModel *)detailModel
{
    [detailModel clear];
    
    if(self.boundObjectStore)
        [detailModel generateSectionsForObject:self.boundObject withDataStore:self.boundObjectStore newObject:NO];
}

- (void)configureDetailModel:(SCTableViewModel *)detailModel
{
    [super configureDetailModel:detailModel];
    
    for(NSUInteger i=0; i<detailModel.sectionCount; i++)
    {
        SCTableViewSection *section = [detailModel sectionAtIndex:i];
        
        [section setDetailViewControllerOptions:self.detailViewControllerOptions];
        section.commitCellChangesLive = FALSE;
        section.cellsImageViews = self.detailCellsImageViews;
        for(NSUInteger j=0; j<section.cellCount; j++)
        {
            [[section cellAtIndex:j] setDetailViewControllerOptions:self.detailViewControllerOptions];
        }
    }
}

- (void)commitDetailModelChanges:(SCTableViewModel *)detailModel
{
	// commitChanges & ignore self.commitChangesLive setting as it's not applicable here
	//looping to include any custom user added sections too
	for(NSUInteger i=0; i<detailModel.sectionCount; i++)
	{
		SCTableViewSection *section = [detailModel sectionAtIndex:i];
		[section commitCellChanges];
	}
	
	[self cellValueChanged];
}

//override superclass
- (SCNavigationBarType)defaultDetailViewControllerNavigationBarType
{
    SCNavigationBarType navBarType;
    if(self.objectDefinition.requireEditingModeToEditPropertyValues)
        navBarType = SCNavigationBarTypeEditRight;
    else
        navBarType = SCNavigationBarTypeDoneRightCancelLeft;
    
    return navBarType;
}

//override superclass
- (void)didSelectCell
{
    [super didSelectCell];
    
	self.ownerTableViewModel.activeCell = self;

	if(!self.boundObject)
		return;
	
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    
    UIViewController *detailViewController = [self generatedDetailViewController:indexPath];
    
    [self presentDetailViewController:detailViewController forCell:self forRowAtIndexPath:indexPath withPresentationMode:self.detailViewControllerOptions.presentationMode];
}

// overrides superclass
- (UIViewController *)generatedDetailViewController:(NSIndexPath *)indexPath
{
    UIViewController *detailViewController;
    if([self.ibDetailViewControllerIdentifier length])
    {
        detailViewController = [SCUtilities instantiateViewControllerWithIdentifier:self.ibDetailViewControllerIdentifier usingStoryboard:self.ownerTableViewModel.viewController.storyboard];
        
        if(detailViewController)
        {
            [self configureDetailViewController:detailViewController];
            SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
            [self.ownerTableViewModel configureDetailModel:detailModel];
            [self configureDetailModel:detailModel];
        }
        else
            SCDebugLog(@"Warning: Could not instantiate view controller with id '%@' from Storyboard.", self.ibDetailViewControllerIdentifier);
    }
    else
    {
        detailViewController = [self getDetailViewControllerForCell:self forRowAtIndexPath:indexPath allowUITableViewControllerSubclass:YES];
    }
    
    return detailViewController;
}


// overrides superclass
- (BOOL)generatesDetailView
{
    return YES;
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCObjectAttributes class]])
		return;
	
	__unused SCObjectAttributes *objectAttributes = (SCObjectAttributes *)attributes;
	// No assignments currently needed.
    // Placeholder for future assignments.
}

- (void)setCellTextAndDetailText
{
	if(self.boundObjectTitleText)
		self.textLabel.text = self.boundObjectTitleText;
	else
	{
		if(self.boundObject && self.objectDefinition.titlePropertyName)
		{
			self.textLabel.text = [self.objectDefinition titleValueForObject:self.boundObject];
		}
	}
	
	if(self.boundObject && self.objectDefinition.descriptionPropertyName)
	{
		self.detailTextLabel.text = [SCUtilities stringValueForPropertyName:self.objectDefinition.descriptionPropertyName
																inObject:self.boundObject
											separateValuesUsingDelimiter:@" "];
	}
}


@end








@implementation SCArrayOfObjectsCell

@synthesize dataStore;
@synthesize dataFetchOptions;
@synthesize allowAddingItems;
@synthesize allowDeletingItems;
@synthesize allowMovingItems;
@synthesize allowEditDetailView;
@synthesize allowRowSelection;
@synthesize autoSelectNewItemCell;
@synthesize displayItemsCountInBadgeView;
@synthesize placeholderCell;
@synthesize addNewItemCell;
@synthesize addNewItemCellExistsInNormalMode;
@synthesize addNewItemCellExistsInEditingMode;
@synthesize detailSectionActions = _detailSectionActions;


+ (instancetype)cellWithDataStore:(SCDataStore *)store
{
    return [[[self class] alloc] initWithDataStore:store];
}

+ (instancetype)cellWithItems:(NSMutableArray *)cellItems itemsDefinition:(SCDataDefinition *)definition
{
	return [[[self class] alloc] initWithItems:cellItems itemsDefinition:definition];
}

//overrides superclass
- (void)performInitialization
{
	[super performInitialization];
	
    dataStore = nil;
    dataFetchOptions = nil;  // will be re-initialized when dataStore is set
    
	allowAddingItems = TRUE;
	allowDeletingItems = TRUE;
	allowMovingItems = TRUE;
	allowEditDetailView = TRUE;
	allowRowSelection = TRUE;
	autoSelectNewItemCell = FALSE;
	displayItemsCountInBadgeView = TRUE;
    
    placeholderCell = nil;
    addNewItemCell = nil;
    addNewItemCellExistsInNormalMode = TRUE;
    addNewItemCellExistsInEditingMode = TRUE;
    
    _detailSectionActions = [[SCSectionActions alloc] init];
}

- (instancetype)initWithDataStore:(SCDataStore *)store
{
    if( (self=[self initWithStyle:SC_DefaultCellStyle reuseIdentifier:nil]) )
	{
		self.dataStore = store;
	}
	return self;
}

- (instancetype)initWithItems:(NSMutableArray *)cellItems itemsDefinition:(SCDataDefinition *)definition
{
	if( (self=[self initWithStyle:SC_DefaultCellStyle reuseIdentifier:nil]) )
	{
		self.dataStore = [SCArrayStore storeWithObjectsArray:cellItems defaultDefiniton:definition];
        [self.dataStore addDataDefinition:definition];
	}
	return self;
}


// overrides superclass
- (void)setBoundObject:(NSObject *)object
{
    [super setBoundObject:object];
    
    [self bindDataStoreToBoundObject];
}

// overrides superclass
- (void)setBoundObjectStore:(SCDataStore *)objectStore
{
    [super setBoundObjectStore:objectStore];
    
    [self bindDataStoreToBoundObject];
}

// overrides superclass
- (void)setBoundPropertyName:(NSString *)propertyName
{
    [super setBoundPropertyName:propertyName];
    
    [self bindDataStoreToBoundObject];
}

- (void)setDataStore:(SCDataStore *)store
{
    dataStore = store;
    
    if(!dataFetchOptions)
        dataFetchOptions = [store.defaultDataDefinition generateCompatibleDataFetchOptions];
    
    [self bindDataStoreToBoundObject];
}

- (void)bindDataStoreToBoundObject
{
    if(self.boundObject && self.boundObjectStore && self.boundPropertyName && self.dataStore)
        [self.dataStore bindStoreToPropertyName:self.boundPropertyName forObject:self.boundObject withDefinition:[self.boundObjectStore definitionForObject:self.boundObject]];
}


//override superclass
- (void)layoutSubviews
{
	if(self.displayItemsCountInBadgeView)
	{
        if(self.dataStore.storeMode==SCStoreModeSynchronous)
        {
            self.badgeView.text = [NSString stringWithFormat:@"%i", (int)self.items.count];
        }
        else
        {
            self.badgeView.text = @"-";
            
            typeof(self) weak_self = self;
            [self.dataStore asynchronousFetchObjectsWithOptions:self.dataFetchOptions
                success:^(NSArray *results)
                {
                    weak_self.badgeView.text = [NSString stringWithFormat:@"%i", (int)results.count];
                }
                failure:nil noConnection:nil];
        }
	}
	
	[super layoutSubviews];
}

//overrides superclass
- (void)buildDetailModel:(SCTableViewModel *)detailModel
{
    [detailModel clear];
    
    if([detailModel isKindOfClass:[SCArrayOfObjectsModel class]])
    {
        SCArrayOfObjectsModel *objectsModel = (SCArrayOfObjectsModel *)detailModel;
        
        objectsModel.dataStore = self.dataStore;
        objectsModel.allowAddingItems = self.allowAddingItems;
        objectsModel.allowDeletingItems = self.allowDeletingItems;
        objectsModel.allowMovingItems = self.allowMovingItems;
        objectsModel.allowEditDetailView = self.allowEditDetailView;
        objectsModel.allowRowSelection = self.allowRowSelection;
        objectsModel.autoSelectNewItemCell = self.autoSelectNewItemCell;
        if([detailModel.viewController isKindOfClass:[SCViewController class]])
            objectsModel.addButtonItem = [(SCViewController *)detailModel.viewController addButton];
        else 
            if([detailModel.viewController isKindOfClass:[SCTableViewController class]])
                objectsModel.addButtonItem = [(SCTableViewController *)detailModel.viewController addButton];
        [objectsModel setDetailViewControllerOptions:self.detailViewControllerOptions];
    }
    else 
    {
        SCArrayOfObjectsSection *objectsSection = [SCArrayOfObjectsSection sectionWithHeaderTitle:nil dataStore:self.dataStore];
        
        objectsSection.boundObjectStore = self.boundObjectStore;
        objectsSection.allowAddingItems = self.allowAddingItems;
        objectsSection.allowDeletingItems = self.allowDeletingItems;
        objectsSection.allowMovingItems = self.allowMovingItems;
        objectsSection.allowEditDetailView = self.allowEditDetailView;
        objectsSection.allowRowSelection = self.allowRowSelection;
        objectsSection.autoSelectNewItemCell = self.autoSelectNewItemCell;
        if([detailModel.viewController isKindOfClass:[SCViewController class]])
            objectsSection.addButtonItem = [(SCViewController *)detailModel.viewController addButton];
        else 
            if([detailModel.viewController isKindOfClass:[SCTableViewController class]])
                objectsSection.addButtonItem = [(SCTableViewController *)detailModel.viewController addButton];
        objectsSection.cellsImageViews = self.detailCellsImageViews;
        objectsSection.placeholderCell = self.placeholderCell;
        objectsSection.addNewItemCell = self.addNewItemCell;
        objectsSection.addNewItemCellExistsInNormalMode = self.addNewItemCellExistsInNormalMode;
        objectsSection.addNewItemCellExistsInEditingMode = self.addNewItemCellExistsInEditingMode;
        [objectsSection setDetailViewControllerOptions:self.detailViewControllerOptions];
        
        [objectsSection.sectionActions setActionsTo:self.detailSectionActions overrideExisting:YES];
        
        [detailModel addSection:objectsSection];
    }
}

- (void)commitDetailModelChanges:(SCTableViewModel *)detailModel
{
	[self cellValueChanged];
}

//overrides superclass
- (void)setEnabled:(BOOL)_enabled
{
    [super setEnabled:_enabled];
    
    [self determineAccessoryType];
}

//override superclass
- (void)willDisplay
{
	[super willDisplay];
	
    [self determineAccessoryType];
}

- (void)determineAccessoryType
{
    if(self.enabled && (self.dataStore.storeMode==SCStoreModeAsynchronous || self.items))
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    else
        self.accessoryType = UITableViewCellAccessoryNone;
}

//override superclass
- (SCNavigationBarType)defaultDetailViewControllerNavigationBarType
{
    SCNavigationBarType navBarType;
	if(!self.allowAddingItems && !self.allowDeletingItems && !self.allowMovingItems)
		navBarType = SCNavigationBarTypeNone;
	else
	{
		if(self.allowAddingItems && !self.addNewItemCell)
			navBarType = SCNavigationBarTypeAddEditRight;
		else
			navBarType = SCNavigationBarTypeEditRight;
	}

    return navBarType;
}

//override superclass
- (void)didSelectCell
{
    [super didSelectCell];
    
	self.ownerTableViewModel.activeCell = self;
	
	// If table is in edit mode, just display the bound object's detail view
	if(self.editing)
	{
		[super didSelectCell];
		return;
	}
    
    NSIndexPath *indexPath = [self.ownerTableViewModel indexPathForCell:self];
    
    UIViewController *detailViewController = [self generatedDetailViewController:indexPath];
    
    
    [self presentDetailViewController:detailViewController forCell:self forRowAtIndexPath:indexPath withPresentationMode:self.detailViewControllerOptions.presentationMode];
}

// overrides superclass
- (UIViewController *)generatedDetailViewController:(NSIndexPath *)indexPath
{
    UIViewController *detailViewController;
    if([self.ibDetailViewControllerIdentifier length])
    {
        detailViewController = [SCUtilities instantiateViewControllerWithIdentifier:self.ibDetailViewControllerIdentifier usingStoryboard:self.ownerTableViewModel.viewController.storyboard];
        
        if(detailViewController)
        {
            [self configureDetailViewController:detailViewController];
            SCTableViewModel *detailModel = [self modelForViewController:detailViewController];
            [self.ownerTableViewModel configureDetailModel:detailModel];
            [self configureDetailModel:detailModel];
        }
        else
            SCDebugLog(@"Warning: Could not instantiate view controller with id '%@' from Storyboard.", self.ibDetailViewControllerIdentifier);
    }
    else
    {
        detailViewController = [self getDetailViewControllerForCell:self forRowAtIndexPath:indexPath allowUITableViewControllerSubclass:YES];
    }
    
    return detailViewController;
}


// overrides superclass
- (BOOL)generatesDetailView
{
    return YES;
}

//overrides superclass
- (void)setAttributesTo:(SCPropertyAttributes *)attributes
{
	[super setAttributesTo:attributes];
	
	if(![attributes isKindOfClass:[SCArrayOfObjectsAttributes class]])
		return;
	
	SCArrayOfObjectsAttributes *objectsArrayAttributes = (SCArrayOfObjectsAttributes *)attributes;
    
    if(!self.dataStore)
    {
        self.dataStore = [objectsArrayAttributes.defaultObjectsDefinition generateCompatibleDataStore];
    }
    
	if(objectsArrayAttributes.objectsFetchOptions)
    {
        self.dataFetchOptions = objectsArrayAttributes.objectsFetchOptions;
    }
    
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
    
    [self.detailSectionActions setActionsTo:objectsArrayAttributes.sectionActions overrideExisting:NO];
}

- (NSArray *)items
{
    return [self.dataStore fetchObjectsWithOptions:self.dataFetchOptions];
}

@end

















