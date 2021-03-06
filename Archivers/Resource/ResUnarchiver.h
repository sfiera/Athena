//
//  ResUnarchiver.h
//  Athena
//
//  Created by Scott McClaugherty on 2/9/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>
#import "ResCoding.h"
#import "DataBasis.h"

@class Index;

@interface ResUnarchiver : NSObject {
    NSMutableDictionary *types;
    NSMutableArray *stack;
    NSMutableArray *files;
}
@property (readonly) DataBasis sourceType;

- (void) addFile:(NSString *)path ofType:(DataBasis)type;
- (NSUInteger) countOfClass:(Class<ResCoding>)class;

- (void) skip:(NSUInteger)bytes;
- (void) seek:(NSUInteger)position;
- (void) readBytes:(void *)buffer length:(NSUInteger)length;
- (NSUInteger) currentIndex;
- (NSUInteger) currentSize;
- (NSString *) currentName;
- (NSData *)rawData;

- (UInt8) decodeUInt8;
- (SInt8) decodeSInt8;
- (UInt16) decodeUInt16;
- (SInt16) decodeSInt16;
- (UInt16) decodeSwappedUInt16;
- (SInt16) decodeSwappedSInt16;
- (UInt32) decodeUInt32;
- (SInt32) decodeSInt32;
- (UInt32) decodeSwappedUInt32;
- (SInt32) decodeSwappedSInt32;

- (CGFloat) decodeFixed;

- (NSString *) decodePString;
//Length does not include the length byte
- (NSString *) decodePStringOfLength:(UInt8)length;

- (BOOL) hasObjectOfClass:(Class<ResCoding>)class atIndex:(NSUInteger)index;
- (id) decodeObjectOfClass:(Class<ResCoding>)class atIndex:(NSUInteger)index;
- (NSMutableDictionary *)allObjectsOfClass:(Class<ResCoding>)class;
- (Index *) getIndexRefWithIndex:(NSUInteger)index forClass:(Class<ResCoding>)class;

- (NSString *)getMetadataForKey:(NSString *)key;
@end
