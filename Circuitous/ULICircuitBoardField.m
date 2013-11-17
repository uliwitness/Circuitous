//
//  ULICircuitBoardField.m
//  Circuitous
//
//  Created by Uli Kusterer on 2013-09-19.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#import "ULICircuitBoardField.h"


@implementation ULICircuitBoardField

-(void) drawInFrame: (NSRect)currBox dirtyRect: (NSRect)dirtyRect selected: (BOOL)isSelected
{
	if( isSelected )
	{
		[[NSColor selectedTextBackgroundColor] set];
		[NSBezierPath fillRect: currBox];
	}
	
	BOOL	havePower = (self.powerSourceDirection.length > 0) && (self.powerDrainDirection.length > 0);
	NSInteger		idx = 0;
	for( NSDictionary* currState in self.objectSpecification )
	{
		NSNumber	*stateBool = currState[@"WhenOn"];
		if( stateBool && stateBool.boolValue == havePower )
			self.objectState = idx;
		
		idx ++;
	}
	
	if( self.objectSpecification )
	{
		NSDictionary*	currState = self.objectSpecification[self.objectState];
		NSImage		*	img = [NSImage imageNamed: currState[@"Image"]];
		[img setFlipped: [[NSGraphicsContext currentContext] isFlipped]];
		[img drawAtPoint: currBox.origin fromRect: NSZeroRect operation: NSCompositeSourceAtop fraction: 1.0];
	}
	
	#if 0
	if( self.powerSourceDirection.length > 0 && self.powerDrainDirection.length > 0 )
		[[self.powerSourceDirection stringByAppendingFormat: @"-> %@", self.powerDrainDirection] drawAtPoint: currBox.origin withAttributes: @{}];
	else if( self.powerSourceDirection.length > 0 )
		[self.powerSourceDirection drawAtPoint: currBox.origin withAttributes: @{}];
	else if( self.powerDrainDirection.length > 0 )
		[self.powerDrainDirection drawAtPoint: currBox.origin withAttributes: @{}];
	#endif
}

@end
