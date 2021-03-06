//
//  ResArchiver.m
//  Athena
//
//  Created by Scott McClaugherty on 2/19/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import "ResArchiver.h"
#import "ResCoding.h"
#import "ResSegment.h"
#import "ResEntry.h"
#import "StringTable.h"
#import <sys/stat.h>

@interface ResArchiver (Private)
- (NSMutableDictionary *) getTableForClass:(Class<ResCoding>)class;
- (NSUInteger) getNextIndexOfClass:(Class<ResCoding>)class;
- (void) flattenTableForType:(NSString *)type;
@end

@implementation ResArchiver (Private)
- (NSMutableDictionary *) getTableForClass:(Class<ResCoding>)class {
    NSMutableDictionary *table = [types objectForKey:[class typeKey]];
    if (table == nil) {
        table = [[NSMutableDictionary alloc] init];
        [types setObject:table forKey:[class typeKey]];
        [table setObject:[NSNumber numberWithUnsignedInt:0u] forKey:@"COUNTER"];
        [table release];
    }
    return table;
}

- (NSUInteger) getNextIndexOfClass:(Class<ResCoding>)class {
    NSMutableDictionary *table = [self getTableForClass:class];
    NSUInteger val = [[table objectForKey:@"COUNTER"] unsignedIntegerValue];
    [table setObject:[NSNumber numberWithUnsignedInt:val+1] forKey:@"COUNTER"];
    if ([class resType] == 'TEXT') {
        return val + 3000;
    }
    return val;
}

- (void) flattenTableForType:(NSString *)type {
    NSMutableDictionary *table = [types objectForKey:type];
    [table removeObjectForKey:@"COUNTER"];
    NSArray *keys = [[table allKeys] sortedArrayUsingSelector:@selector(compare:)];
    Class<ResCoding> class = [[table objectForKey:[keys lastObject]] dataClass];
    if ([class isPacked]) {
        size_t size = [class sizeOfResourceItem];
        NSMutableData *data = [NSMutableData dataWithCapacity:[keys count]*size];
        for (id key in keys) {
            [data appendData:[[table objectForKey:key] data]];
        }
        ResEntry *entry = [[ResEntry alloc] initWithResType:[class resType] atId:500 name:[class typeKey] data:data];
        [planes setObject:[NSDictionary dictionaryWithObject:entry forKey:[NSNumber numberWithInt:500]] forKey:type];
        [entry release];
    } else {
        NSMutableDictionary *plane = [NSMutableDictionary dictionary];
        for (id key in keys) {
            ResSegment *seg = [table objectForKey:key];
            ResEntry *entry = [[ResEntry alloc] initWithSegment:seg];
            [plane setObject:entry forKey:key];
            [entry release];
        }
        [planes setObject:plane forKey:type];
    }
}
@end



