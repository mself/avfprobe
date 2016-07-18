//
//  main.m
//  avfprobe
//
//  Created by Matthew Self on 7/13/16.
//  Copyright © 2016 Matthew Self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <stdio.h>
#import <stddef.h>

static void printAsset(int indent, AVURLAsset *asset);
static void printAssetTrack(int indent, AVAssetTrack *track);
static void printMetadataItem(int indent, AVMetadataItem *item);
static void printFormatDescription(int indent, CMFormatDescriptionRef formatDescription);
static void printAVMediaType(NSString *mediaType);
static void printCMMediaType(CMMediaType mediaType);
static void printTransform(int indent, CGAffineTransform transform);
static void printObject(int indent, NSObject *value);
static void printWithIndent(int indent, const char *format, ...);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            fprintf(stderr, "usage = %s file ...\n", argv[0]);
            exit(EXIT_FAILURE);
        }
        
        for (int i = 1; i < argc; i++) {
            NSString *arg = [NSString stringWithUTF8String:argv[i]];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:arg]) {
                fprintf(stderr, "can't open file = %s;\n", argv[i]);
                exit(EXIT_FAILURE);
            }
            
            AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath: arg]];
            
            if (asset.tracks.count == 0) {
                fprintf(stderr, "can't load asset = %s;\n", argv[i]);
                exit(EXIT_FAILURE);
            }
            
            // Print details of each asset.
            printAsset(0, asset);
            printf(";\n");
        }
    }
    
    return EXIT_SUCCESS;
}


// Helper methods for printf
@interface NSString (PrintHelper)
- (const char *)p;  // returns a c string
- (const char *)q;  // returns a quoted c string
@end

@implementation NSString (PrintHelper)
- (const char *)p
{
    return [self cStringUsingEncoding:NSUTF8StringEncoding];
}
- (const char *)q
{
    return [NSString stringWithFormat:@"\"%@\"", self].p;
}
@end


static void printAsset(int indent, AVURLAsset *asset)
{
    printf("{\n");
    indent++;
    
    // Asset Properties
    printWithIndent(indent, "// Asset Properties\n");
    printWithIndent(indent, "URL = %s;\n", asset.URL.absoluteString.q);
    
    printf("\n");
    
    // Determining Usability
    printWithIndent(indent, "// Determining Usability\n");
    printWithIndent(indent, "hasProtectedContent = %s;\n", asset.hasProtectedContent ? "YES" : "NO");
    printWithIndent(indent, "playable = %s;\n", asset.playable ? "YES" : "NO");
    printWithIndent(indent, "exportable = %s;\n", asset.exportable ? "YES" : "NO");
    printWithIndent(indent, "readable = %s;\n", asset.readable ? "YES" : "NO");
    printWithIndent(indent, "composable = %s;\n", asset.composable ? "YES" : "NO");
    
    printf("\n");
    
    // Accessing Common Metadata
    printWithIndent(indent, "// Accessing Common Metadata\n");
    printWithIndent(indent, "duration = {%lld/%d = %f}; // sec\n",
                    asset.duration.value, asset.duration.timescale, CMTimeGetSeconds(asset.duration));
    printWithIndent(indent, "providesPreciseDurationAndTiming = %s;\n", asset.providesPreciseDurationAndTiming ? "YES" : "NO");
    
    printf("\n");
    
    // Preferred Asset Attributes
    printWithIndent(indent, "// Preferred Asset Attributes\n");
    printWithIndent(indent, "preferredRate = %f;\n", asset.preferredRate);
    printWithIndent(indent, "preferredTransform = "); printTransform(indent, asset.preferredTransform); printf(";\n");
    printWithIndent(indent, "preferredVolume = %f;\n", asset.preferredVolume);
    
    printf("\n");
    
    // Media Selections
    printWithIndent(indent, "// Media Selections\n");
    printWithIndent(indent, "compatibleWithAirPlayVideo = %s;\n", asset.compatibleWithAirPlayVideo ? "YES" : "NO");
    printWithIndent(indent, "creationDate = "); printMetadataItem(indent, asset.creationDate); printf(";\n");
    
    printf("\n");
    
    // Tracks
    printWithIndent(indent, "// Tracks\n");
    printWithIndent(indent, "tracks = "); printObject(indent, asset.tracks); printf(";\n");
    
    // Track Groups
    // (ignore for now)
    
    printf("\n");
    
    // Metadata
    printWithIndent(indent, "// Metadata\n");
    printWithIndent(indent, "metadata = "); printObject(indent, asset.metadata); printf(";\n");
    
    printf("\n");
    
    // Lyrics
    printWithIndent(indent, "// Lyrics\n");
    printWithIndent(indent, "lyrics = %s;\n", asset.lyrics.q);
    
    indent--;
    printf("}");
}

