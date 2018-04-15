/*
 *  SCCellActions.h
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
#import <AssetsLibrary/AssetsLibrary.h>


@class SCTableViewModel;
@class SCTableViewCell;
@class SCImagePickerCell;

typedef void(^SCCellAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath);
typedef BOOL(^SCBOOLReturnCellAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath);
typedef UITableViewCellEditingStyle(^SCCellCustomEditingStyleAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath);
typedef NSArray*(^SCCellEditActionsAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath);
typedef NSObject*(^SCCellCalculatedValueAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath);
typedef NSObject*(^SCCellBoundValueAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath, NSObject *value);
typedef void(^SCCellCustomButtonTappedAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath, UIButton *button);

typedef BOOL(^SCCellCanPerformAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath, SEL action, id sender);
typedef void(^SCCellPerformAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath, SEL action, id sender);


typedef UIViewController*(^SCCellDetailViewControllerAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath);
typedef SCTableViewModel*(^SCCellDetailTableViewModelAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath);

typedef void(^SCDetailModelCellAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath, SCTableViewModel *detailModel);
typedef BOOL(^SCConditionalDetailModelCellAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath, SCTableViewModel *detailModel);


/****************************************************************************************/
/*	class SCCellActions	*/
/****************************************************************************************/ 
/**	
 This class hosts a set of cell action blocks. Once an action is set to a desired code block, it will execute the block as soon as the action occurs.
 
 @see SCSectionActions, SCModelActions.
 */
@interface SCCellActions : NSObject

//////////////////////////////////////////////////////////////////////////////////////////
/// @name Actions
//////////////////////////////////////////////////////////////////////////////////////////

/** Action gets called before the cell gets automatically styled using the provided theme.
 
 This action is typically used to set a custom themeStyle for the cell that is defined in the model's theme file.
 
 Example:
 
    // Objective-C
    cellActions.willStyle = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        cell.themeStyle = @"MyCustomStyle";
    };
 
    // Swift
    cellActions.willStyle =
    {
        (cell, indexPath) in
 
        cell.themeStyle = "MyCustomStyle"
    }
 
 @see SCTheme 
 */
@property (nonatomic, copy) SCCellAction_Block willStyle;

/** Action gets called before the cell is configured. 
 
 This action is typically used to set any attribute that will affect the cell's configuration and layout.
 
 Example:
 
    // Objective-C
    cellActions.willConfigure = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    };
 
    // Swift
    cellActions.willConfigure =
    {
        (cell, indexPath) in
 
        cell.selectionStyle = UITableViewCellSelectionStyleNone
    }
 */
@property (nonatomic, copy) SCCellAction_Block willConfigure;

/** Action gets called after the cell has laid out all its subviews.
 
 This action is typically used to change the subviews' layout.
 
 Example:
 
    // Objective-C
    cellActions.didLayoutSubviews = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        cell.textLabel.frame = CGRectMake(40, 20, 100, 40);
    };
 
    // Swift
    cellActions.didLayoutSubviews =
    {
        (cell, indexPath) in
 
        cell.textLabel.frame = CGRectMake(40, 20, 100, 40)
    }
 */
@property (nonatomic, copy) SCCellAction_Block didLayoutSubviews;

/** Action gets called before the cell is displayed.
 
 This action is typically used to set any attributes that will affect how the cell is displayed.
 
 Example:
 
    // Objective-C
    cellActions.willDisplay = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        cell.backgroundColor = [UIColor yellowColor];
    };
 
    // Swift
    cellActions.willDisplay =
    {
        (cell, indexPath) in
 
        cell.backgroundColor = UIColor.yellowColor()
    }
 
 @note Changing cell properties that influence its layout (such as the cell's height) cannot be set here, and must be set in the willConfigure action instead.
 */
@property (nonatomic, copy) SCCellAction_Block willDisplay;

/** Action gets called after the cell has been displayed and the table view has stopped scrolling.
 
 This action is typically used to load any cell content that is too expensive to load in willDisplay, such as retrieving data from a web service. This guarantees smooth and uninterrupted scrolling of the table view.
 
 Example:
 
    // Objective-C
    cellActions.lazyLoad = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        cell.imageView.image = [self retrieveImageForRowAtIndexPath:indexPath];
    };
 
    // Swift
    cellActions.lazyLoad =
    {
        (cell, indexPath) in
 
        cell.imageView.image = self.retrieveImageForRowAtIndexPath(indexPath)
    }
 */
