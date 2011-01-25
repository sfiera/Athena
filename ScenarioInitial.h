//
//  ScenarioInitial.h
//  Athena
//
//  Created by Scott McClaugherty on 1/25/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LuaCoding.h"
#import "FlagBlob.h"

@class XSPoint, XSRange;

@interface ScenarioInitialAttributes : FlagBlob {
    BOOL fixedRace;
    BOOL initiallyHidden;
    BOOL isPlayerShip;
    BOOL staticDestination;
}
@end


@interface ScenarioInitial : NSObject <LuaCoding> {
    NSInteger type;
    NSInteger owner;
    XSPoint *position;

    float earning;
    NSInteger distanceRange;

    XSRange *rotation;

    NSInteger spriteIdOverride;

    NSMutableArray *builds;

    NSInteger initialDestination;
    NSString *nameOverride;

    ScenarioInitialAttributes *attributes;
}

@end