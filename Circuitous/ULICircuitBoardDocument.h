//
//  ULIDocument.h
//  Circuitous
//
//  Created by Uli Kusterer on 2013-09-19.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class ULICircuitBoardView;


@interface ULICircuitBoardDocument : NSDocument

@property (assign,nonatomic) IBOutlet ULICircuitBoardView	*	boardView;

@end