static void printAssetTrack(int indent, AVAssetTrack *track)
{
    printf("{\n");
    indent++;
    
    // Track Properties
    printWithIndent(indent, "// Track Properties\n");
    printWithIndent(indent, "trackID = %d;\n", track.trackID);
    
    printWithIndent(indent, "mediaType = ");
    printAVMediaType(track.mediaType);
    printf("; // = %s\n", track.mediaType.q);
    
    printWithIndent(indent, "enabled = %s;\n", track.enabled ? "YES" : "NO");
    printWithIndent(indent, "playable = %s;\n", track.playable ? "YES" : "NO");
    printWithIndent(indent, "selfContained = %s;\n", track.selfContained ? "YES" : "NO");
    printWithIndent(indent, "totalSampleDataLength = %lld; // bytes (= %f bps)\n", track.totalSampleDataLength,
                    8 * track.totalSampleDataLength / CMTimeGetSeconds(track.timeRange.duration));
    
    printf("\n");
    
    // Temporal Properties
    printWithIndent(indent, "// Temporal Properties\n");
    printWithIndent(indent, "timeRange = {\n");
    printWithIndent(indent + 1, "start = {%lld/%d = %f}; // sec\n",
                    track.timeRange.start.value, track.timeRange.start.timescale, CMTimeGetSeconds(track.timeRange.start));
    printWithIndent(indent + 1, "duration = {%lld/%d = %f}; // sec\n",
                    track.timeRange.duration.value, track.timeRange.duration.timescale, CMTimeGetSeconds(track.timeRange.duration));
    printWithIndent(indent, "};\n");
    printWithIndent(indent, "naturalTimeScale = %d; // {1/%d = %f} sec\n", track.naturalTimeScale,
                    track.naturalTimeScale, 1.0 / track.naturalTimeScale);
    printWithIndent(indent, "estimatedDataRate = %f; // bps\n", track.estimatedDataRate);
    
    printf("\n");
    
    // Track Language Properties
    printWithIndent(indent, "// Track Language Properties\n");
    printWithIndent(indent, "languageCode = %s;\n", track.languageCode.q);
    printWithIndent(indent, "extendedLanguageTag = %s;\n", track.extendedLanguageTag.q);
    
    printf("\n");
    
    // Visual Characteristics
    printWithIndent(indent, "// Visual Characteristics\n");
    printWithIndent(indent, "naturalSize = {\n");
    printWithIndent(indent + 1, "width = %f;\n", track.naturalSize.width);
    printWithIndent(indent + 1, "height = %f;\n", track.naturalSize.height);
    printWithIndent(indent, "};\n");
    printWithIndent(indent, "preferredTransform = "); printTransform(indent, track.preferredTransform); printf(";\n");
    
    printf("\n");
    
    // Audible Characteristics
    printWithIndent(indent, "// Audible Characteristics\n");
    printWithIndent(indent, "preferredVolume = %f;\n", track.preferredVolume);
    
    printf("\n");
    
    // Frame-Based Characteristics
    printWithIndent(indent, "// Frame-Based Characteristics\n");
    printWithIndent(indent, "nominalFrameRate = %f; // fps (= {%f / %d} sec/frame)\n", track.nominalFrameRate,
                    track.naturalTimeScale / track.nominalFrameRate, track.naturalTimeScale);
    printWithIndent(indent, "minFrameDuration = {%lld / %d = %f}; // sec (= %f fps)\n", track.minFrameDuration.value,
                    track.minFrameDuration.timescale, CMTimeGetSeconds(track.minFrameDuration),
                    1 / CMTimeGetSeconds(track.minFrameDuration));
    printWithIndent(indent, "requiresFrameReordering = %s;\n", track.requiresFrameReordering ? "YES" : "NO");
    
    printf("\n");
    
    // Track Segments
    // (ignore for now)
    
    // Format Descriptions
    printWithIndent(indent, "// Format Descriptions\n");
    printWithIndent(indent, "formatDescriptions = "); printObject(indent, track.formatDescriptions); printf(";\n");
    
    printf("\n");
    
    // Metadata
    printWithIndent(indent, "// Metadata\n");
    printWithIndent(indent, "metadata = "); printObject(indent, track.metadata); printf(";\n");
    
    indent--;
    printWithIndent(indent, "}");
}

