/*
 *  SCArrayOfObjectsSection+WebServices.h
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


#import <SensibleTableView/SCTableViewSection.h>

#import "SCWebServiceDefinition.h"


@interface SCArrayOfObjectsSection (STVWebServices)


/** Allocates and returns an initialized SCArrayOfObjectsSection given a header title and 
 a web service definition. 
 *
 *	@param sectionHeaderTitle A header title for the section.
 *	@param definition The web service definition of the objects to fetch.
 */
+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle webServiceDefinition:(SCWebServiceDefinition *)definition;

/** Allocates and returns an initialized SCArrayOfObjectsSection given a header title,  
 a web service definition and a batch size for the fetched objects. 
 *
 *	@param sectionHeaderTitle A header title for the section.
 *	@param definition The web service definition of the objects to fetch.
 *  @param batchSize The size of the batch to be fetched.
 */
+ (instancetype)sectionWithHeaderTitle:(NSString *)sectionHeaderTitle webServiceDefinition:(SCWebServiceDefinition *)definition batchSize:(NSUInteger)batchSize;


/** Returns an initialized SCArrayOfObjectsSection given a header title and 
 a web service definition. 
 *
 *	@param sectionHeaderTitle A header title for the section.
 *	@param definition The web service definition of the objects to fetch.
 */
- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle webServiceDefinition:(SCWebServiceDefinition *)definition;

/** Returns an initialized SCArrayOfObjectsSection given a header title,  
 a web service definition and a batch size for the fetched objects. 
 *
 *	@param sectionHeaderTitle A header title for the section.
 *	@param definition The web service definition of the objects to fetch.
 *  @param batchSize The size of the batch to be fetched.
 */
- (instancetype)initWithHeaderTitle:(NSString *)sectionHeaderTitle webServiceDefinition:(SCWebServiceDefinition *)definition batchSize:(NSUInteger)batchSize;

@end