@property (nonatomic, copy) SCCellAction_Block lazyLoad;

/** Action gets called when the cell is about to be selected.
 
 @return Return FALSE to prevent selection, otherwise return TRUE.
 
 Example:
 
    // Objective-C
    cellActions.willSelect = ^BOOL(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        NSLog(@"Cell at indexPath:%@ is about to be selected.", indexPath);
 
        return TRUE;
    };
 
    // Swift
    cellActions.willSelect =
    {
        (cell, indexPath)->Bool in
 
        NSLog("Cell at indexPath:%@ is about to be selected.", indexPath)
 
        return true
    }
 */
@property (nonatomic, copy) SCBOOLReturnCellAction_Block willSelect;

/** Action gets called when the cell has been selected.
 
 Example:
 
    // Objective-C
    cellActions.didSelect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        NSLog(@"Cell at indexPath:%@ has been selected.", indexPath);
    };
 
    // Swift
    cellActions.didSelect =
    {
        (cell, indexPath) in
 
        NSLog("Cell at indexPath:%@ has been selected.", indexPath)
    }
 */
@property (nonatomic, copy) SCCellAction_Block didSelect;

/** Action gets called when the cell is about to be deselected.
 
 @return Return FALSE to prevent deselection, otherwise return TRUE.
 
 Example:
 
    // Objective-C
    cellActions.willDeselect = ^BOOL(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        NSLog(@"Cell at indexPath:%@ is about to be deselected.", indexPath);
 
        return TRUE;
    };
 
    // Swift
    cellActions.willDeselect =
    {
        (cell, indexPath)->Bool in
 
        NSLog("Cell at indexPath:%@ is about to be deselected.", indexPath)
 
        return true
    }
 */
@property (nonatomic, copy) SCBOOLReturnCellAction_Block willDeselect;

/** Action gets called when the cell has been deselected.
 
 Example:
 
    // Objective-C
    cellActions.didDeselect = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        NSLog(@"Cell at indexPath:%@ has been selected.", indexPath);
    };
 
    // Swift
    cellActions.didDeselect =
    {
        (cell, indexPath) in
 
        NSLog("Cell at indexPath:%@ has been selected.", indexPath)
    }
 */
@property (nonatomic, copy) SCCellAction_Block didDeselect;

/** Action gives you the opportunity to provide your own custom cell editing style.
 
 @return Return a valid UITableViewCellEditingStyle value.
 
 Example:
 
    // Objective-C
    cellActions.customEditingStyle = ^UITableViewCellEditingStyle(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        // Prevent swipe-to-delete when not in editing mode.
 
        if(cell.ownerTableViewModel.tableView.editing)
            return UITableViewCellEditingStyleDelete;
        //else
        return UITableViewCellEditingStyleNone;
    };
 
    // Swift
    cellActions.customEditingStyle =
    {
        (cell, indexPath)->UITableViewCellEditingStyle in
        
        // Prevent swipe-to-delete when not in editing mode.
 
        if(cell.ownerTableViewModel.tableView.editing)
        {
            return UITableViewCellEditingStyleDelete;
        }
        //else
        return UITableViewCellEditingStyleNone;
    }
 */
@property (nonatomic, copy) SCCellCustomEditingStyleAction_Block customEditingStyle;

