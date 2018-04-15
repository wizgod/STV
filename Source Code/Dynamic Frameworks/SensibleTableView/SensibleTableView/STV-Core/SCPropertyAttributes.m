/*
 *  SCPropertyAttributes.m
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

#import "SCPropertyAttributes.h"

#import "SCClassDefinition.h"
#import "SCStringDefinition.h"
#import "SCArrayStore.h"
#import "SCSectionActions.h"



@implementation SCPropertyAttributes

@synthesize imageView;
@synthesize imageViewArray;
@synthesize expandContentInCurrentView;
@synthesize expandedContentSectionActions = _expandedContentSectionActions;

- (instancetype)init
{
	if( (self = [super init]) )
	{
		imageView = nil;
		imageViewArray = nil;
        
        expandContentInCurrentView = FALSE;
        _expandedContentSectionActions = [[SCSectionActions alloc] init];
	}
	return self;
}



@end







@implementation SCTextViewAttributes

@synthesize minimumHeight;
@synthesize maximumHeight;
@synthesize autoResize;
@synthesize editable;


+ (instancetype)attributesWithMinimumHeight:(CGFloat)minHeight maximumHeight:(CGFloat)maxHeight
					   autoResize:(BOOL)_autoResize editable:(BOOL)_editable
{
	return [[[self class] alloc] initWithMinimumHeight:minHeight maximumHeight:maxHeight autoResize:_autoResize editable:_editable];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
		minimumHeight = FLT_MIN;		// will be ignored
		maximumHeight = FLT_MIN;		// will be ignored
		autoResize = TRUE;
		editable = TRUE;
	}
	return self;
}

- (instancetype)initWithMinimumHeight:(CGFloat)minHeight maximumHeight:(CGFloat)maxHeight
				 autoResize:(BOOL)_autoResize editable:(BOOL)_editable
{
	if( (self=[self init]) )
	{
		self.minimumHeight = minHeight;
		self.maximumHeight = maxHeight;
		self.autoResize = _autoResize;
		self.editable = _editable;
	}
	return self;
}


@end







@implementation SCTextFieldAttributes

@synthesize placeholder;
@synthesize secureTextEntry;
@synthesize autocorrectionType;
@synthesize autocapitalizationType;

+ (instancetype)attributesWithPlaceholder:(NSString *)_placeholder
{
	return [[[self class] alloc] initWithPlaceholder:_placeholder];
}

+ (instancetype)attributesWithPlaceholder:(NSString *)_placeholder secureTextEntry:(BOOL)secure autocorrectionType:(UITextAutocorrectionType)autocorrection autocapitalizationType:(UITextAutocapitalizationType)autocapitalization
{
    return [[[self class] alloc] initWithPlaceholder:_placeholder secureTextEntry:secure autocorrectionType:autocorrection autocapitalizationType:autocapitalization];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
		placeholder = nil;		// will be ignored
        secureTextEntry = FALSE;
        autocorrectionType = UITextAutocorrectionTypeDefault;
        autocapitalizationType = UITextAutocapitalizationTypeSentences;
	}
	return self;
}

- (instancetype)initWithPlaceholder:(NSString *)_placeholder
{
	if( (self=[self init]) )
	{
		self.placeholder = _placeholder;
	}
	return self;
}

- (instancetype)initWithPlaceholder:(NSString *)_placeholder secureTextEntry:(BOOL)secure autocorrectionType:(UITextAutocorrectionType)autocorrection autocapitalizationType:(UITextAutocapitalizationType)autocapitalization
{
    if( (self=[self init]) )
	{
		self.placeholder = _placeholder;
        self.secureTextEntry = secure;
        self.autocorrectionType = autocorrection;
        self.autocapitalizationType = autocapitalization;
	}
	return self;
}


@end







@implementation SCNumericTextFieldAttributes

@synthesize minimumValue;
@synthesize maximumValue;
@synthesize allowFloatValue;
@synthesize numberFormatter;

+ (instancetype)attributesWithMinimumValue:(NSNumber *)minValue maximumValue:(NSNumber *)maxValue
				 allowFloatValue:(BOOL)allowFloat
{
	return [[[self class] alloc] initWithMinimumValue:minValue maximumValue:maxValue allowFloatValue:allowFloat];
}

+ (instancetype)attributesWithMinimumValue:(NSNumber *)minValue maximumValue:(NSNumber *)maxValue
				 allowFloatValue:(BOOL)allowFloat placeholder:(NSString *)_placeholder
{
	return [[[self class] alloc] initWithMinimumValue:minValue maximumValue:maxValue 
									   allowFloatValue:allowFloat
										   placeholder:_placeholder];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
		minimumValue = nil;		// will be ignored
		maximumValue = nil;		// will be ignored
		allowFloatValue = TRUE;
        
        numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
	}
	return self;
}

- (instancetype)initWithMinimumValue:(NSNumber *)minValue maximumValue:(NSNumber *)maxValue
		   allowFloatValue:(BOOL)allowFloat
{
	if( (self=[self init]) )
	{
		self.maximumValue = maxValue;
		self.minimumValue = minValue;
		self.allowFloatValue = allowFloat;
	}
	return self;
}

- (instancetype)initWithMinimumValue:(NSNumber *)minValue maximumValue:(NSNumber *)maxValue
		   allowFloatValue:(BOOL)allowFloat placeholder:(NSString *)_placeholder
{
	if( (self=[self initWithPlaceholder:_placeholder]) )
	{
		self.maximumValue = maxValue;
		self.minimumValue = minValue;
		self.allowFloatValue = allowFloat;
	}
	return self;
}


@end







@implementation SCSliderAttributes

@synthesize minimumValue;
@synthesize maximumValue;

+ (instancetype)attributesWithMinimumValue:(float)minValue maximumValue:(float)maxValue
{
	return [[[self class] alloc] initWithMinimumValue:minValue maximumValue:maxValue];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
		minimumValue = FLT_MIN;		// will be ignored
		maximumValue = FLT_MIN;		// will be ignored
	}
	return self;
}

- (instancetype)initWithMinimumValue:(float)minValue maximumValue:(float)maxValue
{
	if( (self=[self init]) )
	{
		self.minimumValue = minValue;
		self.maximumValue = maxValue;
	}
	return self;
}


@end







@implementation SCSegmentedAttributes

@synthesize segmentTitlesArray;

+ (instancetype)attributesWithSegmentTitlesArray:(NSArray *)titles
{
	return [[[self class] alloc] initWithSegmentTitlesArray:titles];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
		segmentTitlesArray = nil;		// will be ignored
	}
	return self;
}

- (instancetype)initWithSegmentTitlesArray:(NSArray *)titles
{
	if( (self=[self init]) )
	{
		self.segmentTitlesArray = titles;
	}
	return self;
}

@end







@implementation SCDateAttributes

@synthesize dateFormatter;
@synthesize datePickerMode;
@synthesize displayDatePickerAsInputAccessoryView;

+ (instancetype)attributesWithDateFormatter:(NSDateFormatter *)formatter
{
	return [[[self class] alloc] initWithDateFormatter:formatter];
}

+ (instancetype)attributesWithDateFormatter:(NSDateFormatter *)formatter
				   datePickerMode:(UIDatePickerMode)mode
	displayDatePickerAsInputAccessoryView:(BOOL)displayDatePickerAsInputAccessoryView
{
	return [[[self class] alloc] initWithDateFormatter:formatter
										 datePickerMode:mode
						  displayDatePickerAsInputAccessoryView:displayDatePickerAsInputAccessoryView];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
		dateFormatter = nil;		// will be ignored
		datePickerMode = UIDatePickerModeDateAndTime;
		displayDatePickerAsInputAccessoryView = FALSE;
	}
	return self;
}

- (instancetype)initWithDateFormatter:(NSDateFormatter *)formatter
{
	if( (self=[self init]) )
	{
		self.dateFormatter = formatter;
	}
	return self;
}

- (instancetype)initWithDateFormatter:(NSDateFormatter *)formatter
			 datePickerMode:(UIDatePickerMode)mode
	displayDatePickerAsInputAccessoryView:(BOOL)displayAsInputAccessoryView
{
	if( (self=[self init]) )
	{
		self.dateFormatter = formatter;
		self.datePickerMode = mode;
		self.displayDatePickerAsInputAccessoryView = displayAsInputAccessoryView;
	}
	return self;
}

@end







@implementation SCSelectionAttributes

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
@synthesize allowEditingItems;
@synthesize addNewObjectuiElement;
@synthesize placeholderuiElement;

+ (instancetype)attributesWithItems:(NSArray *)items allowMultipleSelection:(BOOL)allowMultipleSel
		 allowNoSelection:(BOOL)allowNoSel
{
	return [[[self class] alloc] initWithItems:items allowMultipleSelection:allowMultipleSel
							   allowNoSelection:allowNoSel];
}

+ (instancetype)attributesWithItems:(NSArray *)items allowMultipleSelection:(BOOL)allowMultipleSel
		 allowNoSelection:(BOOL)allowNoSel autoDismissDetailView:(BOOL)autoDismiss
			hideDetailViewNavigationBar:(BOOL)hideNavBar
{
	return [[[self class] alloc] initWithItems:items allowMultipleSelection:allowMultipleSel
							   allowNoSelection:allowNoSel 
						  autoDismissDetailView:autoDismiss
					hideDetailViewNavigationBar:hideNavBar];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
		selectionItemsStore = nil;	
        selectionItemsFetchOptions = nil;  // will be re-initialized when selectionItemsStore is set
        
		allowMultipleSelection = FALSE;
		allowNoSelection = FALSE;
		maximumSelections = 0;
		autoDismissDetailView = FALSE;
		hideDetailViewNavigationBar = FALSE;
        
        allowAddingItems = FALSE;
		allowDeletingItems = FALSE;
		allowMovingItems = FALSE;
		allowEditingItems = FALSE;
        
        addNewObjectuiElement = nil;
        placeholderuiElement = nil;
	}
	return self;
}

- (instancetype)initWithItems:(NSArray *)items allowMultipleSelection:(BOOL)allowMultipleSel
   allowNoSelection:(BOOL)allowNoSel
{
	if( (self=[self init]) )
	{
		self.selectionItemsStore = [SCArrayStore storeWithObjectsArray:[NSMutableArray arrayWithArray:items] defaultDefiniton:[SCStringDefinition definition]];
        
		self.allowMultipleSelection = allowMultipleSel;
		self.allowNoSelection = allowNoSel;
	}
	return self;
}

- (instancetype)initWithItems:(NSArray *)items allowMultipleSelection:(BOOL)allowMultipleSel
   allowNoSelection:(BOOL)allowNoSel autoDismissDetailView:(BOOL)autoDismiss
		hideDetailViewNavigationBar:(BOOL)hideNavBar
{
	if( (self=[self initWithItems:items allowMultipleSelection:allowMultipleSel allowNoSelection:allowNoSel]) )
	{
		self.autoDismissDetailView = autoDismiss;
		self.hideDetailViewNavigationBar = hideNavBar;
	}
	return self;
}


- (void)setSelectionItemsStore:(SCDataStore *)store
{
    selectionItemsStore = store;
    
    selectionItemsFetchOptions = [store.defaultDataDefinition generateCompatibleDataFetchOptions];
}

- (NSArray *)items
{
    return [self.selectionItemsStore fetchObjectsWithOptions:self.selectionItemsFetchOptions];
}

@end






@implementation SCObjectSelectionAttributes

@synthesize intermediateEntityDefinition;



+ (instancetype)attributesWithSelectionObjects:(NSArray *)objects
                   objectsDefinition:(SCDataDefinition *)definition
              allowMultipleSelection:(BOOL)allowMultipleSel
                    allowNoSelection:(BOOL)allowNoSel
{
    return [[[self class] alloc] initWithSelectionObjects:objects
                                                   objectsDefinition:definition
                                                  allowMultipleSelection:allowMultipleSel
                                                        allowNoSelection:allowNoSel];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
		intermediateEntityDefinition = nil;
	}
	return self;
}

- (instancetype)initWithSelectionObjects:(NSArray *)objects
             objectsDefinition:(SCDataDefinition *)definition
        allowMultipleSelection:(BOOL)allowMultipleSel
              allowNoSelection:(BOOL)allowNoSel
{
	if( (self=[self init]) )
	{
		self.selectionItemsStore = [SCArrayStore storeWithObjectsArray:[NSMutableArray arrayWithArray:objects] defaultDefiniton:definition];
        
		self.allowMultipleSelection = allowMultipleSel;
		self.allowNoSelection = allowNoSel;
	}
	return self;
}

@end







@implementation SCObjectAttributes

@synthesize objectDefinition;

+ (instancetype)attributesWithObjectDefinition:(SCDataDefinition *)definition
{
	return [[[self class] alloc] initWithObjectDefinition:definition];
}

+ (instancetype)attributesWithObjectDefinition:(SCDataDefinition *)definition expandContentInCurrentView:(BOOL)expandContent
{
    return [[[self class] alloc] initWithObjectDefinition:definition expandContentInCurrentView:expandContent];
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
		objectDefinition = nil;
	}
	return self;
}

- (instancetype)initWithObjectDefinition:(SCDataDefinition *)definition
{
	if( (self=[self init]) )
	{
		self.objectDefinition = definition;
	}
	return self;
}

- (instancetype)initWithObjectDefinition:(SCDataDefinition *)definition expandContentInCurrentView:(BOOL)expandContent
{
    if( (self=[self initWithObjectDefinition:definition]) )
    {
        self.expandContentInCurrentView = expandContent;
    }
    return self;
}

@end








@implementation SCArrayOfObjectsAttributes

@synthesize defaultObjectsDefinition;
@synthesize objectsFetchOptions;
@synthesize allowAddingItems;
@synthesize allowDeletingItems;
@synthesize allowMovingItems;
@synthesize allowEditingItems;
@synthesize placeholderuiElement;
@synthesize addNewObjectuiElement;
@synthesize addNewObjectuiElementExistsInNormalMode;
@synthesize addNewObjectuiElementExistsInEditingMode;
@synthesize sectionActions = _sectionActions;


+ (instancetype)attributesWithObjectDefinition:(SCDataDefinition *)definition
						 allowAddingItems:(BOOL)allowAdding allowDeletingItems:(BOOL)allowDeleting
						 allowMovingItems:(BOOL)allowMoving
{
	return [[[self class] alloc] initWithObjectDefinition:definition
											   allowAddingItems:allowAdding
											 allowDeletingItems:allowDeleting
											   allowMovingItems:allowMoving];
}

+ (instancetype)attributesWithObjectDefinition:(SCDataDefinition *)definition
						 allowAddingItems:(BOOL)allowAdding allowDeletingItems:(BOOL)allowDeleting allowMovingItems:(BOOL)allowMoving 
               expandContentInCurrentView:(BOOL)expandContent 
                     placeholderuiElement:(NSObject *)placeholderUI
                    addNewObjectuiElement:(NSObject *)newObjectUI
  addNewObjectuiElementExistsInNormalMode:(BOOL)existsInNormalMode 
 addNewObjectuiElementExistsInEditingMode:(BOOL)existsInEditingMode
{
    return [[[self class] alloc] initWithObjectDefinition:definition
											   allowAddingItems:allowAdding
											 allowDeletingItems:allowDeleting
											   allowMovingItems:allowMoving 
                                     expandContentInCurrentView:expandContent
                                           placeholderuiElement:placeholderUI
                                          addNewObjectuiElement:newObjectUI 
                        addNewObjectuiElementExistsInNormalMode:existsInNormalMode 
                       addNewObjectuiElementExistsInEditingMode:existsInEditingMode]; 
}

- (instancetype)init
{
	if( (self = [super init]) )
	{
        defaultObjectsDefinition = nil;
        objectsFetchOptions = nil; // will be re-initialized when defaultObjectsDefinition is set
        
		allowAddingItems = TRUE;
		allowDeletingItems = TRUE;
		allowMovingItems = TRUE;
		allowEditingItems = TRUE;
        placeholderuiElement = nil;
        addNewObjectuiElement = nil;
        addNewObjectuiElementExistsInNormalMode = TRUE;
        addNewObjectuiElementExistsInEditingMode = TRUE;
        
        _sectionActions = [[SCSectionActions alloc] init];
	}
	return self;
}

- (instancetype)initWithObjectDefinition:(SCDataDefinition *)definition
				   allowAddingItems:(BOOL)allowAdding allowDeletingItems:(BOOL)allowDeleting
				   allowMovingItems:(BOOL)allowMoving
{
	if( (self=[self init]) )
	{
        self.defaultObjectsDefinition = definition;
        
		allowAddingItems = allowAdding;
		allowDeletingItems = allowDeleting;
		allowMovingItems = allowMoving;
	}
	return self;
}

- (instancetype)initWithObjectDefinition:(SCDataDefinition *)definition
                   allowAddingItems:(BOOL)allowAdding allowDeletingItems:(BOOL)allowDeleting allowMovingItems:(BOOL)allowMoving  
         expandContentInCurrentView:(BOOL)expandContent
               placeholderuiElement:(NSObject *)placeholderUI
              addNewObjectuiElement:(NSObject *)newObjectUI
addNewObjectuiElementExistsInNormalMode:(BOOL)existsInNormalMode 
addNewObjectuiElementExistsInEditingMode:(BOOL)existsInEditingMode
{
    if( (self=[self initWithObjectDefinition:definition allowAddingItems:allowAdding allowDeletingItems:allowDeleting allowMovingItems:allowMoving]) )
    {
        self.expandContentInCurrentView = expandContent;
        self.placeholderuiElement = placeholderUI;
        self.addNewObjectuiElement = newObjectUI;
        self.addNewObjectuiElementExistsInNormalMode = existsInNormalMode;
        self.addNewObjectuiElementExistsInEditingMode = existsInEditingMode;
    }
    return self;
}


- (void)setDefaultObjectsDefinition:(SCDataDefinition *)definition
{
    defaultObjectsDefinition = definition;
    
    objectsFetchOptions = [definition generateCompatibleDataFetchOptions];
}

@end






