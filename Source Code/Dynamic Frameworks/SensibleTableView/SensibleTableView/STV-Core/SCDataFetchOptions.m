/*
 *  SCDataFetchOptions.m
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

#import "SCDataFetchOptions.h"


@implementation SCDataFetchOptions

@synthesize sort = _sort;
@synthesize sortKey = _sortKey;
@synthesize sortAscending = _sortAscending;
@synthesize filter = _filter;
@synthesize filterPredicate = _filterPredicate;
@synthesize batchSize = _batchSize;
@synthesize batchStartingOffset = _batchStartingOffset;
@synthesize batchCurrentOffset = _batchCurrentOffset;

+ (instancetype)options
{
    return [[[self class] alloc] init];
}

+ (instancetype)optionsWithSortKey:(NSString *)key sortAscending:(BOOL)ascending filterPredicate:(NSPredicate *)predicate
{
    return [[[self class] alloc] initWithSortKey:key sortAscending:ascending filterPredicate:predicate];
}


- (instancetype)init
{
	if( (self = [super init]) )
	{
        _sort = FALSE;
        _sortKey = nil;
        _sortAscending = TRUE;
        _filter = TRUE;
        _filterPredicate = nil;
        _batchSize = 0;
        _batchStartingOffset = 0;
        _batchCurrentOffset = 0;
	}
	return self;
}

- (instancetype)initWithSortKey:(NSString *)key sortAscending:(BOOL)ascending filterPredicate:(NSPredicate *)predicate
{
    if( (self = [self init]) )
    {
        if(key)
        {
            _sort = TRUE;
            _sortKey = key;
            _sortAscending = ascending;
        }
        
        if(predicate)
        {
            _filter = TRUE;
            _filterPredicate = predicate;
        }
    }
    return self;
}


- (void)setSortAscending:(BOOL)sortAscending
{
    _sortAscending = sortAscending;
    _sort = TRUE;
}

- (void)setBatchStartingOffset:(NSUInteger)offset
{
    _batchStartingOffset = offset;
    
    if(_batchStartingOffset > _batchCurrentOffset)
        _batchCurrentOffset = _batchStartingOffset;
}

- (NSArray *)sortDescriptors
{
    NSMutableArray *descriptors = [NSMutableArray array];
    
    if(self.sortKey)
    {
        NSArray *sortKeys = [self.sortKey componentsSeparatedByString:@";"];
        for(NSString *key in sortKeys)
        {
            NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:key ascending:self.sortAscending];
            [descriptors addObject:descriptor];
        }
    }
    
    return descriptors;
}

- (void)sortMutableArray:(NSMutableArray *)array
{
    if(self.sort && self.sortKey)
    {
        @try 
        {
            [array sortUsingDescriptors:[self sortDescriptors]];
        }
        @catch (NSException * e) 
        {
            SCDebugLog(@"Warning: Invalid sort key: %@.", self.sortKey);
        }
    }
}

- (void)filterMutableArray:(NSMutableArray *)array
{
    if(self.filterPredicate)
    {
        @try 
        {
            [array filterUsingPredicate:self.filterPredicate];
        }
        @catch (NSException * e) 
        {
            SCDebugLog(@"Warning: Invalid filter predicate: %@.", self.filterPredicate);
        }
    }
}

- (void)setBatchOffset:(NSUInteger)offset
{
    _batchCurrentOffset = offset;
}

- (void)incrementBatchOffset
{
    _batchCurrentOffset += 1;
}

- (void)resetBatchOffset
{
    _batchCurrentOffset = _batchStartingOffset;
}

- (NSUInteger)nextBatchStartIndex
{
    return self.batchSize*self.batchCurrentOffset + self.batchStartingOffset;
}

@end


