## Vungle iOS Mediation Adapter Changelog

#### [Version 6.11.0.1](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.11.0.1.zip)
- Added support for loading multiple ads for the same placement ID in bidding interstitial and rewarded ads.

Built and tested with:
- Google Mobile Ads SDK version 9.6.0.
- Vungle SDK version 6.11.0

#### [Version 6.11.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.11.0.0.zip)
- Verified compatibility with Vungle SDK 6.11.0.

Built and tested with:
- Google Mobile Ads SDK version 9.4.0.
- Vungle SDK version 6.11.0

#### [Version 6.10.6.1](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.10.6.1.zip)
- Fixed an issue where the ad delegate was removed if the next ad failed to download. This applies to auto-cached setting placements only.
- Removed `willPresentFullScreenView` and `adapterWillPresentFullScreenModal` callbacks in banner ads.

Built and tested with:
- Google Mobile Ads SDK version 9.0.0.
- Vungle SDK version 6.10.6

#### [Version 6.10.6.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.10.6.0.zip)
- Verified compatibility with Vungle SDK 6.10.6.
- Verified compatibility with Google Mobile Ads SDK version 9.0.0.
- Now requires Google Mobile Ads SDK version 9.0.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 9.0.0.
- Vungle SDK version 6.10.6

#### [Version 6.10.5.1](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.10.5.1.zip)
- Added bidding support for interstitial and rewarded ad formats.

Built and tested with
- Google Mobile Ads SDK version 8.13.0.
- Vungle SDK version 6.10.5

#### [Version 6.10.5.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.10.5.0.zip)
- Verified compatibility with Vungle SDK 6.10.5.

Built and tested with
- Google Mobile Ads SDK version 8.13.0.
- Vungle SDK version 6.10.5

#### [Version 6.10.4.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.10.4.0.zip)
- Verified compatibility with Vungle SDK 6.10.4.
- Updated the adapter to respect the mute setting in Vungle's publisher dashboard when the `muteIsSet` boolean in `VungleAdNetworkExtras` is not explicitly set.

Built and tested with
- Google Mobile Ads SDK version 8.12.0.
- Vungle SDK version 6.10.4

#### [Version 6.10.3.1](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.10.3.1.zip)
- Fixed a bug where interstitial callbacks were not invoked after the first playback.
- Updated the `options` dictionary that is passed into `playAd` method to include the muted property set by the publisher in the extras object.

Built and tested with
- Google Mobile Ads SDK version 8.12.0.
- Vungle SDK version 6.10.3

#### [Version 6.10.3.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.10.3.0.zip)
- Verified compatibility with Vungle SDK 6.10.3.
- Now requires minimum iOS version of 10.0.

Built and tested with
- Google Mobile Ads SDK version 8.11.0.
- Vungle SDK version 6.10.3.

#### [Version 6.10.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.10.1.0.zip)
- Verified compatibility with Vungle SDK 6.10.1.
- Relaxed dependency to Google Mobile Ads SDK version 8.0.0 or higher.
- Now requires building against Xcode 12.5 or higher.

Built and tested with
- Google Mobile Ads SDK version 8.9.0.
- Vungle SDK version 6.10.1.

#### Version 6.10.0.0 (rolled back)
- Verified compatibility with Vungle SDK 6.10.0.
- Relaxed dependency to Google Mobile Ads SDK version 8.0.0 or higher.
- Now requires building against Xcode 12.5 or higher.

Built and tested with
- Google Mobile Ads SDK version 8.4.0.
- Vungle SDK version 6.10.0.

#### [Version 6.9.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.9.2.0.zip)
- Verified compatibility with Vungle SDK 6.9.2.
- Now requires Google Mobile Ads SDK version 8.3.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 8.3.0.
- Vungle SDK version 6.9.2.

#### [Version 6.9.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.9.1.0.zip)
- Verified compatibility with Vungle SDK 6.9.1.
- Now requires Google Mobile Ads SDK version 8.1.0 or higher.
- Added standardized adapter error codes and messages.
- Updated the adapter to use the `.xcframework` format.
- Remove VungleSDKResetPlacementForDifferentAdSize error check for loading Ads.
- Introduce the new SDK delegate callback `vungleAdViewedForPlacement:` to track impression.

Built and tested with
- Google Mobile Ads SDK version 8.1.0.
- Vungle SDK version 6.9.1.

#### [Version 6.8.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.8.1.0.zip)
- Verified compatibility with Vungle SDK 6.8.1.
- Now requires Google Mobile Ads SDK version 7.66.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.66.0.
- Vungle SDK version 6.8.1.

