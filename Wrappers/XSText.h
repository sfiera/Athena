//
//  XSText.h
//  Athena
//
//  Created by Scott McClaugherty on 2/23/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResCoding.h"
#import "LuaCoding.h"

enum {
    TEXTNoShipsOffset = 10000,
};

@interface XSText : NSObject <ResCoding, LuaCoding, NSCopying> {
    NSString *name;
    NSString *text;
}
@property (readwrite, retain) NSString *name;
@property (readwrite, retain) NSString *text;
@end
