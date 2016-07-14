avf-probe
=========

`avfprobe` is an OS X command line tool that prints detailed information about audio and video files using `AVFoundation`.
 
It loads each file as an AVAsset and decodes and displays information on all of the components, including:

* Assets (`AVAsset`)
* Tracks (`AVAssetTrack`)
* Metadata (`AVMetaDataItem`)
* Format Descriptions (`CMFormatDescription`)
* Media Types (`CMMediaType`)

Usage Example
-------------

```$ avfprobe file ...```

Sample Output
-------------

Sample output is included for videos from:

* Apple iPhone 5s
* GoPro HERO4 Silver Edition

Please submit pull requests with sample output from other devices.