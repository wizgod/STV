/*
 *  SCSectionActions.h
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


#import <UIKit/UIKit.h>


@class SCTableViewModel;
@class SCTableViewSection;
@class SCArrayOfItemsSection;
@class SCCustomCell;

typedef void(^SCSectionAction_Block)(SCTableViewSection *section, NSUInteger sectionIndex);
typedef void(^SCSectionViewAction_Block)(SCTableViewSection *section, NSUInteger sectionIndex, UIView *view);

typedef void(^SCDetailModelSectionAction_Block)(SCTableViewSection *section, SCTableViewModel *detailModel, NSIndexPath *indexPath);
typedef BOOL(^SCConditionalDetailModelSectionAction_Block)(SCTableViewSection *section, SCTableViewModel *detailModel, NSIndexPath *indexPath);

typedef void(^SCDidFetchSectionItemsAction_Block)(SCArrayOfItemsSection *itemsSection, NSMutableArray *items);
typedef void(^SCFetchSectionItemsFailedAction_Block)(SCArrayOfItemsSection *itemsSection, NSError *error);
typedef void(^SCSectionItemDidCreateAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item);
typedef BOOL(^SCSectionItemWillInsertAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item, SCTableViewModel *itemModel);
typedef BOOL(^SCSectionItemInsertNoConnectionAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item);
typedef void(^SCSectionItemInsertFailedAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item, NSError *error);
typedef void(^SCSectionItemDidInsertAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item, NSIndexPath *indexPath);
typedef BOOL(^SCSectionItemWillUpdateAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item, NSIndexPath *indexPath, SCTableViewModel *itemModel);
typedef BOOL(^SCSectionItemUpdateNoConnectionAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item);
typedef void(^SCSectionItemUpdateFailedAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item, NSError *error);
typedef void(^SCSectionItemDidUpdateAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item, NSIndexPath *indexPath);
typedef BOOL(^SCSectionItemWillDeleteAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item, NSIndexPath *indexPath);
typedef BOOL(^SCSectionItemDeleteNoConnectionAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item);
typedef void(^SCSectionItemDeleteFailedAction_Block)(SCArrayOfItemsSection *itemsSection, NSObject *item, NSError *error);
typedef void(^SCSectionItemDidDeleteAction_Block)(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath);
typedef void(^SCDidAddSpecialCellsAction_Block)(SCArrayOfItemsSection *itemsSection, NSMutableArray *items);

typedef UIViewController*(^SCDetailViewControllerForRowAtIndexPathAction_Block)(SCTableViewSection *section, NSIndexPath *indexPath);
typedef SCTableViewModel*(^SCDetailTableViewModelForRowAtIndexPathAction_Block)(SCTableViewSection *section, NSIndexPath *indexPath);

typedef SCCustomCell*(^SCCellForRowAtIndexPathAction_Block)(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath);
typedef NSString*(^SCReuseIdForRowAtIndexPathAction_Block)(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath);
typedef CGFloat(^SCCustomHeightForRowAtIndexPathAction_Block)(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath);

/****************************************************************************************/
/*	class SCSectionActions	*/
/****************************************************************************************/ 
/**	
 This class hosts a set of section action blocks. Once an action is set to a desired code block, it will execute the block as soon as the action occurs.
 
 @see SCCellActions, SCModelActions.
 */

@interface SCSectionActions : NSObject


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Section Actions
//////////////////////////////////////////////////////////////////////////////////////////

/** Action gets called right after the section has been added to a model.
 
 This action is typically used to get hold of the section at data definition time and perform any additional configuration.
 
 Example:
 
    // Objective-C
    myArrayOfObjectsAttributes.expandContentInCurrentView = YES;
    myArrayOfObjectsAttributes.expandedContentSectionActions.didAddToModel = ^(SCTableViewSection *section, NSUInteger sectionIndex)
    {
        // set all expanded cells to a different background color
        section.cellActions.willDisplay = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
        {
            cell.backgroundColor = [UIColor yellowColor];
        };
    };
 
    // Swift
    myArrayOfObjectsAttributes.expandContentInCurrentView = true
    myArrayOfObjectsAttributes.expandedContentSectionActions.didAddToModel =
    {
        (section, sectionIndex) in
 
        // set all expanded cells to a different background color
        section.cellActions.willDisplay =
        {
            (cell, indexPath) in
 
            cell.backgroundColor = UIColor.yellowColor
        }
    }
 
  */
