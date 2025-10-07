## LINE iOS Mediation Adapter Changelog

#### [Version 2.9.20250930.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.9.20250930.0.zip)
- Verified compatibility with FiveAd SDK version 2.9.20250930.

Built and tested with:
- Google Mobile Ads SDK version 12.12.0.
- FiveAd SDK version 2.9.20250930.

#### [Version 2.9.20250912.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.9.20250912.0.zip)
- Adapter now initializes the FiveAd SDK before each ad request.
- Verified compatibility with FiveAd SDK version 2.9.20250912.

Built and tested with:
- Google Mobile Ads SDK version 12.11.0.
- FiveAd SDK version 2.9.20250912.

#### [Version 2.9.20250512.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.9.20250512.0.zip)
- Now requires minimum iOS version 13.0.
- Verified compatibility with FiveAd SDK version 2.9.20250512.

Built and tested with:
- Google Mobile Ads SDK version 12.4.0.
- FiveAd SDK version 2.9.20250512.

#### [Version 2.9.20241106.3](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.9.20241106.3.zip)
- Fixed an issue where `GADMediationAdapterLine.h` was not a public header.
- Enabled `-fobjc-arc` and `-fstack-protector-all` flags.
- Removed the banner ad size verification for bidding after successful loading.
  - Waterfall banner ads will continue to check for banner ad sizes upon successful loading.

Built and tested with:
- Google Mobile Ads SDK version 12.2.0.
- FiveAd SDK version 2.9.20241106.

#### [Version 2.9.20241106.2](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.9.20241106.2.zip)
- Added the `GADMediationAdapterLine.testMode` property to indicate whether the FiveAd SDK should be initialized in test mode. This flag must be set before initializing the Google Mobile Ads SDK.
- Removed the check for FiveAd SDK initialization state before initializing the FiveAd SDK.
- Removed the deprecated native ad state check before downloading native ad assets.
- Now requires Google Mobile Ads SDK version 12.0.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 12.0.0.
- FiveAd SDK version 2.9.20241106.

#### [Version 2.9.20241106.1](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.9.20241106.1.zip)
- Updated the adapter to use the latest ad load API for bidding banner ads.
- Fixed an issue preventing ad events from forwarding correctly for bidding interstitial ads.

Built and tested with:
- Google Mobile Ads SDK version 11.12.0.
- FiveAd SDK version 2.9.20241106.

#### [Version 2.9.20241106.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.9.20241106.0.zip)
- Verified compatibility with FiveAd SDK version 2.9.20241106.

Built and tested with:
- Google Mobile Ads SDK version 11.12.0.
- FiveAd SDK version 2.9.20241106.

#### [Version 2.8.20240827.1](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.8.20240827.1.zip)
- Updated `CFBundleShortVersionString` to have three components instead of four.

Built and tested with:
- Google Mobile Ads SDK version 11.10.0.
- FiveAd SDK version 2.8.20240827.

#### [Version 2.8.20240827.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.8.20240827.0.zip)
- Verified compatibility with FiveAd SDK version 2.8.20240827.
- Added bidding support for banner, interstitial, rewarded, and native ad formats.

Built and tested with:
- Google Mobile Ads SDK version 11.8.0.
- FiveAd SDK version 2.8.20240827.

#### [Version 2.8.20240612.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.8.20240612.0.zip)
- Added audio control for native ad via GADVideoOptions.
- Verified compatibility with FiveAd SDK version 2.8.20240612.

Built and tested with:
- Google Mobile Ads SDK version 11.5.0.
- FiveAd SDK version 2.8.20240612.

#### [Version 2.7.20240411.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.7.20240411.0.zip)
- Verified compatibility with FiveAd SDK version 2.7.20240411.

Built and tested with:
- Google Mobile Ads SDK version 11.3.0.
- FiveAd SDK version 2.7.20240411.

#### [Version 2.7.20240318.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.7.20240318.0.zip)
- Verified compatibility with FiveAd SDK version 2.7.20240318.

Built and tested with:
- Google Mobile Ads SDK version 11.2.0.
- FiveAd SDK version 2.7.20240318.

#### [Version 2.7.20240214.1](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.7.20240214.1.zip)
- Now requires minimum iOS version 12.0.
- Now requires Google Mobile Ads SDK version 11.0 or higher.
- Included `Info.plist` in the frameworks within `LineAdapter.xcframework`.

Built and tested with:
- Google Mobile Ads SDK version 11.0.1.
- FiveAd SDK version 2.7.20240214.

#### [Version 2.7.20240214.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.7.20240214.0.zip)
- Verified compatibility with FiveAd SDK version 2.7.20240214.

Built and tested with:
- Google Mobile Ads SDK version 11.0.1.
- FiveAd SDK version 2.7.20240214.

#### [Version 2.7.20240126.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.7.20240126.0.zip)
- Verified compatibility with FiveAd SDK version 2.7.20240126.
- Updated the adapter implementation with FiveAd SDK new delegate protocols.

Built and tested with:
- Google Mobile Ads SDK version 10.14.0.
- FiveAd SDK version 2.7.20240126.

#### [Version 2.7.20231115.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.7.20231115.0.zip)
- Verified compatibility with FiveAd SDK version 2.7.20231115.
- Included `GADMediationAdapterLineExtras` header in the modulemap.

Built and tested with:
- Google Mobile Ads SDK version 10.14.0.
- FiveAd SDK version 2.7.20231115.

#### [Version 2.6.20230609.1](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.6.20230609.1.zip)
- Added `GADMediationAdapterLineAudioState` to manage the initial audio state of the banner, interstitial, and rewarded ad when it is first displayed.

Built and tested with:
- Google Mobile Ads SDK version 10.14.0.
- FiveAd SDK version 2.6.20230609.

#### [Version 2.6.20230609.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.6.20230609.0.zip)
- Initial release!
- Added waterfall support for banner, interstitial, rewarded, and native ad formats.
- Verified compatibility with FiveAd SDK version 2.6.20230609.

Built and tested with:
- Google Mobile Ads SDK version 10.9.0.
- FiveAd SDK version 2.6.20230609.
