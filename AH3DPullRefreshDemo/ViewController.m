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

#import "ViewController.h"

#import "UIScrollView+AH3DPullRefresh.h"

#define kDataArray [NSArray arrayWithObjects:@"Ate", @"Bacchus Moon", @"Bel'Shir", @"Bivouac", @"Brutus", @"Canis", @"Chanuk", @"Dark moon", @"Edis", @"Ehlna", @"Ender", @"Eris", @"Gohbus Moon", @"Haji", @"Hermes", @"Kaldir", @"Luna", @"Monlyth", @"Orson", @"Paralta Moon", @"Pyramus", @"Roxara's moon", @"Saalok", @"Sue", @"Thisby", @"Thunis", @"Treason", @"Ulaan", @"Ursa", @"Urthos III", @"Valhalla", @"Vito", @"Worthing", nil]
#define kRowsInitSize 21

@interface ViewController (Private)

- (void)dataDidRefresh:(NSArray *)data;
- (void)dataDidLoadMore:(NSArray *)data;

@end

// --------------------------------------------------------------------------------
#pragma mark -

@implementation ViewController

@synthesize tableView = _tableView;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Init the rows content
    _rows = [[NSMutableArray alloc] initWithCapacity:kRowsInitSize];
    for (NSUInteger i = 0; i < kRowsInitSize; i++) {
        [_rows addObject:[kDataArray objectAtIndex:rand()%33]];
    }
    
    // Set the pull to refresh handler block
    [_tableView setPullToRefreshHandler:^{
        
        /**
         Note: Here you should deal perform a webservice request, CoreData query or 
         whatever instead of this dummy code ;-)
         */
        NSArray * newRows = [NSArray arrayWithObjects:
                             [kDataArray objectAtIndex:rand()%33],
                             [kDataArray objectAtIndex:rand()%33], nil];
        [self performSelector:@selector(dataDidRefresh:) withObject:newRows afterDelay:5.0];
    }];
    
    // Set the pull to laod more handler block
    [_tableView setPullToLoadMoreHandler:^{
        
        /**
         Note: Here you should deal perform a webservice request, CoreData query or 
         whatever instead of this dummy code ;-)
         */
        NSArray * newRows = [NSArray arrayWithObjects:
                             [kDataArray objectAtIndex:rand()%33],
                             [kDataArray objectAtIndex:rand()%33], nil];
        [self performSelector:@selector(dataDidLoadMore:) withObject:newRows afterDelay:5.0];
    }];
    
    // Customization of the pull refresh view (optional). Uncomment to try ;-)
//    [_tableView setPullToRefreshViewBackgroundColor:[UIColor colorWithRed:0.1 green:0.3 blue:1.0 alpha:1.0]];
//    [[_tableView pullToRefreshLabel] setTextColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
//    [_tableView setPullToRefreshViewActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//    [_tableView setPullToRefreshViewLoadedText:@"Locked and loaded!"];
//    [_tableView setPullToRefreshViewLoadingText:@"Let me think..."];
//    [_tableView setPullToRefreshViewPullingText:@"A little bit more..."];
//    [_tableView setPullToRefreshViewReleaseText:@"NOW!"];
    
    // Customization of the pull to load more view (optional). Uncomment to try ;-)
//    [_tableView setPullToLoadMoreViewBackgroundColor:[UIColor colorWithRed:0.1 green:0.3 blue:1.0 alpha:1.0]];
//    [[_tableView pullToLoadMoreLabel] setTextColor:[UIColor colorWithWhite:1.0 alpha:1.0]];
//    [_tableView setPullToLoadMoreViewActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//    [_tableView setPullToLoadMoreViewLoadedText:@"Locked and loaded!"];
//    [_tableView setPullToLoadMoreViewLoadingText:@"Let me think..."];
//    [_tableView setPullToLoadMoreViewPullingText:@"A little bit more..."];
//    [_tableView setPullToLoadMoreViewReleaseText:@"NOW!"];
}

- (void)viewDidUnload {
    
    [super viewDidUnload];
    
    self.tableView = nil;
    [_rows release];
    _rows = nil;
}

- (void)dealloc {
    
    self.tableView = nil;
    [_rows release];
    _rows = nil;
    
    [super dealloc];
}

#pragma mark - Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return YES;
}

#pragma mark - Public methods

- (IBAction)refreshButtonPressed:(id)sender {
    
    [_tableView pullToRefresh];
}

- (IBAction)loadMoreButtonPressed:(id)sender {
    
    [_tableView pullToLoadMore];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [_rows count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Cell reuse
    static NSString * cellIdentifier = @"Cell";
    
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    }
    
    // Cell customization
    UIView * bgView = [[UIView alloc] initWithFrame:cell.frame];
    [bgView setBackgroundColor:[UIColor whiteColor]];
    [cell setBackgroundView:bgView];
    [bgView release];
    
    [[cell textLabel] setBackgroundColor:[UIColor clearColor]];
    [[cell textLabel] setText:[_rows objectAtIndex:indexPath.row]];
    
    return cell;
}

#pragma mark - Private methods

- (void)dataDidRefresh:(NSArray *)data {
    
    // Warn the table view that the refresh did finish
    [_tableView refreshFinished];
    
    // Insert the objects at the first positions in the rows array
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [data count])];
    [_rows insertObjects:data atIndexes:indexSet];
    
    // Obtain the index paths where to insert the rows in the table view
    NSMutableArray * indexPaths = [[NSMutableArray alloc] initWithCapacity:[data count]];
    for (NSUInteger i = 0; i < [data count]; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }

    // Insert the new data in the table view
    [_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    [indexPaths release];
}

- (void)dataDidLoadMore:(NSArray *)data {
    
//    // Warn the table view that the refresh did finish
//    [_tableView loadMoreFinished];
//    
//    // Insert the objects at the first positions in the rows array
//    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [data count])];
//    [_rows insertObjects:data atIndexes:indexSet];
//    
//    // Obtain the index paths where to insert the rows in the table view
//    NSMutableArray * indexPaths = [[NSMutableArray alloc] initWithCapacity:[data count]];
//    for (NSUInteger i = 0; i < [data count]; i++) {
//        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
//    }
//    
//    // Insert the new data in the table view
//    [_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
//    [indexPaths release];
    
    // Warn the table view that the refresh did finish
    [_tableView loadMoreFinished];
    
    // Insert the objects at the first positions in the rows array
    NSUInteger iniRowsCount = [_rows count];
    NSIndexSet * indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(iniRowsCount, [data count])];
    [_rows insertObjects:data atIndexes:indexSet];
    
    // Obtain the index paths where to insert the rows in the table view
    NSMutableArray * indexPaths = [[NSMutableArray alloc] initWithCapacity:[data count]];
    for (NSUInteger i = iniRowsCount; i < [_rows count]; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    
    // Insert the new data in the table view
    [_tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    [indexPaths release];

}


@end