@property (nonatomic, copy) SCSectionAction_Block didAddToModel;

/** Action gets called when the section's header view is about to be displayed.
 
 Example:
 
    // Objective-C
    sectionActions.willDisplayHeaderView = ^(SCTableViewSection *section, NSUInteger sectionIndex, UIView *view)
    {
        NSLog(@"Header view about to be displayed for section at index '%i'", sectionIndex);
    };
 
    // Swift
    sectionActions.willDisplayHeaderView =
    {
        (section, sectionIndex, view) in
 
        NSLog("Header view about to be displayed for section at index '%i'", sectionIndex)
    }
 
  */
@property (nonatomic, copy) SCSectionViewAction_Block willDisplayHeaderView;

/** Action gets called when the section's footer view is about to be displayed.
 
 Example:
 
    // Objective-C
    sectionActions.willDisplayFooterView = ^(SCTableViewSection *section, NSUInteger sectionIndex, UIView *view)
    {
        NSLog(@"Footer view about to be displayed for section at index '%i'", sectionIndex);
    };
 
    // Swift
    sectionActions.willDisplayFooterView =
    {
        (section, sectionIndex, view) in
 
        NSLog("Footer view about to be displayed for section at index '%i'", sectionIndex)
    }
 
  */
@property (nonatomic, copy) SCSectionViewAction_Block willDisplayFooterView;

/** Action gets called when the value of a section with an inherent value (such as an SCSelectionSection) has changed.
 
 Example:
 
    // Objective-C
    sectionActions.valueChanged = ^(SCTableViewSection *section, NSUInteger sectionIndex)
    {
        NSLog(@"Value for section at index '%i' has changed to %@", sectionIndex, section.boundValue);
    };
 
    // Swift
    sectionActions.valueChanged =
    {
        (section, sectionIndex) in
 
        NSLog("Value for section at index '%i' has changed to %@", sectionIndex, section.boundValue)
    }
 
 */
@property (nonatomic, copy) SCSectionAction_Block valueChanged;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Detail Model Actions
//////////////////////////////////////////////////////////////////////////////////////////

/** Action gets called right after the section's detail model is created, before configuration is set or any sections are added.
 
 This action is typically used to initially configure the detail model (like set a custom tag for example). Most of the model's settings can also be configure in the detailModelConfigured action.
 
 Example:
 
    // Objective-C
    sectionActions.detailModelCreated = ^(SCTableViewSection *section, SCTableViewModel *detailModel, NSIndexPath *indexPath)
    {
        detailModel.tag = 100;
    };
 
    // Swift
    sectionActions.detailModelCreated =
    {
        (section, detailModel, indexPath) in
 
        detailModel.tag = 100
    }
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection. 
 
 @warning In the case where the detail model is not associated with an existing row (such as the case when 'SCArrayOfObjectsSection' creates a new item), indexPath.row will be set to NSNotFound. This is a good way to test if the detail model was generated for a new item or an already existing one.
 
 @see detailModelConfigured
 */
@property (nonatomic, copy) SCDetailModelSectionAction_Block detailModelCreated;

/** Action gets called after the section's detail model is fully configured, including the addition of all automatically generated sections.
 
 This action is typically used to add additional custom sections, or modify the already existing automatically generated ones.
 
 Example:
 
    // Objective-C
    sectionActions.detailModelConfigured = ^(SCTableViewSection *section, SCTableViewModel *detailModel, NSIndexPath *indexPath)
    {
        SCTableViewSection *customSection = [SCTableViewSection section];
        SCCustomCell *customCell = [SCCustomCell cellWithText:@"Custom Cell"];
        [customSection addCell:customCell];
 
        [detailModel addSection:customSection];
    };
 
    // Swift
    sectionActions.detailModelConfigured =
    {
        (section, detailModel, indexPath) in
 
        let customSection = SCTableViewSection()
        let customCell = SCCustomCell(text: "Custom Cell")
        customSection.addCell(customCell)
 
        detailModel.addSection(customSection)
    }
 
 @note In general, it is easier (and more recommended) to add your custom sections and cells using the data definitions, instead of using this action to do so. For more information, please refer to SCDataDefinition and SCCustomPropertyDefinition.
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection. 
 
 @warning In the case where the detail model is not associated with an existing row (such as the case when 'SCArrayOfObjectsSection' creates a new item), indexPath.row will be set to NSNotFound. This is a good way to test if the detail model was generated for a new item or an already existing one.
 */
