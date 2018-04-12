/*
 *  SCWebServiceDefinition.h
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


#import <SensibleTableView/SCDictionaryDefinition.h>


/****************************************************************************************/
/*	class SCWebServiceDefinition	*/
/****************************************************************************************/ 
/**	
 This class functions as a means to further extend the definition of remote web services.
 Using web service definitions, classes like SCObjectCell and SCObjectSection 
 will be able to better generate user interface elements that truly represent their 
 bound web service. 
 
 Sample use:
    // Define the Twitter API search web service for the search term '#iosdev'.
    SCWebServiceDefinition *tweetDef = [SCWebServiceDefinition definitionWithBaseURL:@"http://search.twitter.com/" 
        fetchObjectsAPI:@"search.json" resultsKeyName:@"results" resultsDictionaryKeyNames:nil];
    [tweetDef.fetchObjectsParameters setValue:@"#iosdev" forKey:@"q"];
    [tweetDef.fetchObjectsParameters setValue:@"recent" forKey:@"result_type"];
    tweetDef.batchSizeParameterName = @"rpp";
    tweetDef.nextBatchURLKeyName = @"next_page";
    SCPropertyDefinition *textPropertyDef = [SCPropertyDefinition definitionWithName:@"text" 
        title:@"Tweet" type:SCPropertyTypeTextView];
    [tweetDef addPropertyDefinition:textPropertyDef];
 
    // Create a section that will display the tweets in batches of 50
    SCArrayOfObjectsSecion *tweetsSection = [SCArrayOfObjectsSection sectionWithHeaderTitle:nil 
        webServiceDefinition:tweetDef batchSize:50];
    [self.tableViewModel addSection:tweetsSection];
 
 @see SCPropertyDefinition.
 */
@interface SCWebServiceDefinition : SCDictionaryDefinition


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Creation and Initialization
//////////////////////////////////////////////////////////////////////////////////////////

/** Allocates and returns an initialized SCWebServiceDefinition. 
 @param baseURL The base URL of the web service.
 @param api The api string used to fetch the objects.
 @param resultsKey The name of the dictionary key that will contain the fetched objects.
 @param keyNamesString A string containing the key names of the results dictionary separated by semi-colons. Example string: @"firstName;lastName". Property groups can also be defined in the string using the following format: @"Personal Details:(firstName, lastName); Address:(street, state, country)". The group title can also be ommitted to create a group with no title. For example: @":(firstName, lastName)".
 
 Key names string syntax options:
    @"key1;key2;key3;..."
    @"group1 header:(key1, key2,...):group1 footer;group2..."
 */
+ (instancetype)definitionWithBaseURL:(NSString *)baseURL fetchObjectsAPI:(NSString *)api resultsKeyName:(NSString *)resultsKey resultsDictionaryKeyNamesString:(NSString *)keyNamesString;

/** Allocates and returns an initialized SCWebServiceDefinition. 
 @param baseURL The base URL of the web service.
 @param api The api string used to fetch the objects.
 @param resultsKey The name of the dictionary key that will contain the fetched objects.
 @param keyNames An array containing the key names of the results dictionary.
 */
+ (instancetype)definitionWithBaseURL:(NSString *)baseURL fetchObjectsAPI:(NSString *)api resultsKeyName:(NSString *)resultsKey resultsDictionaryKeyNames:(NSArray *)keyNames;


/** Returns an initialized SCWebServiceDefinition. 
 @param baseURL The base URL of the web service.
 @param api The api string used to fetch the objects.
 @param resultsKey The name of the dictionary key that will contain the fetched objects.
 @param keyNamesString A string containing the key names of the results dictionary separated by semi-colons. Example string: @"firstName;lastName". Property groups can also be defined in the string using the following format: @"Personal Details:(firstName, lastName); Address:(street, state, country)". The group title can also be ommitted to create a group with no title. For example: @":(firstName, lastName)".
 
 Key names string syntax options:
    @"key1;key2;key3;..."
    @"group1 header:(key1, key2,...):group1 footer;group2..."
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL fetchObjectsAPI:(NSString *)api resultsKeyName:(NSString *)resultsKey resultsDictionaryKeyNamesString:(NSString *)keyNamesString;

/** Allocates and returns an initialized SCWebServiceDefinition. 
 @param baseURL The base URL of the web service.
 @param api The api string used to fetch the objects.
 @param resultsKey The name of the dictionary key that will contain the fetched objects.
 @param keyNames An array containing the key names of the results dictionary.
 */
- (instancetype)initWithBaseURL:(NSString *)baseURL fetchObjectsAPI:(NSString *)api resultsKeyName:(NSString *)resultsKey resultsDictionaryKeyNames:(NSArray *)keyNames;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Configuration
//////////////////////////////////////////////////////////////////////////////////////////

