## InMobi iOS Mediation Adapter Changelog

#### [Version 10.7.5.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.7.5.0.zip)
- Verified compatibility with InMobi SDK 10.7.5.

Built and tested with:
- Google Mobile Ads SDK version 11.7.0.
- InMobi SDK version 10.7.5.

#### [Version 10.7.4.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.7.4.0.zip)
- Verified compatibility with InMobi SDK 10.7.4.

Built and tested with:
- Google Mobile Ads SDK version 11.6.0.
- InMobi SDK version 10.7.4.

#### [Version 10.7.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.7.2.0.zip)
- Verified compatibility with InMobi SDK 10.7.2.

Built and tested with:
- Google Mobile Ads SDK version 11.3.0.
- InMobi SDK version 10.7.2.

#### [Version 10.7.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.7.1.0.zip)
- Verified compatibility with InMobi SDK 10.7.1.

Built and tested with:
- Google Mobile Ads SDK version 11.2.0.
- InMobi SDK version 10.7.1.

#### [Version 10.6.4.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.6.4.0.zip)
- Verified compatibility with InMobi SDK 10.6.4.
- Replaced the deprecated method `GADMobileAds.sharedInstance.sdkVersion` with `GADMobileAds.sharedInstance.versionNumber`.
- Replaced the use of `NSUserDefaults` with `CFPreferences` functions.
- Now requires minimum iOS version 12.0.
- Now requires Google Mobile Ads SDK version 11.0 or higher.
- Included `Info.plist` in the frameworks within `InMobiAdapter.xcframework`.

Built and tested with:
- Google Mobile Ads SDK version 11.0.1.
- InMobi SDK version 10.6.4.

#### [Version 10.6.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.6.0.0.zip)
- Verified compatibility with InMobi SDK 10.6.0.
- Added watermark support for bidding banner, interstitial and rewarded ad formats.

Built and tested with:
- Google Mobile Ads SDK version 10.13.0.
- InMobi SDK version 10.6.0.

#### [Version 10.5.8.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.5.8.0.zip)
- Verified compatibility with InMobi SDK 10.5.8.

Built and tested with:
- Google Mobile Ads SDK version 10.10.0.
- InMobi SDK version 10.5.8.

#### [Version 10.5.6.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.5.6.0.zip)
- Added support to read IAB U.S. Privacy string from NSUserDefaults.
- Verified compatibility with InMobi SDK 10.5.6.
- Added bidding support for banner (includes MREC), interstitial and rewarded
ad formats.

Built and tested with:

- Google Mobile Ads SDK version 10.9.0.
- InMobi SDK version 10.5.6.


#### [Version 10.5.5.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.5.5.0.zip)
- Now requires Google Mobile Ads SDK version 10.4.0 or higher.
- Updated the adapter to use the `didRewardUser` API.
- Updated the adapter to initialize InMobi SDK on main thread.

Built and tested with:
- Google Mobile Ads SDK version 10.4.0.
- InMobi SDK version 10.5.5.

#### [Version 10.5.4.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.5.4.0.zip)
- Verified compatibility with InMobi SDK 10.5.4.
- Removed use of deprecated gender, birthday and location mediation APIs.
- Removed support for the `armv7` architecture.
- Now requires minimum iOS version 11.0.
- Now requires Google Mobile Ads SDK version 10.0.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 10.2.0.
- InMobi SDK version 10.5.4.