@property (nonatomic, copy) SCDetailModelSectionAction_Block detailModelConfigured;

/** Implement action to provide your own custom presentation for the detail model instead of having the framework automatically present it.
 
 Example:
 
    // Objective-C
    sectionActions.customPresentDetailModel = ^(SCTableViewSection *section, SCTableViewModel *detailModel, NSIndexPath *indexPath)
    {
        UIViewController *detailViewController = detailModel.viewController;
        [myNavigationController pushViewController:detailViewController animated:YES];
    };
 
    // Swift
    sectionActions.customPresentDetailModel =
    {
        (section, detailModel, indexPath) in
 
        let detailViewController = detailModel.viewController
        myNavigationController?.pushViewController(detailViewController, animated:true)
    }
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection.
 
 @warning In the case where the detail model is not associated with an existing row (such as the case when 'SCArrayOfObjectsSection' creates a new item), indexPath.row will be set to NSNotFound. This is a good way to test if the detail model was generated for a new item or an already existing one.
 */
@property (nonatomic, copy) SCDetailModelSectionAction_Block customPresentDetailModel;

/** Action gets called when the section's detail model is about to be presented in its own view controller.
 
 This action is typically used to further customize the detail model's view controller.
 
 Example:
 
    // Objective-C
    sectionActions.detailModelWillPresent = ^(SCTableViewSection *section, SCTableViewModel *detailModel, NSIndexPath *indexPath)
    {
        detailModel.viewController.title = @"My custom title";
    };
 
    // Swift
    sectionActions.detailModelWillPresent =
    {
        (section, detailModel, indexPath) in
 
        detailModel.viewController.title = "My custom title"
    }
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection. 
 
 @warning In the case where the detail model is not associated with an existing row (such as the case when 'SCArrayOfObjectsSection' creates a new item), indexPath.row will be set to NSNotFound. This is a good way to test if the detail model was generated for a new item or an already existing one.
 */
@property (nonatomic, copy) SCDetailModelSectionAction_Block detailModelWillPresent;

/** Action gets called when the section's detail model has been presented in its own view controller.
 
 Example:
 
    // Objective-C
    sectionActions.detailModelDidPresent = ^(SCTableViewSection *section, SCTableViewModel *detailModel, NSIndexPath *indexPath)
    {
        NSLog(@"Detail model has been presented.");
    };
 
    // Swift
    sectionActions.detailModelDidPresent =
    {
        (section, detailModel, indexPath) in
 
        NSLog("Detail model has been presented.")
    }
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection. 
 
 @warning In the case where the detail model is not associated with an existing row (such as the case when 'SCArrayOfObjectsSection' creates a new item), indexPath.row will be set to NSNotFound. This is a good way to test if the detail model was generated for a new item or an already existing one.
 */
@property (nonatomic, copy) SCDetailModelSectionAction_Block detailModelDidPresent;

/** Action gets called to give you a chance to decide if the detail model should be dismissed. Return YES to allow the detail model to be dismissed, otherwise return NO.
 
 Example:
 
    // Objective-C
    sectionActions.detailModelShouldDismiss = ^BOOL(SCTableViewSection *section, SCTableViewModel *detailModel, NSIndexPath *indexPath)
    {
        return YES;  // allow detail model to be dismissed
    };
 
    // Swift
    sectionActions.detailModelShouldDismiss =
    {
        (section, detailModel, indexPath)->Bool in
 
        return true  // allow detail model to be dismissed
    }
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection.
 
 @warning In the case where the detail model is not associated with an existing row (such as the case when 'SCArrayOfObjectsSection' creates a new item), indexPath.row will be set to NSNotFound. This is a good way to test if the detail model was generated for a new item or an already existing one.
 */
@property (nonatomic, copy) SCConditionalDetailModelSectionAction_Block detailModelShouldDismiss;

/** Action gets called when the section's detail model's view controller is about to be dismissed.
 
 Example:
 
    // Objective-C
    sectionActions.detailModelWillDismiss = ^(SCTableViewSection *section, SCTableViewModel *detailModel, NSIndexPath *indexPath)
    {
        NSLog(@"Detail model will be dismissed.");
    };
 
    // Swift
    sectionActions.detailModelWillDismiss =
    {
        (section, detailModel, indexPath) in
 
        NSLog("Detail model will be dismissed.")
    }
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection. 
 
 @warning In the case where the detail model is not associated with an existing row (such as the case when 'SCArrayOfObjectsSection' creates a new item), indexPath.row will be set to NSNotFound. This is a good way to test if the detail model was generated for a new item or an already existing one.
 */
