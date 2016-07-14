avf-probe
=========

`avfprobe` is an OS X command line tool that prints detailed information about audio and video files using `AVFoundation`.
 
It loads each file as an AVAsset and decodes and displays information on all of the components, including:

* assets (`AVAsset`)
* tracks (`AVAssetTrack`)
* metadata (`AVMetaDataItem`)
* format descriptions (`CMFormatDescription`)
* media types (`CMMediaType`)

Usage Example
-------------

```$ avfprobe file ...```

Sample Output
-------------

Sample output is included for videos from:

* Apple iPhone 5s
* GoPro HERO4 Silver Edition
* ffmpeg output file

Please submit pull requests with sample output from other devices.

Notes
-----

`avfprobe` can help troublshoot issues, such as this one in the sample output from `ffmpeg`.

Note that the `nominalFrameRate` for the video track is 59.84 fps, whereas the reciprocal of
`minFrameDuration` is 59.94 fps.  The `nominalFrameRate` is not commensurate with the track's `naturalTimeScale`.
The `nominalFrameRate` corresponds to a frame interval of `{3008/180000}` whereas `minFrameDuration`
 corresponds to`{3003/180000}`.

```
// Temporal Properties
naturalTimeScale = 60000; // {1/60000 = 0.000017} sec

// Frame-Based Characteristics
nominalFrameRate = 59.840160; // fps (= {1002.671082 / 60000} sec/frame)
minFrameDuration = {1001 / 60000 = 0.016683}; // sec (= 59.940060 fps)
```

The presentation time stamps of the frames in the track are actually multiples of `minFrameDuration`
(`{1001/60000}`, `{2002/60000}`, `{3003/60000}`, ...).

For some videos, I have found that using the reciprocal of `minFrameDuration` is more reliable than using `nominalFrameRate`.