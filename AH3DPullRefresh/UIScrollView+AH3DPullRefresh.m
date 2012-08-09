/**
 Copyright (c) 2012 Albert Hernández López <albert.hernandez@gmail.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is furnished
 to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "UIScrollView+AH3DPullRefresh.h"

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

// --------------------------------------------------------------------------------
#pragma mark - Helpers

#define AHRelease(object) [object release]; object = nil
#define CATransform3DPerspective(t, x, y) (CATransform3DConcat(t, CATransform3DMake(1, 0, 0, x, 0, 1, 0, y, 0, 0, 1, 0, 0, 0, 0, 1)))
#define CATransform3DMakePerspective(x, y) (CATransform3DPerspective(CATransform3DIdentity, x, y))

CG_INLINE CATransform3D CATransform3DMake(CGFloat m11, CGFloat m12, CGFloat m13, CGFloat m14,
                                          CGFloat m21, CGFloat m22, CGFloat m23, CGFloat m24,
                                          CGFloat m31, CGFloat m32, CGFloat m33, CGFloat m34,
                                          CGFloat m41, CGFloat m42, CGFloat m43, CGFloat m44) {
	CATransform3D t;
	t.m11 = m11; t.m12 = m12; t.m13 = m13; t.m14 = m14;
	t.m21 = m21; t.m22 = m22; t.m23 = m23; t.m24 = m24;
	t.m31 = m31; t.m32 = m32; t.m33 = m33; t.m34 = m34;
	t.m41 = m41; t.m42 = m42; t.m43 = m43; t.m44 = m44;
	return t;
}

// --------------------------------------------------------------------------------
#pragma mark - [Interface] AHPullToRefreshView

/**
 Defines the possible states of the pull to refresh view.
 */
typedef enum {
    AHPullViewStateHidden = 1,                // Not visible
	AHPullViewStateVisible,                   // Visible but won't trigger the loading if the user releases
    AHPullViewStateTriggered,                 // If the user releases the scrollview it will load
    AHPullViewStateTriggeredProgramatically,  // When triggering it programmatically
    AHPullViewStateLoading                    // Loading
} AHPullViewState;

static CGFloat const kAHPullView_ViewHeight = 60.0;

#define kAHPullView_ContentOffsetKey    @"contentOffset"
#define kAHPullView_FrameKey            @"frame"

@interface AHPullToRefreshView : UIView {
    
    AHPullViewState _state;                         // Current state

    UIScrollView * _scrollView;                     // The linked scrollview
    BOOL _isObservingScrollView;                    // If it's observing (KVO) the scrollview
    UIEdgeInsets _originalScrollViewContentInset;   // The original content inset of the scrollview
    
    UIColor * _backgroundColor;                     // The view's background color
    
    UIView * _backgroundView;                       // The background view
    UIView * _shadowView;                           // The view that applies the shadow (black with changing alpha)
    UILabel * _label;                               // Where to display the texts depending on the state
    UIActivityIndicatorView * _activityIndicator;   // Shown while loading
    
    NSString * _pullingText;
    NSString * _releaseText;
    NSString * _loadingText;
    NSString * _loadedText;
}

@property (nonatomic, assign) BOOL isObservingScrollView;   // If it's observing (KVO) the scrollview

@property (nonatomic, retain) UILabel * label;

@property (nonatomic, retain) NSString * pullingText;       // Displayed in _label while pulling
@property (nonatomic, retain) NSString * releaseText;       // Displayed in _label before releasing
@property (nonatomic, retain) NSString * loadingText;       // Displayed in _label while loading
@property (nonatomic, retain) NSString * loadedText;        // Displayed in _label when loading did finish

@property (nonatomic, copy) void (^pullHandler)(void);      // The block executed when triggering

/**
 Initializes the view with the linked scrollview.
 @param scrollView The scrollview where to apply the pull refresh view.
 */
- (id)initWithScrollView:(UIScrollView *)scrollView;

/**
 Pulls the scrollview to refresh the contents, scrolling it up.
 The intented use of this method is to pull refresh programatically.
 */
- (void)pullToRefresh;

/**
 Hides the pull refresh view. Use it to notify the pull refresh view that the content have been refreshed. 
 */
- (void)refreshFinished;

/**
 Sets the background color.
 @param backgroundColor the background color.
 */
- (void)setBackgroundColor:(UIColor *)backgroundColor;