@property (nonatomic, copy) SCDetailModelSectionAction_Block detailModelWillDismiss;

/** Action gets called when the section's detail model's view controller has been dismissed.
 
 Example:
 
    // Objective-C
    sectionActions.detailModelDidDismiss = ^(SCTableViewSection *section, SCTableViewModel *detailModel, NSIndexPath *indexPath)
    {
        NSLog(@"Detail model has been dismissed.");
    };
 
    // Swift
    sectionActions.detailModelDidDismiss =
    {
        (section, detailModel, indexPath) in
 
        NSLog("Detail model has been dismissed.")
    }
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection. 
 
 @warning In the case where the detail model is not associated with an existing row (such as the case when 'SCArrayOfObjectsSection' creates a new item), indexPath.row will be set to NSNotFound. This is a good way to test if the detail model was generated for a new item or an already existing one.
 */
@property (nonatomic, copy) SCDetailModelSectionAction_Block detailModelDidDismiss;

/** Action gets called to give you the chance to return a custom detail view controller for the section.
 
 This action is typically used to provide your own custom detail view controller, instead of the one automatically generated by the section.
 
 @return The custom view controller. *Must only be of type SCViewController or SCTableViewController*. Note: returning nil ignores the implementation of this action.
 
 Example:
 
    // Objective-C
    sectionActions.detailViewController = ^UIViewController*(SCTableViewSection *section, NSIndexPath *indexPath)
    {
        MyCustomViewController *customVC = [[MyCustomViewController alloc] initWithNib:@"MyCustomViewController" bundle:nil];
 
        return customVC;
    };
 
    // Swift
    sectionActions.detailViewController =
    {
        (section, indexPath)->UIViewController in
 
        let customVC = MyCustomViewController(nibName: "MyCustomViewController", bundle: nil)
 
        return customVC
    }
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection.
 */
@property (nonatomic, copy) SCDetailViewControllerForRowAtIndexPathAction_Block detailViewControllerForRowAtIndexPath;

/** Action gets called to give you the chance to return a custom detail model for the section's detail view controller.
 
 This action is typically used to provide your own custom detail model, instead of the one automatically generated by the section.
 
 @note It is much more common to use the detailViewController action instead, assigning the custom model in the custom view controller's viewDidLoad method.
 
 @return The custom detail model. The returned detail model should not be associated with any table views, as the framework will automatically handle this on your behalf. Note: returning nil ignores the implementation of this action.
 
 Example:
 
    // Objective-C
    sectionActions.detailTableViewModelForRowAtIndexPath = ^SCTableViewModel*(SCTableViewSection *section, NSIndexPath *indexPath)
    {
        return myCustomTableViewModel;
    };
 
    // Swift
    sectionActions.detailTableViewModelForRowAtIndexPath =
    {
        (section, indexPath)->SCTableViewModel in
 
        return myCustomTableViewModel
    }
 
    @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection.
 */
@property (nonatomic, copy) SCDetailTableViewModelForRowAtIndexPathAction_Block detailTableViewModelForRowAtIndexPath;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name SCArrayOfItemsSection Actions
//////////////////////////////////////////////////////////////////////////////////////////

/** Action gets called to give you the chance to return a custom cell for the section's item, instead of the automatically generated standard SCTableViewCell.
 
 @return The custom cell. *Must only be of type SCCustomCell or subclass*. Note: returning nil ignores the implementation of this action.
 
 Example:
 
    // Objective-C
    sectionActions.cellForRowAtIndexPath = ^SCCustomCell*(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath)
    {
        // '1' and '2' are the tags of the labels corresponding to 
        // the firstName and lastName object properties  ( NO NEED to provide bindingsString if your cell uses curly brace binding )
        NSString *bindingsString = @"1:firstName;2:lastName";
 
        SCCustomCell *customCell = [SCCustomCell cellWithText:nil objectBindingsString:bindingsString nibName:@"MyCustomCell"];
 
        return customCell;
    };
 
    // Swift
    sectionActions.cellForRowAtIndexPath =
    {
        (itemsSection, indexPath) in
 
        // '1' and '2' are the tags of the labels corresponding to 
        // the firstName and lastName object properties
        let bindingsString = "1:firstName;2:lastName"
 
        let customCell = SCCustomCell(text:nil objectBindingsString:bindingsString nibName:"MyCustomCell")
 
        return customCell
    }
 
 @warning If more than one type of custom cell is returned (e.g.: depending on the indexPath), then you *must* also use the reuseIdentifierForRowAtIndexPath action to return a unique reuse id for each different cell you return. Otherwise, there is no need to set the reuseIdentifierForRowAtIndexPath action.
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection.
 
 @see reuseIdentifierForRowAtIndexPath
 */
