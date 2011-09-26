//
//  SoundEditor.h
//  Athena
//
//  Created by Scott McClaugherty on 9/25/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MainData, XSSound;

@interface SoundEditor : NSWindowController {
    NSMutableDictionary *sounds;
    IBOutlet NSDictionaryController *soundsController;
}
@property (readonly) NSMutableDictionary *sounds;
- (id)initWithMainData:(MainData *)data;
- (IBAction)playSound:(id)sender;
- (BOOL)addSoundForPath:(NSString *)path;
- (BOOL)addSound:(XSSound *)sound;
@end

@interface SoundImporterTableView : NSTableView {
}
@end