/**
 Sets the activity indicator style, displayed while loading.
 @param style the activity indicator style.
 */
- (void)setActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style;

@end

// --------------------------------------------------------------------------------
#pragma mark - [Interface] AHPullToRefreshView (Private)

@interface AHPullToRefreshView (Private)

- (void)startObservingScrollView;
- (void)stopObservingScrollView;

- (void)scrollViewDidScroll:(CGPoint)contentOffset;
- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset;
- (void)setState:(AHPullViewState)state;
- (void)layoutSubviews:(NSTimer *)timer;

- (void)pullAfterScrollToTop;

@end

// --------------------------------------------------------------------------------
#pragma mark - AHPullToRefreshView

@implementation AHPullToRefreshView

@synthesize isObservingScrollView = _isObservingScrollView;

@synthesize label = _label;

@synthesize pullingText = _pullingText;
@synthesize releaseText = _releaseText;
@synthesize loadingText = _loadingText;
@synthesize loadedText = _loadedText;

@synthesize pullHandler;

#pragma mark - View lifecycle

- (id)initWithScrollView:(UIScrollView *)scrollView {
    
    self = [super initWithFrame:CGRectMake(0, -kAHPullView_ViewHeight/2, _scrollView.bounds.size.width, kAHPullView_ViewHeight)];

    if (self) {
        
        // View setup
        [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        // Ivars init
        _scrollView = scrollView;
        _originalScrollViewContentInset = [_scrollView contentInset];
        [self setBackgroundColor:[UIColor whiteColor]];

        _pullingText = [NSLocalizedString(@"Continue pulling to refresh",@"") retain];
        _releaseText = [NSLocalizedString(@"Release to refresh",@"") retain];
        _loadingText = [NSLocalizedString(@"Loading...",@"") retain];
        _loadedText = [NSLocalizedString(@"Loaded!",@"") retain];
    }
    return self;
}

- (void)dealloc {
    
    [self stopObservingScrollView];
    
    AHRelease(_backgroundView);
    AHRelease(_shadowView);
    self.label = nil;
    AHRelease(_activityIndicator);
    AHRelease(_backgroundColor);
    
    self.pullingText = nil;
    self.releaseText = nil;
    self.loadingText = nil;
    self.loadedText = nil;
    
    self.pullHandler = nil;
    
    [super dealloc];
}

#pragma mark - Public methods

- (void)pullToRefresh {

    // If the it's actually loading we avoid loading again
    if (_state != AHPullViewStateHidden) {
        return;
    }
    
    // Stop observing scrollview
    [self stopObservingScrollView];
    
    // Scroll to top
    [_scrollView scrollRectToVisible:CGRectMake(0, 0, CGRectGetWidth([_scrollView frame]), CGRectGetHeight([_scrollView frame])) animated:YES];

    
    // Set the state to triggered programmatically
    [self setState:AHPullViewStateTriggeredProgramatically];
    
    // If it's triggered programatically avoid the user interaction
    [_scrollView setScrollEnabled:NO];
        
    // The delay to prevent overlapping animations. It will be between 0.1 and 0.5 seconds
    CGFloat delay = MAX(MIN(_scrollView.contentOffset.y/CGRectGetHeight([_scrollView frame]),0.1),0.5);
    [self performSelector:@selector(pullAfterScrollToTop) withObject:nil afterDelay:delay];
    
}

- (void)refreshFinished {
    
    // Set the state to hidden with a delay
    // Note: if called programatically quickly has a visual bug that the unfolding of the 3d view remains stuck. That's why there's a delay.
    AHPullViewState state = AHPullViewStateHidden;
    SEL selector = @selector(setState:);
    NSMethodSignature *ms = [self methodSignatureForSelector:selector];
	NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:ms];
	[invocation setTarget:self];
	[invocation setSelector:selector];
	[invocation setArgument:&state atIndex:2];
	[invocation performSelector:@selector(invoke) withObject:nil afterDelay:0.3];
    
    // Show the user the scroll indicators
    [_scrollView performSelector:@selector(flashScrollIndicators) withObject:nil afterDelay:0.35];
}