static void printMetadataItem(int indent, AVMetadataItem *item)
{
    printf("{\n");
    indent++;
    
    // Keys and Key Spaces
    printWithIndent(indent, "identifier = %s;\n", item.identifier.q);
    printWithIndent(indent, "keySpace = %s;\n", item.keySpace.q);
    printWithIndent(indent, "key = "); printObject(indent, item.key); printf(";\n");
    printWithIndent(indent, "commonKey = %s;\n", item.commonKey.q);
    
    // Accessing Values
    printWithIndent(indent, "dataType = %s;\n", item.dataType.q);
    printWithIndent(indent, "value = "); printObject(indent, item.value); printf(";\n");
    printWithIndent(indent, "time = {%lld/%d = %f}; // sec\n", item.time.value, item.time.timescale,
                    CMTimeGetSeconds(item.time));
    printWithIndent(indent, "duration = {%lld/%d = %f}; // sec\n", item.duration.value, item.duration.timescale,
                    CMTimeGetSeconds(item.duration));
    printWithIndent(indent, "locale = %s;\n", item.locale.localeIdentifier.q);
    printWithIndent(indent, "extendedLanguageTag = %s;\n", item.extendedLanguageTag.q);
    
    indent--;
    printWithIndent(indent, "}");
}

static void printFormatDescription(int indent, CMFormatDescriptionRef formatDescription)
{
#if 0
    // Use the native description as a cross-reference to debug.
    NSObject *formatObject = (__bridge NSObject *)(formatDescription);
    printWithIndent(indent, "%s\n\n", formatObject.description.p);
#endif
    
    printf("{\n");
    indent++;
    
    // Media-type-Agnostic Functions
    printWithIndent(indent, "// Media-type-Agnostic Functions\n");
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDescription);
    printWithIndent(indent, "mediaType = ");
    printCMMediaType(mediaType);
    printf("; // = %s\n", NSFileTypeForHFSTypeCode(mediaType).p);
    
    FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription);
    printWithIndent(indent, "mediaSubType = %s;\n", NSFileTypeForHFSTypeCode(mediaSubType).p);
    
    printf("\n");
    
    if (mediaType == kCMMediaType_Audio) {
        // Audio-Specific Functions
        printWithIndent(indent, "// Audio-Specific Functions\n");
        const AudioStreamBasicDescription *desc = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
        if (desc) {
            printWithIndent(indent, "AudioStreamBasicDescription = {\n");
            printWithIndent(indent + 1, "mSampleRate = %f;\n", desc->mSampleRate);
            printWithIndent(indent + 1, "mFormatID = %s;\n", NSFileTypeForHFSTypeCode(desc->mFormatID).p);
            printWithIndent(indent + 1, "mFormatFlags = 0x%x;\n", desc->mFormatFlags);
            printWithIndent(indent + 1, "mBytesPerPacket = %d;\n", desc->mBytesPerPacket);
            printWithIndent(indent + 1, "mFramesPerPacket = %d;\n", desc->mFramesPerPacket);
            printWithIndent(indent + 1, "mBytesPerFrame = %d;\n", desc->mBytesPerFrame);
            printWithIndent(indent + 1, "mChannelsPerFrame = %d;\n", desc->mChannelsPerFrame);
            printWithIndent(indent + 1, "mBitsPerChannel = %d;\n", desc->mBitsPerChannel);
            // printWithIndent(indent + 1, "mReserved = %d;\n", desc->mReserved);
            printWithIndent(indent, "};\n");
        }
        
        size_t cookieSize = 0;
        const void *magicCookie = CMAudioFormatDescriptionGetMagicCookie(formatDescription, &cookieSize);
        NSData *data = [NSData dataWithBytes:magicCookie length:cookieSize];
        printWithIndent(indent, "magicCookie = "); printObject(indent, data); printf(";\n");
        
        const AudioChannelLayout *layout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, NULL);
        if (layout) {
            printWithIndent(indent, "AudioChannelLayout = {\n");
            indent++;
            
            printWithIndent(indent, "mChannelLayoutTag = ");
            if (layout->mChannelLayoutTag == kAudioChannelLayoutTag_Mono) {
                printf("kAudioChannelLayoutTag_Mono");
            } else if (layout->mChannelLayoutTag == kAudioChannelLayoutTag_Stereo) {
                printf("kAudioChannelLayoutTag_Stereo");
            } else {
                printf("(%d<<16) | %d", layout->mChannelLayoutTag >> 16, layout->mChannelLayoutTag & ((1<<16) - 1));
            }
            printf(";\n");
            
            printWithIndent(indent, "mChannelBitmap = 0x%08x;\n", layout->mChannelBitmap);
            // printWithIndent(indent, "mNumberChannelDescriptions = %d;\n", layout->mNumberChannelDescriptions);
            printWithIndent(indent, "mChannelDescriptions = [\n");
            indent++;
            
            for (int i = 0; i < layout->mNumberChannelDescriptions; i++) {
                printWithIndent(indent, "{\n");
                indent++;
                printWithIndent(indent, "mChannelLabel = %d;\n", layout->mChannelDescriptions[i].mChannelLabel);
                printWithIndent(indent, "mChannelFlags = %x;\n", layout->mChannelDescriptions[i].mChannelFlags);
                printWithIndent(indent, "mCoordinates = (%f, %f, %f);\n", layout->mChannelDescriptions[i].mCoordinates[0],
                                layout->mChannelDescriptions[i].mCoordinates[1],
                                layout->mChannelDescriptions[i].mCoordinates[2]);
                indent--;
                printWithIndent(indent, "};\n");
            }
            indent--;
            printWithIndent(indent, "];\n");
            indent--;
            printWithIndent(indent, "};\n");
        }
        
        // FormatList
        // TODO: Not implemented yet
    } else if (mediaType == kCMMediaType_Video) {
        // Video-Specific Functions
        printWithIndent(indent, "// Audio-Specific Functions\n");
        CMVideoDimensions videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDescription);
        printWithIndent(indent, "videoDimensions = {\n");
        printWithIndent(indent + 1, "width = %d;\n", videoDimensions.width);
        printWithIndent(indent + 1, "height = %d;\n", videoDimensions.height);
        printWithIndent(indent, "};\n");
        
        // CleanAperture
        // TODO: Not implemented yet
    } else if (mediaType == kCMMediaType_Muxed) {
        // Muxed-Specific Functions
        
        // None
    } else if (mediaType == kCMMediaType_Metadata) {
        // Metadata-Specific Functions
        printWithIndent(indent, "// Metadata-Specific Functions\n");
        
        // The data available from CMMetadataFormatDescriptionGetKeyWithLocalID() is all duplicated in
        // the MetadataKeyTable extension, so don't print it here.
        // Plus, there is no way to enumerate all of the valid localKeyID values.
    } else if (mediaType == kCMMediaType_Text) {
        // Text-Specific Functions
        // TODO: Not implemented yet
    } else if (mediaType == kCMMediaType_TimeCode) {
        // TimeCode-Specific Functions
        printWithIndent(indent, "// TimeCode-Specific Functions\n");
        
        // FrameDuration
        CMTime frameDuration = CMTimeCodeFormatDescriptionGetFrameDuration(formatDescription);
        printWithIndent(indent, "frameDuration = {%lld/%d = %f};\n",
                        frameDuration.value, frameDuration.timescale, CMTimeGetSeconds(frameDuration));
        
        // FrameQuanta
        uint32_t frameQuanta = CMTimeCodeFormatDescriptionGetFrameQuanta(formatDescription);
        printWithIndent(indent, "frameQuanta = %d;\n", frameQuanta);
        
        // TimeCodeFlags
        uint32_t flags = CMTimeCodeFormatDescriptionGetTimeCodeFlags(formatDescription);
        printWithIndent(indent, "timeCodeFlags = %d; //", flags);
        if (flags & kCMTimeCodeFlag_DropFrame) {
            printf(" kCMTimeCodeFlag_DropFrame");
        }
        if (flags & kCMTimeCodeFlag_24HourMax) {
            printf(" kCMTimeCodeFlag_24HourMax");
        }
        if (flags & kCMTimeCodeFlag_NegTimesOK) {
            printf(" kCMTimeCodeFlag_NegTimesOK");
        }
        printf("\n");
    }
    
    printf("\n");
    
    // Extensions
    printWithIndent(indent, "// Extensions\n");
    NSDictionary *extensions = (__bridge NSDictionary *)(CMFormatDescriptionGetExtensions(formatDescription));
    printWithIndent(indent, "extensions = "); printObject(indent, extensions); printf(";\n");
    
    indent--;
    printWithIndent(indent, "}");
}