/** Action gets called to provide custom edit action buttons that appear when the user swipes the cell horizontally.
 
 Use this action when you want to provide custom edit actions for your cell. When the user swipes horizontally, the table view moves the cell content aside to reveal your actions. Tapping one of the action buttons executes the handler block stored with the action object.
 
 @return An array of UITableViewRowAction objects representing the actions for the cell. Each action you provide is used to create a button that the user can tap.
 
 @warning Only available in iOS 8 and later.
 
 Example:
 
    // Objective-C
    cellActions.editActions = ^NSArray*(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        UITableViewRowAction *customButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Button" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
        {
            NSLog(@"Custom edit action button tapped!");
            
            [cell.ownerTableViewModel.tableView setEditing:NO]; // collapse the cell back after completing custom edit action
        }];
        customButton.backgroundColor = [UIColor greenColor]; //arbitrary color
 
        UITableViewRowAction *deleteButton = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Delete" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
        {
            if([cell.ownerSection isKindOfClass:[SCArrayOfItemsSection class]])
                [(SCArrayOfItemsSection *)cell.ownerSection dispatchEventRemoveRowAtIndexPath:indexPath];  // delete the cell
        }];
        deleteButton.backgroundColor = [UIColor redColor];
        
        return @[deleteButton, customButton];
    };
 
    // Swift
    self.tableViewModel.cellActions.editActions =
    {
        (cell, indexPath)->[AnyObject] in
            
        let customButton = UITableViewRowAction(style: .Default, title: "Button", handler:
        {
            (action, indexPath)->Void in
            
            NSLog("Custom edit action button tapped!")
            
            cell.ownerTableViewModel.tableView.editing = false  // collapse the cell back after completing custom edit action
        })
        customButton.backgroundColor = UIColor.greenColor() //arbitrary color
        
        let deleteButton = UITableViewRowAction(style: .Default, title: "Delete", handler:
        {
            (action, indexPath)->Void in
                
            if let itemsSection = cell.ownerSection as? SCArrayOfItemsSection
            {
                itemsSection.dispatchEventRemoveRowAtIndexPath(indexPath)  // delete the cell
            }
        })
            
        return [deleteButton, customButton]
    }
 */
@property (nonatomic, copy) SCCellEditActionsAction_Block editActions;


/** Action gets called when the cell (or more typically one of the cell's controls) becomes the first responder.
 
 Example:
 
    // Objective-C
    cellActions.didBecomeFirstResponder = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        NSLog(@"Cell at indexPath:%@ has become the first responder.", indexPath);
    };
 
    // Swift
    cellActions.didBecomeFirstResponder =
    {
        (cell, indexPath) in
 
        NSLog("Cell at indexPath:%@ has become the first responder.", indexPath)
    }
 */
@property (nonatomic, copy) SCCellAction_Block didBecomeFirstResponder;

/** Action gets called when the cell (or more typically one of the cell's controls) resigns the first responder.
 
 Example:
 
    // Objective-C
    cellActions.didResignFirstResponder = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        NSLog(@"Cell at indexPath:%@ has resigned the first responder.", indexPath);
    };
 
    // Swift
    cellActions.didResignFirstResponder =
    {
        (cell, indexPath) in
 
        NSLog("Cell at indexPath:%@ has resigned the first responder.", indexPath)
    }
 */
@property (nonatomic, copy) SCCellAction_Block didResignFirstResponder;

/** Action gets called when the cell's accessory button has been tapped.
 
 Example:
 
    // Objective-C
    cellActions.accessoryButtonTapped = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        NSLog(@"Cell at indexPath:%@ accessory button has been tapped.", indexPath);
    };
 
    // Swift
    cellActions.accessoryButtonTapped =
    {
        (cell, indexPath) in
 
        NSLog("Cell at indexPath:%@ accessory button has been tapped.", indexPath)
    }
 
 @note For this action to get called, you must first have the cell's accessory button appear by setting its accessoryType property to UITableViewCellAccessoryDetailDisclosureButton.
 */
@property (nonatomic, copy) SCCellAction_Block accessoryButtonTapped;

/** Action gets called when the cell keyboard's return button has been tapped.
 
 This action is typically used to override STV's behavior when the return button is tapped, and define a custom one.
 
 Example:
 
    // Objective-C
    cellActions.returnButtonTapped = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        [self doMyCustomAction];
        [cell.ownerTableViewModel moveToNextCellControl:YES];
    };
 
    // Swift
    cellActions.returnButtonTapped =
    {
        (cell, indexPath) in
 
        self.doMyCustomAction()
        cell.ownerTableViewModel.moveToNextCellControl(YES)
    }
 
 @note Action is only applicable to cells with controls that display a keyboard.
 */
@property (nonatomic, copy) SCCellAction_Block returnButtonTapped;

/** Action gets called when the cell's bound property value has changed via a cell control or a detail model.
 
 This action is typically used to provide a custom behavior when the cell's value changes.
 
 Example:
 
    // Objective-C
    cellActions.valueChanged = ^(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        NSLog(@"Cell at indexPath:%@ value has changed to: %@.", indexPath, cell.boundValue);
    };
 
    // Swift
    cellActions.valueChanged =
    {
        (cell, indexPath) in
 
        NSLog("Cell at indexPath:%@ value has changed to: %@.", indexPath, cell.boundValue)
    }
 */