- (void)setPullHandler:(void (^)(void))handler {
    
    [pullHandler release];
    pullHandler = [handler copy];
    
    // UI setup
    [_scrollView addSubview:self];
    [_scrollView sendSubviewToBack:self];
    
    _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_scrollView.frame), CGRectGetHeight(self.frame))];
    [_backgroundView.layer setAnchorPoint:CGPointMake(0.5, 1.0)];
    [self.layer addSublayer:_backgroundView.layer];
    
    _shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_scrollView.frame), CGRectGetHeight(self.frame))];
    [_shadowView.layer setAnchorPoint:CGPointMake(0.5, 1.0)];
    [self.layer addSublayer:_shadowView.layer];
    
    _label = [[UILabel alloc] initWithFrame:[_backgroundView frame]];
    _label.text = _loadedText;
    _label.font = [UIFont boldSystemFontOfSize:14];
    [_label setTextAlignment:UITextAlignmentCenter];
    _label.backgroundColor = [UIColor clearColor];
    _label.textColor = [UIColor darkGrayColor];
    [_label setCenter:_backgroundView.center];    
    [self addSubview:_label];
    
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activityIndicator.hidesWhenStopped = YES;
    [self addSubview:_activityIndicator];
    
    // Set the state to hidden
    [self setState:AHPullViewStateHidden];
}

// This method is actually an UIView override
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    
    // Set the color for the background view instead of the actual view
    [_backgroundColor release];
    _backgroundColor = [backgroundColor retain];
    [_backgroundView setBackgroundColor:_backgroundColor];
}

- (void)setActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style {

    [_activityIndicator setActivityIndicatorViewStyle:style];
}

#pragma mark - Private methods

/**
 Starts observing the scrollview if it wasn't already.
 */
- (void)startObservingScrollView {
    
    if (_isObservingScrollView) {
        return;
    }
    
    [_scrollView addObserver:self
                  forKeyPath:kAHPullView_ContentOffsetKey 
                     options:NSKeyValueObservingOptionNew
                     context:nil];
    
    [_scrollView addObserver:self
                  forKeyPath:kAHPullView_FrameKey
                     options:NSKeyValueObservingOptionNew
                     context:nil];
    
    self.isObservingScrollView = YES;
}

/**
 Stops observing the scrollview if it was observing.
 */
- (void)stopObservingScrollView {
    
    if (!_isObservingScrollView) {
        return;
    }
    
    [_scrollView removeObserver:self forKeyPath:kAHPullView_ContentOffsetKey];
    [_scrollView removeObserver:self forKeyPath:kAHPullView_FrameKey];
    
    self.isObservingScrollView = NO;
}

/**
 Called when detected changes on scrollview offset. Deals with the states.
 */
- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    
    if (pullHandler) {
        
        // If it's loading adjust the content inset
        if (_state == AHPullViewStateLoading) {
            
            CGFloat offset = MAX(_scrollView.contentOffset.y * -1, 0);
            offset = MIN(offset, _originalScrollViewContentInset.top + kAHPullView_ViewHeight);
            UIEdgeInsets edgeInsets = UIEdgeInsetsMake(offset, 0.0f, 0.0f, 0.0f);
            [_scrollView setContentInset:edgeInsets];
        }
        else {
            
            // Layout subviews when the view is becoming visible (to make the 3D transform happens)
            if (_state == AHPullViewStateVisible) {
                [self layoutSubviews];
            }
            
            // Set the state depending on the current state, if the user is dragging and the content y offset
            CGFloat scrollOffsetYThreshold = CGRectGetMinY(self.frame) * 2 - _originalScrollViewContentInset.top;
            CGFloat contentOffsetY = contentOffset.y;
            BOOL scrollViewIsDragging = [_scrollView isDragging];
            
            if ((_state == AHPullViewStateTriggered || _state == AHPullViewStateTriggeredProgramatically) && 
                !scrollViewIsDragging) {
                
                [self setState:AHPullViewStateLoading];
            }
            else if (_state != AHPullViewStateLoading &&
                     scrollViewIsDragging &&
                     contentOffsetY > scrollOffsetYThreshold &&
                     contentOffsetY < - _originalScrollViewContentInset.top) {
                
                [self setState:AHPullViewStateVisible];
            }
            else if (_state == AHPullViewStateVisible &&
                     scrollViewIsDragging &&
                     contentOffsetY < scrollOffsetYThreshold) {
                
                [self setState:AHPullViewStateTriggered];
            }
            else if (_state != AHPullViewStateHidden && 
                     contentOffsetY >= - _originalScrollViewContentInset.top) {
                
                [self setState:AHPullViewStateHidden];
            }
        }
    }
}

