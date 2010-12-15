//
//  RSSChannel.m
//  miRSS
//
//  Created by Alex Nichol on 12/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RSSChannel.h"
#import "Debugging.h"

@implementation RSSChannel

@synthesize channelDescription;
@synthesize channelTitle;
@synthesize channelLink;
@synthesize items;
@synthesize xmlNode;

- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[self class]]) {
		RSSChannel * channel = object;
		if ([[channel channelTitle] isEqual:[self channelTitle]] && [[channel channelLink] isEqual:[self channelLink]]) {
			return YES;
		}
		return NO;
	} else {
		return [super isEqual:object];
	}
}

- (int)getUniqueID {
	static int uid = 1;
	uid += 1;
	return uid;
}

- (int)uniqueID {
	return uniqueID;
}

- (void)setUniqueID:(int)uid {
	uniqueID = uid;
}

- (id)initWithString:(NSString *)rssData {
	NSXMLDocument * document = [[NSXMLDocument alloc] initWithXMLString:rssData
																options:0
																  error:nil];
	if (!document) {
		return nil;
	}
	if (self = [self initWithXML:[document rootElement]]) {
		// we read it perfectly
		// uniqueID = [self getUniqueID];
	}
	return self;
}
- (id)initWithXML:(NSXMLNode *)rssDocument {
	if (self = [super init]) {
		// read the node
		self.xmlNode = rssDocument;
		uniqueID = [self getUniqueID];
		NSMutableArray * itemArray = [[NSMutableArray alloc] init];
		for (int i = 0; i < [rssDocument childCount]; i++) {
			NSXMLNode * subnode = [[rssDocument children] objectAtIndex:i];
			// read the node name
			if ([[subnode name] isEqual:@"title"]) {
				if ([subnode kind] == NSXMLElementKind)
					self.channelTitle = [subnode stringValue];
				else {
					NSLog(@"Invalid node type for 'title' node: %d", [subnode kind]);
					[super dealloc];
					return nil;
				}
			}
			if ([[subnode name] isEqual:@"link"]) {
				if ([subnode kind] == NSXMLElementKind)
					self.channelLink = [subnode stringValue];
				else {
					NSLog(@"Invalid node type for 'link' node.");
					[super dealloc];
					return nil;
				}
			}
			if ([[subnode name] isEqual:@"description"]) {
				if ([subnode kind] == NSXMLElementKind)
					self.channelDescription = [subnode stringValue];
				else {
					NSLog(@"Invalid node type for 'description' node.");
					[super dealloc];
					return nil;
				}
			}
			if ([[subnode name] isEqual:@"item"]) {
				if ([subnode kind] == NSXMLElementKind) {
					RSSItem * item = [[RSSItem alloc] initWithXML:subnode];
					[itemArray addObject:item];
					[item setParentChannel:self];
					[item release];
				} else {
					NSLog(@"Invalid node type for 'item' node.");
					[super dealloc];
					return nil;
				}
			}
		}
		// don't make it global
		self.items = [NSArray arrayWithArray:itemArray];
		[itemArray release];
	}
	return self;
}

- (id)initWithChannel:(RSSChannel *)channel {
	if (self = [self initWithXML:[channel xmlNode]]) {
		// do nothing
	}
	return self;
}

- (id)description {
	NSMutableString * humanReadable = [NSMutableString string];
	[humanReadable appendFormat:@"{ "];
	int i = 0;
	for (RSSItem * item in self.items) {
		[humanReadable appendFormat:@"Item #%d: %@,\n  ", ++i, item];
	}
	[humanReadable appendFormat:@" }"];
	return humanReadable;
}

- (void)dealloc {
	self.channelLink = nil;
	self.channelTitle = nil;
	self.channelDescription = nil;
	self.xmlNode = nil;
	self.items = nil;
	[super dealloc];
}

@end
