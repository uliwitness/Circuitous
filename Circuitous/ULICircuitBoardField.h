//
//  ULICircuitBoardField.h
//  Circuitous
//
//  Created by Uli Kusterer on 2013-09-19.
//  Copyright (c) 2013 Uli Kusterer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ULICircuitBoardField : NSObject

@property (copy,nonatomic) NSArray		*	objectSpecification;
@property (assign,nonatomic) NSInteger		objectState;
@property (copy,nonatomic) NSString		*	powerSourceDirection;
@property (copy,nonatomic) NSString		*	powerDrainDirection;

-(void) drawInFrame: (NSRect)currBox dirtyRect: (NSRect)dirtyRect selected: (BOOL)isSelected;

@end