/**
 Sets the scroll view content inset.
 @param the scroll view content inset.
 */
- (void)setScrollViewContentInset:(UIEdgeInsets)contentInset {

    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState 
                     animations:^{
                         _scrollView.contentInset = contentInset;
                     }
                     completion:^(BOOL finished){}];
}

/**
 Sets the current state applying the corresponding UI updates.
 */
- (void)setState:(AHPullViewState)state {

    if (pullHandler) {
        [self setScrollViewContentInset:_originalScrollViewContentInset];
    } 
    
    if (_state == state)
        return;
    
    _state = state;
    
    if (pullHandler) {
        switch (_state) {
            case AHPullViewStateHidden:
                [_label setText:_loadedText];
                [_activityIndicator stopAnimating];
                [self setScrollViewContentInset:_originalScrollViewContentInset];
                break;
                
            case AHPullViewStateVisible:
                [_label setText:_pullingText];
                [self setScrollViewContentInset:_originalScrollViewContentInset];
                break;
                
            case AHPullViewStateTriggered:
                [_label setText:_releaseText];
                break;
            
            case AHPullViewStateTriggeredProgramatically:
                // Do nothing
                break;
                
            case AHPullViewStateLoading:
            {
                // Change the position of the activity indicator
                CGSize textSize = [_loadingText sizeWithFont:[_label font]];
                CGPoint activityIndicatorCenter = CGPointMake([_label center].x - textSize.width/2 - CGRectGetWidth([_activityIndicator frame]), [_label center].y);
                [_activityIndicator setCenter:activityIndicatorCenter];
                [_label setText:_loadingText];
                
                // Start animating the activity indicator
                [_activityIndicator startAnimating];
                
                // Set the new scrollview insets
                UIEdgeInsets newInsets = _originalScrollViewContentInset;
                newInsets.top = self.frame.origin.y*-1+_originalScrollViewContentInset.top;
                newInsets.bottom = _scrollView.contentInset.bottom;
                [self setScrollViewContentInset:newInsets];
                [_scrollView setContentOffset:CGPointMake(0, -self.frame.size.height) animated:YES];

                // Execute the pull handler block
                pullHandler();
                break;
            }
        }
    }
}

/**
 Called by a timer to layout the subviews periodically.
 @param timer The timer that fired this method.
 */
- (void)layoutSubviews:(NSTimer *)timer {
    
    [self layoutSubviews];
}

/**
 Called when pull refresh is called programatically, after scrolling the scrollview to top.
 */
- (void)pullAfterScrollToTop {
    
    // Start observing
    [self startObservingScrollView];
    
    // Enable the user interaction (only changes if it was triggered programmatically)
    [_scrollView setScrollEnabled:YES];
    
    // Set the state to loading
    [self setState:AHPullViewStateLoading];
    
    // Force layout subview while performing the 3d animation
    NSTimer * timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(layoutSubviews:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [timer performSelector:@selector(invalidate) withObject:nil afterDelay:0.5];
}

#pragma mark - UIView overrides

- (void)addSubview:(UIView *)view {
    
    [_backgroundView addSubview:view];
    [self bringSubviewToFront:_activityIndicator];
    [self bringSubviewToFront:_label];
    [self bringSubviewToFront:_shadowView];
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    
    if (newSuperview == _scrollView) {
        
        [self startObservingScrollView];
    }
    else if (newSuperview == nil) {
        
        [self stopObservingScrollView];
    }
}

- (void)layoutSubviews {

    [super layoutSubviews];
    
    // Subviews repositioning
    [_backgroundView setFrame:CGRectMake(0, -kAHPullView_ViewHeight/2, CGRectGetWidth(_scrollView.frame), CGRectGetHeight(self.frame))];
    [_shadowView setFrame:CGRectMake(0, -kAHPullView_ViewHeight/2, CGRectGetWidth(_scrollView.frame), CGRectGetHeight(self.frame))];
    [_label setFrame:CGRectMake(0, 0, CGRectGetWidth(_scrollView.frame), CGRectGetHeight(self.frame))];
    CGSize textSize = [_loadingText sizeWithFont:[_label font]];
    CGPoint activityIndicatorCenter = CGPointMake([_label center].x - textSize.width/2 - CGRectGetWidth([_activityIndicator frame]), [_label center].y);
    [_activityIndicator setCenter:activityIndicatorCenter];
    
    // Calculate the offset percentage (considering the height of this view * 2)
    CGFloat fraction = ((CGRectGetMinY(self.frame)*2 - _scrollView.contentOffset.y) / CGRectGetMinY(self.frame));
    fraction = MIN(MAX(fraction,0),1);
    
    // Aply the perspective transform
    CATransform3D transform = CATransform3DMakePerspective(0, 0.01 * -fraction);
    [_backgroundView.layer setTransform:transform];
    [_shadowView.layer setTransform:transform];
    
    // Set the backgroundView color
    [_backgroundView setBackgroundColor:_backgroundColor];
    
    // Calculate the alpha/brightness of the view and subviews' color with a min of 0.5
    CGFloat alpha = MIN(fraction,0.5);
    [_shadowView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:alpha]];    
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:kAHPullView_ContentOffsetKey]) {
        
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    }  
    else if ([keyPath isEqualToString:kAHPullView_FrameKey]) {
        
        [self layoutSubviews];
    }
}

