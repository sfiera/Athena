//
//  XSRange.h
//  Athena
//
//  Created by Scott McClaugherty on 1/22/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LuaCoding.h"

@interface XSRange : NSObject <LuaCoding> {
    NSRange range;
}
- (id) initWithRange:(NSRange)range;
- (id) initWithFirst:(NSUInteger)first count:(NSUInteger)count;

@property (readwrite, assign) NSRange range;
@property (readwrite, assign) NSUInteger first;
@property (readwrite, assign) NSUInteger count;

+ (id) range;
@end