@implementation ResArchiver
@synthesize saveType;
- (id) init {
    self = [super init];
    if (self) {
        saveType = DataBasisAres;
        hasBeenFlattened = NO;
        types = [[NSMutableDictionary alloc] init];
        stack = [[NSMutableArray alloc] init];
        stringTables = [[NSMutableDictionary alloc] init];
        planes = [[NSMutableDictionary alloc] init];
        metadataFiles = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc {
    [types release];
    [stack release];
    [stringTables release];
    [planes release];
    [metadataFiles release];
    [super dealloc];
}

- (BOOL) writeToResourceFile:(NSString *)filePath {
    FSRef directoryRef;
    Boolean isDirectory;
    if (FSPathMakeRef((const UInt8 *)[[filePath stringByDeletingLastPathComponent] cStringUsingEncoding:NSMacOSRomanStringEncoding], &directoryRef, &isDirectory) != noErr) {
        //Could not make path ref
        return NO;
    }
    NSAssert(isDirectory, @"Path is not directory.");
    //Get the filename
    NSString *fileName = [filePath lastPathComponent];
    HFSUniStr255 file;
    file.length = [fileName length];
    [fileName getCharacters:file.unicode];
    //Prepare the resource file
    FSRef fileRef;
    FSCatalogInfo catInfo;
    FSCreateResFile(&directoryRef, file.length, file.unicode, kFSCatInfoFinderInfo, &catInfo, &fileRef, NULL);
    //'nlAe' or 'ar12' (optimized)
    FSGetCatalogInfo(&fileRef, kFSCatInfoNone, NULL, NULL, NULL, NULL);
    FileInfo *info = (FileInfo*)&catInfo.finderInfo;
    info->fileCreator = 'ar12';
    info->fileType = 'rsrc';
    info->finderFlags = 0;
    FSSetCatalogInfo(&fileRef, kFSCatInfoFinderInfo, &catInfo);
    ResFileRefNum resFile = FSOpenResFile(&fileRef, fsRdPerm | fsWrPerm);
    UseResFile(resFile);
    for (NSString *key in planes) {
        NSDictionary *table = [planes objectForKey:key];
        for (NSNumber *index in table) {
            [[table objectForKey:index] save];
        }
    }
    CloseResFile(resFile);
    return YES;
}

- (BOOL) writeToZipFile:(NSString *)file {
    NSString *baseDir = [[file stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"data"];
    mkdir([baseDir UTF8String], 0777);
    chdir([baseDir UTF8String]);
    BOOL ok = YES;
    //Write the data tables
    for (NSString *key in planes) {
        NSString *typeDir = [NSString stringWithFormat:@"./%@", key];
        mkdir([typeDir UTF8String], 0777);
        chdir([typeDir UTF8String]);
        NSDictionary *table = [planes objectForKey:key];
        for (NSNumber *index in table) {
            ResEntry *entry = [table objectForKey:index];
            NSString *fileName = [NSString stringWithFormat:@"./%i %@.%@", [index intValue], [[entry name] stringByReplacingOccurrencesOfString:@"/" withString:@":"], key];
            ok = [[entry data] writeToFile:fileName atomically:NO];
            if (!ok) {
                break;
            }
        }
        chdir("..");
        if (!ok) {
            break;
        }
    }
    //Add the metadata
    if (ok) {
        for (NSString *key in metadataFiles) {
            ok = [[metadataFiles objectForKey:key] writeToFile:key atomically:NO];
            if (!ok) {
                break;
            }
        }
    }
    chdir("..");
    if (ok) {
        //zip it
        NSTask *zipTask = [[NSTask alloc] init];
        [zipTask setLaunchPath:@"/usr/bin/zip"];
        [zipTask setArguments:[NSArray arrayWithObjects:@"-q", [file lastPathComponent], @"-x", @".DS_Store", @"-r", @"./data/", nil]];
        [zipTask setCurrentDirectoryPath:[file stringByDeletingLastPathComponent]];
        [zipTask launch];
        [zipTask waitUntilExit];
        ok = ([zipTask terminationStatus] == 0);
        [zipTask release];
    }
    //clean up the directories
    NSTask *rmTask = [[NSTask alloc] init];
    [rmTask setLaunchPath:@"/bin/rm"];
    [rmTask setArguments:[NSArray arrayWithObjects:@"-r", @"./data/", nil]];
    [rmTask setCurrentDirectoryPath:[file stringByDeletingLastPathComponent]];
    [rmTask launch];
    [rmTask waitUntilExit];
    [rmTask release];

    return ok;
}

- (size_t) tell {
    return [[stack lastObject] cursor];
}

- (void) skip:(size_t)length {
    [[stack lastObject] advance:length];
}

- (void) seek:(size_t)position {
    [[stack lastObject] seek:position];
}

- (void) extend:(NSUInteger)bytes {
    [[stack lastObject] extend:bytes];
}

- (void) setName:(NSString *)name {
    [(ResSegment *)[stack lastObject] setName:name];
}

- (NSUInteger) currentIndex; {
    return [(ResSegment *)[stack lastObject] index];
}

- (NSUInteger) encodeObject:(id<ResCoding, NSObject>)object {
    if (hasBeenFlattened) {
        @throw @"Cannot encode new object because the data has been flattened.";
    }
    Class<ResCoding> class = [object class];
    NSMutableDictionary *table = [self getTableForClass:class];
    NSUInteger idx = [self getNextIndexOfClass:class];
    ResSegment *seg = [[ResSegment alloc] initWithObject:object atIndex:idx];
    [table setObject:seg forKey:[NSNumber numberWithUnsignedInteger:idx]];
    [stack addObject:seg];
    [object encodeResWithCoder:self];
    [stack removeLastObject];
    [seg release];
    return idx;
}

- (void) encodeObject:(id<ResCoding, NSObject>)object atIndex:(NSUInteger)index {
    if (hasBeenFlattened) {
        @throw @"Cannot encode new object because the data has been flattened.";
    }
    Class<ResCoding> class = [object class];
    NSMutableDictionary *table = [self getTableForClass:class];
    ResSegment *seg = [[ResSegment alloc] initWithObject:object atIndex:index];
    [table setObject:seg forKey:[NSNumber numberWithUnsignedInteger:index]];
    [stack addObject:seg];
    [object encodeResWithCoder:self];
    [stack removeLastObject];
    [seg release];
    if (hasBeenFlattened) {//For flattening the top level object
        [self flattenTableForType:[class typeKey]];
    }
}

- (void) writeBytes:(void *)bytes length:(size_t)length {
    [[stack lastObject] writeBytes:bytes length:length];
}

- (void) encodeUInt8:(UInt8)value {
    [[stack lastObject] writeBytes:&value length:sizeof(UInt8)];
}

- (void) encodeSInt8:(SInt8)value {
    [[stack lastObject] writeBytes:&value length:sizeof(SInt8)];
}

- (void) encodeUInt16:(UInt16)value {
    value = CFSwapInt16HostToBig(value);
    [[stack lastObject] writeBytes:&value length:sizeof(UInt16)];
}

- (void) encodeSInt16:(SInt16)value {
    value = CFSwapInt16HostToBig(value);
    [[stack lastObject] writeBytes:&value length:sizeof(SInt16)];
}

- (void) encodeSwappedUInt16:(UInt16)value {
    [[stack lastObject] writeBytes:&value length:sizeof(UInt16)];
}

- (void) encodeSwappedSInt16:(SInt16)value {
    [[stack lastObject] writeBytes:&value length:sizeof(SInt16)];
}

- (void) encodeUInt32:(UInt32)value {
    value = CFSwapInt32HostToBig(value);
    [[stack lastObject] writeBytes:&value length:sizeof(UInt32)];
}

- (void) encodeSInt32:(SInt32)value {
    value = CFSwapInt32HostToBig(value);
    [[stack lastObject] writeBytes:&value length:sizeof(SInt32)];
}

- (void) encodeSwappedUInt32:(UInt32)value {
    [[stack lastObject] writeBytes:&value length:sizeof(UInt32)];
}

- (void) encodeSwappedSInt32:(SInt32)value {
    [[stack lastObject] writeBytes:&value length:sizeof(SInt32)];
}

- (void) encodeUInt64:(UInt64)value {
    value = CFSwapInt64HostToBig(value);
    [[stack lastObject] writeBytes:&value length:sizeof(UInt64)];
}

- (void) encodeSInt64:(SInt64)value {
    value = CFSwapInt64HostToBig(value);
    [[stack lastObject] writeBytes:&value length:sizeof(SInt64)];
}

- (void) encodeSwappedUInt64:(UInt64)value {
    [[stack lastObject] writeBytes:&value length:sizeof(UInt64)];
}

- (void) encodeSwappedSInt64:(SInt64)value {
    [[stack lastObject] writeBytes:&value length:sizeof(SInt64)];
}

- (void) encodeFixed:(CGFloat)value {
    [self encodeSInt32:(SInt32)(value*256.0f)];
}

- (void) encodePString:(NSString *)string {
    NSUInteger length = [string length];
    [self encodeUInt8:(UInt8)length];
    [[stack lastObject]
     writeBytes:(void *)[string cStringUsingEncoding:NSMacOSRomanStringEncoding]
     length:length];
}

- (void) encodePString:(NSString *)string ofFixedLength:(size_t)length {
    NSUInteger length_ = [string length];
    [self encodeUInt8:(UInt8)length_];
    [[stack lastObject]
     writeBytes:(void *)[string cStringUsingEncoding:NSMacOSRomanStringEncoding]
     length:length_];
    [[stack lastObject] advance:(length - length_)];
}

- (NSUInteger) addString:(NSString *)string toStringTable:(NSUInteger)tableId {
    NSNumber *key = [NSNumber numberWithUnsignedInteger:tableId];
    StringTable *table = [stringTables objectForKey:key];
    if (table == nil) {
        table = [[StringTable alloc] init];
        [stringTables setObject:table forKey:key];
        [table autorelease];
    }
    return [table addString:string];
}

- (NSUInteger) addUniqueString:(NSString *)string toStringTable:(NSUInteger)tableId {
    NSNumber *key = [NSNumber numberWithUnsignedInteger:tableId];
    StringTable *table = [stringTables objectForKey:key];
    if (table == nil) {
        table = [[StringTable alloc] init];
        [stringTables setObject:table forKey:key];
        [table autorelease];
    }
    return [table addUniqueString:string];
}

- (void) addMetadata:(NSString *)data forKey:(NSString *)key {
    [metadataFiles setObject:[NSData dataWithBytes:[data UTF8String]
                                            length:[data lengthOfBytesUsingEncoding:NSUTF8StringEncoding]]
                      forKey:key];
}

- (void) flatten {
    NSAssert(!hasBeenFlattened, @"Data has been flattened, no more objects can be encoded.");
    NSAssert([stack count] <= 1, @"-flatten must be called externally or from the top level object.");
    for (NSNumber *key in stringTables) {
        [self encodeObject:[stringTables objectForKey:key] atIndex:[key unsignedIntValue]];
    }
    hasBeenFlattened = YES;
    NSString *excludedType = [[[stack lastObject] dataClass] typeKey];
    for (NSString *type in types) {
        if ([type isNotEqualTo:excludedType]) {
            [self flattenTableForType:type];
        }
    }
}

- (uint32) checkSumForIndex:(NSInteger)index ofPlane:(NSString *)plane {
    NSDictionary *table = [planes objectForKey:plane];
    NSAssert(table != nil, @"Attempt to checksum nonexistant data plane.");
    NSData *data = [[table objectForKey:[NSNumber numberWithUnsignedInt:index]] data];
    NSAssert(data != nil, @"Attempt to checksum nonexistant data plane.");
    //Checksumming code lifted almost verbatim from Hera_Data.c
    uint32 checkSum = 0x00000000;
    sint32 l = [data length];
    sint32 shiftCount = 0;
    uint8 *c = (uint8 *)[data bytes];
    while (l > 0) {
        checkSum ^= ((uint32)*c) << shiftCount;
        shiftCount += 8;
        c++;
        if (shiftCount >= 32) shiftCount = 0;
        l--;
    }
    return checkSum;
}
@end
