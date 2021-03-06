//
//  MainData.m
//  Athena
//
//  Created by Scott McClaugherty on 1/20/11.
//  Copyright 2011 Scott McClaugherty. All rights reserved.
//

#import "MainData.h"
#import "Archivers.h"

#import "BaseObject.h"
#import "Action.h"
#import "Scenario.h"
#import "BriefPoint.h"
#import "ScenarioInitial.h"
#import "Condition.h"
#import "Race.h"

#import "SMIVImage.h"
#import "XSSound.h"
#import "XSImage.h"

#import "VersionFormatter.h"

//CBA0 = A.B.C
const uint32_t ARES_VERSION_MIN = 0x00000201; //1.2.0
const uint32_t DEFAULT_SCENARIO_VERSION = 0x00000001; //1.0.0

static NSArray *mainDataKeys;
@implementation MainDataFlags
@synthesize isNetworkable, customObjects, customRaces, customScenarios, isUnoptimized;

+ (NSArray *)keys {
    if (mainDataKeys == nil) {
        mainDataKeys = [[NSArray alloc] initWithObjects:@"isNetworkable", @"customObjects", @"customRaces", @"customScenarios", @"isUnoptimized", nil];
    }
    return mainDataKeys;
}
@end


@implementation MainData
@synthesize warpInFlare, warpOutFlare, playerBody, energyBlob;
@synthesize title, downloadUrl, author, authorUrl, identifier, flags;
@synthesize version, minVersion;
//@synthesize checkSum;

@synthesize objects, scenarios, races;
@synthesize sprites, sounds, images;

