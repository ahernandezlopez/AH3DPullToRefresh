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

#import <UIKit/UIKit.h>

@class AHPullToRefreshView;

@interface UIScrollView (AH3DPullRefresh)

@property (nonatomic, retain) AHPullToRefreshView * pullToRefreshView;
@property (nonatomic, retain) AHPullToRefreshView * pullToLoadMoreView;

#pragma mark - Init

/**
 Sets the pull to refresh handler. Call this method to initialize the pull to refresh view.
 @param handler The block to be executed when the pull to refresh view is pulled and released.
 */
- (void)setPullToRefreshHandler:(void (^)(void))handler;

/**
 Sets the pull to load more handler. Call this method to initialize the pull to load more view.
 @param handler The block to be executed when the pull to load more view is pulled and released.
 */
- (void)setPullToLoadMoreHandler:(void (^)(void))handler;

#pragma mark - Action

/**
 Pulls the scrollview to the top in order to refresh the contents.
 The intented use of this method is to pull refresh programatically.
 */
- (void)pullToRefresh;

/**
 Pulls the scrollview to the bottom in order to load more contents.
 The intented use of this methos is to pull to load more programmatically.
 */
- (void)pullToLoadMore;

/**
 Hides the pull refresh view. Use it to notify the pull refresh view that the content have been refreshed. 
 */
- (void)refreshFinished;

/**
 Hides the pull to load more view. Use it to notify the pull to load more view that the content have been refreshed. 
 */
- (void)loadMoreFinished;

#pragma mark - Customization

/**
 Returns the pull to refresh label.
 @return the pull to refresh label.
 */
- (UILabel *)pullToRefreshLabel;

/**
 Sets the pull to refresh view's background color. Default: white.
 @param backgroundColor The background color.
 */
- (void)setPullToRefreshViewBackgroundColor:(UIColor *)backgroundColor;

/**
 Sets the activity indicator style of the pull to refresh view.
 @param style The activity indicator style.
 */
- (void)setPullToRefreshViewActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style;

/**
 Sets the text when pulling the pull to refresh view.
 Default: NSLocalizedString(@"Continue pulling to refresh",@"")
 @param pullingText The text to display when pulling the view.
 */
- (void)setPullToRefreshViewPullingText:(NSString *)pullingText;

/**
 Sets the text when the pull to refresh view is pulled to the maximum to suggest the user release to refresh.
 Default: NSLocalizedString(@"Release to refresh",@"")
 @param releaseText The text to display to suggest the user release the scrollview.
 */
- (void)setPullToRefreshViewReleaseText:(NSString *)releaseText;

/**
 Sets the text when the pull to refresh view has been released to tell the user that the content is being loaded.
 Default: NSLocalizedString(@"Loading...",@"")
 @param loadingText The text to display while refreshing.
 */
- (void)setPullToRefreshViewLoadingText:(NSString *)loadingText;

/**
 Sets the text when the pull to refresh view has finished loading.
 Default: NSLocalizedString(@"Loaded!",@"")
 @param loadedText The text to display when the contents has been refreshed.
 */
- (void)setPullToRefreshViewLoadedText:(NSString *)loadedText;

/**
 Returns the pull to load more label.
 @return the pull to load more label.
 */
- (UILabel *)pullToLoadMoreLabel;

/**
 Sets the pull to load more view's background color. Default: white.
 @param backgroundColor The background color.
 */
- (void)setPullToLoadMoreViewBackgroundColor:(UIColor *)backgroundColor;

/**
 Sets the activity indicator style of the pull to load more view.
 @param style The activity indicator style.
 */
- (void)setPullToLoadMoreViewActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style;

/**
 Sets the text when pulling the pull to load more view.
 Default: NSLocalizedString(@"Continue pulling to refresh",@"")
 @param pullingText The text to display when pulling the view.
 */
- (void)setPullToLoadMoreViewPullingText:(NSString *)pullingText;

/**
 Sets the text when the pull to load more view is pulled to the maximum to suggest the user release to refresh.
 Default: NSLocalizedString(@"Release to refresh",@"")
 @param releaseText The text to display to suggest the user release the scrollview.
 */
- (void)setPullToLoadMoreViewReleaseText:(NSString *)releaseText;

/**
 Sets the text when the pull to load more view has been released to tell the user that the content is being loaded.
 Default: NSLocalizedString(@"Loading...",@"")
 @param loadingText The text to display while refreshing.
 */
- (void)setPullToLoadMoreViewLoadingText:(NSString *)loadingText;

/**
 Sets the text when the pull to load more view has finished loading.
 Default: NSLocalizedString(@"Loaded!",@"")
 @param loadedText The text to display when the contents has been refreshed.
 */
- (void)setPullToLoadMoreViewLoadedText:(NSString *)loadedText;

@end
