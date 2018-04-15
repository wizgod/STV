/*
 *  SCPullToRefreshView.m
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


#import "SCPullToRefreshView.h"


#define kOffsetRange    65.0f


@interface SCPullToRefreshView ()

- (void)setState:(SCPullToRefreshViewState)state;

@end



@implementation SCPullToRefreshView

@synthesize state = _state;
@synthesize stateLabel = _stateLabel;
@synthesize detailTextLabel = _detailTextLabel;
@synthesize activityIndicator = _activityIndicator;
@synthesize pullStateText = _pullStateText;
@synthesize loadingStateText = _loadingStateText;
@synthesize releaseStateText = _releaseStateText;
@synthesize arrowImageView = _arrowImageView;


- (instancetype)init
{
    if( (self=[super init]) )
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor colorWithRed:226.0/255.0 green:231.0/255.0 blue:237.0/255.0 alpha:1.0];
        
        _boundScrollView = nil;
        _target = nil;
        _startLoadingAction = nil;
        
        _pullStateText = NSLocalizedString(@"Pull down to refresh", @"Pull down to refresh text");
        _releaseStateText = NSLocalizedString(@"Release to refresh", @"Release to refresh text");
        _loadingStateText = NSLocalizedString(@"Loading...", @"Loading... text");
        
        _state = SCPullToRefreshViewStatePull;
        
        _stateLabel = [[UILabel alloc] init];
        _stateLabel.text = _pullStateText;
        _stateLabel.textColor = [UIColor colorWithRed:87.0/255.0 green:108.0/255.0 blue:137.0/255.0 alpha:1.0];
        _stateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_stateLabel.font = [UIFont boldSystemFontOfSize:13.0f];
		_stateLabel.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		_stateLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_stateLabel.backgroundColor = [UIColor clearColor];
		_stateLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_stateLabel];
        
        _detailTextLabel = [[UILabel alloc] init];
        _detailTextLabel.textColor = [UIColor colorWithRed:87.0/255.0 green:108.0/255.0 blue:137.0/255.0 alpha:1.0];
        _detailTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_detailTextLabel.font = [UIFont systemFontOfSize:12.0f];
		_detailTextLabel.shadowColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
		_detailTextLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		_detailTextLabel.backgroundColor = [UIColor clearColor];
		_detailTextLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_detailTextLabel];
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.hidesWhenStopped = TRUE;
        [self addSubview:_activityIndicator];
        
        _arrowImageView = [[UIImageView alloc] init];
        _arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_arrowImageView];
    }
    return self;
}

// overrides superclass
- (void)drawRect:(CGRect)rect
{	
	CGFloat strokeOffset = 0.5f;
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextDrawPath(context,  kCGPathFillStroke);
	UIColor *strokeColor = [UIColor colorWithRed:160.0/255.0 green:173.0/255.0 blue:182.0/255.0 alpha:1.0];
	[strokeColor setStroke];
	CGContextSetLineWidth(context, 1.0f);
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 0.0f, self.bounds.size.height - strokeOffset);
	CGContextAddLineToPoint(context, self.bounds.size.width, self.bounds.size.height - strokeOffset);
	CGContextStrokePath(context);
}

- (void)bindToScrollView:(UIScrollView *)scrollView
{
    _boundScrollView = scrollView;
       
    self.frame = CGRectMake(scrollView.frame.origin.x, 0.0f - scrollView.frame.size.height, scrollView.frame.size.width, scrollView.frame.size.height);
    
    _stateLabel.frame = CGRectMake(0.0f, scrollView.frame.size.height - 48.0f, self.frame.size.width, 20.0f);
    _detailTextLabel.frame = CGRectMake(0.0f, scrollView.frame.size.height - 30.0f, self.frame.size.width, 20.0f);
    _activityIndicator.frame = CGRectMake(25.0f, scrollView.frame.size.height - 38.0f, 20.0f, 20.0f);
    _arrowImageView.frame = CGRectMake(25.0f, scrollView.frame.size.height - 65.0f, 30.0f, 55.0f);
}

- (void)setTarget:(id)target forStartLoadingAction:(SEL)action
{
    _target = target;
    _startLoadingAction = action;
}

- (void)setPullStateText:(NSString *)pullStateText
{
    _pullStateText = [pullStateText copy];
    
    if(self.state == SCPullToRefreshViewStatePull)
        self.stateLabel.text = _pullStateText;
}

- (void)boundScrollViewDidScroll
{
    if (_boundScrollView.isDragging) 
    {
        CGFloat yOffset = _boundScrollView.contentOffset.y;
        
		if ( (self.state==SCPullToRefreshViewStateRelease) && yOffset>-kOffsetRange && yOffset<0.0f) 
        {
            [self setState:SCPullToRefreshViewStatePull];
		} 
        else 
            if (self.state == SCPullToRefreshViewStatePull && yOffset<-kOffsetRange) 
            {
                [self setState:SCPullToRefreshViewStateRelease];
            }
	}
}

- (void)boundScrollViewDidEndDragging
{
    if (_target && _boundScrollView.contentOffset.y <= -kOffsetRange && self.state!=SCPullToRefreshViewStateLoading) 
    {
		[self setState:SCPullToRefreshViewStateLoading];
        
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.2];
		_boundScrollView.contentInset = UIEdgeInsetsMake(60.0f, 0.0f, 0.0f, 0.0f);
		[UIView commitAnimations];
	}
}

- (void)boundScrollViewDidFinishLoading
{
    [self setState:SCPullToRefreshViewStatePull];
    
    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:.3];
	[_boundScrollView setContentInset:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f)];
	[UIView commitAnimations];
}

- (void)setState:(SCPullToRefreshViewState)state
{
    switch (state) 
    {
		case SCPullToRefreshViewStatePull:
			
			self.stateLabel.text = self.pullStateText;
			[self.activityIndicator stopAnimating];
			self.arrowImageView.hidden = NO;
            
            CGFloat duration = 0.2f;
            if(_state == SCPullToRefreshViewStateLoading)
                duration = 0.0f;
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:duration];
            self.arrowImageView.transform = CGAffineTransformMakeRotation(0.0f);
            [UIView commitAnimations];
			
			break;
        case SCPullToRefreshViewStateRelease:
            self.stateLabel.text = self.releaseStateText;
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:0.2];
            self.arrowImageView.transform = CGAffineTransformMakeRotation((M_PI / 180.0f) * 180.0f);
            [UIView commitAnimations];
			
            
			break;
		case SCPullToRefreshViewStateLoading:
			
            self.arrowImageView.hidden = YES;
			self.stateLabel.text = self.loadingStateText;
			[self.activityIndicator startAnimating];
			
            // delay to guarantee exit from this method
            [_target performSelector:_startLoadingAction withObject:nil afterDelay:0.01f];
            
			break;
    }
    
    _state = state;
}

@end



