//
//  miRSSAppDelegate.m
//  miRSS
//
//  Created by Alex Nichol on 12/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "miRSSAppDelegate.h"
#import "RSSChannelView.h"
#import "Debugging.h"

@implementation miRSSAppDelegate

@synthesize window;

- (BOOL)stringArray:(NSArray *)strings containsString:(NSString *)string {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	for (int i = 0; i < [strings count]; i++) {
		if ([[strings objectAtIndex:i] isEqual:string]) {
			[pool drain];
			return YES;
		}
	}
	[pool drain];
	return NO;
}

- (void)centerWindow:(NSWindow *)_window {
	NSRect frame = [[NSScreen mainScreen] frame];
	NSRect wfram = [_window frame];
	wfram.origin.x = frame.size.width / 2 - (wfram.size.width / 2);
	wfram.origin.y = frame.size.height / 2 - (wfram.size.height / 2);
	[_window setFrameOrigin:wfram.origin];
}
- (IBAction)addDone:(id)sender {
	// add done
	if (![addURL stringValue]) {
		return;
	}
	[manager addRSSURL:[addURL stringValue]];
	[self updateMenu];
	[addWindow orderOut:self];
	[tableView reloadData];
}

- (void)addFeed:(id)sender {
	//
	ProcessSerialNumber num;	
	GetCurrentProcess(&num);
	SetFrontProcess(&num);
	[self centerWindow:addWindow];
	[addWindow makeKeyAndOrderFront:self];
	[addURL setStringValue:@""];
	[addURL selectText:self];
}
- (void)showFeed:(NSMenuItem *)menu {
	//
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	if (!channelView) {
		channelView = [[RSSChannelView alloc] initWithFrame:[[window contentView] bounds]];
		[[window contentView] addSubview:channelView];
	}
	BOOL found = NO;
	
	[channelView setDelegate:self];
	
	int count = [manager channelCount];
	[manager lock];
	for (int i = 0; i < count; i++) {
		NSDictionary * dict = [manager channelAtIndex:i];
		if ([(RSSChannel *)[dict objectForKey:ANRSSManagerChannelRSSChannelKey] uniqueID] == [menu tag]) {
			found = YES;
			RSSChannel * copy = [[RSSChannel alloc] initWithChannel:[dict objectForKey:ANRSSManagerChannelRSSChannelKey]];
			for (RSSItem * item in [copy items]) {
				NSArray * check1 = [dict objectForKey:ANRSSManagerChannelReadGUIDSKey];
				if ([self stringArray:check1 containsString:[item postGuid]]) {
					[item setIsRead:YES];
				}
			}
			[channelView setChannel:copy];
			[copy release];
		}
	}
	[manager unlock];
	
	[self centerWindow:window];
	
	if (found) {
		[window makeKeyAndOrderFront:self];
	
		ProcessSerialNumber num;	
		GetCurrentProcess(&num);
		SetFrontProcess(&num);
	}
	
	[pool drain];
}

- (IBAction)remove:(id)sender {
	// remove the stuff later
	if ([tableView selectedRow] >= 0) {
		[manager removeAtIndex:[tableView selectedRow]];
		[tableView reloadData];
	}
}

- (void)showFeeds:(id)sender {
	// show the window
	[channelsList makeKeyAndOrderFront:self];
	ProcessSerialNumber num;	
	GetCurrentProcess(&num);
	SetFrontProcess(&num);
	[self centerWindow:channelsList];
	[tableView setDataSource:self];
	[tableView reloadData];
}

- (void)articlesUpdated:(id)sender {
	[self updateMenu];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	mainMenu = [self createMenu];
	
	statusItem = [[[NSStatusBar systemStatusBar]
                                   statusItemWithLength:NSSquareStatusItemLength] retain];
    [statusItem setMenu:mainMenu];
    [statusItem setHighlightMode:YES];
    [statusItem setToolTip:@"miRSS"];
    [statusItem setImage:[NSImage imageNamed:@"rss.png"]];
	
	manager = [[ANRSSManager alloc] init];
	[manager setDelegate:self];
	[manager startFetchThread];
	[manager addRSSURL:@"http://macheads101.aqnichol.com/pages/news/rss.php"];
}