/** The base URL of the web service. */
@property (nonatomic, strong) NSURL *baseURL;

/** The base URL in string format. */
@property (nonatomic, copy) NSString *baseURLString;

/**
 *  The INSERT URL computed based on baseURL and insertObjectAPI;
 */
@property (nonatomic, readonly) NSURL *insertURL;

/**
 *  The UPDATE URL computed based on baseURL and updateObjectAPI;
 */
@property (nonatomic, readonly) NSURL *updateURL;

/**
 *  The DELETE URL computed based on baseURL and deleteObjectAPI;
 */
@property (nonatomic, readonly) NSURL *deleteURL;

/** The dictionary of HTTP header values.
 
 Sample use:
    [myWebServiceDef.httpHeaders setValue:@"application/json" forKey:@"Content-Type"];
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *httpHeaders;

/** The string containing the fetch objects API. */
@property (nonatomic, copy) NSString *fetchObjectsAPI;

/** The dictionary of fetch objects parameters. 
 
 Sample use:
    [tweetDef.fetchObjectsParameters setValue:@"#iosdev" forKey:@"q"];
 */
@property (nonatomic, readonly) NSMutableDictionary *fetchObjectsParameters;

/** The name of the results dictionary key that will contain the objects fetched from the web service. This value has no effect if the returned results are an array instead of a dictionary. */
@property (nonatomic, copy) NSString *resultsKeyName;

/** Set only if the fetched result is an atomic array of a single dictionary object. When this is the case, resultsKeyName can be set to a key in the returned atomic dictionary. */
@property (nonatomic, copy) NSString *atomicResultKeyName;


/** The name of the parameter that can be assigned the fetched batch size. */
@property (nonatomic, copy) NSString *batchSizeParameterName;

/** The name of the parameter that can be assigned the batch starting index. */
@property (nonatomic, copy) NSString *batchStartIndexParameterName;

/** 
 The initial starting index for the batch. Default: 0.
 
 @note Only has effect if batchStartIndexParameterName is set.
 */
@property (nonatomic, readwrite) NSUInteger batchInitialStartIndex;

/** The name of the dictionary key that contains the URL to the next batch of objects. */
@property (nonatomic, copy) NSString *nextBatchURLKeyName;

/** The name of the dictionary key that contains the token to the next batch of objects. */
@property (nonatomic, copy) NSString *nextBatchTokenKeyName;

/** The name of the parameter to send the value received from nextBatchTokenKeyName in. */
@property (nonatomic, copy) NSString *batchTokenParameterName;


/** The name of the object key containing a unique id. */
@property (nonatomic, copy) NSString *objectIdKeyName;

/** The string containing all the readonly object keys separated by semi-colons. All keys specified here will not be updated during an object update operation. */
@property (nonatomic, copy) NSString *readOnlyKeyNames;  

/** The string containing the insert object API. */
@property (nonatomic, copy) NSString *insertObjectAPI;

/**
 *  The HTTP method used for INSERT operations. Default: @"POST".
 */
@property (nonatomic, copy) NSString *insertHTTPMethod;

/** The dictionary of insert object parameters. */
@property (nonatomic, strong, readonly) NSMutableDictionary *insertObjectParameters;

/** The string containing the update object API. */
@property (nonatomic, copy) NSString *updateObjectAPI;

/**
 *  The HTTP method used for UPDATE operations. Default: @"PUT".
 */
@property (nonatomic, copy) NSString *updateHTTPMethod;

/** The dictionary of update object parameters. */
@property (nonatomic, strong, readonly) NSMutableDictionary *updateObjectParameters;

/** The string containing the delete object API. */
@property (nonatomic, copy) NSString *deleteObjectAPI;

/** The dictionary of delete object parameters. */
@property (nonatomic, strong, readonly) NSMutableDictionary *deleteObjectParameters;


//////////////////////////////////////////////////////////////////////////////////////////
/// @name Authorization Methods
//////////////////////////////////////////////////////////////////////////////////////////

/**
 Sets the "Authorization" HTTP header to a HTTP basic authentication value with Base64-encoded username and password. This overwrites any existing value for this header.
 
 @param username The HTTP basic auth username
 @param password The HTTP basic auth password
 */
- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password;

/**
 Sets the "Authorization" HTTP header to a token-based authentication value, such as an OAuth access token. This overwrites any existing value for this header.
 
 @param token The authentication token
 */
- (void)setAuthorizationHeaderWithToken:(NSString *)token;

/**
 Clears any existing value for the "Authorization" HTTP header.
 */
- (void)clearAuthorizationHeader;

@end
