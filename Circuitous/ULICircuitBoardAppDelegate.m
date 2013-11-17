//
//  ULICircuitBoardAppDelegate.m
//  Circuitous
//
//  Created by Uli Kusterer on 2013-09-19.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#import "ULICircuitBoardAppDelegate.h"

@implementation ULICircuitBoardAppDelegate

-(void)	applicationDidFinishLaunching: (NSNotification*)notification
{
	NSString*	partsFolder = [[NSBundle mainBundle] pathForResource:  @"Components" ofType: @""];
	NSArray	*	files = [[NSFileManager defaultManager] directoryContentsAtPath: partsFolder];
	
	NSMenuItem	*	newItem = [self.partsMenu addItemWithTitle: NSLocalizedString(@"Toggle",@"") action: @selector(advancePartState:) keyEquivalent:@"k"];
	[self.partsMenu addItem: [NSMenuItem separatorItem]];

	for( NSString * fname in files )
	{
		if( [[fname pathExtension] isEqualToString: @"plist"] )
		{
			NSMenuItem	*	newItem = [self.partsMenu addItemWithTitle: [fname stringByDeletingPathExtension] action: @selector(applyPartType:) keyEquivalent:@""];
			NSArray		*	theDescription = [NSArray arrayWithContentsOfFile: [partsFolder	stringByAppendingPathComponent: fname]];
			[newItem setRepresentedObject: theDescription];
		}
	}
}

@end
