/*
 *  SCPropertyDefinition.m
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

#import "SCPropertyDefinition.h"

#import "SCSectionActions.h"
#import "SCTableViewCell.h"


@implementation SCPropertyDefinition

@synthesize ownerDataStuctureDefinition;
@synthesize dataType;
@synthesize dataReadOnly;
@synthesize name;
@synthesize title;
@synthesize type;
@synthesize attributes;
@synthesize editingModeType;
@synthesize editingModeAttributes;
@synthesize required;
@synthesize autoValidate;
@synthesize existsInNormalMode;
@synthesize existsInEditingMode;
@synthesize existsInCreationMode;
@synthesize existsInDetailMode;
@synthesize uiElementClass;
@synthesize uiElementNibName;
@synthesize objectBindings;
@synthesize cellActions = _cellActions;


+ (instancetype)definitionWithName:(NSString *)propertyName
{
	return [[[self class] alloc] initWithName:propertyName];
}

+ (instancetype)definitionWithName:(NSString *)propertyName 
				   title:(NSString *)propertyTitle
					type:(SCPropertyType)propertyType
{
	return [[[self class] alloc] initWithName:propertyName title:propertyTitle type:propertyType];
}

- (instancetype)initWithName:(NSString *)propertyName
{
	return [self initWithName:propertyName title:nil type:SCPropertyTypeAutoDetect];
}

- (instancetype)initWithName:(NSString *)propertyName 
			 title:(NSString *)propertyTitle
			  type:(SCPropertyType)propertyType
{
	if( (self=[super init]) )
	{
		ownerDataStuctureDefinition = nil;
		
		dataType = SCDataTypeUnknown;
		dataReadOnly = FALSE;
		
		name = [propertyName copy];
		self.title = propertyTitle;
		self.type = propertyType;
		self.attributes = nil;
		self.editingModeType = SCPropertyTypeUndefined;
		self.editingModeAttributes = nil;
		self.required = FALSE;
		self.autoValidate = TRUE;
        self.existsInNormalMode = TRUE;
        self.existsInEditingMode = TRUE;
        self.existsInCreationMode = TRUE;
        self.existsInDetailMode = TRUE;
        
        uiElementClass = nil;
        uiElementNibName = nil;
        objectBindings = nil;
        
        _cellActions = [[SCCellActions alloc] init];
	}
	return self;
}

- (void)setAllPropertiesFromibDictionary:(NSDictionary *)ibDictionary
{
    if(!ibDictionary)
        return;
    
    NSString *pTitle = [ibDictionary valueForKey:@"title"];
    if([pTitle length])
        self.title = pTitle;
    else
        self.title = nil;
    
    self.required = [(NSNumber *)[ibDictionary valueForKey:@"required"] boolValue];
    
    NSNumber *normalMode = [ibDictionary valueForKey:@"existsInNormalMode"];
    if(normalMode)
        self.existsInNormalMode = [normalMode boolValue];
    NSNumber *editingMode = [ibDictionary valueForKey:@"existsInEditingMode"];
    if(editingMode)
        self.existsInEditingMode = [editingMode boolValue];
    NSNumber *creationMode = [ibDictionary valueForKey:@"existsInCreationMode"];
    if(creationMode)
        self.existsInCreationMode = [creationMode boolValue];
    NSNumber *detailMode = [ibDictionary valueForKey:@"existsInDetailMode"];
    if(detailMode)
        self.existsInDetailMode = [detailMode boolValue];
    
    NSString *elementClassName = [ibDictionary valueForKey:@"uiElementClassName"];
    if([elementClassName length])
        self.uiElementClass = [SCUtilities swiftCompatibleNSClassFromString:elementClassName];
    NSString *elementNibName = [ibDictionary valueForKey:@"uiElementNibName"];
    if([elementNibName length])
        self.uiElementNibName = elementNibName;
    
    
    self.type = (SCPropertyType)[[ibDictionary valueForKey:@"type"] integerValue];
    
    switch (type)
    {
        case SCPropertyTypeAutoDetect:
            break;
        case SCPropertyTypeLabel:
            break;
        case SCPropertyTypeTextView:
            self.attributes = [SCTextViewAttributes attributesWithMinimumHeight:[[ibDictionary valueForKey:@"genericFloat1"] floatValue] maximumHeight:[[ibDictionary valueForKey:@"genericFloat2"] floatValue] autoResize:[[ibDictionary valueForKey:@"genericBool1"] boolValue] editable:[[ibDictionary valueForKey:@"genericBool2"] boolValue]];
            break;
        case SCPropertyTypeTextField:
            self.attributes = [SCTextFieldAttributes attributesWithPlaceholder:[ibDictionary valueForKey:@"genericString1"] secureTextEntry:[[ibDictionary valueForKey:@"genericBool1"] boolValue] autocorrectionType:[[ibDictionary valueForKey:@"genericInt1"] integerValue] autocapitalizationType:[[ibDictionary valueForKey:@"genericInt2"] integerValue]];
            break;
        case SCPropertyTypeNumericTextField:
        {
            NSNumber *minValue = nil;
            if([[ibDictionary valueForKey:@"useGenericFloat1"] boolValue])
                minValue = [ibDictionary valueForKey:@"genericFloat1"];
            NSNumber *maxValue = nil;
            if([[ibDictionary valueForKey:@"useGenericFloat2"] boolValue])
                maxValue = [ibDictionary valueForKey:@"genericFloat2"];
            self.attributes = [SCNumericTextFieldAttributes attributesWithMinimumValue:minValue maximumValue:maxValue allowFloatValue:[[ibDictionary valueForKey:@"genericBool2"] boolValue] placeholder:[ibDictionary valueForKey:@"genericString1"]];
        }
            break;
        case SCPropertyTypeSlider:
            self.attributes = [SCSliderAttributes attributesWithMinimumValue:[[ibDictionary valueForKey:@"genericFloat1"] floatValue] maximumValue:[[ibDictionary valueForKey:@"genericFloat2"] floatValue]];
            break;
        case SCPropertyTypeSegmented:
            self.attributes = [SCSegmentedAttributes attributesWithSegmentTitlesArray:[ibDictionary valueForKey:@"stringsArray"]];
            break;
        case SCPropertyTypeSwitch:
            break;
        case SCPropertyTypeDate:
        {
            NSDateFormatter *dateFormatter = nil;
            NSString *dateFormat = [ibDictionary valueForKey:@"genericString1"];
            if([dateFormat length])
            {
                dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:dateFormat];
            }
            self.attributes = [SCDateAttributes attributesWithDateFormatter:dateFormatter datePickerMode:[[ibDictionary valueForKey:@"genericInt1"] integerValue] displayDatePickerAsInputAccessoryView:NO];
        }
            break;
        case SCPropertyTypeImagePicker:
            break;
        case SCPropertyTypeSelection:
            self.attributes = [SCSelectionAttributes attributesWithItems:[ibDictionary valueForKey:@"stringsArray"] allowMultipleSelection:[[ibDictionary valueForKey:@"genericBool1"] boolValue] allowNoSelection:[[ibDictionary valueForKey:@"genericBool2"] boolValue] autoDismissDetailView:[[ibDictionary valueForKey:@"genericBool3"] boolValue] hideDetailViewNavigationBar:[[ibDictionary valueForKey:@"genericBool4"] boolValue]];
            break;
        case SCPropertyTypeObjectSelection:
        {
            SCObjectSelectionAttributes *attribs = [[SCObjectSelectionAttributes alloc] init];
            attribs.objectsDefinitionibUniqueId = [ibDictionary valueForKey:@"genericString1"];
            attribs.ibPredicateString = [ibDictionary valueForKey:@"genericString2"];
            attribs.ibPlaceholderTextAlignment = (NSTextAlignment)[[ibDictionary valueForKey:@"genericInt1"] integerValue];
            attribs.ibPlaceholderText = [ibDictionary valueForKey:@"genericString3"];
            attribs.ibAddNewObjectText = [ibDictionary valueForKey:@"genericString4"];
            attribs.allowMultipleSelection = [[ibDictionary valueForKey:@"genericBool1"] boolValue];
            attribs.allowNoSelection = [[ibDictionary valueForKey:@"genericBool2"] boolValue];
            attribs.autoDismissDetailView = [[ibDictionary valueForKey:@"genericBool3"] boolValue];
            attribs.hideDetailViewNavigationBar = [[ibDictionary valueForKey:@"genericBool4"] boolValue];
            attribs.allowAddingItems = [[ibDictionary valueForKey:@"genericBool5"] boolValue];
            attribs.allowDeletingItems = [[ibDictionary valueForKey:@"genericBool6"] boolValue];
            attribs.allowMovingItems = [[ibDictionary valueForKey:@"genericBool7"] boolValue];
            attribs.allowEditingItems = [[ibDictionary valueForKey:@"genericBool8"] boolValue];
            
            self.attributes = attribs;
        }
            break;
        case SCPropertyTypeObject:
        {
            SCObjectAttributes *attribs = [[SCObjectAttributes alloc] init];
            attribs.objectDefinitionibUniqueId = [ibDictionary valueForKey:@"genericString1"];
            attribs.expandContentInCurrentView = [[ibDictionary valueForKey:@"genericBool1"] boolValue];
            
            self.attributes = attribs;
        }
            break;
        case SCPropertyTypeArrayOfObjects:
        {
            SCArrayOfObjectsAttributes *attribs = [[SCArrayOfObjectsAttributes alloc] init];
            attribs.defaultObjectsDefinitionibUniqueId = [ibDictionary valueForKey:@"genericString1"];
            attribs.ibPredicateString = [ibDictionary valueForKey:@"genericString2"];
            attribs.ibPlaceholderTextAlignment = (NSTextAlignment)[[ibDictionary valueForKey:@"genericInt1"] integerValue];
            attribs.ibPlaceholderText = [ibDictionary valueForKey:@"genericString3"];
            attribs.ibAddNewObjectText = [ibDictionary valueForKey:@"genericString4"];
            attribs.allowAddingItems = [[ibDictionary valueForKey:@"genericBool1"] boolValue];
            attribs.allowDeletingItems = [[ibDictionary valueForKey:@"genericBool2"] boolValue];
            attribs.allowMovingItems = [[ibDictionary valueForKey:@"genericBool3"] boolValue];
            attribs.allowEditingItems = [[ibDictionary valueForKey:@"genericBool4"] boolValue];
            attribs.expandContentInCurrentView = [[ibDictionary valueForKey:@"genericBool5"] boolValue];
            
            NSString *itemsUIElementClassName = [ibDictionary valueForKey:@"genericString5"];
            NSString *itemsUIElementNibName = [ibDictionary valueForKey:@"genericString6"];
            NSObject *itemsUIElement = nil;
            if([itemsUIElementNibName length])
            {
                itemsUIElement = [SCUtilities getFirstNodeInNibWithName:itemsUIElementNibName];
            }
            else if([itemsUIElementClassName length])
            {
                Class itemsUIElementClass = NSClassFromString(itemsUIElementClassName);
                itemsUIElement = [[itemsUIElementClass alloc] init];
            }
            if(itemsUIElement && [itemsUIElement isKindOfClass:[UITableViewCell class]])
            {
                attribs.sectionActions.cellForRowAtIndexPath = ^SCCustomCell*(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath)
                {
                    if([itemsUIElement isKindOfClass:[SCCustomCell class]])
                        return (SCCustomCell *)itemsUIElement;
                    
                    SCCustomCell *customCell = [SCCustomCell cellWithCell:(UITableViewCell *)itemsUIElement];
                    return customCell;
                };
            }
            
            self.attributes = attribs;
        }
            break;
        case SCPropertyTypeCustom:
            break;
            
        default:
            break;
    }
}


- (NSString *)objectBindingsString
{
    return [SCUtilities bindingsStringForBindingsDictionary:self.objectBindings];
}

- (void)setObjectBindingsString:(NSString *)objectBindingsString
{
    self.objectBindings = [SCUtilities bindingsDictionaryForBindingsString:objectBindingsString];
}

- (BOOL)dataTypeScalar
{
    if(self.dataType==SCDataTypeBOOL || self.dataType==SCDataTypeDouble || self.dataType==SCDataTypeFloat || self.dataType==SCDataTypeInt)
        return TRUE;
    //else
    return FALSE;
}

@end






@implementation SCCustomPropertyDefinition



+ (instancetype)definitionWithName:(NSString *)propertyName 
          uiElementClass:(Class)elementClass
          objectBindings:(NSDictionary *)bindings
{
	return [[[self class] alloc] initWithName:propertyName uiElementClass:elementClass objectBindings:bindings];
}

+ (instancetype)definitionWithName:(NSString *)propertyName 
          uiElementClass:(Class)elementClass
    objectBindingsString:(NSString *)bindingsString
{
	return [[[self class] alloc] initWithName:propertyName uiElementClass:elementClass objectBindingsString:bindingsString];
}

+ (instancetype)definitionWithName:(NSString *)propertyName 
        uiElementNibName:(NSString *)elementNibName
          objectBindings:(NSDictionary *)bindings
{
	return [[[self class] alloc] initWithName:propertyName uiElementNibName:elementNibName objectBindings:bindings];
}

+ (instancetype)definitionWithName:(NSString *)propertyName 
        uiElementNibName:(NSString *)elementNibName
    objectBindingsString:(NSString *)bindingsString
{
	return [[[self class] alloc] initWithName:propertyName uiElementNibName:elementNibName objectBindingsString:bindingsString];
}

//overrides superclass
- (instancetype)initWithName:(NSString *)propertyName
{
    if( (self = [super initWithName:propertyName]) )
    {
        type = SCPropertyTypeCustom;
    }
    
    return self;
}

- (instancetype)initWithName:(NSString *)propertyName uiElementClass:(Class)elementClass objectBindings:(NSDictionary *)bindings
{
	if( (self = [self initWithName:propertyName]) )
	{
		self.uiElementClass = elementClass;
		self.objectBindings = bindings;
        self.dataType = SCDataTypeNSString;
	}
	
	return self;
}

- (instancetype)initWithName:(NSString *)propertyName uiElementClass:(Class)elementClass objectBindingsString:(NSString *)bindingsString
{
    NSDictionary *bindings = [SCUtilities bindingsDictionaryForBindingsString:bindingsString];
    
    return [self initWithName:propertyName uiElementClass:elementClass objectBindings:bindings];
}

- (instancetype)initWithName:(NSString *)propertyName uiElementNibName:(NSString *)elementNibName objectBindings:(NSDictionary *)bindings
{
	if( (self = [self initWithName:propertyName]) )
	{
		self.uiElementNibName = elementNibName;
		self.objectBindings = bindings;
	}
	
	return self;
}

- (instancetype)initWithName:(NSString *)propertyName uiElementNibName:(NSString *)elementNibName objectBindingsString:(NSString *)bindingsString
{
    NSDictionary *bindings = [SCUtilities bindingsDictionaryForBindingsString:bindingsString];
    
    return [self initWithName:propertyName uiElementNibName:elementNibName objectBindings:bindings];
}

@end







@implementation SCPropertyGroup

@synthesize headerTitle;
@synthesize footerTitle;


+ (instancetype)groupWithHeaderTitle:(NSString *)groupHeaderTitle footerTitle:(NSString *)groupFooterTitle
         propertyNames:(NSArray *)propertyNames
{
    return [[[self class] alloc] initWithHeaderTitle:groupHeaderTitle footerTitle:groupFooterTitle propertyNames:propertyNames];
}

- (instancetype)init
{
	if( (self=[super init]) )
	{
		headerTitle = nil;
        footerTitle = nil;
        propertyDefinitionNames = [[NSMutableArray alloc] init];
	}
	return self;
}

- (instancetype)initWithHeaderTitle:(NSString *)groupHeaderTitle footerTitle:(NSString *)groupFooterTitle
        propertyNames:(NSArray *)propertyNames
{
    if( (self=[self init]) )
	{
		self.headerTitle = groupHeaderTitle;
        self.footerTitle = groupFooterTitle;
        [propertyDefinitionNames addObjectsFromArray:propertyNames];
	}
	return self;
}

- (NSInteger)propertyNameCount
{
    return [propertyDefinitionNames count];
}

- (void)addPropertyName:(NSString *)propertyName
{
    [propertyDefinitionNames addObject:propertyName];
}

- (void)insertPropertyName:(NSString *)propertyName atIndex:(NSInteger)index
{
    [propertyDefinitionNames insertObject:propertyName atIndex:index];
}

- (NSString *)propertyNameAtIndex:(NSInteger)index
{
    return [propertyDefinitionNames objectAtIndex:index];
}

- (void)removePropertyNameAtIndex:(NSInteger)index
{
    [propertyDefinitionNames removeObjectAtIndex:index];
}

- (void)removeAllPropertyNames
{
    [propertyDefinitionNames removeAllObjects];
}

- (BOOL)containsPropertyName:(NSString *)propertyName
{
    return [propertyDefinitionNames containsObject:propertyName];
}


@end




@implementation SCPropertyGroupArray

+ (instancetype)groupArray
{
	return [[[self class] alloc] init];
}

- (instancetype)init
{
	if( (self=[super init]) )
	{
		propertyGroups = [[NSMutableArray alloc] init];
	}
	return self;
}

- (NSInteger)groupCount
{
    return [propertyGroups count];
}

- (void)addGroup:(SCPropertyGroup *)group
{
    [propertyGroups addObject:group];
}

- (void)insertGroup:(SCPropertyGroup *)group atIndex:(NSInteger)index
{
    [propertyGroups insertObject:group atIndex:index];
}

- (SCPropertyGroup *)groupAtIndex:(NSInteger)index
{
    return [propertyGroups objectAtIndex:index];
}

- (SCPropertyGroup *)groupByHeaderTitle:(NSString *)headerTitle
{
    for(SCPropertyGroup *group in propertyGroups)
    {
        if([group.headerTitle isEqualToString:headerTitle])
            return group;
    }
    return nil;
}

- (void)removeGroupAtIndex:(NSInteger)index
{
    [propertyGroups removeObjectAtIndex:index];
}

- (void)removeAllGroups
{
    [propertyGroups removeAllObjects];
}

@end