@property (nonatomic, copy) SCCellForRowAtIndexPathAction_Block cellForRowAtIndexPath;

/** In case more than one type of custom cell is returned in cellForRowAtIndexPath, this action gets called to give you the chance to return a custom cell reuse identifier for each different type. 
 
 @note You only need to set this action if more than one type of custom cell is returned in cellForRowAtIndexPath.
 
 @return An NSString containing the custom cell reuse identifier.
 
 Example:
 
    // Objective-C
    sectionActions.cellForRowAtIndexPath = ^SCCustomCell*(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath)
    {
        SCCustomCell *customCell;
        if(indexPath.row % 2)
            customCell = [[MyCustomOddCell alloc] init];
        else
            customCell = [[MyCustomEvenCell alloc] init];
 
        return customCell;
    };
    sectionActions.reuseIdentifierForRowAtIndexPath = ^NSString*(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath)
    {
        NSString *reuseId;
        if(indexPath.row % 2)
            reuseId = @"OddCell";
        else
            reuseId = @"EvenCell";
 
        return reuseId;
    };
 
    // Swift
    sectionActions.cellForRowAtIndexPath =
    {
        (itemsSection, indexPath)->SCCustomCell in
 
        var customCell : SCCustomCell
        if indexPath.row%2 != 0
        {
            customCell = MyCustomOddCell()
        }
        else
        {
            customCell = MyCustomEvenCell()
        }
        
        return customCell
    }
    sectionActions.reuseIdentifierForRowAtIndexPath =
    {
        (itemsSection, indexPath)->String in
 
        var reuseId : String
        if indexPath.row%2 != 0
        {
            reuseId = "OddCell"
        }
        else
        {
            reuseId = "EvenCell"
        }
        
        return reuseId
    }
 
 @note This action is only applicable to sections that generate detail views, such as SCArrayOfObjectsSection.
 */
@property (nonatomic, copy) SCReuseIdForRowAtIndexPathAction_Block reuseIdentifierForRowAtIndexPath;

/** Action gets called to give you the chance to return a custom cell height for each of the section's cells, instead of STV's automatically calculated cell height.
 
 @return The custom cell height. Note: returning UITableViewAutomaticDimension ignores the implementation of this action and will have the framework automatically calculate the cell height.
 
 Example:
 
    // Objective-C
    sectionActions.customHeightForRowAtIndexPath = ^CGFloat(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath)
    {
        CGFloat cellHeight;
        if(indexPath.row % 2)
            cellHeight = 44;
        else
            cellHeight = 60;
 
        return cellHeight;
    };
 
    // Swift
    sectionActions.customHeightForRowAtIndexPath =
    {
        (itemsSection, indexPath)->CGFloat in
 
        var cellHeight : CGFloat
        if indexPath.row%2 != 0
        {
            cellHeight = 44
        }
        else
        {
            cellHeight = 60
        }
        
        return cellHeight
    }
 
 @note Implement this action only if you would like to the cell height directly instead of having the framework automatically calculate it for you.
 
 */
@property (nonatomic, copy) SCCustomHeightForRowAtIndexPathAction_Block customHeightForRowAtIndexPath;

