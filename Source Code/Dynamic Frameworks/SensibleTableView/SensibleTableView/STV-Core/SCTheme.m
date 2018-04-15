/*
 *  SCTheme.m
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


#import "SCTheme.h"

#import "SCGlobals.h"
#import "SCTableViewCell.h"




@interface SCTheme ()
{
    NSMutableDictionary *_themeStyles;
    
    NSDictionary *_UITableViewCellSeparatorStyleDictionary;
}

@property (nonatomic, readonly) NSMutableDictionary *themeStyles;

@property (nonatomic, readonly) NSDictionary *UITableViewCellSeparatorStyleDictionary;

- (void)loadFromPath:(NSString *)path;
- (NSString *)stringByRemovingCommentsFromString:(NSString *)originalString;
- (id)valueForValueString:(NSString *)valueString forPropertyWithName:(NSString *)propertyName;
- (UIColor *)colorFromColorString:(NSString *)colorString;
- (UIFont *)fontFromFontString:(NSString *)fontString;
- (UIImage *)imageFromImageString:(NSString *)imageString;
- (NSValue *)rectFromRectString:(NSString *)rectString;
- (NSValue *)sizeFromSizeString:(NSString *)sizeString;


@end


@implementation SCTheme

@synthesize themeStyles = _themeStyles;
@synthesize UITableViewCellSeparatorStyleDictionary = _UITableViewCellSeparatorStyleDictionary;


+ (instancetype)themeWithPath:(NSString *)path
{
    return [[[self class] alloc] initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path
{
    if( (self = [self init]) )
    {
        _themeStyles = [NSMutableDictionary dictionary];
        
        _UITableViewCellSeparatorStyleDictionary = nil;
        
        [self loadFromPath:path];
    }
    return self;
}

- (NSDictionary *)UITableViewCellSeparatorStyleDictionary
{
    if(!_UITableViewCellSeparatorStyleDictionary)
    {
        _UITableViewCellSeparatorStyleDictionary = 
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithInt:UITableViewCellSeparatorStyleNone], @"UITableViewCellSeparatorStyleNone",
         [NSNumber numberWithInt:UITableViewCellSeparatorStyleSingleLine], @"UITableViewCellSeparatorStyleSingleLine", 
         [NSNumber numberWithInt:UITableViewCellSeparatorStyleSingleLineEtched], @"UITableViewCellSeparatorStyleSingleLineEtched", nil];
    }
        
    return _UITableViewCellSeparatorStyleDictionary;
}


- (void)loadFromPath:(NSString *)path
{
    [self.themeStyles removeAllObjects];
    
    NSString *fullPath = [[NSBundle mainBundle] pathForResource:path ofType:nil];
    NSString *themeFileString = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
    if(!themeFileString)
    {
        SCDebugLog(@"Warning: Unable to load theme file at path: %@", path);
        return;
    }
    
    // remove all comments
    themeFileString = [self stringByRemovingCommentsFromString:themeFileString];
    
    // Parse the theme file into the _themeStyles dictionary
    NSCharacterSet *trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSScanner *themeScanner = [NSScanner scannerWithString:themeFileString];
    while (![themeScanner isAtEnd])
    {
        NSString *styleName = nil;
        [themeScanner scanUpToString:@"{" intoString:&styleName];
        if(!styleName)
            break;
        if([styleName rangeOfString:@"}"].location != NSNotFound)
        {
            SCDebugLog(@"Warning: theme file '%@' is missing an opening '{' bracket.", path);
            break;
        }
        styleName = [styleName stringByTrimmingCharactersInSet:trimSet];
        [themeScanner setScanLocation:themeScanner.scanLocation+1]; // skip the '{' bracket.
        
        NSString *styleSet = nil;
        [themeScanner scanUpToString:@"}" intoString:&styleSet];
        
        if(!styleSet)
        {
            if([themeScanner scanString:@"}" intoString:nil])
            {
                continue;
            }
            else 
            {
                SCDebugLog(@"Warning: theme file '%@' is missing a closing '}' bracket.", path);
                break;
            }
        }
        styleSet = [styleSet stringByTrimmingCharactersInSet:trimSet];
        [themeScanner setScanLocation:themeScanner.scanLocation+1]; // skip the '}' bracket.
        
        NSMutableDictionary *styleSetDictionary = [NSMutableDictionary dictionary];
        NSArray *propertyValuePairs = [styleSet componentsSeparatedByString:@";"];
        for(NSString *propertyValuePair in propertyValuePairs)
        {
            if(![propertyValuePair length])
                continue;
            
            NSArray *pairComponents = [propertyValuePair componentsSeparatedByString:@":"];
            if(pairComponents.count != 2)
            {
                SCDebugLog(@"Warning: syntax error in property/value pair: %@", propertyValuePair);
                continue;
            }
            NSString *propertyName = [(NSString *)[pairComponents objectAtIndex:0] stringByTrimmingCharactersInSet:trimSet];
            NSString *valueString = [(NSString *)[pairComponents objectAtIndex:1] stringByTrimmingCharactersInSet:trimSet];
            id value = [self valueForValueString:valueString forPropertyWithName:propertyName];
            
            if(value)
                [styleSetDictionary setValue:value forKey:propertyName];
        }
        
        [_themeStyles setValue:styleSetDictionary forKey:styleName];
    }
}

- (NSString *)stringByRemovingCommentsFromString:(NSString *)originalString
{
    NSMutableString *cleanString = [NSMutableString string];
    
    NSScanner *stringScanner = [NSScanner scannerWithString:originalString];
    [stringScanner setCharactersToBeSkipped:nil];
    while (![stringScanner isAtEnd])
    {
        NSString *subString;
        if([stringScanner scanUpToString:@"/" intoString:&subString])
        {
            [cleanString appendString:subString];
            
            if([stringScanner scanString:@"/*" intoString:nil])
            {
                if([stringScanner scanUpToString:@"*/\n" intoString:nil])
                {
                    if(![stringScanner isAtEnd])
                        [stringScanner setScanLocation:stringScanner.scanLocation+2]; // advance past '*/'
                }
                else 
                    break;
            }
            else 
            if([stringScanner scanString:@"//" intoString:nil])
            {
                if(![stringScanner scanUpToString:@"\n" intoString:nil])
                    break;
            }
        }
        else 
        {
            subString = [originalString substringFromIndex:stringScanner.scanLocation];
            [cleanString appendString:subString];
            break;
        }
    }
    
    return cleanString;
}

