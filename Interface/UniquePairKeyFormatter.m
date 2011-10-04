//
//  UniquePairKeyFormatter.m
//  Athena
//
//  Created by Scott McClaugherty on 9/29/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import "UniquePairKeyFormatter.h"

@implementation UniquePairKeyFormatter
@synthesize array;
- (id)init {
    self = [super init];
    if (self) {
        numberChecker = [[NSNumberFormatter alloc] init];
        [numberChecker setLenient:NO];
    }
    
    return self;
}

- (void)dealloc {
    [numberChecker release];
    [super dealloc];
}

- (NSString *)stringForObjectValue:(id)obj {
    return obj;
}

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error {
    if ([string length] == 0) {
        if (error != NULL) {
            *error = @"Index can't be empty.";
        }
        return NO;
    }
    NSMutableArray *wk = [[array arrangedObjects] mutableCopy];
    [wk removeObject:[array selection]];
    BOOL ok = ![[wk valueForKeyPath:@"key"] containsObject:string];
    *obj = string;
    if (!ok) {
        if (error != NULL) {
            *error = [NSString stringWithFormat:@"Plugin already contains object with index %@", string];
        }
    }
    [wk release];
    return ok;
}

- (BOOL)isPartialStringValid:(NSString *)partialString newEditingString:(NSString **)newString errorDescription:(NSString **)error {
    if ([partialString length] == 0) {
        return YES;
    }
    NSNumber *num = [numberChecker numberFromString:partialString];
    if (num != nil) {
        *newString = [num stringValue];
        return NO;
    } else {
        return NO;
    }
}
@end
