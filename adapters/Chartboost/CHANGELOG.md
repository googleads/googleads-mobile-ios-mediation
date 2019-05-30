# Chartboost Ads Mediation Adapter for Google Mobile Ads SDK for iOS

## Version 7.5.0.0
- Verified compatibility with Chartboost SDK 7.5.0.
- Updated the adapter to use the new rewarded API.
- Updated the adapter to handle multiple interstitial requests.
- Now requires Google Mobile Ads SDK version 7.42.2 or higher.

## Version 7.3.0.0
- Verified compatibility with Chartboost SDK 7.3.0.

## Version 7.2.0.1
- Added `adapterDidCompletePlayingRewardBasedVideoAd:` callback to the adapter.

## Version 7.2.0.0
- Verified compatibility with Chartboost SDK 7.2.0.

## Version 7.1.2.0
- Verified compatibility with Chartboost SDK 7.1.2.

## Version 7.1.1.0
- Verified compatibility with Chartboost SDK 7.1.1.

## Version 7.1.0.0
- Verified compatibility with Chartboost SDK 7.1.0.

## Version 7.0.4.0
- Verified compatibility with Chartboost SDK 7.0.4.

## Version 7.0.3.0
- Verified compatibility with Chartboost SDK 7.0.3.

## Version 7.0.2.0
- Verified compatibility with Chartboost SDK 7.0.2.
- Added support for two new Chartboost error codes.

## Version 7.0.1.0
- Verified compatibility with Chartboost SDK 7.0.1.

## Version 7.0.0.0
- Verified compatibility with Chartboost SDK 7.0.0.

## Version 6.6.3.0
- Verified compatibility with Chartboost SDK 6.6.3.
- Removed the support for 'armv7s' architecture.
- Fixed a bug where publishers faced a compilation issue in Swift when importing
  `ChartboostAdapter.framework` as a module which was importing non-modular
  Chartboost SDK.

## Version 6.6.2.0
- Verified compatibility with Chartboost SDK 6.6.2.

## Version 6.6.1.0
- Verified compatibility with Chartboost SDK 6.6.1.

## Version 6.6.0.0
- Verified compatibility with Chartboost SDK 6.6.0.

## Version 6.5.2.1
- Enabled bitcode support.
- Now distributing Chartboost adapter as a framework.
- To import `ChartboostAdapter.framework` in your project, make sure to set
  `Allow Non-modular Includes in Framework Modules` to `YES` under Build
  Settings of your target.

## Version 6.5.2.0
- Changed the version naming system to
  [Chartboost SDK version].[adapter patch version].
- Updated the minimum required Chartboost SDK to v6.5.1.
- Updated the minimum required Google Mobile Ads SDK to v7.10.1.
- Fixed a bug to support multiple Chartboost ad locations.
- Apps now get the `interstitialWillDismissScreen:` callback when the
  interstitial ad is about to dismiss.
- Apps now get the `rewardBasedVideoAdDidOpen:` callback when a reward-based
  video ad is opened.

## Version 1.1.0
- Removed Chartboost Ad Location from Chartboost extras. Ad Location is now
specified in the AdMob console when configuring Chartboost for mediation.

## Version 1.0.0
- Initial release. Supports reward-based video ads and interstitial ads.
