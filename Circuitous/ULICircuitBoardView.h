//
//  ULICircuitBoardView.h
//  Circuitous
//
//  Created by Uli Kusterer on 2013-09-19.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ULICircuitBoardView : NSView

@property (copy) NSArray     *      fields; // Array of ULICircuitBoardFields.
@property (assign) NSInteger		selectedField;

@end


