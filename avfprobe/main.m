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

static void printAsset(AVURLAsset *asset);
static void printTrack(AVAssetTrack *track);
static void printMetadata(AVMetadataItem *item, const char *indent);
static void printFormatDescription(CMFormatDescriptionRef formatDescription);
static void printAVMediaType(NSString *mediaType);
static void printCMMediaType(CMMediaType mediaType);
static void printTransform(CGAffineTransform transform, const char *indent);

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
            printAsset(asset);
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


static void printAsset(AVURLAsset *asset)
{
    printf("{\n");
    
    // Asset Properties
    printf("    // Asset Properties\n");
    printf("    URL = %s;\n", asset.URL.absoluteString.q);
    
    printf("\n");
    
    // Determining Usability
    printf("    // Determining Usability\n");
    printf("    hasProtectedContent = %s;\n", asset.hasProtectedContent ? "YES" : "NO");
    printf("    playable = %s;\n", asset.playable ? "YES" : "NO");
    printf("    exportable = %s;\n", asset.exportable ? "YES" : "NO");
    printf("    readable = %s;\n", asset.readable ? "YES" : "NO");
    printf("    composable = %s;\n", asset.composable ? "YES" : "NO");
    
    printf("\n");
    
    // Accessing Common Metadata
    printf("    // Accessing Common Metadata\n");
    printf("    duration = %f; // sec\n", CMTimeGetSeconds(asset.duration));
    printf("    providesPreciseDurationAndTiming = %s;\n", asset.providesPreciseDurationAndTiming ? "YES" : "NO");
    
    printf("\n");
    
    // Preferred Asset Attributes
    printf("    // Preferred Asset Attributes\n");
    printf("    preferredRate = %f;\n", asset.preferredRate);
    printf("    preferredTransform = "); printTransform(asset.preferredTransform, "    ");
    printf("    preferredVolume = %f;\n", asset.preferredVolume);
    
    printf("\n");
    
    // Media Selections
    printf("    // Media Selections\n");
    printf("    compatibleWithAirPlayVideo = %s;\n", asset.compatibleWithAirPlayVideo ? "YES" : "NO");
    printf("    creationDate = %s;\n", asset.creationDate.stringValue.p);
    
    printf("\n");
    
    // Tracks
    printf("    // Tracks\n");
    printf("    tracks = [\n");
    for (AVAssetTrack *track in asset.tracks) {
        printTrack(track);
    }
    printf("    ];\n");

    // Track Groups
    // (ignore for now)
    
    printf("\n");
    
    // Metadata
    printf("    // Metadata\n");
    printf("    metadata = [\n");
    for (AVMetadataItem *item in asset.metadata) {
        printMetadata(item, "    ");
    }
    printf("    ];\n");
    
    printf("\n");
    
    // Lyrics
    printf("    // Lyrics\n");
    printf("    lyrics = %s;\n", asset.lyrics.q);
    
    printf("}\n");
}

static void printTrack(AVAssetTrack *track)
{
    printf("    {\n");
    
    // Track Properties
    printf("        // Track Properties\n");
    printf("        trackID = %d;\n", track.trackID);
    
    printf("        mediaType = ");
    printAVMediaType(track.mediaType);
    printf("; // = %s\n", track.mediaType.q);
    
    printf("        enabled = %s;\n", track.enabled ? "YES" : "NO");
    printf("        playable = %s;\n", track.playable ? "YES" : "NO");
    printf("        selfContained = %s;\n", track.selfContained ? "YES" : "NO");
    printf("        totalSampleDataLength = %lld; // bytes\n", track.totalSampleDataLength);
    
    printf("\n");
    
    // Temporal Properties
    printf("        // Temporal Properties\n");
    printf("        timeRange = {\n");
    printf("            start = %f; // sec\n", CMTimeGetSeconds(track.timeRange.start));
    printf("            duration = %f; // sec\n", CMTimeGetSeconds(track.timeRange.duration));
    printf("        };\n");
    printf("        naturalTimeScale = %d; // {1/%d = %f} sec\n", track.naturalTimeScale,
           track.naturalTimeScale, 1.0 / track.naturalTimeScale);
    printf("        estimatedDataRate = %f; // bps\n", track.estimatedDataRate);
    
    printf("\n");
    
    // Track Language Properties
    printf("        // Track Language Properties\n");
    printf("        languageCode = %s;\n", track.languageCode.q);
    printf("        extendedLanguageTag = %s;\n", track.extendedLanguageTag.q);
    
    printf("\n");
    
    // Visual Characteristics
    printf("        // Visual Characteristics\n");
    printf("        naturalSize = {\n");
    printf("            width = %f;\n", track.naturalSize.width);
    printf("            height = %f;\n", track.naturalSize.height);
    printf("        };\n");
    printf("        preferredTransform = "); printTransform(track.preferredTransform, "        ");
    
    printf("\n");
    
    // Audible Characteristics
    printf("        // Audible Characteristics\n");
    printf("        preferredVolume = %f;\n", track.preferredVolume);
    
    printf("\n");
    
    // Frame-Based Characteristics
    printf("        // Frame-Based Characteristics\n");
    printf("        nominalFrameRate = %f; // fps (= {%f / %d} sec/frame)\n", track.nominalFrameRate,
           track.naturalTimeScale / track.nominalFrameRate, track.naturalTimeScale);
    printf("        minFrameDuration = {%lld / %d = %f}; // sec (= %f fps)\n", track.minFrameDuration.value,
           track.minFrameDuration.timescale, CMTimeGetSeconds(track.minFrameDuration),
           1 / CMTimeGetSeconds(track.minFrameDuration));
    printf("        requiresFrameReordering = %s;\n", track.requiresFrameReordering ? "YES" : "NO");
    
    printf("\n");
    
    // Track Segments
    // (ignore for now)
    
    // Metadata
    printf("        // Metadata\n");
    printf("        metadata = [\n");
    for (AVMetadataItem *item in track.metadata) {
        printMetadata(item, "        ");
    }
    printf("        ];\n");
    
    printf("\n");
    
    // Format Descriptions
    printf("        // Format Descriptions\n");
    printf("        formatDescriptions = [\n");
    for (id item in track.formatDescriptions) {
        CMFormatDescriptionRef formatDescription = (__bridge CMFormatDescriptionRef)item;
        
        printFormatDescription(formatDescription);
    }
    printf("        ];\n");

    printf("    },\n");
}

