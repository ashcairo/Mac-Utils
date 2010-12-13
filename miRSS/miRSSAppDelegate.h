//
//  miRSSAppDelegate.h
//  miRSS
//
//  Created by Alex Nichol on 12/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSSFeed.h"
#import "ANRSSManager.h"
#import "RSSChannel.h"
#import "RSSChannelView.h"

@interface miRSSAppDelegate : NSObject <NSApplicationDelegate, ANRSSManagerDelegate> {
    NSWindow * window;
	IBOutlet NSWindow * addWindow;
	IBOutlet NSTextField * addURL;
	RSSChannelView * channelView;
	NSMenu * mainMenu;
	
	NSMenuItem * rssFeedsItem;
	NSMenu * rssFeedsMenu;
	NSMutableDictionary * feedMenus;
	ANRSSManager * manager;
	NSStatusItem * statusItem;

	IBOutlet NSWindow * channelsList;
	IBOutlet NSTableView * tableView;
}

- (void)updateMenu;
- (NSMenu *)createMenu;

- (void)centerWindow:(NSWindow *)_window;
- (IBAction)addDone:(id)sender;
- (IBAction)remove:(id)sender;

- (void)showFeeds:(id)sender;
- (void)addFeed:(id)sender;
- (void)showFeed:(NSMenuItem *)menu;

@property (assign) IBOutlet NSWindow * window;

@end
