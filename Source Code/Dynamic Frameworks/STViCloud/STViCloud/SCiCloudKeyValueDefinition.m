/*
 *  SCiCloudKeyValueDefinition.m
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


#import "SCiCloudKeyValueDefinition.h"

#import "SCiCloudKeyValueStore.h"


@implementation SCiCloudKeyValueDefinition


+ (instancetype)definitionWithiCloudKeyNamesString:(NSString *)keyNamesString
{
    return [[[self class] alloc] initWithiCloudKeyNamesString:keyNamesString];
}

+ (instancetype)definitionWithiCloudKeyNames:(NSArray *)keyNames
{
    return [[[self class] alloc] initWithiCloudKeyNames:keyNames];
}

+ (instancetype)definitionWithiCloudKeyNames:(NSArray *)keyNames keyTitles:(NSArray *)keyTitles
{
    return [[[self class] alloc] initWithiCloudKeyNames:keyNames keyTitles:keyTitles];
}


- (instancetype)initWithiCloudKeyNamesString:(NSString *)keyNamesString
{
    return [self initWithDictionaryKeyNamesString:keyNamesString];
}

- (instancetype)initWithiCloudKeyNames:(NSArray *)keyNames
{
    return [self initWithDictionaryKeyNames:keyNames];
}

- (instancetype)initWithiCloudKeyNames:(NSArray *)keyNames keyTitles:(NSArray *)keyTitles
{
    return [self initWithDictionaryKeyNames:keyNames keyTitles:keyTitles];
}


// overrides superclass
- (SCDataStore *)generateCompatibleDataStore
{
    return [SCiCloudKeyValueStore storeWithDefaultDataDefinition:self];
}


@end