static void printMetadata(AVMetadataItem *item, const char *indent)
{
    printf("%s{\n", indent);
    
    // Keys and Key Spaces
    printf("%s    identifier = %s;\n", indent, item.identifier.q);
    printf("%s    keySpace = %s;\n", indent, item.keySpace.q);
    printf("%s    key = %s;\n", indent, item.key.description.p);
    printf("%s    commonKey = %s;\n", indent, item.commonKey.q);
    
    // Accessing Values
    printf("%s    dataType = %s;\n", indent, item.dataType.q);
    if (item.stringValue) {
        printf("%s    value = %s;", indent, item.stringValue.q);
    } else {
        printf("%s    value = %s;", indent, item.value.description.p);
    }
    if (item.dataValue) {
        // See if we can interpret the raw data as a UTF8 string.
        NSString *dataString = [[NSString alloc] initWithData:item.dataValue encoding:NSUTF8StringEncoding];
        
        if (dataString) {
            dataString = [dataString stringByReplacingOccurrencesOfString:@"\0" withString:@""];
            dataString = [dataString stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
            dataString = [dataString stringByReplacingOccurrencesOfString:@"\t" withString:@"\\t"];
            dataString = [dataString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
            
            if (dataString.length > 0) {
                // Add the decoded string as a comment.
                printf(" // = %s", dataString.q);
            }
        }
    }
    printf("\n");
    printf("%s    time = {%lld/%d = %f}; // sec\n", indent, item.time.value, item.time.timescale,
           CMTimeGetSeconds(item.time));
    printf("%s    duration = {%lld/%d = %f}; // sec\n", indent, item.duration.value, item.duration.timescale,
           CMTimeGetSeconds(item.duration));
    printf("%s    locale = %s;\n", indent, item.locale.localeIdentifier.q);
    printf("%s    extendedLanguageTag = %s;\n", indent, item.extendedLanguageTag.q);
    
    printf("%s},\n", indent);
}

static void printFormatDescription(CMFormatDescriptionRef formatDescription)
{
    printf("        {\n");
    
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDescription);
    printf("            mediaType = ");
    printCMMediaType(mediaType);
    printf("; // = %s\n", NSFileTypeForHFSTypeCode(mediaType).p);
    
    FourCharCode mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription);
    printf("            mediaSubType = %s;\n", NSFileTypeForHFSTypeCode(mediaSubType).p);
    
    NSDictionary *extensions = (id)(CMFormatDescriptionGetExtensions(formatDescription));
    NSString *description = extensions.description;
    description = [description stringByReplacingOccurrencesOfString:@"\n" withString:@"\n            "];
    printf("            extensions = %s;\n", description.p);
    
    printf("        },\n");
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

static void printTransform(CGAffineTransform transform, const char *indent)
{
    if (CGAffineTransformIsIdentity(transform)) {
        printf("CGAffineTransformIdentity;\n");
    } else {
        printf("{\n");
        printf("%s    %f, %f, %f\n", indent, transform.a, transform.b, 0.0);
        printf("%s    %f, %f, %f\n", indent, transform.c, transform.d, 0.0);
        printf("%s    %f, %f, %f\n", indent, transform.tx, transform.ty, 1.0);
        printf("%s};\n", indent);
    }
}