@end

// --------------------------------------------------------------------------------
#pragma mark - [Interface] AHTableView (Private)

@interface UIScrollView (AHTableViewPrivate)

@property (nonatomic, assign) BOOL isPullToRefreshEnabled;

@end 

// --------------------------------------------------------------------------------
#pragma mark - AHTableView

static char kAHTV_Key_PullToRefreshView;
static char kAHTV_Key_IsPullRefreshEnabled;

@implementation UIScrollView (AH3DPullRefresh)

@dynamic pullToRefreshView;

#pragma mark - Public methods

#pragma mark > Actions

- (void)pullToRefresh {
    
    if (self.pullToRefreshView) {
        [self.pullToRefreshView pullToRefresh];
    }
}

- (void)refreshFinished {
    
    if (self.pullToRefreshView) {
        [self.pullToRefreshView refreshFinished];
    }
}

#pragma mark > Customization

- (UILabel *)pullToRefreshLabel {
    
    return [self.pullToRefreshView label];
}

- (void)setPullToRefreshViewBackgroundColor:(UIColor *)backgroundColor {
    
    [self.pullToRefreshView setBackgroundColor:backgroundColor];
}

- (void)setPullToRefreshViewActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style {
    
    [self.pullToRefreshView setActivityIndicatorStyle:style];
}

- (void)setPullToRefreshViewPullingText:(NSString *)pullingText {
    
    [self.pullToRefreshView setPullingText:pullingText];
}

- (void)setPullToRefreshViewReleaseText:(NSString *)releaseText {
    
    [self.pullToRefreshView setReleaseText:releaseText];
}

- (void)setPullToRefreshViewLoadingText:(NSString *)loadingText {
    
    [self.pullToRefreshView setLoadingText:loadingText];
}

- (void)setPullToRefreshViewLoadedText:(NSString *)loadedText {
    
    [self.pullToRefreshView setLoadedText:loadedText];
}

#pragma mark > Dynamic Ivars Getters/Setters

- (void)setPullToRefreshHandler:(void (^)(void))handler {

    // If the pull to refresh view is nil, then it's created
    if (!self.pullToRefreshView) {
        
        self.pullToRefreshView = [[[AHPullToRefreshView alloc] initWithScrollView:self] autorelease];
    }
    
    [self.pullToRefreshView setPullHandler:handler];
}

- (void)setPullToRefreshView:(AHPullToRefreshView *)aView {
    
    BOOL isEnabled = aView ? YES : NO;
    [self setIsPullToRefreshEnabled:isEnabled];
    
    objc_setAssociatedObject(self, &kAHTV_Key_PullToRefreshView, aView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (AHPullToRefreshView *)pullToRefreshView {
    
    return objc_getAssociatedObject(self, &kAHTV_Key_PullToRefreshView);
}

@end

// --------------------------------------------------------------------------------
#pragma mark - AHTableViewPrivate

@implementation UIScrollView (AHTableViewPrivate)

@dynamic isPullToRefreshEnabled;

#pragma mark - Getters/Setters

- (void)setIsPullToRefreshEnabled:(BOOL)enabled {
    
    objc_setAssociatedObject(self, &kAHTV_Key_IsPullRefreshEnabled, [NSNumber numberWithBool:enabled], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isPullToRefreshEnabled {
    
    return [objc_getAssociatedObject(self, &kAHTV_Key_IsPullRefreshEnabled) boolValue];
}

@end
