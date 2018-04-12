/*
 *  SCParseDefinition.m
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

#import "SCParseDefinition.h"

#import "SCParseStore.h"


@implementation SCParseDefinition

+ (instancetype)definitionWithClassName:(NSString *)className columnNamesString:(NSString *)columnNames applicationId:(NSString *)applicationId clientKey:(NSString *)clientKey
{
    return [[[self class] alloc] initWithClassName:className columnNamesString:columnNames applicationId:applicationId clientKey:clientKey];
}

- (instancetype)initWithClassName:(NSString *)className columnNamesString:(NSString *)columnNames applicationId:(NSString *)applicationId clientKey:(NSString *)clientKey
{
    self = [self initWithDictionaryKeyNamesString:columnNames];
    if(self)
    {
        self.className = className;
        self.applicationId = applicationId;
        self.clientKey = clientKey;
    }
    
    return self;
}


// overrides superclass
- (NSString *)dataStructureName
{
    NSString *dataStructureName = self.className;
    
    if([dataStructureName isEqualToString:@"User"])
    {
        dataStructureName = @"_User";  // User class is a special case where Parse always adds an underscore before it
    }
    
    return dataStructureName;
}

// overrides superclass
- (SCDataStore *)generateCompatibleDataStore
{
    return [SCParseStore storeWithDefaultParseDefinition:self];
}

@end