static void printAVMediaType(NSString *mediaType)
{
    if ([mediaType isEqualToString:AVMediaTypeVideo]) {
        printf("AVMediaTypeVideo");
    } else if ([mediaType isEqualToString:AVMediaTypeAudio]) {
        printf("AVMediaTypeAudio");
    } else if ([mediaType isEqualToString:AVMediaTypeText]) {
        printf("AVMediaTypeText");
    } else if ([mediaType isEqualToString:AVMediaTypeClosedCaption]) {
        printf("AVMediaTypeClosedCaption");
    } else if ([mediaType isEqualToString:AVMediaTypeSubtitle]) {
        printf("AVMediaTypeSubtitle");
    } else if ([mediaType isEqualToString:AVMediaTypeTimecode]) {
        printf("AVMediaTypeTimecode");
    } else if ([mediaType isEqualToString:AVMediaTypeMetadata]) {
        printf("AVMediaTypeMetadata");
    } else if ([mediaType isEqualToString:AVMediaTypeMuxed]) {
        printf("AVMediaTypeMuxed");
    } else {
        printf("%s", mediaType.q);
    }
}

static void printCMMediaType(CMMediaType mediaType)
{
    if (mediaType == kCMMediaType_Video) {
        printf("kCMMediaType_Video");
    } else if (mediaType == kCMMediaType_Audio) {
        printf("kCMMediaType_Audio");
    } else if (mediaType == kCMMediaType_Muxed) {
        printf("kCMMediaType_Muxed");
    } else if (mediaType == kCMMediaType_Text) {
        printf("kCMMediaType_Text");
    } else if (mediaType == kCMMediaType_ClosedCaption) {
        printf("kCMMediaType_ClosedCaption");
    } else if (mediaType == kCMMediaType_Subtitle) {
        printf("kCMMediaType_Subtitle");
    } else if (mediaType == kCMMediaType_TimeCode) {
        printf("kCMMediaType_TimeCode");
    } else if (mediaType == kCMMediaType_Metadata) {
        printf("kCMMediaType_Metadata");
    } else {
        printf("%s", NSFileTypeForHFSTypeCode(mediaType).p);
    }
}