/** Action gets called as soon as the section has retrieved its items from their data store.
 
 This action is typically used to customize the 'items' array after it has been fetched from the data store. Items can be added, removed, or rearranged. The added items can either be objects that are suppored by the data store, or normal SCTableViewCell (or subclass) objects.
 
 Example:
 
    // Objective-C
    sectionActions.didFetchItemsFromStore = ^(SCArrayOfItemsSection *itemsSection, NSMutableArray *items)
    {
        // Add a button cell at the end of the items list
        SCTableViewCell *buttonCell = [SCTableViewCell cellWithText:@"Tap me!" textAlignment:NSTextAlignmentCenter];
        buttonCell.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
        {
            NSLog(@"buttonCell tapped!");
        };
 
        [items addObject:buttonCell];
    };
 
    // Swift
    sectionActions.didFetchItemsFromStore =
    {
        (itemsSection, items) in
 
        // Add a button cell at the end of the items list
 
        let buttonCell = SCTableViewCell(text: "Tap me!", textAlignment: .Center)
        buttonCell.cellActions.didSelect =
        {
            (cell, indexPath) in
            
            NSLog("buttonCell tapped!")
        }
 
        items.addObject(buttonCell)
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection. 
 
 */
@property (nonatomic, copy) SCDidFetchSectionItemsAction_Block didFetchItemsFromStore;