- (id)valueForValueString:(NSString *)valueString forPropertyWithName:(NSString *)propertyName
{
    if(!([propertyName length] && [valueString length]))
        return nil;
    
    if([valueString caseInsensitiveCompare:@"nil"]==NSOrderedSame)
    {
        return [NSNull null];
    }

    
    id value = nil;
    
    if([propertyName rangeOfString:@"color" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        value = [self colorFromColorString:valueString];
        if(value && [propertyName rangeOfString:@"layer"].location!=NSNotFound)
        {
            UIColor *color = (UIColor *)value;
            value = (id)color.CGColor;
        }
    }
    else 
    if([propertyName rangeOfString:@"font" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        value = [self fontFromFontString:valueString];
    }
    else 
    if([propertyName rangeOfString:@"image" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        UIImage *image = [self imageFromImageString:valueString];
        if(image)
        {
            value = image;
        }
    }
    else
    if([valueString rangeOfString:@"CGRect(" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        value = [self rectFromRectString:valueString];
    }
    else
    if([valueString rangeOfString:@"CGSize(" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        value = [self sizeFromSizeString:valueString];
    }
    else 
    if( ([valueString caseInsensitiveCompare:@"TRUE"]==NSOrderedSame) || ([valueString caseInsensitiveCompare:@"YES"]==NSOrderedSame) )
    {
        value = [NSNumber numberWithBool:TRUE];
    }
    else 
    if( ([valueString caseInsensitiveCompare:@"FALSE"]==NSOrderedSame) || ([valueString caseInsensitiveCompare:@"NO"]==NSOrderedSame) )
    {
        value = [NSNumber numberWithBool:FALSE];
    }
    else 
    if([propertyName hasSuffix:@"View"])
    {
        UIImage *image = [self imageFromImageString:valueString];
        if(image)
        {
            value = image;
        }
    }
    else 
    if([valueString hasPrefix:@"UITableViewCellSeparatorStyle"])
    {
        value = [self.UITableViewCellSeparatorStyleDictionary valueForKey:valueString];
        if(!value)
            SCDebugLog(@"Warning: '%@' is not a valid constant for UITableViewCellSeparatorStyle", valueString);
    }
    else 
    {
        NSScanner *valueScanner = [NSScanner scannerWithString:valueString];
        
        float floatValue;
        if([valueScanner scanFloat:&floatValue])
        {
            value = [NSNumber numberWithFloat:floatValue];
        }
        else 
        {
            NSCharacterSet *trimSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\'@"];
            value = [valueString stringByTrimmingCharactersInSet:trimSet];
        }
    }
    
    return value;
}

- (NSValue *)rectFromRectString:(NSString *)rectString
{
    NSValue *rectValue = nil;
    
    NSScanner *rectScanner = [NSScanner scannerWithString:rectString];
    [rectScanner setCaseSensitive:NO];
    if([rectScanner scanString:@"CGRect(" intoString:nil])
    {
        NSString *rectValuesString = nil;
        if([rectScanner scanUpToString:@")" intoString:&rectValuesString])
        {
            NSArray *rectValues = [rectValuesString componentsSeparatedByString:@","];
            if(rectValues.count != 4)
            {
                SCDebugLog(@"Warning: syntax error in CGRect definition: %@", rectString);
            }
            else
            {
                CGFloat x = [(NSString *)[rectValues objectAtIndex:0] floatValue];
                CGFloat y = [(NSString *)[rectValues objectAtIndex:1] floatValue];
                CGFloat width = [(NSString *)[rectValues objectAtIndex:2] floatValue];
                CGFloat height = [(NSString *)[rectValues objectAtIndex:3] floatValue];
                
                rectValue = [NSValue valueWithCGRect:CGRectMake(x, y, width, height)];
            }
        }
        else
            SCDebugLog(@"Warning: syntax error in CGRect definition: %@", rectString);
    }
    
    return rectValue;
}

- (NSValue *)sizeFromSizeString:(NSString *)sizeString
{
    NSValue *sizeValue = nil;
    
    NSScanner *sizeScanner = [NSScanner scannerWithString:sizeString];
    [sizeScanner setCaseSensitive:NO];
    if([sizeScanner scanString:@"CGSize(" intoString:nil])
    {
        NSString *sizeValuesString = nil;
        if([sizeScanner scanUpToString:@")" intoString:&sizeValuesString])
        {
            NSArray *sizeValues = [sizeValuesString componentsSeparatedByString:@","];
            if(sizeValues.count != 2)
            {
                SCDebugLog(@"Warning: syntax error in CGSize definition: %@", sizeString);
            }
            else
            {
                CGFloat width = [(NSString *)[sizeValues objectAtIndex:0] floatValue];
                CGFloat height = [(NSString *)[sizeValues objectAtIndex:1] floatValue];
                
                sizeValue = [NSValue valueWithCGSize:CGSizeMake(width, height)];
            }
        }
        else
            SCDebugLog(@"Warning: syntax error in CGSize definition: %@", sizeString);
    }
    
    return sizeValue;
}

- (UIColor *)colorFromColorString:(NSString *)colorString
{
    UIColor *color = nil;
    
    NSScanner *colorScanner = [NSScanner scannerWithString:colorString];
    [colorScanner setCaseSensitive:NO];
    if([colorScanner scanString:@"rgb(" intoString:nil])
    {
        NSString *rgbValuesString = nil;
        if([colorScanner scanUpToString:@")" intoString:&rgbValuesString])
        {
            NSArray *rgbValues = [rgbValuesString componentsSeparatedByString:@","];
            if(rgbValues.count<3 || rgbValues.count>4)
            {
                SCDebugLog(@"Warning: syntax error in RGB definition: %@", colorString);
            }
            else 
            {
                CGFloat red = [(NSString *)[rgbValues objectAtIndex:0] floatValue];
                CGFloat green = [(NSString *)[rgbValues objectAtIndex:1] floatValue];
                CGFloat blue = [(NSString *)[rgbValues objectAtIndex:2] floatValue];
                CGFloat alpha;
                if(rgbValues.count==4)
                    alpha = [(NSString *)[rgbValues objectAtIndex:3] floatValue];
                else 
                    alpha = 1;
                
                color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
            }
        }
    }
    else 
    if([colorScanner scanString:@"#" intoString:nil])
    {
        unsigned int rgbValue;
        if([colorScanner scanHexInt:&rgbValue])
        {
            color = [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0
                                    green:((float)((rgbValue & 0xFF00) >> 8))/255.0
                                     blue:((float)(rgbValue & 0xFF))/255.0 
                                    alpha:1.0];
        }
    }
    else 
    {
        SEL colorSelector = NSSelectorFromString(colorString);
        if([UIColor respondsToSelector:colorSelector])
        {
            color = [UIColor performSelector:colorSelector];
        }
        else 
        {
            UIImage *colorImage = [self imageFromImageString:colorString];
            
            if(colorImage)
            {
                color = [UIColor colorWithPatternImage:colorImage];
            }
            else 
            {
                SCDebugLog(@"Warning: Invalid color string: %@.", colorString);
            }
        }
    }
    
    return color;
}

- (UIFont *)fontFromFontString:(NSString *)fontString
{
    UIFont *font = nil;
    
    NSArray *fontComponents = [fontString componentsSeparatedByString:@" "];
    if(fontComponents.count >=2)
    {
        NSString *fontName = [fontComponents objectAtIndex:0];
        CGFloat fontSize = [(NSString *)[fontComponents objectAtIndex:1] floatValue];
        
        font = [UIFont fontWithName:fontName size:fontSize];
    }
    
    return font;
}

- (UIImage *)imageFromImageString:(NSString *)imageString
{
    UIImage *image = nil;
    
    NSArray *imageComponents = [imageString componentsSeparatedByString:@" "];
    
    if(imageComponents.count>0 && imageComponents.count<3)
    {
        NSString *pathString = [imageComponents objectAtIndex:0];
        NSCharacterSet *trimSet = [NSCharacterSet characterSetWithCharactersInString:@"\"\'@"];
        image = [UIImage imageNamed:[pathString stringByTrimmingCharactersInSet:trimSet]];
        if(!image)
            SCDebugLog(@"Warning: Unable to load image at path: %@", pathString);
        
        if(imageComponents.count==2 && [image respondsToSelector:@selector(resizableImageWithCapInsets:)])
        {
            NSString *capInsetsString = [imageComponents objectAtIndex:1];
            NSScanner *capInsetsScanner = [NSScanner scannerWithString:capInsetsString];
            [capInsetsScanner setCaseSensitive:NO];
            if([capInsetsScanner scanString:@"capInsets(" intoString:nil])
            {
                NSString *insetsValuesString = nil;
                if([capInsetsScanner scanUpToString:@")" intoString:&insetsValuesString])
                {
                    NSArray *insetsValues = [insetsValuesString componentsSeparatedByString:@","];
                    if(insetsValues.count != 4)
                    {
                        SCDebugLog(@"Warning: syntax error in capInsets definition: %@", capInsetsString);
                    }
                    else 
                    {
                        CGFloat top = [(NSString *)[insetsValues objectAtIndex:0] floatValue];
                        CGFloat left = [(NSString *)[insetsValues objectAtIndex:1] floatValue];
                        CGFloat bottom = [(NSString *)[insetsValues objectAtIndex:2] floatValue];
                        CGFloat right = [(NSString *)[insetsValues objectAtIndex:3] floatValue];
                        
                        UIEdgeInsets capInsets = UIEdgeInsetsMake(top, left, bottom, right);
                        image = [image resizableImageWithCapInsets:capInsets];
                    }
                }
            }
        }
    }
    else 
    {
        SCDebugLog(@"Warning: Syntax error for image with string: %@", imageString);
    }
    
    return image;
}

- (void)styleObject:(NSObject *)object usingThemeStyle:(NSString *)style
{
    [self styleObject:object usingThemeStyle:style onlyStylePropertyNamesInSet:nil]; // style all properties
}

- (void)styleObject:(NSObject *)object usingThemeStyle:(NSString *)style onlyStylePropertyNamesInSet:(NSSet *)propertyNamesSet
{
    if(!object)
        return;
    
    NSDictionary *styleSetDictionary;
    if(!style)
    {
        Class objectClass = [object class];
        do 
        {
            style = NSStringFromClass(objectClass);
            styleSetDictionary = [_themeStyles valueForKey:style];
            
            objectClass = [objectClass superclass];
            
        } while (!styleSetDictionary && objectClass);
    }
    else 
    {
        styleSetDictionary = [_themeStyles valueForKey:style];
    }
        
    if(![styleSetDictionary count])
        return;
    
    NSArray *stylePropertyNames = [styleSetDictionary allKeys];
    for(__strong NSString *stylePropertyName in stylePropertyNames)
    {
        if(propertyNamesSet)
        {
            NSString *lastPropertyName = [[stylePropertyName componentsSeparatedByString:@"."] lastObject];
            if(![propertyNamesSet containsObject:lastPropertyName])
                continue;  // skip properties not in propertyNames
        }
        
        id value = [styleSetDictionary valueForKey:stylePropertyName];
        
        if([stylePropertyName hasSuffix:@"View"] && [value isKindOfClass:[UIImage class]])
            value = [[UIImageView alloc] initWithImage:value];
        
        if([object isKindOfClass:[SCControlCell class]] && [stylePropertyName rangeOfString:@"textLabel"].location!=NSNotFound)
        {
            SCControlCell *controlCell = (SCControlCell *)object;
            if(controlCell.controlCreatedInIB)
            {
                stylePropertyName = [stylePropertyName stringByReplacingOccurrencesOfString:@"textLabel" withString:@"ibControlLabel"];
            }
        }
        
        @try 
        {
            if([stylePropertyName rangeOfString:@"backgroundImage" options:NSCaseInsensitiveSearch].location!=NSNotFound && [value isKindOfClass:[UIImage class]])
            {
                // Make sure to get the subObject in case the property name has a key hierarchy
                NSObject *subObject = object;
                if([stylePropertyName rangeOfString:@"."].location != NSNotFound)
                {
                    NSString *subObjectKeyPath = [stylePropertyName stringByDeletingPathExtension];
                    subObject = [object valueForSensibleKeyPath:subObjectKeyPath];
                }
                
                if([subObject respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)])
                {
                    [(id)subObject setBackgroundImage:value forBarMetrics:UIBarMetricsDefault];
                }
                else 
                {
                    SCDebugLog(@"Warning: setting '%@' for '%@' is not supported on iOS versions less than 5.0.", stylePropertyName, NSStringFromClass([subObject class]));
                }
            }
            else 
            {
                if([value isKindOfClass:[NSNull class]])
                    value = nil;
                
                [object setValue:value forSensibleKeyPath:stylePropertyName];
            }
        }
        @catch (NSException *exception) {
            SCDebugLog(@"Warning: unable to set style value '%@' for property '%@' in class '%@'", value, stylePropertyName, NSStringFromClass([object class]));
        }
    }
}

@end
