//
//  ResUnarchiver.m
//  Athena
//
//  Created by Scott McClaugherty on 2/9/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import "ResUnarchiver.h"
#import "ResCoding.h"
#import "ResSegment.h"
#import "StringTable.h"
#import "Scenario.h"
#import <objc/runtime.h>
#import <sys/stat.h>

@implementation ResUnarchiver
@synthesize sourceType;

- (id) initWithResourceFilePath:(NSString *)path; {
    self = [super init];
    if (self) {
        types = [[NSMutableDictionary alloc] init];
        stack = [[NSMutableArray alloc] init];
        files = [[NSMutableArray alloc] init];
        sourceType = DataOriginAres;
        [self addFile:path];
        [self registerClass:[StringTable class]];
    }

    return self;
}

- (id) initWithZipFilePath:(NSString *)path {
    self = [super init];
    if (self) {
        types = [[NSMutableDictionary alloc] init];
        stack = [[NSMutableArray alloc] init];
        files = [[NSMutableArray alloc] init];
        sourceType = DataOriginAntares;
        [self addFile:path];
        [self registerClass:[StringTable class]];
    }
    return self;
}

- (void)dealloc {
    [types release];
    [stack release];
    if (sourceType == DataOriginAres) {
        for (NSNumber *resRef in files) {
            CloseResFile([resRef shortValue]);
        }
    } else if (sourceType == DataOriginAntares) {
        //Clean up
        for (NSString *dir in files) {
            NSTask *rmTask = [[NSTask alloc] init];
            [rmTask setLaunchPath:@"/bin/rm"];
            [rmTask setArguments:[NSArray arrayWithObjects:@"-r", dir, nil]];
            [rmTask setCurrentDirectoryPath:[dir stringByDeletingLastPathComponent]];
            [rmTask launch];
            [rmTask waitUntilExit];
            assert([rmTask terminationStatus] == 0);
            [rmTask release];
        }
    }
    [files release];
    [super dealloc];
}

- (void) addFile:(NSString *)path {
    if (sourceType == DataOriginAres) {
        FSRef file;
        if (!FSPathMakeRef((UInt8 *)[path cStringUsingEncoding:NSMacOSRomanStringEncoding], &file, NULL)) {
            ResFileRefNum resFile = FSOpenResFile(&file, fsRdPerm);
            UseResFile(resFile);
            [files addObject:[NSNumber numberWithShort:resFile]];
        }
    } else {
        const char *tempDirTemplate = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"TEMP.XXXXXX"] fileSystemRepresentation];
        char *tempDir = malloc(strlen(tempDirTemplate) + 1);
        strcpy(tempDir, tempDirTemplate);
        mkdtemp(tempDir);
        NSString *workDir = [NSString stringWithUTF8String:tempDir];
        free(tempDir);
        
        mkdir([workDir UTF8String], 0777);
        
        NSTask *unzipTask = [[NSTask alloc] init];
        [unzipTask setLaunchPath:@"/usr/bin/unzip"];
        [unzipTask setCurrentDirectoryPath:workDir];
        [unzipTask setArguments:[NSArray arrayWithObjects:@"-q", path, @"-d", workDir, nil]];
        [unzipTask launch];
        [unzipTask waitUntilExit];
        [unzipTask release];
        [files addObject:workDir];
    }
}

- (void) registerClass:(Class <NSObject, Alloc, ResCoding>)class {
    if (sourceType == DataOriginAres) {
        [self registerAresClass:class];
    } else if (sourceType == DataOriginAntares) {
        [self registerAntaresClass:class];
    }
}