static void printTransform(int indent, CGAffineTransform transform)
{
    if (CGAffineTransformIsIdentity(transform)) {
        printf("CGAffineTransformIdentity");
    } else {
        printf("{\n");
        printWithIndent(indent + 1, "%f, %f, %f\n", transform.a, transform.b, 0.0);
        printWithIndent(indent + 1, "%f, %f, %f\n", transform.c, transform.d, 0.0);
        printWithIndent(indent + 1, "%f, %f, %f\n", transform.tx, transform.ty, 1.0);
        printWithIndent(indent, "}");
    }
}

static void printObject(int indent, NSObject *value) {
    if (!value) {
        printf("nil");
    } else if ([value isKindOfClass:[AVURLAsset class]] ) {
        printAsset(indent, (AVURLAsset *)value);
    } else if ([value isKindOfClass:[AVAssetTrack class]] ) {
        printAssetTrack(indent, (AVAssetTrack *)value);
    } else if ([value isKindOfClass:[AVMetadataItem class]] ) {
        printMetadataItem(indent, (AVMetadataItem *)value);
    } else if (CFGetTypeID((__bridge CFTypeRef)(value)) == CMFormatDescriptionGetTypeID()) {
        printFormatDescription(indent, (__bridge CMFormatDescriptionRef)value);
    } else if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)value;
        
        if ((__bridge CFBooleanRef)number == kCFBooleanTrue) {
            printf("YES");
        } else if ((__bridge CFBooleanRef)number == kCFBooleanFalse) {
            printf("NO");
        } else {
            printf("%s", value.description.p);
        }
    } else if ([value isKindOfClass:[NSDate class]] ) {
        printf("%s", ((NSDate *)value).description.p);
    } else if ([value isKindOfClass:[NSString class]] ) {
        printf("%s", ((NSString *)value).q);
    } else if ([value isKindOfClass:[NSData class]] ) {
        // See if we can interpret the raw data as a UTF8 string.
        NSString *dataString = [[NSString alloc] initWithData:((NSData *)value) encoding:NSUTF8StringEncoding];
        
        if (dataString && dataString.length > 0 && [dataString characterAtIndex:0] != '\0') {
            dataString = [dataString stringByReplacingOccurrencesOfString:@"\0" withString:@"\\0"];
            dataString = [dataString stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
            dataString = [dataString stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
            dataString = [dataString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            
            if (dataString.length > 0) {
                printf("(NSData *)%s", dataString.q);
            } else {
                printf("%s", value.description.p);
            }
        } else {
            printf("%s", value.description.p);
        }
    } else if ([value isKindOfClass:[NSArray class]] ) {
        NSArray *array = (NSArray *)value;
        
        if (array.count == 0) {
            printf("[]");
        } else {
            printf("[\n");
            for (NSObject *item in array) {
                printWithIndent(indent + 1, ""); printObject(indent + 1, item);
                if (item == array.lastObject) {
                    printf("\n");
                } else {
                    printf(",\n");
                }
            }
            printWithIndent(indent, "]");
        }
    } else if ([value isKindOfClass:[NSDictionary class]] ) {
        NSDictionary *dictionary = (NSDictionary *)value;
        
        if (dictionary.count == 0) {
            printf("{}");
        } else {
            printf("{\n");
            for (NSString *key in [dictionary.allKeys sortedArrayUsingComparator: ^(id obj1, id obj2) {
                return [(NSString *)obj1 compare:(NSString *)obj2];
            }]) {
                printWithIndent(indent + 1, "%s = ", key.q);
                printObject(indent + 1, dictionary[key]);
                printf(";\n");
            }
            printWithIndent(indent, "}");
        }
    } else {
        printf("(%s *) %s", value.className.p, value.description.p);
    }
}

static void printWithIndent(int indent, const char *format, ...)
{
    const int spacesToIndent = 4;
    
    va_list(args);
    va_start(args, format);
    printf("%*s", spacesToIndent * indent, "");
    vprintf(format, args);
}
