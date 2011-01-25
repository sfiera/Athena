//
//  MainData.m
//  Athena
//
//  Created by Scott McClaugherty on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainData.h"
#import "Archivers.h"
#import "BaseObject.h"
#import "Race.h"

#import "BriefPoint.h"

@implementation MainData
- (id) initWithLuaCoder:(LuaUnarchiver *)decoder {
    [super init];
    objects = [[decoder decodeArrayOfClass:[BaseObject class]
                                    forKey:@"objects"
                               zeroIndexed:YES] retain];
    
    races = [[decoder decodeArrayOfClass:[Race class]
                                 forKey:@"race"
                             zeroIndexed:YES] retain];
    
    briefings = [[decoder decodeArrayOfClass:[BriefPoint class]
                                      forKey:@"briefings"
                                 zeroIndexed:YES] retain];;
    return self;
}

- (void) encodeLuaWithCoder:(LuaArchiver *)aCoder {
    [aCoder encodeArray:objects forKey:@"objects" zeroIndexed:YES];
    [aCoder encodeArray:races forKey:@"race" zeroIndexed:YES];
    [aCoder encodeArray:briefings forKey:@"briefings" zeroIndexed:YES];
}


- (void) dealloc {
    [objects release];
    [races release];
    [briefings release];
    [super dealloc];
}

+ (BOOL) isComposite {
    return YES;
}
@end