Additional notes:
- This release was created before [Version 10.1.3.0](https://github.com/googleads/googleads-mobile-ios-mediation/blob/main/adapters/InMobi/CHANGELOG.md#version-10130) so it does not use the `didRewardUser` API.

#### [Version 10.1.3.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.1.3.0.zip)
- Verified compatibility with InMobi SDK 10.1.3.
- Now requires Google Mobile Ads SDK version 10.4.0 or higher.
- Updated the adapter to use the `didRewardUser` API.

Built and tested with:
- Google Mobile Ads SDK version 10.5.0.
- InMobi SDK version 10.1.3.

Additional notes:
- This release was created after [Version 10.5.4.0](https://github.com/googleads/googleads-mobile-ios-mediation/blob/main/adapters/InMobi/CHANGELOG.md#version-10540).

#### [Version 10.1.2.1](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.1.2.1.zip)
- Verified compatibility with InMobi SDK 10.1.2.
- Fixed an issue where the native ads could become blank in scrollable UIs.
- Updated the adapter to use the new mediation APIs.
- Added support for forwarding the COPPA value to InMobi SDK.

Built and tested with:
- Google Mobile Ads SDK version 9.14.0.
- InMobi SDK version 10.1.2.

#### [Version 10.1.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.1.2.0.zip)
- Verified compatibility with InMobi SDK 10.1.2.

Built and tested with:
- Google Mobile Ads SDK version 9.13.0.
- InMobi SDK version 10.1.2.

#### [Version 10.1.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.1.1.0.zip)
- Verified compatibility with InMobi SDK 10.1.1.

Built and tested with:
- Google Mobile Ads SDK version 9.12.0.
- InMobi SDK version 10.1.1.

#### [Version 10.1.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.1.0.0.zip)
- Verified compatibility with InMobi SDK 10.1.0.
- Updated the adapter to use the `didRewardUser` API.
- Now requires Google Mobile Ads SDK version 9.8.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 9.11.0.
- InMobi SDK version 10.1.0.

#### [Version 10.0.7.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.0.7.0.zip)
- Verified compatibility with InMobi SDK 10.0.7.

Built and tested with:
- Google Mobile Ads SDK version 9.5.0.
- InMobi SDK version 10.0.7.

#### [Version 10.0.5.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.0.5.0.zip)
- Verified compatibility with InMobi SDK 10.0.5.

Built and tested with:
- Google Mobile Ads SDK version 9.2.0.
- InMobi SDK version 10.0.5.

#### [Version 10.0.2.1](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.0.2.1.zip)
- Verified compatibility with Google Mobile Ads SDK version 9.0.0.
- Now requires Google Mobile Ads SDK version 9.0.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 9.0.0.
- InMobi SDK version 10.0.2.

#### [Version 10.0.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.0.2.0.zip)
- Verified compatibility with InMobi SDK 10.0.2.

Built and tested with
- Google Mobile Ads SDK version 8.13.0.
- InMobi SDK version 10.0.2.

#### [Version 10.0.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.0.1.0.zip)
- Verified compatibility with InMobi SDK 10.0.1.

Built and tested with
- Google Mobile Ads SDK version 8.12.0.
- InMobi SDK version 10.0.1.

#### [Version 10.0.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-10.0.0.0.zip)
- Verified compatibility with InMobi SDK 10.0.0.
- Now requires minimum iOS version 10.0.

Built and tested with
- Google Mobile Ads SDK version 8.11.0.
- InMobi SDK version 10.0.0.

#### [Version 9.2.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.2.1.0.zip)
- Verified compatibility with InMobi SDK 9.2.1.

Built and tested with
- Google Mobile Ads SDK version 8.9.0.
- InMobi SDK version 9.2.1.

#### [Version 9.2.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.2.0.0.zip)
- Verified compatibility with InMobi SDK 9.2.0.
- Relaxed dependency to Google Mobile Ads SDK version 8.0.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 8.8.0.
- InMobi SDK version 9.2.0.

#### [Version 9.1.7.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.1.7.0.zip)
- Verified compatibility with InMobi SDK 9.1.7.
- Now requires Google Mobile Ads SDK version 8.3.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 8.3.0.
- InMobi SDK version 9.1.7.

#### [Version 9.1.5.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.1.5.0.zip)
- Verified compatibility with InMobi SDK 9.1.5.
- Now requires Google Mobile Ads SDK version 8.1.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 8.1.0.
- InMobi SDK version 9.1.5.

#### [Version 9.1.1.1](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.1.1.1.zip)
- Updated the adapter to use the `.xcframework` format.
- Now requires Google Mobile Ads SDK version 8.0.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 8.0.0.
- InMobi SDK version 9.1.1.

#### [Version 9.1.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.1.1.0.zip)
- Verified compatibility with InMobi SDK 9.1.1.
- Now requires Google Mobile Ads SDK version 7.68.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.68.0.
- InMobi SDK version 9.1.1.

#### [Version 9.1.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.1.0.0.zip)
- Verified compatibility with InMobi SDK 9.1.0.
- Now requires Google Mobile Ads SDK version 7.65.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.65.0.
- InMobi SDK version 9.1.0.

#### [Version 9.0.7.2](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.0.7.2.zip)
- Rewarded ads no longer default to coppa=0 when child directed treatment is unspecified.

Built and tested with
- Google Mobile Ads SDK version 7.61.0.
- InMobi SDK version 9.0.7.

#### [Version 9.0.7.1](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.0.7.1.zip)
- Now requires Google Mobile Ads SDK version 7.61.0 or higher.
- Added standardized adapter error codes and messages.

Built and tested with
- Google Mobile Ads SDK version 7.61.0.
- InMobi SDK version 9.0.7.

#### [Version 9.0.7.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.0.7.0.zip)
- Verified compatibility with InMobi SDK 9.0.7.

Built and tested with
- Google Mobile Ads SDK version 7.60.0.
- InMobi SDK version 9.0.7.

#### [Version 9.0.6.0](https://dl.google.com/googleadmobadssdk/mediation/ios/inmobi/InMobiAdapter-9.0.6.0.zip)
- Verified compatibility with InMobi SDK 9.0.6.
- Updated InMobi iOS adapter CocoaPod dependency to use `InMobiSDK/Core`.
- Now requires Google Mobile Ads SDK version 7.60.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.60.0
- InMobi SDK version 9.0.6

#### Version 9.0.4.0
- Verified compatibility with InMobi SDK 9.0.4.
- Adapter now fails early when InMobi SDK initialization fails.
- Removed support for the i386 architecture.

Built and tested with
- Google Mobile Ads SDK version 7.57.0
- InMobi SDK version 9.0.4

#### Version 9.0.0.0
- Verified compatibility with InMobi SDK 9.0.0.
- Removed bidding capability for banner, interstitial, and rewarded formats.

Built and tested with
- Google Mobile Ads SDK version 7.53.1
- InMobi SDK version 9.0.0

#### Version 7.4.0.0
- Verified compatibility with InMobi SDK 7.4.0.

#### Version 7.3.2.1
- Fixed an issue where the adapter fails to initialize due to invalid mediation configurations.

#### Version 7.3.2.0
- Verified compatibility with InMobi SDK 7.3.2.
- Added bidding capability to the adapter for banner, interstitial and rewarded ad formats.

#### Version 7.3.0.0
- Verified compatibility with InMobi SDK 7.3.0.
- Removed support for Native Content and App Install ad requests. Apps must use the Unified Native Ads API to request native ads.
- Now requires Google Mobile Ads SDK version 7.46.0 or higher.

#### Version 7.2.7.0
- Verified compatibility with InMobi SDK 7.2.7.
- Updated the adapter to use the new rewarded API.
- Now requires Google Mobile Ads SDK version 7.42.2 or higher.
- Added support for flexible banner ad sizes.

#### Version 7.2.4.0
- Verified compatibility with InMobi SDK 7.2.4.

#### Version 7.2.1.0
- Verified compatibility with InMobi SDK 7.2.1.

#### Version 7.2.0.0
- Verified compatibility with InMobi SDK 7.2.0.

#### Version 7.1.2.0
- Verified compatibility with InMobi SDK 7.1.2.

#### Version 7.1.1.2
- Added `adapterDidCompletePlayingRewardBasedVideoAd:` callback to the adapter.

#### Version 7.1.1.1
- Added the `GADInMobiConsent` class which provides `updateGDPRConsent` and `getConsent` methods.

#### Version 7.1.1.0
- Verified compatibility with InMobi SDK 7.1.1.

#### Version 7.1.0.0
- Verified compatibility with InMobi SDK 7.1.0.

#### Version 7.0.4.1
- Fixed an issue causing duplicate symbol errors when the adapter was used with
  those of other networks.

#### Version 7.0.4.0
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

#### Version 6.2.1.0
- Verified compatibility with inMobi SDK 6.2.1

#### Earlier versions
- Support for banners, interstitials, rewarded video and native ad formats.
