/*
 *  SCWebServiceDefinition.m
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


#import "SCWebServiceDefinition.h"

#import "SCWebServiceFetchOptions.h"
#import "SCArrayOfObjectsSection+WebServices.h"
#import "SCWebServiceStore.h"



@interface SCWebServiceDefinition ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *httpHeaders;
@property (nonatomic, strong, readwrite) NSMutableDictionary *insertObjectParameters;
@property (nonatomic, strong, readwrite) NSMutableDictionary *updateObjectParameters;
@property (nonatomic, strong, readwrite) NSMutableDictionary *deleteObjectParameters;

@end




@implementation SCWebServiceDefinition


+ (instancetype)definitionWithBaseURL:(NSString *)baseURL fetchObjectsAPI:(NSString *)api resultsKeyName:(NSString *)resultsKey resultsDictionaryKeyNamesString:(NSString *)keyNamesString
{
    return [[[self class] alloc] initWithBaseURL:baseURL fetchObjectsAPI:api resultsKeyName:resultsKey resultsDictionaryKeyNamesString:keyNamesString];
}

+ (instancetype)definitionWithBaseURL:(NSString *)baseURL fetchObjectsAPI:(NSString *)api resultsKeyName:(NSString *)resultsKey resultsDictionaryKeyNames:(NSArray *)keyNames
{
    return [[[self class] alloc] initWithBaseURL:baseURL fetchObjectsAPI:api resultsKeyName:resultsKey resultsDictionaryKeyNames:keyNames];
}


- (instancetype)init
{
	if( (self = [super init]) )
	{
        _baseURL = nil;
        
        _httpHeaders = [[NSMutableDictionary alloc] init];
        _insertHTTPMethod = @"POST";
        _updateHTTPMethod = @"PUT";
        _fetchObjectsParameters = [[NSMutableDictionary alloc] init];
        _insertObjectParameters = [[NSMutableDictionary alloc] init];
        _updateObjectParameters = [[NSMutableDictionary alloc] init];
        _deleteObjectParameters = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (instancetype)initWithBaseURL:(NSString *)baseURL fetchObjectsAPI:(NSString *)api resultsKeyName:(NSString *)resultsKey resultsDictionaryKeyNamesString:(NSString *)keyNamesString
{
    if( (self = [self initWithDictionaryKeyNamesString:keyNamesString]) )
	{
        self.baseURL = [NSURL URLWithString:baseURL];
        self.fetchObjectsAPI = api;
        self.resultsKeyName = resultsKey;
    }
    return self;
}

- (instancetype)initWithBaseURL:(NSString *)baseURL fetchObjectsAPI:(NSString *)api resultsKeyName:(NSString *)resultsKey resultsDictionaryKeyNames:(NSArray *)keyNames
{
    if( (self = [self initWithDictionaryKeyNames:keyNames]) )
	{
        self.baseURL = [NSURL URLWithString:baseURL];
        self.fetchObjectsAPI = api;
        self.resultsKeyName = resultsKey;
    }
    return self;
}


- (NSString *)baseURLString
{
    return [self.baseURL absoluteString];
}

- (void)setBaseURLString:(NSString *)baseURLString
{
    self.baseURL = [NSURL URLWithString:[baseURLString copy]];
}

- (NSURL *)insertURL
{
    if(!self.baseURL || !self.insertObjectAPI)
        return nil;
    
    return [NSURL URLWithString:self.insertObjectAPI relativeToURL:self.baseURL];
}

- (NSURL *)updateURL
{
    if(!self.baseURL || !self.updateObjectAPI)
        return nil;
    
    return [NSURL URLWithString:self.updateObjectAPI relativeToURL:self.baseURL];
}

- (NSURL *)deleteURL
{
    if(!self.baseURL || !self.deleteObjectAPI)
        return nil;
    
    return [NSURL URLWithString:self.deleteObjectAPI relativeToURL:self.baseURL];
}

- (void)setHttpHeaders:(NSMutableDictionary *)httpHeaders
{
    // Ensure any httpHeaders inserted by our plugin is an NSMutableDictionary instance (not NSDictionary)
    _httpHeaders = [NSMutableDictionary dictionaryWithDictionary:httpHeaders];
}

- (void)setInsertObjectParameters:(NSMutableDictionary *)insertObjectParameters
{
    // Ensure any insertObjectParameters inserted by our plugin is an NSMutableDictionary instance (not NSDictionary)
    _insertObjectParameters = [NSMutableDictionary dictionaryWithDictionary:insertObjectParameters];
}

- (void)setUpdateObjectParameters:(NSMutableDictionary *)updateObjectParameters
{
    // Ensure any updateObjectParameters inserted by our plugin is an NSMutableDictionary instance (not NSDictionary)
    _updateObjectParameters = [NSMutableDictionary dictionaryWithDictionary:updateObjectParameters];
}

- (void)setDeleteObjectParameters:(NSMutableDictionary *)deleteObjectParameters
{
    // Ensure any deleteObjectParameters inserted by our plugin is an NSMutableDictionary instance (not NSDictionary)
    _deleteObjectParameters = [NSMutableDictionary dictionaryWithDictionary:deleteObjectParameters];
}

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password
{
	NSString *credentials = [NSString stringWithFormat:@"%@:%@", username, password];
    NSString *encodedCredentials = [SCUtilities base64EncodedStringFromString:credentials];
    [self.httpHeaders setValue:[NSString stringWithFormat:@"Basic %@", encodedCredentials] forKey:@"Authorization"];
}

- (void)setAuthorizationHeaderWithToken:(NSString *)token
{
    [self.httpHeaders setValue:[NSString stringWithFormat:@"Token token=\"%@\"", token] forKey:@"Authorization"];
}

- (void)clearAuthorizationHeader
{
	[self.httpHeaders removeObjectForKey:@"Authorization"];
}


// overrides superclass
- (SCDataStore *)generateCompatibleDataStore
{
    return [SCWebServiceStore storeWithDefaultWebServiceDefinition:self];
}

// overrides superclass
- (SCDataFetchOptions *)generateCompatibleDataFetchOptions
{
    SCWebServiceFetchOptions *webServiceFetchOptions = [[SCWebServiceFetchOptions alloc] init];
    webServiceFetchOptions.sortKey = self.keyPropertyName;
    
    return webServiceFetchOptions;
}




@end