@property (nonatomic, copy) SCCellAction_Block valueChanged;

/** Action gets called when the cell's value needs to be validated.
 
 This action is typically used to provide a custom cell value validation.
 
 @return Return YES if the current cell value is valid, otherwise return NO.
 
 Example:
 
    // Objective-C
    cellActions.valueIsValid = ^BOOL(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        BOOL valid = NO;
 
        if([cell isKindOfClass:[SCTextFieldCell class]])
        {
            SCTextFieldCell *textFieldCell = (SCTextFieldCell *)cell;
 
            // Make sure the password field is at least 8 characters long
            if([textFieldCell.textField.text length] >= 8)
                valid = YES;
        }
 
        return valid;
    };
 
    // Swift
    cellActions.valueIsValid =
    {
        (cell, indexPath)->Bool in
        
        var valid = false
        
        if let textFieldCell = cell as? SCTextFieldCell
        {
            // Make sure the password field is at least 8 characters long
            if countElements(textFieldCell.textField.text) >= 8
            {
                valid = true
            }
        }
        
        return valid
    }
 */
@property (nonatomic, copy) SCBOOLReturnCellAction_Block valueIsValid;

/** Action is used to provide a value for calculated cells.
 
 Cells implementing this action are typically calculated cells that do not have their own values in the data store and depend on this action to provide a value. The return value is typically a mathematical operation on serveral other boundObject properties. For a more elaborate example on calculated cells, please refer to the CalculatedCellsApp bundled sample application.
 
 Example:
 
    // Objective-C
    cellActions.calculatedValue = ^NSObject*(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        NSNumber *speed = [cell.boundObject valueForKey:@"speed"];
        NSNumber *distance = [cell.boundObject valueForKey:@"distance"];
        CGFloat time = 0;
        if([speed floatValue])
            time = [distance floatValue]/[speed floatValue];
 
        return [NSNumber numberWithFloat:time];
    };
 
    // Swift
    cellActions.calculatedValue =
    {
        (cell, indexPath)->NSObject in
 
        let speed = cell.boundObject.valueForKey("speed") as! NSNumber
        let distance = cell.boundObject.valueForKey("distance") as! NSNumber
        var time = 0.0f
        if(speed.floatValue != 0)
            time = distance.floatValue()/speed.floatValue()
        
        return NSNumber.numberWithFloat(time)
    }
 */
@property (nonatomic, copy) SCCellCalculatedValueAction_Block calculatedValue;

/** Action gets called whenever a cell's bound value has been loaded.
 
 This action is typically used to do any customization to the loaded bound value.
 
 Example:
 
    // Objective-C
    cellActions.didLoadBoundValue = ^NSObject*(SCTableViewCell *cell, NSIndexPath *indexPath, NSObject *value)
    {
        // Make sure all string spaces are trimmed before displaying string.
 
        NSString *stringValue = (NSStirng *)value;
        NSString *trimmedString = [stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
 
        return trimmedString;
    };
 
    // Swift
    cellActions.didLoadBoundValue =
    {
        (cell, indexPath, value)->NSObject in
 
        // Make sure all string spaces are trimmed before displaying string.
        var trimmedString = ""
        if let stringValue = value as? String
        {
            trimmedString = stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
        
        return trimmedString
    }
 */
@property (nonatomic, copy) SCCellBoundValueAction_Block didLoadBoundValue;

/** Action gets called before a cell's bound value is committed to its bound object.
 
 This action is typically used to do any customization to the bound value before being committed.
 
 Example:
 
    // Objective-C
    cellActions.willCommitBoundValue = ^NSObject*(SCTableViewCell *cell, NSIndexPath *indexPath, NSObject *value)
    {
        // Make sure all string spaces are trimmed before committing the string.
 
        NSString *stringValue = (NSStirng *)value;
        NSString *trimmedString = [stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
 
        return trimmedString;
    };
 
    // Swift
    cellActions.willCommitBoundValue =
    {
        (cell, indexPath, value)->NSObject in
 
        // Make sure all string spaces are trimmed before committing the string.
        var trimmedString = ""
        if let stringValue = value as? String
        {
            trimmedString = stringValue.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        }
        
        return trimmedString
    }
 */