#### [Version 6.8.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.8.0.0.zip)
- Verified compatibility with Vungle SDK 6.8.0.
- Now requires Google Mobile Ads SDK version 7.65.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.65.0.
- Vungle SDK version 6.8.0.

#### [Version 6.7.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.7.1.0.zip)
- Verified compatibility with Vungle SDK 6.7.1.
- Now requires Google Mobile Ads SDK version 7.64.0 or higher.
- Fixed an issue where `didFailToPresentWithError:` was not called when a rewarded ad failed to present.

Built and tested with
- Google Mobile Ads SDK version 7.64.0.
- Vungle SDK version 6.7.1.

#### [Version 6.7.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.7.0.0.zip)
- Verified compatibility with Vungle SDK 6.7.0.
- Now requires Google Mobile Ads SDK version 7.62.0 or higher.
- Added support for playing multiple banner ads at the same time.
- Clicks now reported when the click happens instead of when the ad is closed.
- Banner and interstitial ads now forward the willLeaveApplication callback.

Built and tested with
- Google Mobile Ads SDK version 7.62.0.
- Vungle SDK version 6.7.0.

#### [Version 6.5.3.0](https://dl.google.com/googleadmobadssdk/mediation/ios/vungle/VungleAdapter-6.5.3.0.zip)
- Verified compatibility with Vungle SDK 6.5.3.
- Now requires Google Mobile Ads SDK version 7.58.0 or higher.
- Added support for Smart and Adaptive Banner ads.
- Added support for Banner (320x50, 300x50, 728x90) ads.
- Added video orientation option when play ads.
- Fix a bug where failed to call report_ad after the first refresh.
- Fix ad availability delays issue with longer waterfall.
- Remove support for i386 architecture.

Built and tested with
- Google Mobile Ads SDK version 7.58.0.
- Vungle SDK version 6.5.3.

#### Version 6.4.6.0
- Verified compatibility with Vungle SDK 6.4.6.
- Added support for banner (MREC) ads.
- Fixed a bug where didReceiveInterstitial: callback is called more than once.
- Removed callbacks to adapterWillLeaveApplication, which were previously not invoked at the correct time.

Built and tested with
- Google Mobile Ads SDK version 7.52.0.
- Vungle SDK version 6.4.6.

#### Version 6.3.2.3
- Fixed a crash in [GADMAdapterVungleRewardedAd adAvailable:].

#### Version 6.3.2.2
- Fixed a bug where the Vungle adapter would never load rewarded ads if Vungle SDK initialization failed. Now, the adapter will try to re-initialize the Vungle SDK on subsequent rewarded ad requests.
- Now requires Google Mobile Ads SDK version 7.42.2 or higher.

#### Version 6.3.2.1
- Updated the adapter to use new rewarded API.
- Now requires Google Mobile Ads SDK version 7.41.0 or higher.

#### Version 6.3.2.0
- Verified compatibility with Vungle SDK 6.3.2.

#### Version 6.3.0.0
- Verified compatibility with Vungle SDK 6.3.0.
- Updated `updateConsentStatus` method to `updateConsentStatus:consentMessageVersion:` in `VungleRouterConsent` class.

#### Version 6.2.0.3
- Added `adapterDidCompletePlayingRewardBasedVideoAd:` callback to the adapter.

#### Version 6.2.0.2
- Added `VungleRouterConsent` class which contains `updateConsentStatus` and `getConsentStatus` methods.

#### Version 6.2.0.1
- Updated Vungle SDK initializer correctly.

#### Version 6.2.0.0
- Verified compatibility with Vungle SDK 6.2.0.

#### Version 5.4.0.0
- Verified compatibility with Vungle SDK 5.4.0.
- Updated adapter to correctly report clicks to the Google Mobile Ads SDK.

#### Version 5.3.2.0
- Added two new extras to `VungleAdNetworkExtras`:
  - `ordinal` - An integer indicating the order in which this ad was shown in
    the game session.
  - `flexViewAutoDismissSeconds` - Sets Flex View ads to automatically close in
    the specified amount of seconds.
- Verified compatibility with Vungle SDK 5.3.2.

#### Version 5.3.0.0
- Updated the deployment target to iOS 8.
- Verified compatibility with Vungle SDK 5.3.0.

#### Version 5.2.0.0
- Verified compatibility with Vungle SDK 5.2.0.

#### Version 5.1.1.0
- Verified compatibility with Vungle SDK 5.1.1.

#### Version 5.1.0.0
- Verified compatibility with Vungle SDK 5.1.0.

#### Earlier versions
- Added support for interstitial and rewarded video ad formats.
