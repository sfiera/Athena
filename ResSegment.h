//
//  ResSegment.h
//  Athena
//
//  Created by Scott McClaugherty on 2/10/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResCoding.h"

@class ResUnarchiver;

@interface ResSegment : NSObject {
    NSData *data;
    id<ResCoding, NSObject> object;
    Class dataClass;
    NSUInteger cursor;
    BOOL loaded;
}
- (id) initWithClass:(Class)class data:(NSData *)data;
- (id) loadObjectWithCoder:(ResUnarchiver *)unarchiver;
- (void) readBytes:(void *)bytes length:(NSUInteger)length;
- (void) advance:(NSUInteger)bytes;
@end
