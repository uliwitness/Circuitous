//
//  ULIDocument.m
//  Circuitous
//
//  Created by Uli Kusterer on 2013-09-19.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#import "ULICircuitBoardDocument.h"
#import "ULICircuitBoardView.h"
#import "ULICircuitBoardField.h"


@interface ULICircuitBoardDocument ()

@property (retain,nonatomic) NSData * fileData;

@end


@implementation ULICircuitBoardDocument

- (id)init
{
    self = [super init];
    if (self)
	{
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"ULICircuitBoardDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib: aController];
    
	if( self.fileData )
	{
		NSArray	*	fields = [NSKeyedUnarchiver unarchiveObjectWithData: self.fileData];
		self.boardView.fields = fields;
	}
	else
	{
		NSMutableArray	*	fields = [NSMutableArray array];
		NSInteger			count  = 16 * 16;
		for( NSInteger x = 0; x < count; x++ )
		{
			[fields addObject: [[ULICircuitBoardField alloc] init]];
			self.boardView.fields = fields;
		}
	}
}

+(BOOL)	autosavesInPlace
{
    return YES;
}

-(NSData *)	dataOfType:(NSString *)typeName error:(NSError **)outError
{
    return [NSKeyedArchiver archivedDataWithRootObject: self.boardView.fields];
}

-(BOOL)	readFromData: (NSData *)data ofType: (NSString *)typeName error: (NSError **)outError
{
    self.fileData = data;
	
	if( self.boardView )
	{
		NSArray	*	fields = [NSKeyedUnarchiver unarchiveObjectWithData: self.fileData];
		self.boardView.fields = fields;
	}
	
    return YES;
}

@end