- (id) init {
    self = [super init];
    if (self) {
        warpInFlare = [[Index alloc] init];
        warpOutFlare = [[Index alloc] init];
        playerBody = [[Index alloc] init];
        energyBlob = [[Index alloc] init];
        title = @"";
        downloadUrl = @"";
        author = @"";
        authorUrl = @"";
        identifier = @"";
        version = DEFAULT_SCENARIO_VERSION;
        minVersion = ARES_VERSION_MIN;

        flags = [[MainDataFlags alloc] init];

        objects = [[NSMutableArray alloc] init];
        scenarios = [[NSMutableArray alloc] init];
        races = [[NSMutableArray alloc] init];
        sprites = [[NSMutableArray alloc] init];
        sounds = [[NSMutableArray alloc] init];
        images = [[NSMutableArray alloc] init];
        [self addObserver:self forKeyPath:@"objects" options:NSKeyValueObservingOptionPrior | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
        [self addObserver:self forKeyPath:@"scenarios" options:NSKeyValueObservingOptionPrior | NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
    return self;
}

//MARK: Lua Coding
- (id) initWithLuaCoder:(LuaUnarchiver *)coder {
    self = [self init];
    if (self) {
        title = [[coder decodeStringForKey:@"title"] retain];
        downloadUrl = [[coder decodeStringForKey:@"downloadUrl"] retain];
        author = [[coder decodeStringForKey:@"author"] retain];
        authorUrl = [[coder decodeStringForKey:@"authorUrl"] retain];
        identifier = [[coder decodeStringForKey:@"identifier"] retain];

        NSNumber *versObj = nil;
        BOOL ok = [[[[VersionFormatter alloc] init] autorelease] getObjectValue:&versObj forString:[coder decodeStringForKey:@"version"] errorDescription:nil];
        if (ok) {
            version = [versObj unsignedIntValue];
        }
        
        [self setWarpInFlare:[coder getIndexRefWithIndex:[coder decodeIntegerForKey:@"warpInFlare"]
                                                forClass:[BaseObject class]]];
        [self setWarpOutFlare:[coder getIndexRefWithIndex:[coder decodeIntegerForKey:@"warpOutFlare"] forClass:[BaseObject class]]];
        [self setPlayerBody:[coder getIndexRefWithIndex:[coder decodeIntegerForKey:@"playerBody"] forClass:[BaseObject class]]];
        [self setEnergyBlob:[coder getIndexRefWithIndex:[coder decodeIntegerForKey:@"energyBlob"] forClass:[BaseObject class]]];

        [objects    setArray:[coder decodeArrayOfClass:[BaseObject class]      forKey:@"objects"    zeroIndexed:YES]];
        [scenarios  setArray:[coder decodeArrayOfClass:[Scenario class]        forKey:@"scenarios"  zeroIndexed:YES]];
        [races      setArray:[coder decodeArrayOfClass:[Race class]            forKey:@"race"       zeroIndexed:YES]];
        [sprites setArray:[[coder decodeDictionaryOfClass:[SMIVImage class] forKey:@"sprites"] allValues]];
        [sounds setArray:[[coder decodeDictionaryOfClass:[XSSound class] forKey:@"sounds"] allValues]];
        [images setArray:[[coder decodeDictionaryOfClass:[XSImage class] forKey:@"images"] allValues]];

        [flags initWithLuaCoder:coder];
    }
    return self;
}

- (void) encodeLuaWithCoder:(LuaArchiver *)coder {
    [coder encodeString:title forKey:@"title"];
    [coder encodeString:downloadUrl forKey:@"downloadUrl"];
    [coder encodeString:author forKey:@"author"];
    [coder encodeString:authorUrl forKey:@"authorUrl"];
    
    [coder encodeString:[[[[VersionFormatter alloc] init] autorelease] stringForObjectValue:[NSNumber numberWithUnsignedInt:version]]
                 forKey:@"version"];
    
    if (identifier == nil || [identifier isEqualTo:@""]) {
        [coder encodeString:[[self computedIdentifier] stringByAppendingString:@"\n"]
                     forKey:@"identifier"];
    } else {
        [coder encodeString:[identifier stringByAppendingString:@"\n"]
                     forKey:@"identifier"];
    }
    [flags encodeLuaWithCoder:coder];

    [coder encodeInteger:warpInFlare.orNull forKey:@"warpInFlare"];
    [coder encodeInteger:warpOutFlare.orNull forKey:@"warpOutFlare"];
    [coder encodeInteger:playerBody.orNull forKey:@"playerBody"];
    [coder encodeInteger:energyBlob.orNull forKey:@"energyBlob"];

    [coder encodeArray:objects    forKey:@"objects"    zeroIndexed:YES];
    [coder encodeArray:scenarios  forKey:@"scenarios"  zeroIndexed:YES];
    [coder encodeArray:races      forKey:@"race"       zeroIndexed:YES];
    [coder encodeDictionary:[NSDictionary dictionaryWithObjects:sprites forKeys:[sprites valueForKeyPath:@"objectIndex"]] forKey:@"sprites" asArray:YES];
    [coder encodeDictionary:[NSDictionary dictionaryWithObjects:sounds forKeys:[sounds valueForKeyPath:@"objectIndex"]] forKey:@"sounds" asArray:YES];
    [coder encodeDictionary:[NSDictionary dictionaryWithObjects:images forKeys:[images valueForKeyPath:@"objectIndex"]] forKey:@"images" asArray:YES];
}

- (void) finishLoadingFromLuaWithRootData:(id)data {
    [objects makeObjectsPerformSelector:@selector(finishLoadingFromLuaWithRootData:) withObject:data];
    [scenarios makeObjectsPerformSelector:@selector(finishLoadingFromLuaWithRootData:) withObject:data];
}

+ (BOOL) isComposite {
    return YES;
}

+ (Class) classForLuaCoder:(LuaUnarchiver *)coder {
    return self;
}

//MARK: Res Coding
- (id)initWithResArchiver:(ResUnarchiver *)coder {
    self = [self init];
    if (self) {
        if ([coder sourceType] == DataBasisAntares && [[coder getMetadataForKey:@"version"] intValue] != 1) {
            [self release];
            return nil;
        }
        int inFlareId = [coder decodeSInt32];
        if (inFlareId >= 0) [self setWarpInFlare:[coder getIndexRefWithIndex:inFlareId forClass:[BaseObject class]]];
        
        int outFlareId = [coder decodeSInt32];
        if (outFlareId >= 0) [self setWarpOutFlare:[coder getIndexRefWithIndex:outFlareId forClass:[BaseObject class]]];
        
        int playerBodyId = [coder decodeSInt32];
        if (playerBodyId >= 0) [self setPlayerBody:[coder getIndexRefWithIndex:playerBodyId forClass:[BaseObject class]]];
        
        int energyBlobId = [coder decodeSInt32];
        if (energyBlobId >= 0) [self setEnergyBlob:[coder getIndexRefWithIndex:energyBlobId forClass:[BaseObject class]]];

        downloadUrl = [[coder decodePStringOfLength:0xff] retain];
        title = [[coder decodePStringOfLength:0xff] retain];
        author = [[coder decodePStringOfLength:0xff] retain];
        authorUrl = [[coder decodePStringOfLength:0xff] retain];

        identifier = [[coder getMetadataForKey:@"identifier"] retain];

        version = [coder decodeSwappedUInt32];
        minVersion = [coder decodeSwappedUInt32];

        [flags initWithResArchiver:coder];
        checkSum = [coder decodeUInt32];

        NSUInteger count;
        count = [coder countOfClass:[Race class]];
        for (NSUInteger index = 0; index < count; index++) {
            [races addObject:[coder decodeObjectOfClass:[Race class] atIndex:index]];
        }

        count = [coder countOfClass:[Scenario class]];
        for (NSUInteger index = 0; index < count; index++) {
            [scenarios addObject:[coder decodeObjectOfClass:[Scenario class] atIndex:index]];
        }

        count = [coder countOfClass:[BaseObject class]];
        for (NSUInteger index = 0; index < count; index++) {
            [objects addObject:[coder decodeObjectOfClass:[BaseObject class] atIndex:index]];
        }

        [sprites setArray:[[coder allObjectsOfClass:[SMIVImage class]] allValues]];

        [sounds setArray:[[coder allObjectsOfClass:[XSSound class]] allValues]];

        [images setArray:[[coder allObjectsOfClass:[XSImage class]] allValues]];

        //Remove blacklisted images.
        assert([[NSNumber numberWithInt:42] isEqual:[NSNumber numberWithShort:42]]);
        NSSet *imageBlacklist = [XSImage blacklistedImageIDs];
        NSArray *imagesIter = [images copy];
        for (XSImage *image in imagesIter) {
            if ([imageBlacklist containsObject:[NSNumber numberWithShort:image.objectIndex]]) {
                [images removeObject:image];
            }
        }
        [imagesIter release];
    }
    return self;
}

- (void)encodeResWithCoder:(ResArchiver *)coder {
    //ENCODE OTHER OBJECTS AND STUFF!!!
    for (Race *race in races) {
        [coder encodeObject:race];
    }

    for (Scenario *scenario in scenarios) {
        [coder encodeObject:scenario];
    }

    for (BaseObject *object in objects) {
        [coder encodeObject:object];
    }

    for (SMIVImage *sprite in sprites) {
        [coder encodeObject:sprite atIndex:sprite.objectIndex];
    }

    for (XSSound *sound in sounds) {
        [coder encodeObject:sound atIndex:sound.objectIndex];
    }
    
    for (XSImage *image in images) {
        [coder encodeObject:image atIndex:image.objectIndex];
    }

    [coder extend:1056];
    [coder encodeSInt32:warpInFlare.orNull];
    [coder encodeSInt32:warpOutFlare.orNull];
    [coder encodeSInt32:playerBody.orNull];
    [coder encodeSInt32:energyBlob.orNull];

    [coder encodePString:downloadUrl ofFixedLength:255u];
    [coder encodePString:title ofFixedLength:255u];
    [coder encodePString:author ofFixedLength:255u];
    [coder encodePString:authorUrl ofFixedLength:255u];

    [coder encodeSwappedUInt32:version];
    [coder encodeSwappedUInt32:minVersion];

    flags.isUnoptimized = YES;
    flags.customRaces = YES;
    flags.customObjects = YES;
    flags.customScenarios = YES;
    [flags encodeResWithCoder:coder];

    [coder flatten];
    //Compile CheckSum
    checkSum = 0;
    checkSum ^= [coder checkSumForIndex:500u ofPlane:@"sncd"];
    checkSum ^= [coder checkSumForIndex:500u ofPlane:@"obac"];
    checkSum ^= [coder checkSumForIndex:500u ofPlane:@"snit"];
    checkSum ^= [coder checkSumForIndex:500u ofPlane:@"bsob"];
    checkSum ^= [coder checkSumForIndex:500u ofPlane:@"snro"];
    [coder encodeUInt32:checkSum];

    [coder addMetadata:@"1\n" forKey:@"version"];
    
    if (identifier == nil || [identifier isEqualTo:@""]) {
        [coder addMetadata:[[self computedIdentifier] stringByAppendingString:@"\n"] forKey:@"identifier"];
    } else {
        [coder addMetadata:[identifier stringByAppendingString:@"\n"]
                    forKey:@"identifier"];
    }
}

+ (ResType)resType {
    return 'nlAG';
}

+ (NSString *)typeKey {
    return @"nlAG";
}

+ (BOOL) isPacked {
    return NO;
}

+ (size_t) sizeOfResourceItem {
    return 1056;
}

- (NSString *) computedIdentifier {
    NSString *tTitle = [title stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (tTitle == nil || [tTitle isEqualTo:@""]) {
        tTitle = @"untitled";
    }
    NSString *tAuthor = [author stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (tAuthor == nil || [tTitle isEqualTo:@""]) {
        tAuthor = @"unknown";
    }
    return [[NSString stringWithFormat:@"com.%@.%@", tAuthor, tTitle] lowercaseString];
    
}

- (void) dealloc {
    [self removeObserver:self forKeyPath:@"objects"];
    [self removeObserver:self forKeyPath:@"scenarios"];
    [objects release];
    [scenarios release];
    [races release];
    [sprites release];
    [sounds release];
    [images release];

    [flags release];
    [title release];
    [author release];
    [authorUrl release];
    [downloadUrl release];
    [identifier release];
    [energyBlob release];
    [playerBody release];
    [warpOutFlare release];
    [warpInFlare release];
    [super dealloc];
}

+ (NSSet *)keyPathsForValuesAffectingComputedIdentifier {
    return [NSSet setWithObjects:@"title", @"author", nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    BOOL isPrior = [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
    NSInteger kind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
    NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
    if (isPrior) {
        if (kind == NSKeyValueChangeInsertion) {
            [[object valueForKeyPath:keyPath] makeObjectsPerformSelector:@selector(objectsAddedAtIndexes:) withObject:indexes];
        }
    } else {
        if (kind == NSKeyValueChangeRemoval) {
            [[object valueForKeyPath:keyPath] makeObjectsPerformSelector:@selector(objectsRemovedAtIndexes:) withObject:indexes];
            //TODO: Make the next to calls work if there is more than one change.
            [[[change objectForKey:NSKeyValueChangeOldKey] objectAtIndex:0] setObjectIndex:[indexes firstIndex]];
        } else if (kind == NSKeyValueChangeInsertion) {
            [[[change objectForKey:NSKeyValueChangeNewKey] objectAtIndex:0] setObjectIndex:[indexes firstIndex]];
        }
    }
}
@end