@property (nonatomic, copy) SCCellBoundValueAction_Block willCommitBoundValue;

/** Action gets called whenever a cell's user defined custom button is tapped.
 
 This action is typically used to easily provide a custom behavior for the cell's custom button(s).
 
 Example:
 
    // Objective-C
    cellActions.customButtonTapped = ^(SCTableViewCell *cell, NSIndexPath *indexPath, UIButton *button)
    {
        NSLog(@"Custom button with tag:%i has been tapped for cell at indexPath:%@.", button.tag, indexPath);
    };
 
    // Swift
    cellActions.customButtonTapped =
    {
        (cell, indexPath, button) in
 
        NSLog("Custom button with tag:%i has been tapped for cell at indexPath:%@.", button.tag, indexPath)
    }
 */
@property (nonatomic, copy) SCCellCustomButtonTappedAction_Block customButtonTapped;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Copying and Pasting
//////////////////////////////////////////////////////////////////////////////////////////

/** Action gets called to ask if the editing menu should be shown for the cell.
 
 @return Return TRUE to show editing menu, otherwise return FALSE.
 
 Example:
 
    // Objective-C
    cellActions.shouldShowMenu = ^BOOL(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        return TRUE;
    };
 
    // Swift
    cellActions.shouldShowMenu =
    {
        (cell, indexPath)->Bool in
 
        return true
    }
 */
@property (nonatomic, copy) SCBOOLReturnCellAction_Block shouldShowMenu;


/** Action gets called to ask if the editing menu should omit the Copy or Paste command for the cell.
 
 @action A selector type identifying the copy: or paste: method of the UIResponderStandardEditActions informal protocol.
 @sender The object that initially sent the copy: or paste: message.
 @return Return TRUE if the command corresponding to action should appear in the editing menu, otherwise return FALSE.
 
 Example:
 
    // Objective-C
    cellActions.canPerformAction = ^BOOL(SCTableViewCell *cell, NSIndexPath *indexPath, SEL action, id sender)
    {
        return (action == @selector(copy:);  // only allow 'Copy'
    };
 
    // Swift
    cellActions.canPerformAction =
    {
        (cell, indexPath, action, sender)->Bool in
 
        return true   // allow all actions
    }
 */
@property (nonatomic, copy) SCCellCanPerformAction_Block canPerformAction;


/** Action gets called to perform a copy or paste operation on the content of the cell.
 
 @action A selector type identifying the copy: or paste: method of the UIResponderStandardEditActions informal protocol.
 @sender The object that initially sent the copy: or paste: message.
 
 Example:
 
    // Objective-C
    cellActions.performAction = ^(SCTableViewCell *cell, NSIndexPath *indexPath, SEL action, id sender)
    {
        // perform operation here
    };
 
    // Swift
    cellActions.performAction =
    {
        (cell, indexPath, action, sender) in
 
        // perform operation here
    }
 */
@property (nonatomic, copy) SCCellPerformAction_Block performAction;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Detail Model Actions
//////////////////////////////////////////////////////////////////////////////////////////


/** Action gets called to give you the chance to return a custom detail view controller for the cell.
 
 This action is typically used to provide your own custom detail view controller, instead of the one automatically generated by the cell.
 
 @return The custom view controller. *Must only be of type SCViewController or SCTableViewController*. Note: returning nil ignores the implementation of this action.
 
 Example:
 
    // Objective-C
    cellActions.detailViewController = ^UIViewController*(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        MyCustomViewController *customVC = [[MyCustomViewController alloc] initWithNib:@"MyCustomViewController" bundle:nil];
        
        return customVC;
    };
 
    // Swift
    cellActions.detailViewController =
    {
        (cell, indexPath)->UIViewController in
 
        let customVC = MyCustomViewController(nibName: "MyCustomViewController", bundle: nil)
 
        return customVC
    }
 
 @note This action is only applicable to cells that generate detail views, such as SCSelectionCell and SCArrayOfObjectsCell.
 */
@property (nonatomic, copy) SCCellDetailViewControllerAction_Block detailViewController;

