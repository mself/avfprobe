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
static void printObject(int indent, NSObject *value);
static void printWithIndent(int indent, const char *format, ...);
static void printTransform(int indent, CGAffineTransform transform);
static void printAVMediaType(NSString *mediaType);
static void printFourCharCode(CMMediaType mediaType);

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
    printf("; // %s\n", track.mediaType.q);
    
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
    FourCharCode mediaType = CMFormatDescriptionGetMediaType(formatDescription);
    printWithIndent(indent, "mediaType = ");
    printFourCharCode(mediaType);
    
    FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription);
    printWithIndent(indent, "mediaSubType = ");
    printFourCharCode(mediaSubType);
    
    printf("\n");
    
    if (mediaType == kCMMediaType_Audio) {
        // Audio-Specific Functions
        printWithIndent(indent, "// Audio-Specific Functions\n");
        const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
        if (asbd) {
            printWithIndent(indent, "AudioStreamBasicDescription = {\n");
            printWithIndent(indent + 1, "mSampleRate = %f;\n", asbd->mSampleRate);
            
            printWithIndent(indent + 1, "mFormatID = ");
            printFourCharCode(asbd->mFormatID);
            
            printWithIndent(indent + 1, "mFormatFlags = 0x%x;\n", asbd->mFormatFlags);
            printWithIndent(indent + 1, "mBytesPerPacket = %d;\n", asbd->mBytesPerPacket);
            printWithIndent(indent + 1, "mFramesPerPacket = %d;\n", asbd->mFramesPerPacket);
            printWithIndent(indent + 1, "mBytesPerFrame = %d;\n", asbd->mBytesPerFrame);
            printWithIndent(indent + 1, "mChannelsPerFrame = %d;\n", asbd->mChannelsPerFrame);
            printWithIndent(indent + 1, "mBitsPerChannel = %d;\n", asbd->mBitsPerChannel);
            // printWithIndent(indent + 1, "mReserved = %d;\n", asbd->mReserved);
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
            if (layout->mNumberChannelDescriptions == 0) {
                printWithIndent(indent, "mChannelDescriptions = [];\n");
            } else {
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
            }
            
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

static void printFourCharCode(FourCharCode fourCharCode)
{
    // CMMediaType
    if (fourCharCode == kCMMediaType_Video) {
        printf("kCMMediaType_Video");
    } else if (fourCharCode == kCMMediaType_Audio) {
        printf("kCMMediaType_Audio");
    } else if (fourCharCode == kCMMediaType_Muxed) {
        printf("kCMMediaType_Muxed");
    } else if (fourCharCode == kCMMediaType_Text) {
        printf("kCMMediaType_Text");
    } else if (fourCharCode == kCMMediaType_ClosedCaption) {
        printf("kCMMediaType_ClosedCaption");
    } else if (fourCharCode == kCMMediaType_Subtitle) {
        printf("kCMMediaType_Subtitle");
    } else if (fourCharCode == kCMMediaType_TimeCode) {
        printf("kCMMediaType_TimeCode");
    } else if (fourCharCode == kCMMediaType_Metadata) {
        printf("kCMMediaType_Metadata");
    }
    
    // CMTimeCodeFormatType
    else if (fourCharCode == kCMTimeCodeFormatType_TimeCode32) {
        printf("kCMTimeCodeFormatType_TimeCode32");
    } else if (fourCharCode == kCMTimeCodeFormatType_TimeCode64) {
        printf("kCMTimeCodeFormatType_TimeCode64");
    } else if (fourCharCode == kCMTimeCodeFormatType_Counter32) {
        printf("kCMTimeCodeFormatType_Counter32");
    } else if (fourCharCode == kCMTimeCodeFormatType_Counter64) {
        printf("kCMTimeCodeFormatType_Counter64");
    }
    
    // CMTextFormatType
    else if (fourCharCode == kCMTextFormatType_QTText) {
        printf("kCMTextFormatType_QTText");
    } else if (fourCharCode == kCMTextFormatType_3GText) {
        printf("kCMTextFormatType_3GText");
    }
    
    // CMAudioCodecType
    else if (fourCharCode == kCMAudioCodecType_AAC_LCProtected) {
        printf("kCMAudioCodecType_AAC_LCProtected");
    } else if (fourCharCode == kCMAudioCodecType_AAC_AudibleProtected) {
        printf("kCMAudioCodecType_AAC_AudibleProtected");
    }
    
    // CMMuxedStreamType
    else if (fourCharCode == kCMMuxedStreamType_MPEG1System) {
        printf("kCMMuxedStreamType_MPEG1System");
    } else if (fourCharCode == kCMMuxedStreamType_MPEG2Transport) {
        printf("kCMMuxedStreamType_MPEG2Transport");
    } else if (fourCharCode == kCMMuxedStreamType_MPEG2Program) {
        printf("kCMMuxedStreamType_MPEG2Program");
    } else if (fourCharCode == kCMMuxedStreamType_DV) {
        printf("kCMMuxedStreamType_DV");
    }
    
    // CMClosedCaptionFormatType
    else if (fourCharCode == kCMClosedCaptionFormatType_CEA608) {
        printf("kCMClosedCaptionFormatType_CEA608");
    } else if (fourCharCode == kCMClosedCaptionFormatType_CEA708) {
        printf("kCMClosedCaptionFormatType_CEA708");
    }
    
    // CMPixelFormatType
    else if (fourCharCode == kCMPixelFormat_32ARGB) {
        printf("kCMPixelFormat_32ARGB");
    } else if (fourCharCode == kCMPixelFormat_32BGRA) {
        printf("kCMPixelFormat_32BGRA");
    } else if (fourCharCode == kCMPixelFormat_24RGB) {
        printf("kCMPixelFormat_24RGB");
    } else if (fourCharCode == kCMPixelFormat_16BE555) {
        printf("kCMPixelFormat_16BE555");
    } else if (fourCharCode == kCMPixelFormat_16BE565) {
        printf("kCMPixelFormat_16BE565");
    } else if (fourCharCode == kCMPixelFormat_16LE555) {
        printf("kCMPixelFormat_16LE555");
    } else if (fourCharCode == kCMPixelFormat_16LE565) {
        printf("kCMPixelFormat_16LE565");
    } else if (fourCharCode == kCMPixelFormat_16LE5551) {
        printf("kCMPixelFormat_16LE5551");
    } else if (fourCharCode == kCMPixelFormat_422YpCbCr8) {
        printf("kCMPixelFormat_422YpCbCr8");
    } else if (fourCharCode == kCMPixelFormat_422YpCbCr8_yuvs) {
        printf("kCMPixelFormat_422YpCbCr8_yuvs");
    } else if (fourCharCode == kCMPixelFormat_444YpCbCr8) {
        printf("kCMPixelFormat_444YpCbCr8");
    } else if (fourCharCode == kCMPixelFormat_4444YpCbCrA8) {
        printf("kCMPixelFormat_4444YpCbCrA8");
    } else if (fourCharCode == kCMPixelFormat_422YpCbCr16) {
        printf("kCMPixelFormat_422YpCbCr16");
    } else if (fourCharCode == kCMPixelFormat_422YpCbCr10) {
        printf("kCMPixelFormat_422YpCbCr10");
    } else if (fourCharCode == kCMPixelFormat_444YpCbCr10) {
        printf("kCMPixelFormat_444YpCbCr10");
    } else if (fourCharCode == kCMPixelFormat_8IndexedGray_WhiteIsZero) {
        printf("kCMPixelFormat_8IndexedGray_WhiteIsZero");
    }
    
    // CMMetadataFormatType
    else if (fourCharCode == kCMMetadataFormatType_ICY) {
        printf("kCMMetadataFormatType_ICY");
    } else if (fourCharCode == kCMMetadataFormatType_ID3) {
        printf("kCMMetadataFormatType_ID3");
    } else if (fourCharCode == kCMMetadataFormatType_Boxed) {
        printf("kCMMetadataFormatType_Boxed");
    }
    
    // CMVideoCodecType
    else if (fourCharCode == kCMVideoCodecType_422YpCbCr8) {
        printf("kCMVideoCodecType_422YpCbCr8");
    } else if (fourCharCode == kCMVideoCodecType_Animation) {
        printf("kCMVideoCodecType_Animation");
    } else if (fourCharCode == kCMVideoCodecType_Cinepak) {
        printf("kCMVideoCodecType_Cinepak");
    } else if (fourCharCode == kCMVideoCodecType_JPEG) {
        printf("kCMVideoCodecType_JPEG");
    } else if (fourCharCode == kCMVideoCodecType_JPEG_OpenDML) {
        printf("kCMVideoCodecType_JPEG_OpenDML");
    } else if (fourCharCode == kCMVideoCodecType_SorensonVideo) {
        printf("kCMVideoCodecType_SorensonVideo");
    } else if (fourCharCode == kCMVideoCodecType_SorensonVideo3) {
        printf("kCMVideoCodecType_SorensonVideo3");
    } else if (fourCharCode == kCMVideoCodecType_H263) {
        printf("kCMVideoCodecType_H263");
    } else if (fourCharCode == kCMVideoCodecType_H264) {
        printf("kCMVideoCodecType_H264");
    } else if (fourCharCode == kCMVideoCodecType_MPEG4Video) {
        printf("kCMVideoCodecType_MPEG4Video");
    } else if (fourCharCode == kCMVideoCodecType_MPEG2Video) {
        printf("kCMVideoCodecType_MPEG2Video");
    } else if (fourCharCode == kCMVideoCodecType_MPEG1Video) {
        printf("kCMVideoCodecType_MPEG1Video");
    } else if (fourCharCode == kCMVideoCodecType_DVCNTSC) {
        printf("kCMVideoCodecType_DVCNTSC");
    } else if (fourCharCode == kCMVideoCodecType_DVCPAL) {
        printf("kCMVideoCodecType_DVCPAL");
    } else if (fourCharCode == kCMVideoCodecType_DVCProPAL) {
        printf("kCMVideoCodecType_DVCProPAL");
    } else if (fourCharCode == kCMVideoCodecType_DVCPro50NTSC) {
        printf("kCMVideoCodecType_DVCPro50NTSC");
    } else if (fourCharCode == kCMVideoCodecType_DVCPro50PAL) {
        printf("kCMVideoCodecType_DVCPro50PAL");
    } else if (fourCharCode == kCMVideoCodecType_DVCPROHD720p60) {
        printf("kCMVideoCodecType_DVCPROHD720p60");
    } else if (fourCharCode == kCMVideoCodecType_DVCPROHD720p50) {
        printf("kCMVideoCodecType_DVCPROHD720p50");
    } else if (fourCharCode == kCMVideoCodecType_DVCPROHD1080i60) {
        printf("kCMVideoCodecType_DVCPROHD1080i60");
    } else if (fourCharCode == kCMVideoCodecType_DVCPROHD1080i50) {
        printf("kCMVideoCodecType_DVCPROHD1080i50");
    } else if (fourCharCode == kCMVideoCodecType_DVCPROHD1080p30) {
        printf("kCMVideoCodecType_DVCPROHD1080p30");
    } else if (fourCharCode == kCMVideoCodecType_DVCPROHD1080p25) {
        printf("kCMVideoCodecType_DVCPROHD1080p25");
    }
    
    // Video Profiles
    else if (fourCharCode == kCMMPEG2VideoProfile_HDV_720p30) {
        printf("kCMMPEG2VideoProfile_HDV_720p30");
    } else if (fourCharCode == kCMMPEG2VideoProfile_HDV_1080i60) {
        printf("kCMMPEG2VideoProfile_HDV_1080i60");
    } else if (fourCharCode == kCMMPEG2VideoProfile_HDV_1080i50) {
        printf("kCMMPEG2VideoProfile_HDV_1080i50");
    } else if (fourCharCode == kCMMPEG2VideoProfile_HDV_720p24) {
        printf("kCMMPEG2VideoProfile_HDV_720p24");
    } else if (fourCharCode == kCMMPEG2VideoProfile_HDV_720p25) {
        printf("kCMMPEG2VideoProfile_HDV_720p25");
    } else if (fourCharCode == kCMMPEG2VideoProfile_HDV_1080p24) {
        printf("kCMMPEG2VideoProfile_HDV_1080p24");
    } else if (fourCharCode == kCMMPEG2VideoProfile_HDV_1080p25) {
        printf("kCMMPEG2VideoProfile_HDV_1080p25");
    } else if (fourCharCode == kCMMPEG2VideoProfile_HDV_1080p30) {
        printf("kCMMPEG2VideoProfile_HDV_1080p30");
    } else if (fourCharCode == kCMMPEG2VideoProfile_HDV_720p60) {
        printf("kCMMPEG2VideoProfile_HDV_720p60");
    } else if (fourCharCode == kCMMPEG2VideoProfile_HDV_720p50) {
        printf("kCMMPEG2VideoProfile_HDV_720p50");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD_1080i60_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD_1080i60_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD_1080i50_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD_1080i50_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD_1080p24_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD_1080p24_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD_1080p25_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD_1080p25_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD_1080p30_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD_1080p30_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_EX_720p24_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_EX_720p24_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_EX_720p25_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_EX_720p25_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_EX_720p30_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_EX_720p30_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_EX_720p50_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_EX_720p50_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_EX_720p60_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_EX_720p60_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_EX_1080i60_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_EX_1080i60_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_EX_1080i50_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_EX_1080i50_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_EX_1080p24_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_EX_1080p24_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_EX_1080p25_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_EX_1080p25_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_EX_1080p30_VBR35) {
        printf("kCMMPEG2VideoProfile_XDCAM_EX_1080p30_VBR35");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD422_720p50_CBR50) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD422_720p50_CBR50");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD422_720p60_CBR50) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD422_720p60_CBR50");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD422_1080i60_CBR50) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD422_1080i60_CBR50");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD422_1080i50_CBR50) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD422_1080i50_CBR50");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD422_1080p24_CBR50) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD422_1080p24_CBR50");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD422_1080p25_CBR50) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD422_1080p25_CBR50");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD422_1080p30_CBR50) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD422_1080p30_CBR50");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD_540p) {
        printf("kCMMPEG2VideoProfile_XDCAM_HD422_540p");
    } else if (fourCharCode == kCMMPEG2VideoProfile_XDCAM_HD422_540p) {
        printf("kCMVideoCodecType_DVCPROHD1080p25");
    }
    
    // Audio Data Format Identifiers
    else if (fourCharCode == kAudioFormatLinearPCM) {
        printf("kAudioFormatLinearPCM");
    } else if (fourCharCode == kAudioFormatAC3) {
        printf("kAudioFormatAC3");
    } else if (fourCharCode == kAudioFormat60958AC3) {
        printf("kAudioFormat60958AC3");
    } else if (fourCharCode == kAudioFormatAppleIMA4) {
        printf("kAudioFormatAppleIMA4");
    } else if (fourCharCode == kAudioFormatMPEG4AAC) {
        printf("kAudioFormatMPEG4AAC");
    } else if (fourCharCode == kAudioFormatMPEG4CELP) {
        printf("kAudioFormatMPEG4CELP");
    } else if (fourCharCode == kAudioFormatMPEG4HVXC) {
        printf("kAudioFormatMPEG4HVXC");
    } else if (fourCharCode == kAudioFormatMPEG4TwinVQ) {
        printf("kAudioFormatMPEG4TwinVQ");
    } else if (fourCharCode == kAudioFormatMACE3) {
        printf("kAudioFormatMACE3");
    } else if (fourCharCode == kAudioFormatMACE6) {
        printf("kAudioFormatMACE6");
    } else if (fourCharCode == kAudioFormatULaw) {
        printf("kAudioFormatULaw");
    } else if (fourCharCode == kAudioFormatALaw) {
        printf("kAudioFormatALaw");
    } else if (fourCharCode == kAudioFormatQDesign) {
        printf("kAudioFormatQDesign");
    } else if (fourCharCode == kAudioFormatQDesign2) {
        printf("kAudioFormatQDesign2");
    } else if (fourCharCode == kAudioFormatQUALCOMM) {
        printf("kAudioFormatQUALCOMM");
    } else if (fourCharCode == kAudioFormatMPEGLayer1) {
        printf("kAudioFormatMPEGLayer1");
    } else if (fourCharCode == kAudioFormatMPEGLayer2) {
        printf("kAudioFormatMPEGLayer2");
    } else if (fourCharCode == kAudioFormatMPEGLayer3) {
        printf("kAudioFormatMPEGLayer3");
    } else if (fourCharCode == kAudioFormatTimeCode) {
        printf("kAudioFormatTimeCode");
    } else if (fourCharCode == kAudioFormatMIDIStream) {
        printf("kAudioFormatMIDIStream");
    } else if (fourCharCode == kAudioFormatParameterValueStream) {
        printf("kAudioFormatParameterValueStream");
    } else if (fourCharCode == kAudioFormatAppleLossless) {
        printf("kAudioFormatAppleLossless");
    } else if (fourCharCode == kAudioFormatMPEG4AAC_HE) {
        printf("kAudioFormatMPEG4AAC_HE");
    } else if (fourCharCode == kAudioFormatMPEG4AAC_LD) {
        printf("kAudioFormatMPEG4AAC_LD");
    } else if (fourCharCode == kAudioFormatMPEG4AAC_ELD) {
        printf("kAudioFormatMPEG4AAC_ELD");
    } else if (fourCharCode == kAudioFormatMPEG4AAC_ELD_SBR) {
        printf("kAudioFormatMPEG4AAC_ELD_SBR");
    } else if (fourCharCode == kAudioFormatMPEG4AAC_HE_V2) {
        printf("kAudioFormatMPEG4AAC_HE_V2");
    } else if (fourCharCode == kAudioFormatMPEG4AAC_Spatial) {
        printf("kAudioFormatMPEG4AAC_Spatial");
    } else if (fourCharCode == kAudioFormatAMR) {
        printf("kAudioFormatAMR");
    } else if (fourCharCode == kAudioFormatAudible) {
        printf("kAudioFormatAudible");
    } else if (fourCharCode == kAudioFormatiLBC) {
        printf("kAudioFormatiLBC");
    } else if (fourCharCode == kAudioFormatDVIIntelIMA) {
        printf("kAudioFormatDVIIntelIMA");
    } else if (fourCharCode == kAudioFormatMicrosoftGSM) {
        printf("kAudioFormatMicrosoftGSM");
    } else if (fourCharCode == kAudioFormatAES3) {
        printf("kAudioFormatAES3");
    }
    
    // Other
    else {
        printf("0x%04x", fourCharCode);
    }
    
    // Include a comment with the FourCharCode.
    printf("; // %s\n", NSFileTypeForHFSTypeCode(fourCharCode).p);
}