- (void) registerAresClass:(Class<ResCoding>)class {
    ResType type = [class resType];


    if ([class isPacked]) {//data is a concatenated array of structs
        //500 seems to be used for all of ares's packed types
        const ResID packedResourceId = 500u;
        //Pull the data out of resource
        Handle dataH = GetResource(type, packedResourceId);
        HLock(dataH);
        Size size = GetHandleSize(dataH);
        NSData *data = [NSData dataWithBytes:*dataH length:size];
        HUnlock(dataH);
        ReleaseResource(dataH);
        size_t recSize = [class sizeOfResourceItem];
        NSUInteger count = size/recSize;
        //Dictionary is used because NSArray doesn't handle sparse arrays
        NSMutableDictionary *table = [NSMutableDictionary dictionaryWithCapacity:count];
        for (NSUInteger k = 0; k < count; k++) {
            ResSegment *seg = [[ResSegment alloc]
                               initWithClass:class
                               data:[data subdataWithRange:NSMakeRange(recSize * k, recSize)]
                               index:k
                               name:@""];
            if (class_conformsToProtocol(class, @protocol(ResIndexOverriding))) {
                [stack addObject:seg];
                seg.index = [(id<ResIndexOverriding>)class peekAtIndexWithCoder:self];
                [stack removeLastObject];
            }
            
            [table setObject:seg forKey:[[NSNumber numberWithUnsignedInteger:seg.index] stringValue]];
            [seg release];
        }
        [types setObject:table forKey:[class typeKey]];
    } else {//Use indexed resources
        ResourceCount count = CountResources(type);
        NSMutableDictionary *table = [NSMutableDictionary dictionaryWithCapacity:count];
        for (ResourceIndex index = 1; index <= count; index++) {
            Handle dataH = GetIndResource(type, index);
            //Pull out the ResId
            ResID rID;
            Str255 name;
            GetResInfo(dataH, &rID, NULL, name);
            NSString *str = [[NSString alloc] initWithBytes:&name[1] length:*name encoding:NSMacOSRomanStringEncoding];
            HLock(dataH);
            Size size = GetHandleSize(dataH);
            ResSegment *seg = [[ResSegment alloc]
                               initWithClass:class
                               data:[NSData dataWithBytes:*dataH length:size]
                               index:rID
                               name:str];
            [str release];
            [table setObject:seg forKey:[[NSNumber numberWithUnsignedShort:rID] stringValue]];
            [seg release];
            HUnlock(dataH);
            ReleaseResource(dataH);
        }
        [types setObject:table forKey:[class typeKey]];
        OSErr err = ResError();
        if (err != 0) {
            @throw [NSString stringWithFormat:@"Resource error: %d", err];
        }
    }
}

- (void) registerAntaresClass:(Class<ResCoding>)class {
    NSMutableDictionary *table = [NSMutableDictionary dictionary];
    for (NSString *base in files) {
        NSString *dir = [[base stringByAppendingPathComponent:@"data"] stringByAppendingPathComponent:[class typeKey]];
        NSError *error = nil;
        NSArray *subPaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:dir error:&error];
//        NSLog(@"PATHS: %@", dir);
        NSAssert(error == nil, @"ERROR %@", error);
        for (NSString *file in subPaths) {
            NSScanner *scanner = [NSScanner scannerWithString:[file stringByDeletingPathExtension]];
            int idx = 0xDEADBEEF;
            BOOL ok = YES;
            ok = [scanner scanInt:&idx];
            assert(ok);
            assert(idx != 0xDEADBEEF);
            if ([class isPacked] && idx != 500) {//only read packed data from index 500
                continue;
            }
            NSString *name = nil;
            ok = [scanner scanUpToString:@"\0" intoString:&name];
            assert(ok);
//            NSLog(@"FILE: %i|'%@'", idx, name);
            if ([class isPacked]) {
                NSData *data = [NSData dataWithContentsOfFile:[dir stringByAppendingPathComponent:file]];
                size_t recSize = [class sizeOfResourceItem];
                NSUInteger count = [data length]/recSize;
                for (int k = 0; k < count; k++) {
                    ResSegment *seg = [[ResSegment alloc] initWithClass:class data:[data subdataWithRange:NSMakeRange(recSize * k, recSize)] index:k name:@""];
                    if (class_conformsToProtocol(class, @protocol(ResIndexOverriding))) {
                        [stack addObject:seg];
                        seg.index = [(id<ResIndexOverriding>)class peekAtIndexWithCoder:self];
                        [stack removeLastObject];
                    }
                    [table setObject:seg forKey:[[NSNumber numberWithUnsignedInt:seg.index] stringValue]];
                    [seg release];
                }
            } else {
                ResSegment *seg = [[ResSegment alloc] initWithClass:class data:[NSData dataWithContentsOfFile:[dir stringByAppendingPathComponent:file]] index:idx name:name];
                [table setObject:seg forKey:[[NSNumber numberWithInt:idx] stringValue]];
                [seg release];
            }
        }
    }
    [types setObject:table forKey:[class typeKey]];
}

