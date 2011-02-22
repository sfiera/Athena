//
//  XSPoint.h
//  Athena
//
//  Created by Scott McClaugherty on 1/22/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LuaCoding.h"

@interface XSPoint : NSObject <LuaCoding> {
    NSPoint point;
}
@property (readwrite, assign) CGFloat x;
@property (readwrite, assign) CGFloat y;
@property (readwrite, assign) NSPoint point;

- (id) initWithPoint:(NSPoint)point;
- (id) initWithX:(CGFloat)x Y:(CGFloat)y;

+ (id) point;
@end


@interface XSIPoint : NSObject <LuaCoding> {
    int x, y;
}
@property (readwrite, assign) int x;
@property (readwrite, assign) int y;
@property (readwrite, assign) NSPoint point;

- (id) initWithPoint:(NSPoint)point;
- (id) initWithX:(int)x Y:(int)y;

+ (id) point;
@end