/** Action gets called to give you the chance to return a custom detail model for the cell's detail view controller.
 
 This action is typically used to provide your own custom detail model, instead of the one automatically generated by the cell. This might be needed in cases where the cell generates a detail SCArrayOfObjectsSection for example, and you need an SCArrayOfObjectsModel instead (to automatically generate sections for instance).
 
 @note It is much more common to use the detailViewController action instead, assigning the custom model in the custom view controller's viewDidLoad method. This also gives you the chance to add a search bar (for example, to make use of SCArrayOfObjectsModel automatic searching functionality), or any other controls.
 
 @return The custom detail model. The returned detail model should not be associated with any table views, as the framework will automatically handle this on your behalf. Note: returning nil ignores the implementation of this action.
 
 Example:
 
    // Objective-C
    cellActions.detailTableViewModel = ^SCTableViewModel*(SCTableViewCell *cell, NSIndexPath *indexPath)
    {
        SCTableViewModel *detailModel = nil;
        if([cell isKindOfClass:[SCArrayOfObjectsCell class]])
        {
            detailModel = [SCArrayOfObjectsModel modelWithTableView:nil];
        }
 
        return detailModel;
    };
 
    // Swift
    cellActions.detailTableViewModel =
    {
        (cell, indexPath)->SCTableViewModel in
 
        if let arrayOfObjectsCell = cell as? SCArrayOfObjectsCell
        {
            return SCArrayOfObjectsModel(tableView: nil)
        }
        // else
        return nil
    }
 
 @note This action is only applicable to cells that generate detail views, such as SCSelectionCell and SCArrayOfObjectsCell.
 */
@property (nonatomic, copy) SCCellDetailTableViewModelAction_Block detailTableViewModel;


/** Action gets called right after the cell's detail model is created, before configuration is set or any sections are added.
 
 This action is typically used to initially configure the detail model (like set a custom tag for example). Most of the model's settings can also be configure in the detailModelConfigured action.
 
 Example:
 
    // Objective-C
    cellActions.detailModelCreated = ^(SCTableViewCell *cell, NSIndexPath *indexPath, SCTableViewModel *detailModel)
    {
        detailModel.tag = 100;
    };
 
    // Swift
    cellActions.detailModelCreated =
    {
        (cell, indexPath, detailModel) in
 
        detailModel.tag = 100
    }
 
 @note This action is only applicable to cells that generate detail views, such as SCSelectionCell.
 
 @see detailModelConfigured
 */
@property (nonatomic, copy) SCDetailModelCellAction_Block detailModelCreated;

/** Action gets called after the cell's detail model is fully configured, including the addition of all automatically generated sections.
 
 This action is typically used to add additional custom sections, or modify the already existing automatically generated ones.
 
 Example:
 
    // Objective-C
    cellActions.detailModelConfigured = ^(SCTableViewCell *cell, NSIndexPath *indexPath, SCTableViewModel *detailModel)
    {
        SCTableViewSection *customSection = [SCTableViewSection section];
        SCCustomCell *customCell = [SCCustomCell cellWithText:@"Custom Cell"];
        [customSection addCell:customCell];
 
        [detailModel addSection:customSection];
    };
 
    // Swift
    cellActions.detailModelConfigured =
    {
        (cell, indexPath, detailModel) in
 
        let customSection = SCTableViewSection()
        let customCell = SCCustomCell(text: "Custom Cell")
        customSection.addCell(customCell)
 
        detailModel.addSection(customSection)
    }
 
 @note In general, it is easier (and more recommended) to add your custom sections and cells using the data definitions, instead of using this action to do so. For more information, please refer to SCDataDefinition and SCCustomPropertyDefinition.
 
 @note This action is only applicable to cells that generate detail views, such as SCSelectionCell.
 
 */
@property (nonatomic, copy) SCDetailModelCellAction_Block detailModelConfigured;

/** Action gets called when the cell's detail model is about to be presented in its own view controller.
 
 This action is typically used to further customize the detail model's view controller.
 
 Example:
 
    // Objective-C
    cellActions.detailModelWillPresent = ^(SCTableViewCell *cell, NSIndexPath *indexPath, SCTableViewModel *detailModel)
    {
        detailModel.viewController.title = @"My custom title";
    };
 
    // Swift
    cellActions.detailModelWillPresent =
    {
        (cell, indexPath, detailModel) in
 
        detailModel.viewController.title = "My custom title"
    }
 
 @note This action is only applicable to cells that generate detail views, such as SCSelectionCell.
 
 */
