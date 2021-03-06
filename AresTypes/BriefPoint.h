//
//  BriefPoint.h
//  Athena
//
//  Created by Scott McClaugherty on 1/22/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LuaCoding.h"
#import "ResCoding.h"

@class XSIPoint, XSText;

typedef enum {
    BriefTypeNoPoint,
    BriefTypeObject,
    BriefTypeAbsolute,
    BriefTypeFreestanding
} BriefingType;

@interface BriefPoint : NSObject <LuaCoding, ResCoding> {
    NSString *title;
    BriefingType type;
    NSInteger objectId;
    BOOL isVisible;
    XSIPoint *range;
    XSText *content;
}
@property (readwrite, retain) NSString *title;
@property (readwrite, assign) BriefingType type;
@property (readwrite, assign) NSInteger objectId;
@property (readwrite, assign) BOOL isVisible;
@property (readwrite, retain) XSIPoint *range;
@property (readwrite, assign) XSText *content;
//Properties for Interface Builder
@property (readwrite, retain) NSNumber *typeObj;
@property (readonly) BOOL doesntHaveObject;
@end