- (NSUInteger) countOfClass:(Class<ResCoding>)_class {
    NSMutableDictionary *table = [types objectForKey:[_class typeKey]];
    if (table == nil) {
        [self registerClass:_class];
        table = [types objectForKey:[_class typeKey]];
    }
    return [table count];
}

- (void) skip:(NSUInteger)bytes {
    [[stack lastObject] advance:bytes];
}

- (void) seek:(NSUInteger)position {
    [[stack lastObject] seek:position];
}

- (void) readBytes:(void *)buffer length:(NSUInteger)length {
    [[stack lastObject] readBytes:buffer length:length];
}

- (NSUInteger) currentIndex {
    return [[stack lastObject] index];
}

- (NSUInteger) currentSize {
    return [[[stack lastObject] data] length];
}

- (NSString *) currentName {
    NSString *name = [[stack lastObject] name];
    /*
     Fucking fancy quotes...
    The resource name for the audmedon assault transport's sound inexplicably contains a fancy quote mark.
     This messes up fopen so this fix is being hard coded for now.
    */
    return [name stringByReplacingOccurrencesOfString:@"\x2019" withString:@"'"];
}

- (NSData *)rawData {
    return [[stack lastObject] data];
}

- (UInt8) decodeUInt8 {
    UInt8 out;
    ResSegment *seg = [stack lastObject];
    [seg readBytes:&out length:sizeof(UInt8)];
    return out;
}

- (SInt8) decodeSInt8 {
    SInt8 out;
    [[stack lastObject] readBytes:&out length:sizeof(SInt8)];
    return out;
}

- (UInt16) decodeUInt16 {
    UInt16 out;
    [[stack lastObject] readBytes:&out length:sizeof(UInt16)];
    return CFSwapInt16BigToHost(out);
}

- (SInt16) decodeSInt16 {
    SInt16 out;
    [[stack lastObject] readBytes:&out length:sizeof(SInt16)];
    return CFSwapInt16BigToHost(out);
}

- (UInt16) decodeSwappedUInt16 {
    UInt16 out;
    [[stack lastObject] readBytes:&out length:sizeof(UInt16)];
    return out;;
}

- (SInt16) decodeSwappedSInt16 {
    SInt16 out;
    [[stack lastObject] readBytes:&out length:sizeof(SInt16)];
    return out;;
}

- (UInt32) decodeUInt32 {
    UInt32 out;
    [[stack lastObject] readBytes:&out length:sizeof(UInt32)];
    return CFSwapInt32BigToHost(out);
}

- (SInt32) decodeSInt32 {
    SInt32 out;
    [[stack lastObject] readBytes:&out length:sizeof(SInt32)];
    return CFSwapInt32BigToHost(out);
}

- (UInt32) decodeSwappedUInt32 {
    UInt32 out;
    [[stack lastObject] readBytes:&out length:sizeof(UInt32)];
    return out;
}

- (SInt32) decodeSwappedSInt32 {
    SInt32 out;
    [[stack lastObject] readBytes:&out length:sizeof(SInt32)];
    return out;
}