@property (nonatomic, copy) SCDetailModelCellAction_Block detailModelWillPresent;

/** Action gets called when the cell's detail model has been presented in its own view controller.
 
 Example:
 
    // Objective-C
    cellActions.detailModelDidPresent = ^(SCTableViewCell *cell, NSIndexPath *indexPath, SCTableViewModel *detailModel)
    {
        NSLog(@"Detail model has been presented.");
    };
 
    // Swift
    cellActions.detailModelDidPresent =
    {
        (cell, indexPath, detailModel) in
 
        NSLog("Detail model has been presented.")
    }
 
 @note This action is only applicable to cells that generate detail views, such as SCSelectionCell.

 */
@property (nonatomic, copy) SCDetailModelCellAction_Block detailModelDidPresent;

/** Action gets called to give you a chance to decide if the detail model should be dismissed. Return YES to allow the detail model to be dismissed, otherwise return NO.
 
 Example:
 
    // Objective-C
    cellActions.detailModelShouldDismiss = ^BOOL(SCTableViewCell *cell, NSIndexPath *indexPath, SCTableViewModel *detailModel)
    {
        return YES;  // allow detail model to be dismissed
    };
 
    // Swift
    cellActions.detailModelShouldDismiss =
    {
        (cell, indexPath, detailModel)->Bool in
 
        return true  // allow detail model to be dismissed
    }
 
 @note This action is only applicable to cells that generate detail views, such as SCSelectionCell.

 */
@property (nonatomic, copy) SCConditionalDetailModelCellAction_Block detailModelShouldDismiss;

/** Action gets called when the cell's detail model's view controller is about to be dismissed.
 
 Example:
 
    // Objective-C
    cellActions.detailModelWillDismiss = ^(SCTableViewCell *cell, NSIndexPath *indexPath, SCTableViewModel *detailModel)
    {
        NSLog(@"Detail model will be dismissed.");
    };
 
    // Swift
    cellActions.detailModelWillDismiss =
    {
        (cell, indexPath, detailModel) in
 
        NSLog("Detail model will be dismissed.")
    }
 
 @note This action is only applicable to cells that generate detail views, such as SCSelectionCell.
 
 */
@property (nonatomic, copy) SCDetailModelCellAction_Block detailModelWillDismiss;

/** Action gets called when the cell's detail model's view controller has been dismissed.
 
 Example:
 
    // Objective-C
    cellActions.detailModelDidDismiss = ^(SCTableViewCell *cell, NSIndexPath *indexPath, SCTableViewModel *detailModel)
    {
        NSLog(@"Detail model has been dismissed.");
    };
 
    // Swift
    cellActions.detailModelDidDismiss =
    {
        (cell, indexPath, detailModel) in
 
        NSLog("Detail model has been dismissed.")
    }
 
 @note This action is only applicable to cells that generate detail views, such as SCSelectionCell.
 
 */
@property (nonatomic, copy) SCDetailModelCellAction_Block detailModelDidDismiss;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Cell Text Field Related Actions
//////////////////////////////////////////////////////////////////////////////////////////

typedef BOOL(^SCTextFieldShouldChangeCharactersInRangeAction_Block)(SCTableViewCell *cell, NSIndexPath *indexPath, UITextField *textField, NSRange range, NSString *replacementString);

/** Implement action to control whether the specified text field's text should change.
 
 Example:
 
    // Objective-C
    cellActions.shouldChangeCharactersInRange = ^BOOL(SCTableViewCell *cell, NSIndexPath *indexPath, UITextField *textField, NSRange range, NSString *replacementString)
    {
        NSLog(@"shouldChangeCharactersInRange called with replacement string: %@", replacementString);
        
        return YES;
    };
 
    // Swift
    cellActions.shouldChangeCharactersInRange = 
    {
        (cell, indexPath, textField, range, replacementString)->Bool in
 
        NSLog("shouldChangeCharactersInRange called with replacement string: %@", replacementString)
 
        return true
    }
 
 */
@property (nonatomic, copy) SCTextFieldShouldChangeCharactersInRangeAction_Block shouldChangeCharactersInRange;

