//
//  ActionEditor.m
//  Athena
//
//  Created by Scott McClaugherty on 5/3/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import "ActionEditor.h"
#import "ObjectEditor.h"

@implementation ActionEditor
@synthesize actions;

- (void) dealloc {
    [super dealloc];
}

- (void) awakeFromNib {
    [super awakeFromNib];
//    [[self view] setFrame:[targetView bounds]];
    [[self view] setFrameSize:[targetView frame].size];
    [[self view] setFrameSize:(NSSize){.width = 761, .height = 419}];
    [[[self view] superview] setFrameSize:(NSSize){.width = 761, .height = 419}];
//    [[self view] setFrameSize:actionsSize];
//    [[[self view] superview] setFrameSize:actionsSize];

    [[[self view] superview] setFrameOrigin:NSZeroPoint];
    [targetView addSubview:[self view]];
}

@end