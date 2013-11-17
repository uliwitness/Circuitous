//
//  ULICircuitBoardView.m
//  Circuitous
//
//  Created by Uli Kusterer on 2013-09-19.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#import "ULICircuitBoardView.h"
#import "ULICircuitBoardField.h"


const NSInteger     kNumColumns = 16;
    

@interface ULICircuitBoardView ()

@end


@implementation ULICircuitBoardView

@synthesize fields = _fields;

-(id)   initWithFrame: (NSRect)frame
{
    self = [super initWithFrame: frame];
    if( self )
    {
        self.selectedField = -1;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect: dirtyRect];
    
    NSRect      currBox = { { 0, -64 }, { 64, 64 } };
    NSInteger   idx = 0;
	
    for( ULICircuitBoardField * currField in self.fields )
    {
        if( (idx % kNumColumns) == 0 )
        {
            currBox.origin.y += currBox.size.height;
            currBox.origin.x = 0;
        }
        
        [currField drawInFrame: currBox dirtyRect: dirtyRect selected: (idx == self.selectedField)];
		currBox.origin.x += currBox.size.width;
		
		idx ++;
    }
}


-(void)	mouseDown:(NSEvent *)theEvent
{
	[self.window makeFirstResponder: self];

	NSPoint		pos = [self convertPoint: [theEvent locationInWindow] fromView: nil];
    NSRect      currBox = { { 0, -64 }, { 64, 64 } };
    NSInteger   idx = 0;
	
    for( ULICircuitBoardField * currField in self.fields )
    {
        if( (idx % kNumColumns) == 0 )
        {
            currBox.origin.y += currBox.size.height;
            currBox.origin.x = 0;
        }
        
        if( NSPointInRect( pos, currBox ) )
		{
			self.selectedField = idx;
			[self setNeedsDisplay: YES];
			return;
		}
		
		currBox.origin.x += currBox.size.width;
		
		idx ++;
    }
}


-(void)	setFields: (NSArray *)fields
{
	self->_fields = [fields mutableCopy];
}


-(NSArray*)	fields
{
	return self->_fields;
}


-(BOOL)	canBecomeKeyView
{
	return YES;
}


-(BOOL)	becomeFirstResponder
{
	return YES;
}


-(void)	applyPartType: (NSMenuItem*)sender
{
	if( self.selectedField < 0 )
		return;
	
	ULICircuitBoardField	*	selField = [self.fields objectAtIndex: self.selectedField];
	[selField setObjectSpecification: sender.representedObject];
	[self reevaluateCircuit];
}


-(void)	advancePartState: (NSMenuItem*)sender
{
	if( self.selectedField < 0 )
		return;
	
	ULICircuitBoardField	*	selField = [self.fields objectAtIndex: self.selectedField];
	NSInteger		nextState = selField.objectState +1;
	if( nextState >= selField.objectSpecification.count )
		nextState = 0;
	[selField setObjectState: nextState];
	
	[self reevaluateCircuit];
}


-(BOOL)	validateMenuItem:(NSMenuItem *)menuItem
{
	if( menuItem.action == @selector(advancePartState:) )
	{
	if( self.selectedField < 0 )
		return NO;
	
		ULICircuitBoardField	*	selField = [self.fields objectAtIndex: self.selectedField];
		
		BOOL	haveStates = (selField.objectSpecification.count > 1);
		if( haveStates )
		{
			NSString	*	stateAction = selField.objectSpecification[selField.objectState][@"StateAction"];
			if( !stateAction )
				stateAction = NSLocalizedString(@"Next State",@"");
			[menuItem setTitle: stateAction];
		}
		return haveStates;
	}
	else
		return [self respondsToSelector: menuItem.action];
}


-(void)	reevaluateCircuit
{
	// Reset all power inputs so we don't think a disconnected item is still powered:
    for( ULICircuitBoardField * currField in self.fields )
	{
		[currField setPowerSourceDirection: @""];
		[currField setPowerDrainDirection: @""];
	}

	// Now grab each battery and transmit power from it to connected parts:
	NSInteger		idx = 0;
    for( ULICircuitBoardField * currField in self.fields )
    {
        if( currField.objectSpecification[currField.objectState][@"MinusIn"] )	// Found a battery!
		{
			[self reevaluateCircuitPart: currField atIndex: idx];
			[self reevaluateCircuitPartDrain: currField atIndex: idx];
		}
		idx++;
	}
	
	// Let user see the result of our efforts:
	[self setNeedsDisplay: YES];
}