//////////////////////////////////////////////////////////////////////////////////////////
/// @name SCImagePickerCell Specific Actions
//////////////////////////////////////////////////////////////////////////////////////////

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
typedef void(^SCImagePickerDidFinishPickingMediaAction_Block)(SCImagePickerCell *imagePickerCell, NSIndexPath *indexPath, NSDictionary *mediaInfo, ALAsset *mediaAsset);
#pragma clang diagnostic pop
typedef NSString*(^SCImagePickerImageNameAction_Block)(SCImagePickerCell *imagePickerCell, NSIndexPath *indexPath);
typedef void(^SCImagePickerSaveImageAction_Block)(SCImagePickerCell *imagePickerCell, NSIndexPath *indexPath, NSString *imagePath);
typedef UIImage*(^SCImagePickerLoadImageAction_Block)(SCImagePickerCell *imagePickerCell, NSIndexPath *indexPath, NSString *imagePath);

/** Implement action to get notified when media is selected by SCImagePickerCell.
 
 Example:
 
    // Objective-C
    cellActions.didFinishPickingMedia = ^(SCImagePickerCell *imagePickerCell, NSIndexPath *indexPath, NSDictionary *mediaInfo, ALAsset *mediaAsset)
    {
        // Determine selected media date
        NSDate *date = [mediaAsset valueForProperty:ALAssetPropertyDate];
        NSLog(@"Selected media date: %@", date);
    };
 
    // Swift
    cellActions.didFinishPickingMedia =
    {
        (imagePickerCell, indexPath, mediaInfo, mediaAsset) in
 
        // Determine selected media date
        let date = mediaAsset.valueForProperty(ALAssetPropertyDate)
        NSLog("Selected media date: %@", date)
    }
 
 */
@property (nonatomic, copy) SCImagePickerDidFinishPickingMediaAction_Block didFinishPickingMedia;

/** Implement action to provide your own custom image name of the SCImagePickerCell image.
 
 Example:
 
    // Objective-C
    cellActions.imageName = ^NSString*(SCImagePickerCell *imagePickerCell, NSIndexPath *indexPath)
    {
        return @"My Custom Image Name";
    };
 
    // Swift
    cellActions.imageName =
    {
        (imagePickerCell, indexPath)->String in
 
        return "My Custom Image Name"
    }
 
 */
@property (nonatomic, copy) SCImagePickerImageNameAction_Block imageName;

/** Implement action to provide your own custom code for saving the SCImagePickerCell image to imagePath.
 
 Example:
 
    // Objective-C
    cellActions.saveImage = ^(SCImagePickerCell *imagePickerCell, NSIndexPath *indexPath, NSString *imagePath)
    {
        [UIImageJPEGRepresentation(imagePickerCell.selectedImage, 80) writeToFile:imagePath atomically:YES];
    };
 
    // Swift
    cellActions.saveImage =
    {
        (imagePickerCell, indexPath, imagePath) in
 
        UIImageJPEGRepresentation(imagePickerCell.selectedImage, 80).writeToFile(imagePath, atomically: true)
    }
 
 */
@property (nonatomic, copy) SCImagePickerSaveImageAction_Block saveImage;

/** Implement action to provide your own custom code for loading the SCImagePickerCell image from imagePath.
 
 Example:
 
    // Objective-C
    cellActions.loadImage = ^UIImage*(SCImagePickerCell *imagePickerCell, NSIndexPath *indexPath, NSString *imagePath)
    {
        return [UIImage imageWithContentsOfFile:imagePath];
    };
 
    // Swift
    cellActions.loadImage =
    {
        (imagePickerCell, indexPath, imagePath)->UIImage in
 
        return UIImage(contentsOfFile: imagePath)
    }
 
 */
@property (nonatomic, copy) SCImagePickerLoadImageAction_Block loadImage;



//////////////////////////////////////////////////////////////////////////////////////////
/// @name Miscellaneous
//////////////////////////////////////////////////////////////////////////////////////////

/** Method assigns all the actions of another 'SCCellActions' class to the current one.
 
 @param actions The source 'SCCellActions' class.
 @param override Set to TRUE to override any existing actions, otherwise set to FALSE.
 */
- (void)setActionsTo:(SCCellActions *)actions overrideExisting:(BOOL)override;

@end
