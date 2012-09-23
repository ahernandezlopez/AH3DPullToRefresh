# AH3DPullRefresh #

AH3DPullRefresh is a simple iOS control to add a pull to refresh and/or a pull to load more to UITableView with a cool 3D effect.

![Animated screenshot :-)](https://raw.github.com/ahernandezlopez/AH3DPullToRefresh/master/Screenshots/animation.gif)

## Overview ##

The AH3DPullRefresh UI component is a BSD-licensed iOS addition to UITableView that lets you integrate easily a pull to refresh and/or a pull to load more interaction/s with a unfolding 3d animation. It works on iPhone and iPad and has been tested on iOS 4 & 5, but should work on earlier and later versions of iOS.

I created this component just to try with Objective-C runtime's associated objects and CA3DTransforms :-) Feel free to use, modify and distribute this code. Pull requests are welcome ;-)

## Usage ##

1) Copy UIScrollView+AH3DPullRefresh.h & UIScrollView+AH3DPullRefresh.m into your project.

2) Add the framework QuartzCore.framework in order to be linked into your build

3) Wherever you want to add the component to a UITableView:
	
	#import "UIScrollView+AH3DPullRefresh.h"
	
4a) Set a handler to the table view that will be fired when the pull to refresh view is triggered:

	[_tableView setPullToRefreshHandler:^{
		// Handler code: WebService call, CoreData fetch,...
    }];

4b) Set a handled to the table view that will be fired when the pull to load more view is triggered:

	[_tableView setPullToLoadMoreHandler:^{
		// Handler code: WebService call, CoreData fetch,...
	}];
	
5) (Optional) Customize the pull to refresh view and/or the pull to load more view.

## Non-ARC ##

This project does NOT use ARC. If you are using ARC in your project, add '-fno-objc-arc' as a compiler flag for UIScrollView+AH3DPullRefresh.m

## To-do ##

- Refactor the code. The code has become too big, so next step is splitting the pullable view and the scrollview category.
- Add more customization to the component. Add probably direct access to the component and make easy subclassing.

## Credits ##

Thanks to the initial code inspiration from SVPullToRefresh (http://github.com/samvermette/SVPullToRefresh) by Sam Vernette and http://b2cloud.com.au/how-to-guides/ios-perspective-transform by Tom from B2Cloud.

## Contact ##

- Twitter: [@ahernandezlopez](http://twitter.com/ahernandezlopez)
- E-mail: [albert.hernandez@gmail.com](mailto:albert.hernandez@gmail.com)