-(void) reevaluateCircuitPart: (ULICircuitBoardField*)theField atIndex: (NSInteger)idx
{
	if( theField.objectSpecification == nil )
		return;
	
	ULICircuitBoardField	*	northField = nil;
	ULICircuitBoardField	*	eastField = nil;
	ULICircuitBoardField	*	southField = nil;
	ULICircuitBoardField	*	westField = nil;
	if( idx > 0 )
	{
		NSInteger	westIdx = idx -1;
		westField = self.fields[westIdx];
	}
	if( idx < self.fields.count -kNumColumns )
	{
		NSInteger	southIdx = idx +kNumColumns;
		southField = self.fields[southIdx];
	}
	if( idx > kNumColumns )
	{
		NSInteger	northIdx = idx -kNumColumns;
		northField = self.fields[northIdx];
	}
	if( idx < self.fields.count -1 )
	{
		NSInteger	eastIdx = idx +1;
		eastField = self.fields[eastIdx];
	}
	
	if( theField.powerSourceDirection.length > 0 || theField.objectSpecification[theField.objectState][@"MinusIn"] )	// We have power or produce it?
	{
		NSString	*	powerSource = theField.objectSpecification[theField.objectState][@"MinusIn"];
		if( !powerSource )
			powerSource = theField.powerSourceDirection;
		
		if( northField && [powerSource rangeOfString: @"N"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"N"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( northField.objectSpecification && [northField.objectSpecification[northField.objectState][@"Connected"]rangeOfString: @"S"].location != NSNotFound )	// Has an input?
			{
				northField.powerSourceDirection = [northField.powerSourceDirection stringByAppendingString: @"S"];	// Tell it it's powered from south.
				[self reevaluateCircuitPart: northField atIndex: idx -kNumColumns];
			}
		}

		// South:
		if( southField && [powerSource rangeOfString: @"S"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"S"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( southField.objectSpecification && [southField.objectSpecification[southField.objectState][@"Connected"]rangeOfString: @"N"].location != NSNotFound )	// Has an input?
			{
				southField.powerSourceDirection = [northField.powerSourceDirection stringByAppendingString: @"N"];	// Tell it it's powered from south.
				[self reevaluateCircuitPart: southField atIndex: idx +kNumColumns];
			}
		}

		// East:
		if( eastField && [powerSource rangeOfString: @"E"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"E"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( eastField.objectSpecification && [eastField.objectSpecification[eastField.objectState][@"Connected"]rangeOfString: @"W"].location != NSNotFound )	// Has an input?
			{
				eastField.powerSourceDirection = [northField.powerSourceDirection stringByAppendingString: @"W"];	// Tell it it's powered from south.
				[self reevaluateCircuitPart: eastField atIndex: idx +1];
			}
		}

		// West:
		if( westField && [powerSource rangeOfString: @"W"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"W"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( westField.objectSpecification && [westField.objectSpecification[westField.objectState][@"Connected"]rangeOfString: @"E"].location != NSNotFound )	// Has an input?
			{
				westField.powerSourceDirection = [northField.powerSourceDirection stringByAppendingString: @"E"];	// Tell it it's powered from south.
				[self reevaluateCircuitPart: westField atIndex: idx -1];
			}
		}
	}

	if( theField.powerDrainDirection.length > 0 || theField.objectSpecification[theField.objectState][@"MinusIn"] )	// We have power or produce it?
	{
		if( northField && [theField.powerDrainDirection rangeOfString: @"N"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"N"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( northField.objectSpecification && [northField.objectSpecification[northField.objectState][@"Connected"]rangeOfString: @"S"].location != NSNotFound )	// Has an input?
			{
				northField.powerDrainDirection = [northField.powerDrainDirection stringByAppendingString: @"S"];	// Tell it it's powered from south.
				[self reevaluateCircuitPartDrain: northField atIndex: idx -kNumColumns];
			}
		}

		// South:
		if( southField && [theField.powerDrainDirection rangeOfString: @"S"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"S"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( southField.objectSpecification && [southField.objectSpecification[southField.objectState][@"Connected"]rangeOfString: @"N"].location != NSNotFound )	// Has an input?
			{
				southField.powerDrainDirection = [northField.powerDrainDirection stringByAppendingString: @"N"];	// Tell it it's powered from south.
				[self reevaluateCircuitPartDrain: southField atIndex: idx +kNumColumns];
			}
		}

		// East:
		if( eastField && [theField.powerDrainDirection rangeOfString: @"E"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"E"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( eastField.objectSpecification && [eastField.objectSpecification[eastField.objectState][@"Connected"]rangeOfString: @"W"].location != NSNotFound )	// Has an input?
			{
				eastField.powerDrainDirection = [northField.powerDrainDirection stringByAppendingString: @"W"];	// Tell it it's powered from south.
				[self reevaluateCircuitPartDrain: eastField atIndex: idx +1];
			}
		}

		// West:
		if( westField && [theField.powerDrainDirection rangeOfString: @"W"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"W"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( westField.objectSpecification && [westField.objectSpecification[westField.objectState][@"Connected"]rangeOfString: @"E"].location != NSNotFound )	// Has an input?
			{
				westField.powerDrainDirection = [northField.powerDrainDirection stringByAppendingString: @"E"];	// Tell it it's powered from south.
				[self reevaluateCircuitPartDrain: westField atIndex: idx -1];
			}
		}
	}
}

-(void) reevaluateCircuitPartDrain: (ULICircuitBoardField*)theField atIndex: (NSInteger)idx
{
	if( theField.objectSpecification == nil )
		return;
	
	ULICircuitBoardField	*	northField = nil;
	ULICircuitBoardField	*	eastField = nil;
	ULICircuitBoardField	*	southField = nil;
	ULICircuitBoardField	*	westField = nil;
	if( idx > 0 )
	{
		NSInteger	westIdx = idx -1;
		westField = self.fields[westIdx];
	}
	if( idx < self.fields.count -kNumColumns )
	{
		NSInteger	southIdx = idx +kNumColumns;
		southField = self.fields[southIdx];
	}
	if( idx > kNumColumns )
	{
		NSInteger	northIdx = idx -kNumColumns;
		northField = self.fields[northIdx];
	}
	if( idx < self.fields.count -1 )
	{
		NSInteger	eastIdx = idx +1;
		eastField = self.fields[eastIdx];
	}
	
	if( theField.powerDrainDirection.length > 0 || theField.objectSpecification[theField.objectState][@"PlusIn"] )	// We have power or produce it?
	{
		NSString	*	powerDrain = theField.objectSpecification[theField.objectState][@"PlusIn"];
		if( !powerDrain )
			powerDrain = theField.powerDrainDirection;
		
		if( northField && [powerDrain rangeOfString: @"N"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"N"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( northField.objectSpecification && [northField.objectSpecification[northField.objectState][@"Connected"]rangeOfString: @"S"].location != NSNotFound )	// Has an input?
			{
				northField.powerDrainDirection = [northField.powerDrainDirection stringByAppendingString: @"S"];	// Tell it it's powered from south.
				[self reevaluateCircuitPartDrain: northField atIndex: idx -kNumColumns];
			}
		}

		// South:
		if( southField && [powerDrain rangeOfString: @"S"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"S"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( southField.objectSpecification && [southField.objectSpecification[southField.objectState][@"Connected"]rangeOfString: @"N"].location != NSNotFound )	// Has an input?
			{
				southField.powerDrainDirection = [northField.powerDrainDirection stringByAppendingString: @"N"];	// Tell it it's powered from south.
				[self reevaluateCircuitPartDrain: southField atIndex: idx +kNumColumns];
			}
		}

		// East:
		if( eastField && [powerDrain rangeOfString: @"E"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"E"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( eastField.objectSpecification && [eastField.objectSpecification[eastField.objectState][@"Connected"]rangeOfString: @"W"].location != NSNotFound )	// Has an input?
			{
				eastField.powerDrainDirection = [northField.powerDrainDirection stringByAppendingString: @"W"];	// Tell it it's powered from south.
				[self reevaluateCircuitPartDrain: eastField atIndex: idx +1];
			}
		}

		// West:
		if( westField && [powerDrain rangeOfString: @"W"].location == NSNotFound && [theField.objectSpecification[theField.objectState][@"Connected"] rangeOfString: @"W"].location != NSNotFound )	// Power isn't coming from North, and we have an outlet North?
		{
			if( westField.objectSpecification && [westField.objectSpecification[westField.objectState][@"Connected"]rangeOfString: @"E"].location != NSNotFound )	// Has an input?
			{
				westField.powerDrainDirection = [northField.powerDrainDirection stringByAppendingString: @"E"];	// Tell it it's powered from south.
				[self reevaluateCircuitPartDrain: westField atIndex: idx -1];
			}
		}
	}
}


-(BOOL) isFlipped
{
    return YES;
}

@end
