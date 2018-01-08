# InMobi Adapter for Google Mobile Ads SDK for iOS

## Version 7.0.4.0
- Updated the adapter to make it compatibility with InMobi SDK 7.0.4.
- Added support for native video ads.
- InMobi's SDK does not provide images for ads containing video assets. To avoid
  potential NullPointerExceptions, when the adapter receives one of these ads it
  will automatically create a blank NativeAd.Image and include it in the images
  asset array in the ad object received by the app. Publishers using this
  adapter are encouraged to avoid using the image assets directly when mediating
  to InMobi, and instead use GADMediaView in their UI. GADMediaView will
  automatically display video assets for ads that contain them, and an image
  asset for ads that don't.

## Version 6.2.1.0
- Verified compatibility with inMobi SDK 6.2.1

## Earlier versions
- Support for banners, interstitials, rewarded video and native ad formats.
