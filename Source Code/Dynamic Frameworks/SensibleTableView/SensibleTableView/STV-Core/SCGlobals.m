/*
 *  SCGlobals.m
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

#import "SCGlobals.h"
#import "SCTableViewModel.h"

#import <objc/runtime.h>
#import <unistd.h>
#import <netdb.h>


#ifndef ARC_ENABLED

#error STV must be compiled with ARC enabled. If your project doesn't use ARC, either use STV's static framework library, or set the '-fno-objc-arc' flag for all STV files in your project's target build phases (under Compile Source).

#endif






@implementation NSObject (SensibleCocoa)

- (instancetype)valueForSensibleKeyPath:(NSString *)keyPath
{
    if(!keyPath)
        return nil;
    
    NSRange bRange = [keyPath rangeOfString:@"["];
    
    // Return valueForKeyPath if string has no index brackets
    if(bRange.location == NSNotFound)
        return [self valueForKeyPath:keyPath];
    
    id currentObject = self;
    
    NSArray *keys = [keyPath componentsSeparatedByString:@"."];
    for(NSString *key in keys)
    {
        NSRange lbRange = [key rangeOfString:@"["];
        if(lbRange.location == NSNotFound)
        {
            currentObject = [currentObject valueForKey:key];
        }
        else
        {
            NSRange rbRange = [key rangeOfString:@"]"];
            if(rbRange.location==NSNotFound || rbRange.location<lbRange.location)
            {
                SCDebugLog(@"Error: Invalid syntax in key:'%@'", key);
                return nil;
            }
            
            NSRange arrayKeyRange;
            arrayKeyRange.location = 0;
            arrayKeyRange.length = lbRange.location;
            NSString *arrayKey = [key substringWithRange:arrayKeyRange];
            NSArray *array = [currentObject valueForKey:arrayKey];
            if(![array respondsToSelector:@selector(objectAtIndex:)])
            {
                SCDebugLog(@"Error: Accessing a non-array object in key:'%@'", key);
                return nil;
            }
            if(!array.count)
            {
                SCDebugLog(@"Error: Accessing an empty array in key:'%@'", key);
                return nil;
            }
            
            NSRange bracketRange;
            bracketRange.location = lbRange.location+1;
            bracketRange.length = rbRange.location - lbRange.location - 1;
            NSString *bracketString = [key substringWithRange:bracketRange];
            bracketString = [bracketString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            NSInteger bracketValue;
            
            // check if the bracket string has the 'n' variable
            NSRange nRange = [bracketString rangeOfString:@"n"];
            if(nRange.location == NSNotFound)
            {
                bracketValue = [bracketString integerValue];
            }
            else
            {
                // determine if there is a number subtracted from n
                NSUInteger nSubtract = 0;
                NSRange minusRange = [bracketString rangeOfString:@"-"];
                if(minusRange.location!=NSNotFound && minusRange.location>nRange.location)
                {
                    NSString *nSubtractString = [bracketString substringFromIndex:minusRange.location+1];
                    nSubtract = [nSubtractString integerValue];
                }
                
                bracketValue = array.count-1 - nSubtract;
            }
            
            if(bracketValue<0 || bracketValue>=array.count)
            {
                SCDebugLog(@"Error: Index out of bounds for array in key:'%@'", key);
                return nil;
            }
            
            currentObject = [array objectAtIndex:bracketValue];
        }
        
        if(!currentObject)
            break;
    }
    
    return currentObject;
}

- (void)setValue:(id)value forSensibleKeyPath:(NSString *)keyPath
{
    if(!keyPath)
        return;
    
    NSRange bRange = [keyPath rangeOfString:@"["];
    
    // Return valueForKeyPath if string has no index brackets
    if(bRange.location == NSNotFound)
    {
        [self setValue:value forKeyPath:keyPath];
        return;
    }
    
    id currentObject = self;
    
    NSArray *keys = [keyPath componentsSeparatedByString:@"."];
    for(NSUInteger i=0; i<keys.count-1; i++) // exclude last key
    {
        NSString *key = [keys objectAtIndex:i];
        
        NSRange lbRange = [key rangeOfString:@"["];
        if(lbRange.location == NSNotFound)
        {
            currentObject = [currentObject valueForKey:key];
        }
        else
        {
            NSRange rbRange = [key rangeOfString:@"]"];
            if(rbRange.location==NSNotFound || rbRange.location<lbRange.location)
            {
                SCDebugLog(@"Error: Invalid syntax in key:'%@'", key);
                return;
            }
            
            NSRange arrayKeyRange;
            arrayKeyRange.location = 0;
            arrayKeyRange.length = lbRange.location;
            NSString *arrayKey = [key substringWithRange:arrayKeyRange];
            NSArray *array = [currentObject valueForKey:arrayKey];
            if(![array respondsToSelector:@selector(objectAtIndex:)])
            {
                SCDebugLog(@"Error: Accessing a non-array object in key:'%@'", key);
                return;
            }
            if(!array.count)
            {
                SCDebugLog(@"Error: Accessing an empty array in key:'%@'", key);
                return;
            }
            
            NSRange bracketRange;
            bracketRange.location = lbRange.location+1;
            bracketRange.length = rbRange.location - lbRange.location - 1;
            NSString *bracketString = [key substringWithRange:bracketRange];
            bracketString = [bracketString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            NSInteger bracketValue;
            
            // check if the bracket string has the 'n' variable
            NSRange nRange = [bracketString rangeOfString:@"n"];
            if(nRange.location == NSNotFound)
            {
                bracketValue = [bracketString integerValue];
            }
            else
            {
                // determine if there is a number subtracted from n
                NSUInteger nSubtract = 0;
                NSRange minusRange = [bracketString rangeOfString:@"-"];
                if(minusRange.location!=NSNotFound && minusRange.location>nRange.location)
                {
                    NSString *nSubtractString = [bracketString substringFromIndex:minusRange.location+1];
                    nSubtract = [nSubtractString integerValue];
                }
                
                bracketValue = array.count-1 - nSubtract;
            }
            
            if(bracketValue<0 || bracketValue>=array.count)
            {
                SCDebugLog(@"Error: Index out of bounds for array in key:'%@'", key);
                return;
            }
            
            currentObject = [array objectAtIndex:bracketValue];
        }
        
        if(!currentObject)
            break;
    }
    
    NSString *lastKey = [keys lastObject];
    [currentObject setValue:value forKey:lastKey];
}

@end






@implementation UILabel (SensibleCocoa)

@dynamic prefix, suffix;

- (NSString *)prefix
{
    NSString *prefix = objc_getAssociatedObject(self, @selector(prefix));
    if(!prefix)
        prefix = @"";
    
    return prefix;
}

- (void)setPrefix:(NSString *)prefix
{
    objc_setAssociatedObject(self, @selector(prefix), prefix, OBJC_ASSOCIATION_COPY);
}

- (NSString *)suffix
{
    NSString *suffix = objc_getAssociatedObject(self, @selector(suffix));
    if(!suffix)
        suffix = @"";
    
    return suffix;
}

- (void)setSuffix:(NSString *)suffix
{
    objc_setAssociatedObject(self, @selector(suffix), suffix, OBJC_ASSOCIATION_COPY);
}

@end




@implementation UINavigationController(KeyboardDismiss)

- (BOOL)disablesAutomaticKeyboardDismissal
{
    return NO;
}

@end




@implementation SCUtilities

+ (double)systemVersion
{
    return [[[UIDevice currentDevice] systemVersion] doubleValue];
}

+ (BOOL)is_iPad
{
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
}

+ (BOOL)isViewInsidePopover:(UIView *)view
{
	BOOL inPopover = FALSE;
	while (view.superview)
	{
		NSString *sviewClassName = NSStringFromClass([view.superview class]);
        if([sviewClassName rangeOfString:@"UIPopoverView"].location != NSNotFound)
		{
			inPopover = TRUE;
			break;
		}
		view = view.superview;
	}
	
	return inPopover;
}

+ (BOOL)IsInternetConnectionAvailable
{
    char *hostname;
    struct hostent *hostinfo;
    hostname = "google.com";
    hostinfo = gethostbyname (hostname);
    if (hostinfo == NULL)
        return NO;
    //else
    return YES;
}

+ (BOOL)isURLValid:(NSString *)urlString
{
    BOOL valid = FALSE;
    
    NSURL *url = [NSURL URLWithString:urlString];
    if (url && url.scheme && url.host)
        valid = TRUE;
    
    return valid;
}

+ (NSObject *)getFirstNodeInNibWithName:(NSString *)nibName
{
    if(!nibName)
        return nil;
    
	NSArray *topLevelNodes = [[UINib nibWithNibName:nibName bundle:[NSBundle mainBundle]] instantiateWithOwner:nil options:nil];
    if([topLevelNodes count])
		return [topLevelNodes objectAtIndex:0];
	//else
	return nil;
}

+ (NSString *)getUserFriendlyTitleFromName:(NSString *)propertyName
{
	NSMutableString *UFName = [[NSMutableString alloc] init];
	
	if(![propertyName length])
		return UFName;
	
	// Capitalize & append the 1st character
    if([propertyName characterAtIndex:0] != '~')
        [UFName appendString:[[propertyName substringToIndex:1] uppercaseString]];
	
	// Leave a space for every capital letter
	NSCharacterSet *uppercaseSet = [NSCharacterSet uppercaseLetterCharacterSet];
	for(NSUInteger i=1; i<[propertyName length]; i++)
	{
		unichar chr = [propertyName characterAtIndex:i];
		if([uppercaseSet characterIsMember:chr])
			[UFName appendString:[NSString stringWithFormat:@" %c", chr]];
		else
			[UFName appendString:[NSString stringWithFormat:@"%c", chr]];
	}
	
	return UFName;
}

+ (Class)swiftCompatibleNSClassFromString:(NSString *)className
{
    Class _class = NSClassFromString(className);
    if(_class)
        return _class;
    
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *classStringName = [NSString stringWithFormat:@"_TtC%lu%@%lu%@", (unsigned long)appName.length, appName, (unsigned long)className.length, className];
    return NSClassFromString(classStringName);
}

+ (BOOL)isStringClass:(Class)aClass
{
    return [aClass respondsToSelector:@selector(availableStringEncodings)];
}

+ (BOOL)isNumberClass:(Class)aClass
{
    return [aClass respondsToSelector:@selector(numberWithUnsignedLongLong:)];
}

+ (BOOL)isDateClass:(Class)aClass
{
    return [aClass respondsToSelector:@selector(timeIntervalSinceReferenceDate)];
}

+ (BOOL)isDictionaryClass:(Class)aClass
{
    return [aClass respondsToSelector:@selector(dictionaryWithDictionary:)];
}

+ (BOOL)isBasicDataTypeClass:(Class)aClass
{
    if(
       [self isStringClass:aClass]  ||
       [self isNumberClass:aClass]  ||
       [self isDateClass:aClass])
    {
        return TRUE;
    }
    //else
    return FALSE;
}

+ (NSString *)dataStructureNameForClass:(Class)aClass
{
    if([self isStringClass:aClass])
        return @"NSString";
    //else
    if([self isNumberClass:aClass])
        return @"NSNumber";
    //else
    if([self isDateClass:aClass])
        return @"NSDate";
    //else
    if([self isDictionaryClass:aClass])
        return @"NSDictionary";
    //else
    return NSStringFromClass(aClass);
}

+ (BOOL)propertyName:(NSString *)propertyName existsInObject:(NSObject *)object
{
    if([self isBasicDataTypeClass:[object class]] || [self isDictionaryClass:[object class]])
        return TRUE;
    
    BOOL propertyExists;
    
	@try 
    { 
        if([object isKindOfClass:[NSUbiquitousKeyValueStore class]])
        {
            [(NSUbiquitousKeyValueStore *)object objectForKey:propertyName];
        }
        else
        {
            [object valueForSensibleKeyPath:propertyName];
        }
        propertyExists = TRUE; 
    }
	@catch (NSException *exception) 
    { 
        propertyExists = FALSE; 
        
        SCDebugLog(@"Warning: Property '%@' does not exist in object '%@'.", propertyName, object);   
    }
    
    return propertyExists;
}

+ (NSObject *)valueForPropertyName:(NSString *)propertyName inObject:(NSObject *)object
{
    if([self isBasicDataTypeClass:[object class]])
        return object;
    
	if(!propertyName)
		return nil;
	
	NSArray *propertyNames = [propertyName componentsSeparatedByString:@";"];
	NSMutableArray *valuesArray = [NSMutableArray arrayWithCapacity:propertyNames.count];
	for(NSString *pName in propertyNames)
	{
		NSObject *value = nil;
		@try 
		{
			if([object isKindOfClass:[NSUbiquitousKeyValueStore class]])
            {
                value = [(NSUbiquitousKeyValueStore *)object objectForKey:pName];
            }
            else
            {
                value = [object valueForSensibleKeyPath:pName];
            }
		}
		@catch (NSException * e) 
		{
			SCDebugLog(@"Warning: Property '%@' does not exist in object '%@'.", propertyName, NSStringFromClass([object class]));
		}
		if(!value)
			value = [NSNull null];
		[valuesArray addObject:value];
	}
	
	if(propertyNames.count > 1)
		return valuesArray;
	//else
	NSObject *value = [valuesArray objectAtIndex:0];
	if([value isKindOfClass:[NSNull class]])
		return nil;
	return value;
}

+ (NSString *)stringValueForPropertyName:(NSString *)propertyName inObject:(NSObject *)object
			separateValuesUsingDelimiter:(NSString *)delimiter
{
	if([self isBasicDataTypeClass:[object class]])
        return [NSString stringWithFormat:@"%@", object];
    
    NSObject *value = [SCUtilities valueForPropertyName:propertyName inObject:object];
	
	if(!value)
		return nil;
	
	NSMutableString *stringValue = [NSMutableString string];
	if([value isKindOfClass:[NSArray class]])
	{
		NSArray *stringsArray = (NSArray *)value;
		for(NSUInteger i=0; i<stringsArray.count; i++)
		{
			NSObject *str = [stringsArray objectAtIndex:i];
			if(![str isKindOfClass:[NSNull class]])
			{
				if(i!=0 && delimiter)
					[stringValue appendString:delimiter];
				[stringValue appendString:[NSString stringWithFormat:@"%@", str]];
			}
		}
	}
	else
	{
		if(value)
			[stringValue appendFormat:@"%@", value];
	}
	
	return stringValue;
}

+ (void)setValue:(NSObject *)value forPropertyName:(NSString *)propertyName inObject:(NSObject *)object
{
    if([self isBasicDataTypeClass:[object class]])
        return;
    
    if(![SCUtilities propertyName:propertyName existsInObject:object])
        return;
    
    if([object isKindOfClass:[NSUbiquitousKeyValueStore class]])
    {
        [(NSUbiquitousKeyValueStore *)object setObject:value forKey:propertyName];
    }
    else
    {
        if(value == nil)
        {
            // check if the property's data type is scalar since scalars don't support nil
            objc_property_t property = class_getProperty([object class], [propertyName UTF8String]);
            if(property)
            {
                NSArray *attributesArray = [[NSString stringWithUTF8String: property_getAttributes(property)] 
                                            componentsSeparatedByString:@","];
                NSSet *attributesSet = [NSSet setWithArray:attributesArray];
                if([attributesSet containsObject:@"Tc"] || [attributesSet containsObject:@"Ti"] || [attributesSet containsObject:@"Tf"] || [attributesSet containsObject:@"Td"])
                {
                    value = [NSNumber numberWithUnsignedShort:0];
                }
            }
        }
        [object setValue:value forKeyPath:propertyName];
    }
}

+ (NSObject *)getValueCompatibleWithDataType:(SCDataType)dataType fromValue:(NSObject *)value
{
    if(!value)
        return nil;
    
    NSObject *convertedValue = value;
    
    switch (dataType)
    {
        case SCDataTypeNSString:
            if(![SCUtilities isStringClass:[value class]])
            {
                convertedValue = [NSString stringWithFormat:@"%@", value];
            }
            break;
            
        case SCDataTypeNSNumber:
            if(![value isKindOfClass:[NSNumber class]])
            {
                if([SCUtilities isStringClass:[value class]])
                {
                    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                    convertedValue = [numberFormatter numberFromString:(NSString *)value];
                }
                else 
                {
                    convertedValue = nil;
                }
            }
            break;
            
        case SCDataTypeNSDate:
            if(![value isKindOfClass:[NSDate class]])
            {
                if([SCUtilities isStringClass:[value class]])
                {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    convertedValue = [dateFormatter dateFromString:(NSString *)value];
                }
                else 
                {
                    convertedValue = nil;
                }
            }
            break;
            
        default:;   // nothing to do for other types
    }
    
    return convertedValue;
}

+ (NSDictionary *)bindingsDictionaryForBindingsString:(NSString *)bindingsString
{
    NSMutableDictionary *bindings = [NSMutableDictionary dictionary];
    
    if([bindingsString length])
    {
        NSCharacterSet *trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        
        NSArray *bindingsComponents = [bindingsString componentsSeparatedByString:@";"];
        for(NSString *pairString in bindingsComponents)
        {
            NSArray *pairComponents = [pairString componentsSeparatedByString:@":"];
            if(pairComponents.count != 2)
            {
                SCDebugLog(@"Warning: Invalid bindings string: %@", pairString);
                continue;
            }
            
            NSString *key = [(NSString *)[pairComponents objectAtIndex:0] stringByTrimmingCharactersInSet:trimSet];
            NSString *value = [(NSString *)[pairComponents objectAtIndex:1] stringByTrimmingCharactersInSet:trimSet];
            [bindings setValue:value forKey:key];
        }
    }
    
    return bindings;
}

+ (NSString *)bindingsStringForBindingsDictionary:(NSDictionary *)bindingsDictionary
{
    NSArray *keysArray = [bindingsDictionary allKeys];
    if(!keysArray.count)
        return nil;
    
    NSMutableString *bindingsString = [NSMutableString string];
    for(NSUInteger i=0; i<keysArray.count; i++)
    {
        NSString *key = [keysArray objectAtIndex:i];
        if(i!=0)
            [bindingsString appendString:@";"];
        [bindingsString appendFormat:@"%@:%@", key, [bindingsDictionary valueForKey:key]];
    }
     
    return bindingsString;
}

+ (NSString *)base64EncodedStringFromString:(NSString *)string
{
    NSData *data = [NSData dataWithBytes:[string UTF8String] length:[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
    NSUInteger length = [data length];
    NSMutableData *mutableData = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    
    uint8_t *input = (uint8_t *)[data bytes];
    uint8_t *output = (uint8_t *)[mutableData mutableBytes];
    
    for (NSUInteger i = 0; i < length; i += 3)
    {
        NSUInteger value = 0;
        for (NSUInteger j = i; j < (i + 3); j++)
        {
            value <<= 8;
            if (j < length)
            {
                value |= (0xFF & input[j]);
            }
        }
        
        static uint8_t const kAFBase64EncodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        
        NSUInteger idx = (i / 3) * 4;
        output[idx + 0] = kAFBase64EncodingTable[(value >> 18) & 0x3F];
        output[idx + 1] = kAFBase64EncodingTable[(value >> 12) & 0x3F];
        output[idx + 2] = (i + 1) < length ? kAFBase64EncodingTable[(value >> 6)  & 0x3F] : '=';
        output[idx + 3] = (i + 2) < length ? kAFBase64EncodingTable[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:mutableData encoding:NSASCIIStringEncoding];
}

+ (UIViewController *)instantiateViewControllerWithIdentifier:(NSString *)identifier usingStoryboard:(UIStoryboard *)storyboard
{
    UIViewController *viewController = nil;
    @try
    {
        viewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
    }
    @catch (NSException *exception)
    {
        // Fix for Xcode 7 new view controller identifier naming convention (needed to support projects developed with Xcode 6)
        // This fix can be removed after all customer projects are ported to Xcode 7
        identifier = [identifier stringByReplacingOccurrencesOfString:@"UIViewController" withString:@"UITableViewController"];
        
        viewController = [storyboard instantiateViewControllerWithIdentifier:identifier];
    }
    
    return viewController;
}


+ (NSDate *)stripTimeFromDate:(NSDate *)date
{
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;  // strip time by not including NSCalendarUnitHour/Min/Sec
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:flags fromDate:date];
    
    return [calendar dateFromComponents:components];
}


@end




@interface SCModelCenter ()

- (void)registerForKeyboardNotifications;
- (void)unregisterKeyboardNotifications;
- (void)keyboardWillShow:(NSNotification *)aNotification;
- (void)keyboardWillHide:(NSNotification *)aNotification;

@end

@implementation SCModelCenter

@synthesize keyboardIssuer;


+ (SCModelCenter *)sharedModelCenter
{
	static SCModelCenter *_sharedModelCenter = nil;
	
	@synchronized(self)
	{
		if(!_sharedModelCenter)
			_sharedModelCenter = [[SCModelCenter alloc] init];
	}
	
	return _sharedModelCenter;
}

- (instancetype) init
{
	if( (self = [super init]) )
	{
		keyboardIssuer = nil;
		[self registerForKeyboardNotifications];
		
		modelsSet = CFSetCreateMutable(kCFAllocatorDefault, 0, NULL);
	}
	
	return self;
}

- (void)dealloc
{
	[self unregisterKeyboardNotifications];
	CFRelease(modelsSet);
}

- (void)registerForKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) 
												 name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) 
												 name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterKeyboardNotifications
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)keyboardWillShow:(NSNotification *)aNotification
{
	if(!self.keyboardIssuer)
		return;
	
	for(SCTableViewModel *model in (__bridge id)modelsSet)
		if(model.viewController == self.keyboardIssuer)
			[model keyboardWillShow:aNotification];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
	if(!self.keyboardIssuer)
		return;
	
	for(SCTableViewModel *model in (__bridge id)modelsSet)
		if(model.viewController == self.keyboardIssuer)
			[model keyboardWillHide:aNotification];
}



- (void)registerModel:(SCTableViewModel *)model
{
    CFSetAddValue(modelsSet, (__bridge const void *)model);
}

- (void)unregisterModel:(SCTableViewModel *)model
{
    CFSetRemoveValue(modelsSet, (__bridge const void *)model);
}

- (SCTableViewModel *)modelForViewController:(UIViewController *)viewController
{
    for(SCTableViewModel *model in (__bridge id)modelsSet)
        if(model.viewController == viewController)
            return model;
    
    return nil;
}

@end


