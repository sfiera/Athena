//
//  Scenario.h
//  Athena
//
//  Created by Scott McClaugherty on 1/26/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LuaCoding.h"

@class XSPoint;
@class ScenarioPar;

@interface Scenario : NSObject <LuaCoding> {
//    NSInteger scenId;
    NSString *name;

    NSUInteger netRaceFlags;
    NSInteger playerNum;//Number of players
    NSMutableArray *players;
    NSMutableArray *scoreStrings;

    NSMutableArray *initialObjects;
    NSMutableArray *conditions;
    NSMutableArray *briefings;

    XSPoint *starmap;

    ScenarioPar *par;

    NSInteger angle;
    NSInteger startTime;
    BOOL isTraining;

    NSInteger prologueId;
    NSInteger epilogueId;
    NSInteger songId;
    NSString *movie;
}
@property (readwrite, retain) NSString *name;
@property (readonly) NSString *singleLineName;

@property (readwrite, assign) NSUInteger netRaceFlags;
@property (readwrite, assign) NSInteger playerNum;
@property (readwrite, retain) NSMutableArray *players;
@property (readwrite, retain) NSMutableArray *scoreStrings;
@property (readwrite, retain) NSMutableArray *initialObjects;
@property (readwrite, retain) NSMutableArray *conditions;
@property (readwrite, retain) NSMutableArray *briefings;
@property (readwrite, retain) XSPoint *starmap;
@property (readwrite, retain) ScenarioPar *par;
@property (readwrite, assign) NSInteger angle;
@property (readwrite, assign) NSInteger startTime;
@property (readwrite, assign) BOOL isTraining;
@property (readwrite, assign) NSInteger prologueId;
@property (readwrite, assign) NSInteger epilogueId;
@property (readwrite, assign) NSInteger songId;
@property (readwrite, retain) NSString *movie;
@end

typedef enum {
    PlayerTypeSingle,
    PlayerTypeNet,
    PlayerTypeCpu
} PlayerType;

@interface ScenarioPlayer : NSObject <LuaCoding> {
    PlayerType type;
    NSInteger race;
    NSString *name;
    float earningPower;
    NSUInteger netRaceFlags;
}
@property (readwrite, assign) PlayerType type;
@property (readwrite, assign) NSInteger race;
@property (readwrite, retain) NSString *name;
@property (readwrite, assign) float earningPower;
@property (readwrite, assign) NSUInteger netRaceFlags;
- (id) initAsSinglePlayer;
@end

@interface ScenarioPar : NSObject <LuaCoding> {
    NSInteger time;
    NSInteger kills;
    float ratio;
    NSInteger losses;
}
@property (readwrite, assign) NSInteger time;
@property (readwrite, assign) NSInteger kills;
@property (readwrite, assign) float ratio;
@property (readwrite, assign) NSInteger losses;
@end

