avf-probe
=========

`avfprobe` is an OS X command line tool that prints detailed information about audio and video files using `AVFoundation`.
 
It loads each file as an AVAsset and decodes and displays information on all of the components, including:

* assets (`AVAsset`)
* tracks (`AVAssetTrack`)
* metadata (`AVMetaDataItem`)
* format descriptions (`CMFormatDescription`)
* media types (`CMMediaType`)

### Usage
---------

```$ avfprobe file ...```

### Sample Output
-----------------

Sample output is included for videos from:

* Apple iPhone 5s
* GoPro HERO4 Silver Edition
* ffmpeg output file

Please submit pull requests with sample output from other devices.

### Examples
------------

##### iPhone:

The iPhone sample includes an example of a geographic location in the asset metadata:

```
identifier = "mdta/com.apple.quicktime.location.ISO6709";
keySpace = "mdta";
key = com.apple.quicktime.location.ISO6709;
commonKey = "location";
dataType = "com.apple.metadata.datatype.UTF-8";
value = "+37.4866-122.2296+005.952/";
```

You can look up "+37.4866-122.2296+005.952/" on [Google Maps](https://www.google.com/maps/place/%2B37.4866-122.2296) to see where this video was shot.

It also includes an example of face detection in one of the metadata tracks:

```
"MetadataKeyDataType" = (NSData *)"com.apple.quicktime.detected-face";
"MetadataKeyValue" = (NSData *)"com.apple.quicktime.detected-face";
"MetadataKeyValue" = (NSData *)"com.apple.quicktime.detected-face.face-id";
"MetadataKeyValue" = (NSData *)"com.apple.quicktime.detected-face.bounds";
"MetadataKeyValue" = (NSData *)"com.apple.quicktime.detected-face.roll-angle";
"MetadataKeyValue" = (NSData *)"com.apple.quicktime.detected-face.yaw-angle";
```

##### GoPro:

The GoPro sample includes an example of the camera firmware version in the metadata:

```
identifier = "uiso/FIRM";
keySpace = "uiso";
key = 1179210317;
commonKey = (null);
dataType = "com.apple.metadata.datatype.raw-data";
value = (NSData *)"HD4.01.02.00.00";
```

You can look up "HD4.01.02.00.00" on [GoPro's website](https://gopro.com/support/articles/firmware-release-information) to see that this is a "HERO4 Silver Edition Camera".

##### ffmpeg:

`avfprobe` can also help troublshoot issues, such as this one:

```
// Temporal Properties
naturalTimeScale = 60000; // {1/60000 = 0.000017} sec

// Frame-Based Characteristics
nominalFrameRate = 59.840160; // fps (= {1002.671082 / 60000} sec/frame)
minFrameDuration = {1001 / 60000 = 0.016683}; // sec (= 59.940060 fps)
```

Note that the `nominalFrameRate` for the video track is 59.84 fps, whereas the reciprocal of
`minFrameDuration` is 59.94 fps.  The `nominalFrameRate` is not commensurate with the track's `naturalTimeScale`.
The `nominalFrameRate` corresponds to a frame interval of `{3008/180000}` whereas `minFrameDuration`
 corresponds to`{3003/180000}`.

The presentation time stamps of the frames in the track are actually multiples of `minFrameDuration`
(`{1001/60000}`, `{2002/60000}`, `{3003/60000}`, ...).

For some videos, I have found that using the reciprocal of `minFrameDuration` is more reliable than using `nominalFrameRate`.