- (UInt64) decodeUInt64 {
    UInt64 out;
    [[stack lastObject] readBytes:&out length:sizeof(UInt64)];
    return CFSwapInt64BigToHost(out);
}

- (SInt64) decodeSInt64 {
    SInt64 out;
    [[stack lastObject] readBytes:&out length:sizeof(SInt64)];
    return CFSwapInt64BigToHost(out);
}

- (CGFloat) decodeFixed {
    return (CGFloat)[self decodeSInt32]/256.0f;
}

- (BOOL) hasObjectOfClass:(Class<ResCoding>)class atIndex:(NSUInteger)index {
    NSMutableDictionary *table = [types objectForKey:[class typeKey]];
    if (table == nil) {
        [self registerClass:class];
        table = [types objectForKey:[class typeKey]];
    }
    if (table == nil) return NO;
    ResSegment *seg =  [table objectForKey:[[NSNumber numberWithUnsignedInteger:index] stringValue]];
    return (seg != nil);
}

- (id)decodeObjectOfClass:(Class)class atIndex:(NSUInteger)index {
    NSMutableDictionary *table = [types objectForKey:[class typeKey]];
    if (table == nil) {
        [self registerClass:class];
        table = [types objectForKey:[class typeKey]];
    }
    if (table == nil) @throw [NSString stringWithFormat:@"Unable to access objects of type '%@'", [class typeKey]];
    ResSegment *seg =  [table objectForKey:[[NSNumber numberWithUnsignedInteger:index] stringValue]];
    if (seg == nil) @throw [NSString stringWithFormat:@"Failed to load resource of type '%@' at index %lu.", [class typeKey], index];
    [stack addObject:seg];
    id object = [seg loadObjectWithCoder:self];
    [stack removeLastObject];
    return object;
}

- (NSMutableDictionary *)allObjectsOfClass:(Class<ResCoding>)class {
    NSMutableDictionary *table = [types objectForKey:[class typeKey]];
    if (table == nil) {
        [self registerClass:class];
        table = [types objectForKey:[class typeKey]];
    }
    NSMutableDictionary *outDict = [NSMutableDictionary dictionary];
    NSArray *indexes = [table allKeys];
    for (NSString *key in indexes) {
        ResSegment *seg = [table objectForKey:key];
        [stack addObject:seg];
        [outDict setObject:[seg loadObjectWithCoder:self] forKey:key];
        [stack removeLastObject];
    }
    return outDict;
}

- (Index *) getIndexRefWithIndex:(NSUInteger)index forClass:(Class<Alloc, ResCoding>)class {
    NSMutableDictionary *table = [types objectForKey:[class typeKey]];
    if (table == nil) {
        [self registerClass:class];
        table = [types objectForKey:[class typeKey]];
    }
    return [[table objectForKey:[[NSNumber numberWithUnsignedInteger:index] stringValue]] indexRef];
}

- (NSString *) decodePString {
    UInt8 length;
    ResSegment *seg = [stack lastObject];
    [seg readBytes:&length length:sizeof(UInt8)];
    char *buffer = malloc(length + 1);
    [seg readBytes:buffer length:length];
    buffer[length] = '\0';//Just in case
    NSString *string = [NSString stringWithCString:buffer encoding:NSMacOSRomanStringEncoding];
    free(buffer);
    return string;
}

- (NSString *) decodePStringOfLength:(UInt8)length {
    UInt8 sLength;
    ResSegment *seg = [stack lastObject];
    [seg readBytes:&sLength length:1];
    char *buffer = malloc(length + 1);
    [seg readBytes:buffer length:length];
    buffer[sLength] = '\0';//Just in case
    NSString *string = [NSString stringWithCString:buffer encoding:NSMacOSRomanStringEncoding];
    free(buffer);
    return string;
}

@end
