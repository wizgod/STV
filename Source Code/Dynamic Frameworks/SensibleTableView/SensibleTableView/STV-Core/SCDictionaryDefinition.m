/*
 *  SCDictionaryDefinition.m
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


#import "SCDictionaryDefinition.h"

#import "SCArrayStore.h"
#import <objc/runtime.h>



@implementation SCDictionaryDefinition

+ (instancetype)definitionWithDictionaryKeyNamesString:(NSString *)keyNamesString
{
    return [[[self class] alloc] initWithDictionaryKeyNamesString:keyNamesString];
}

+ (instancetype)definitionWithDictionaryKeyNames:(NSArray *)keyNames
{
	return [[[self class] alloc] initWithDictionaryKeyNames:keyNames];
}

+ (instancetype)definitionWithDictionaryKeyNames:(NSArray *)keyNames keyTitles:(NSArray *)keyTitles
{
	return [[[self class] alloc] initWithDictionaryKeyNames:keyNames keyTitles:keyTitles];
}


- (instancetype)initWithDictionaryKeyNamesString:(NSString *)keyNamesString
{
    if( (self=[self init]) )
	{
		[self generatePropertiesFromPropertyNamesString:keyNamesString];
		
		[self setupDefaultConfiguration];
	}
	return self;
}

- (instancetype)initWithDictionaryKeyNames:(NSArray *)keyNames
{
	return [self initWithDictionaryKeyNames:keyNames keyTitles:nil];
}

- (instancetype)initWithDictionaryKeyNames:(NSArray *)keyNames keyTitles:(NSArray *)keyTitles
{
	if( (self=[self init]) )
	{
		[self generatePropertiesFromPropertyNamesArray:keyNames propertyTitlesArray:keyTitles];
		
		[self setupDefaultConfiguration];
	}
	return self;
}


// overrides superclass
- (void)generatePropertiesFromPropertyNamesArray:(NSArray *)propertyNamesArray propertyTitlesArray:(NSArray *)propertyTitlesArray
{
    for(NSUInteger i=0; i<propertyNamesArray.count; i++)
    {
        NSString *keyName = [propertyNamesArray objectAtIndex:i];
        NSString *keyTitle;
        if(i < propertyTitlesArray.count)
            keyTitle = [propertyTitlesArray objectAtIndex:i];
        else
            keyTitle = [SCUtilities getUserFriendlyTitleFromName:keyName];
        [self addPropertyDefinitionWithName:keyName
                                      title:keyTitle
                                       type:SCPropertyTypeTextField];
    }
}

// overrides superclass
- (BOOL)isValidPropertyName:(NSString *)propertyName
{
	return TRUE;	// Should accept any key name as a valid property name
}

// overrides superclass
- (BOOL)insertPropertyDefinition:(SCPropertyDefinition *)propertyDefinition
						 atIndex:(NSInteger)index
{
	propertyDefinition.dataType = SCDataTypeDictionaryItem;
	
	return [super insertPropertyDefinition:propertyDefinition atIndex:index];
}

// overrides superclass
- (NSString *)dataStructureName
{
	return [SCUtilities dataStructureNameForClass:[NSDictionary class]];
}

// overrides superclass
- (SCDataStore *)generateCompatibleDataStore
{
    return [SCArrayStore storeWithObjectsArray:nil defaultDefiniton:self];
}


@end