- (void)updateMenu {
	// NSLog(@"Update.");
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	[tableView setDataSource:self];
	[tableView reloadData];
	
	int count = [manager channelCount];
	
	[rssFeedsMenu removeAllItems];
	[feedMenus removeAllObjects];
	
	[manager lock];
	
	// loop through
	for (int i = 0; i < count; i++) {
		NSDictionary * channeld = [manager channelAtIndex:i];
		// read the stuff
		
		RSSChannel * channel = [channeld objectForKey:ANRSSManagerChannelRSSChannelKey];
		if ([[channeld objectForKey:ANRSSManagerChannelWasModified] intValue]) {
			NSLog(@"Channel %@ was modified", [channel channelTitle]);
		}
		//int new = 0;
		NSString * title = nil;
		BOOL enabled = YES;
		if (![channel channelTitle]) {
			title = [NSString stringWithString:[channeld objectForKey:ANRSSManagerChannelURLKey]];
			enabled = NO;
		} else {
			title = [NSString stringWithString:[channel channelTitle]];
			int ncount = [manager unreadInChannelIndex:i lock:NO];
			if (ncount > 0) {
				title = [title stringByAppendingFormat:@" (%d)", ncount];
			}
		}
		
		if (title) {
			NSMenuItem * item = [rssFeedsMenu addItemWithTitle:title
													action:@selector(showFeed:)
											 keyEquivalent:@""];
			[item setTag:[channel uniqueID]];
			if (enabled)
				[item setTarget:self];
			else {
				[item setTarget:nil];
				[item setAction:0];
			}
			[item setEnabled:enabled];
			if (channel)
				[feedMenus setObject:channel forKey:item];
		}
	}
	
	[manager unlock];
	
	[mainMenu setSubmenu:rssFeedsMenu forItem:rssFeedsItem];
	[statusItem setMenu:nil];
	[statusItem setMenu:mainMenu];
	
	[pool drain];
	
	
}

- (NSMenu *)createMenu {
	feedMenus = [[NSMutableDictionary alloc] init];
    NSZone * menuZone = [NSMenu menuZone];
    NSMenu * menu = [[NSMenu allocWithZone:menuZone] init];
    NSMenuItem * menuItem;
	
    // Add To Items
    menuItem = [menu addItemWithTitle:@"Add Feed"
                               action:@selector(addFeed:)
                        keyEquivalent:@""];
	[menuItem setTarget:self];
	
	menuItem = [menu addItemWithTitle:@"Edit Feeds"
                               action:@selector(showFeeds:)
                        keyEquivalent:@""];
	[menuItem setTarget:self];
	
	rssFeedsItem = [menu addItemWithTitle:@"Feeds"
                               action:@selector(showFeed:)
                        keyEquivalent:@""];
    [rssFeedsItem setTarget:self];
	[rssFeedsItem setEnabled:YES];
	
	// create the submenu
	rssFeedsMenu = [[NSMenu alloc] initWithTitle:@"Feeds"];
	//[rssFeedsItem setMenu:menu];
	
	menuItem = [menu addItemWithTitle:@"Quit"
                               action:@selector(terminate:)
                        keyEquivalent:@""];
    [menuItem setTarget:[NSApplication sharedApplication]];
	
    return menu;
}

#pragma mark Table View Methods

- (long)numberOfRowsInTableView:(NSTableView *)tv {
	return [manager channelCount];
}

- (NSString *)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tableColumn row:(long)row {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	if (row >= 0) {
		[manager lock];
		
		NSDictionary * post = [manager channelAtIndex:row];
		NSString * string = [NSString stringWithString:[post objectForKey:ANRSSManagerChannelURLKey]];
		
		[manager unlock];
		[pool drain];
		return string;
	}
	[pool drain];
	return nil;
}

#pragma mark Delegates

- (void)rssChannel:(id)sender itemHighlighted:(RSSItemView *)_item {
	// go ahead and set the read to less
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	RSSItem * item = [_item item];
	RSSChannel * channel = [item parentChannel];
	// now find it
	int count = [manager channelCount];
	[manager lock];
	
	int index = -1;
	
	for (int i = 0; i < count; i++) {
		NSDictionary * dict = [manager channelAtIndex:i];
		RSSChannel * chan = [dict objectForKey:ANRSSManagerChannelRSSChannelKey];
		if ([chan isEqual:channel]) {
			// found
			index = i;
			break;
		}
	}
	
	if (index < 0) {
		[manager unlock];
		NSLog(@"selected item was not found.");
		return;
	}
	
	NSDictionary * dict = [manager channelAtIndex:index];
	RSSChannel * chan = [dict objectForKey:ANRSSManagerChannelRSSChannelKey];
	for (int i = 0; i < [[chan items] count]; i++) {
		RSSItem * item1 = [[chan items] objectAtIndex:i];
		if ([[item1 postGuid] isEqual:[item postGuid]]) {
			// NSLog(@"Found.");
			[manager changeToRead:index
					 articleIndex:i lock:NO];
		}
	}
	
	[manager unlock];
	[self updateMenu];
	
	[pool drain];
}

@end