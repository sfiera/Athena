//
//  ObjectTypeSelector.h
//  Athena
//
//  Created by Scott McClaugherty on 7/4/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class Index;
@class BaseObject;

@interface ObjectTypeSelector : NSView {
@private
    NSTextField *displayField;
    NSButton *openButton;
    Index *index;

    IBOutlet id target;
    //Configure next two with IB User Defined Runtime Attributes
    NSString *targetKeyPath;
    NSString *keyPath;
}

@property (readwrite, retain) BaseObject *type;
@property (readwrite, retain) Index *index;
@property (readwrite, retain) NSString *keyPath;
@property (readwrite, retain) NSString *targetKeyPath;
- (void)openObjectPicker:(id)sender;
- (void)preformDelayedBinding;
@end