/** Action gets called if the section fails to retrieve its items from their data store.
 
 This action is typically used when the section is bound to a web service and you want to give the user feedback that their web service was not reachable.
 
 Example:
 
    // Objective-C
     sectionActions.fetchItemsFromStoreFailed = ^(SCArrayOfItemsSection *itemsSection, NSError *error)
     {
          NSLog(@"Failed retrieving section items with error: %@", error);
     };
 
    // Swift
    sectionActions.fetchItemsFromStoreFailed =
    {
        (itemsSection, error) in
 
        NSLog("Failed retrieving section items with error: %@", error)
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCFetchSectionItemsFailedAction_Block fetchItemsFromStoreFailed;

/** Action gets called as soon as the section has created a new item to be used in its add new item detail view (which usually apprears right after the user taps the section's Add button).
 
 This action is typically used to customize the newly created item before the new item detail view is displayed.
 
 Example:
 
    // Objective-C
    sectionActions.didCreateItem = ^(SCArrayOfItemsSection *itemsSection, NSObject *item)
    {
        // Set an initial value for startDate
        [item setValue:[NSDate date] forKey:@"startDate"];
    };
 
    // Swift
    sectionActions.didCreateItem =
    {
        (itemsSection, item) in
 
        // Set an initial value for startDate
        item.setValue(NSDate(), forKey:@"startDate")
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemDidCreateAction_Block didCreateItem;

/** Action gets called right before a newly created item is inserted into the section.
 
 This action is typically used to customize the newly created item before it's inserted. Furthermore, returning FALSE gives you the chance to discard adding the new item altogether.
 
 Example:
 
    // Objective-C
    sectionActions.willInsertItem = ^BOOL(SCArrayOfItemsSection *itemsSection, NSObject *item, SCTableViewModel *itemModel)
    {
        // Set a default description if no description is set
        if(![item valueForKey:@"description"])
            [item setValue:@"My default description" forKey:@"description"];
 
        // Accept insert
        return TRUE;
    };
 
    // Swift
    sectionActions.willInsertItem =
    {
        (itemsSection, item, itemModel)->Bool in
 
        // Set a default description if no description is set
        if item.valueForKey("description") == nil
        {
            item.setValue("My default description", forKey: "description")
        }
 
        // Accept insert
        return true
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemWillInsertAction_Block willInsertItem;

/** Action gets called when a newly created item is being inserted into the section, but no data store connection could be established.
 
 This action is typically called for Internet connection dependent data stores, such as SCWebServiceStore and SCParseStore. Return YES to try operation again later when connection is available (currently only available with SCParseDefinition), otherwise return NO to call the insertItemFailed action.
 
 Example:
 
    // Objective-C
    sectionActions.insertItemNoConnection = ^BOOL(SCArrayOfItemsSection *itemsSection, NSObject *item)
    {
        NSLog(@"No connection available for current operation. Will try again later.");
 
        return YES;  // try again later
    };
 
    // Swift
    sectionActions.insertItemNoConnection =
    {
        (itemsSection, item)->Bool in
 
        NSLog("No connection available for current operation. Will try again later.")
 
        return true  // try again later
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemInsertNoConnectionAction_Block insertItemNoConnection;

/** Action gets called when a newly created item could not be inserted into the section.
 
 This action is typically called for Internet connection dependent data stores, such as SCWebServiceStore and SCParseStore.
 
 Example:
 
    // Objective-C
    sectionActions.insertItemFailed = ^(SCArrayOfItemsSection *itemsSection, NSObject *item, NSError *error)
    {
        NSLog(@"Operation failed with error: %@", error);
    };
 
    // Swift
    sectionActions.insertItemFailed =
    {
        (itemsSection, item, error) in
 
        NSLog("Operation failed with error: %@", error)
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemInsertFailedAction_Block insertItemFailed;

/** Action gets called as soon as a new item has been added to the section.
 
 This action is typically used to provide custom functionality after a new item has been added.
 
 Example:
 
    // Objective-C
    sectionActions.didInsertItem = ^(SCArrayOfItemsSection *itemsSection, NSObject *item, NSIndexPath *indexPath)
    {
        NSLog(@"New item inserted at indexPath: %@", indexPath);
    };
 
    // Swift
    sectionActions.didInsertItem =
    {
        (itemsSection, item, indexPath) in
 
        NSLog("New item inserted at indexPath: %@", indexPath)
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemDidInsertAction_Block didInsertItem;

/** Action gets called right before an existing item is updated.
 
 This action is typically used to give the user the chance to discard updating the item altogether by returning FALSE.
 
 Example:
 
    // Objective-C
    sectionActions.willUpdateItem = ^BOOL(SCArrayOfItemsSection *itemsSection, NSObject *item, NSIndexPath *indexPath, SCTableViewModel *itemModel)
    {
        if(myCondition)
            return TRUE; // Accept update
        //else
        return FALSE; // Reject update
    };
 
    // Swift
    sectionActions.willUpdateItem =
    {
        (itemsSection, item, indexPath, itemModel)->Bool in
 
        if myCondition==true
        {
            return true
        }
        // else
        return false
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemWillUpdateAction_Block willUpdateItem;

/** Action gets called when an existing item is being updated, but no data store connection could be established.
 
 This action is typically called for Internet connection dependent data stores, such as SCWebServiceStore and SCParseStore. Return YES to try operation again later when connection is available (currently only available with SCParseDefinition), otherwise return NO to call the updateItemFailed action.
 
 Example:
 
    // Objective-C
    sectionActions.updateItemNoConnection = ^BOOL(SCArrayOfItemsSection *itemsSection, NSObject *item)
    {
        NSLog(@"No connection available for current operation. Will try again later.");
 
        return YES;  // try again later
    };
 
    // Swift
    sectionActions.updateItemNoConnection =
    {
        (itemsSection, item)->Bool in
 
        NSLog("No connection available for current operation. Will try again later.")
 
        return true  // try again later
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemUpdateNoConnectionAction_Block updateItemNoConnection;

/** Action gets called when an existing item could not be updated.
 
 This action is typically called for Internet connection dependent data stores, such as SCWebServiceStore and SCParseStore.
 
 Example:
 
    // Objective-C
    sectionActions.updateItemFailed = ^(SCArrayOfItemsSection *itemsSection, NSObject *item, NSError *error)
    {
        NSLog(@"Operation failed with error: %@", error);
    };
 
    // Swift
    sectionActions.updateItemFailed =
    {
        (itemsSection, item, error) in
 
        NSLog("Operation failed with error: %@", error)
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemUpdateFailedAction_Block updateItemFailed;

/** Action gets called as soon as an existing item has been updated.
 
 This action is typically used to modify the item's values or provide custom functionality after an item has been updated.
 
 Example:
 
    // Objective-C
    sectionActions.didUpdateItem = ^(SCArrayOfItemsSection *itemsSection, NSObject *item, NSIndexPath *indexPath)
    {
        // Set a default description if no description is set
        if(![item valueForKey:@"description"])
            [item setValue:@"My default description" forKey:@"description"];
    };
 
    // Swift
    sectionActions.didUpdateItem =
    {
        (itemsSection, item, indexPath) in
 
        // Set a default description if no description is set
        if item.valueForKey("description") == nil
        {
            item.setValue("My default description", forKey: "description")
        }
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemDidUpdateAction_Block didUpdateItem;

/** Action gets called right before an existing item is deleted.
 
 This action is typically used to provide you with a chance to override the item delete operation by returning FALSE.
 
 Example:
 
    // Objective-C
    sectionActions.willDeleteItem = ^BOOL(SCArrayOfItemsSection *itemsSection, NSObject *item, NSIndexPath *indexPath)
    {
        BOOL deleteItem;
 
        if(myCondition)
            deleteItem = TRUE;
        else
            deleteItem = FALSE;
 
        return deleteItem;
    };
 
    // Swift
    sectionActions.willDeleteItem =
    {
        (itemsSection, item, indexPath)->Bool in
 
        var deleteItem : Bool
 
        if myCondition==true
        {
            deleteItem = true
        }
        else
        {
            deleteItem = false
        }
 
        return deleteItem
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemWillDeleteAction_Block willDeleteItem;

/** Action gets called when an existing item is being deleted, but no data store connection could be established.
 
 This action is typically called for Internet connection dependent data stores, such as SCWebServiceStore and SCParseStore. Return YES to try operation again later when connection is available (currently only available with SCParseDefinition), otherwise return NO to call the deleteItemFailed action.
 
 Example:
 
    // Objective-C
    sectionActions.deleteItemNoConnection = ^BOOL(SCArrayOfItemsSection *itemsSection, NSObject *item)
    {
        NSLog(@"No connection available for current operation. Will try again later.");
 
        return YES;  // try again later
    };
 
    // Swift
    sectionActions.deleteItemNoConnection =
    {
        (itemsSection, item)->Bool in
 
        NSLog("No connection available for current operation. Will try again later.")
 
        return true  // try again later
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemDeleteNoConnectionAction_Block deleteItemNoConnection;

/** Action gets called when an existing item could not be deleted.
 
 This action is typically called for Internet connection dependent data stores, such as SCWebServiceStore and SCParseStore.
 
 Example:
 
    // Objective-C
    sectionActions.deleteItemFailed = ^(SCArrayOfItemsSection *itemsSection, NSObject *item, NSError *error)
    {
        NSLog(@"Operation failed with error: %@", error);
    };
 
    // Swift
    sectionActions.deleteItemFailed =
    {
        (itemsSection, item, error) in
 
        NSLog("Operation failed with error: %@", error)
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemDeleteFailedAction_Block deleteItemFailed;

/** Action gets called as soon as an existing item has been deleted.
 
 This action is typically used to provide custom functionality after an item has been deleted.
 
 Example:
 
    // Objective-C
    sectionActions.didDeleteItem = ^(SCArrayOfItemsSection *itemsSection, NSIndexPath *indexPath)
    {
        NSLog(@"Item at indexPath: %@ has been deleted.", indexPath);
    };
 
    // Swift
    sectionActions.didDeleteItem =
    {
        (itemsSection, indexPath) in
 
        NSLog("Item at indexPath: %@ has been deleted.", indexPath)
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection.
 
 */
