# Unity Ads Mediation Adapter for Google Mobile Ads SDK for iOS

## Version 3.0.0.1
- Fixed an issue where the adapter stores the 'placementId' of previous request.

## Version 3.0.0.0
- Verified compatibility with Unity Ads SDK 3.0.0.

## Version 2.3.0.0
- Verified compatibility with Unity Ads SDK 2.3.0.

## Version 2.2.1.1
- Added `adapterDidCompletePlayingRewardBasedVideoAd:` callback to the adapter.

## Version 2.2.1.0
- Verified compatibility with Unity Ads SDK 2.2.1.

## Version 2.2.0.0
- Verified compatibility with Unity Ads SDK 2.2.0.

## Version 2.1.2.0
- Verified compatibility with Unity Ads SDK 2.1.2.
- Removed the support for 'armv7s' architecture.

## Version 2.1.1.0
- Verified compatibility with Unity Ads SDK 2.1.1.

## Version 2.1.0.0
- Updated the adapter to make it compatible with Unity Ads SDK 2.1.0.

## Version 2.0.8.0
- Verified compatibility with Unity Ads SDK 2.0.8.

## Version 2.0.7.0
- Adapter now tracks Unity Ads clicks so the AdMob and the Unity Ads click
  statistics can match up.
- Apps now get `interstitialWillLeaveApplication:` and
  `rewardBasedVideoAdWillLeaveApplication:` callbacks.

## Version 2.0.6.0
- Verified compatibility with Unity Ads SDK 2.0.6.

## Version 2.0.5.0
- Verified compatibility with Unity Ads SDK 2.0.5.

## Version 2.0.4.0
- Changed the version naming system to
  [Unity Ads SDK version].[adapter patch version].
- Updated the minimum required Unity Ads SDK to v2.0.4.
- Updated the minimum required Google Mobile Ads SDK to v7.10.1.

## Version 1.0.2
- Made the user reward item's key non nil. The reward key will always be an
  empty or a valid string.

## Version 1.0.1
- Fixed bug where the `rewardBasedVideoAdDidOpen:` callback wasn’t getting called.

## Version 1.0.0
- Supports interstitial and reward-based video ads.