@property (nonatomic, copy) SCSectionItemDidDeleteAction_Block didDeleteItem;


/** Action gets called after the section has retrieved its items from their data store, and the framework has automatically added any needed special cells (e.g.: placeholder cell, load more cell, etc.) to the items array.
 
 This action is typically used to customize the 'items' array after it has been fetched from the data store and the special cells added to it.
 
 Example:
 
    // Objective-C
    sectionActions.didAddSpecialCells = ^(SCArrayOfItemsSection *itemsSection, NSMutableArray *items)
    {
        // Add a button cell at the end of the items list
        SCTableViewCell *buttonCell = [SCTableViewCell cellWithText:@"Tap me!" textAlignment:NSTextAlignmentCenter];
        buttonCell.cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
        {
            NSLog(@"buttonCell tapped!");
        };
 
        [items addObject:buttonCell];
    };
 
    // Swift
    sectionActions.didAddSpecialCells =
    {
        (itemsSection, items) in
 
        // Add a button cell at the end of the items list
 
        let buttonCell = SCTableViewCell(text: "Tap me!", textAlignment: .Center)
        buttonCell.cellActions.didSelect =
        {
            (cell, indexPath) in
            
            NSLog("buttonCell tapped!")
        }
 
        items.addObject(buttonCell)
    }
 
 @note This action is only applicable to SCArrayOfItemsSection subclasses, such as SCArrayOfObjectsSection. 
 */
@property (nonatomic, copy) SCDidAddSpecialCellsAction_Block didAddSpecialCells;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Miscellaneous
//////////////////////////////////////////////////////////////////////////////////////////

/** Method assigns all the actions of another 'SCSectionActions' class to the current one.
 
 @param actions The source 'SCSectionActions' class.
 @param override Set to TRUE to override any existing actions, otherwise set to FALSE.
 */
- (void)setActionsTo:(SCSectionActions *)actions overrideExisting:(BOOL)override;

@end
