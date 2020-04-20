## Unity Ads iOS Mediation Adapter Changelog

#### Version 3.4.2.1
- Improved forwarding of Unity's errors to recognize initialization and ad load failures earlier and reduce timeouts.
- Removed support for the i386 architecture.

Built and tested with
- Google Mobile Ads SDK version 7.57.0.
- Unity Ads SDK version 3.4.2.

#### Version 3.4.2.0
- Verified compatibility with unity ads SDK 3.4.2.

Built and tested with
- Google Mobile Ads SDK version 7.55.1.
- Unity Ads SDK version 3.4.2.

#### Version 3.4.0.0
- Verified compatibility with unity ads SDK 3.4.0.
- Now supports loading multiple banner ads at once.

Built and tested with
- Google Mobile Ads SDK version 7.53.0.
- Unity Ads SDK version 3.4.0.

#### Version 3.3.0.0
- Verified compatibility with unity ads SDK 3.3.0.
- Now supports loading multiple banner ads at once.

Built and tested with
- Google Mobile Ads SDK version 7.51.0.
- Unity Ads SDK version 3.3.0.

#### Version 3.2.0.1
- Verified compatibility with Unity Ads SDK 3.2.0.
- Now requires Google Mobile Ads SDK version 7.46.0 or higher.
- Fixed an issue where Unity Banner ads would fail to show when loaded.
- Fixed an issue where the adapter was not properly forwarding the `unityAdsReady` callback.

#### Version 3.2.0.0
- Release was removed due to a regression on no-fill reporting.

#### Version 3.1.0.0
- Verified compatibility with Unity Ads SDK 3.1.0.

#### Version 3.0.3.0
- Verified compatibility with Unity Ads SDK 3.0.3.
- Now requires Google Mobile Ads SDK version 7.42.2 or higher.
- Added support for flexible banner ad sizes.
- Fixed an issue where Unity Banner ads would only successfully load once per session.

#### Version 3.0.1.0
- Verified compatibility with Unity Ads SDK 3.0.1.
- Fixed a crash that occurred when deallocating rewarded ads.

#### Version 3.0.0.3
- Updating adapter to use new rewarded API.
- Now requires Google Mobile Ads SDK version 7.41.0 or higher.

#### Version 3.0.0.2
- Added support for banner ads.

#### Version 3.0.0.1
- Fixed an issue where the adapter stores the 'placementId' of previous request.

#### Version 3.0.0.0
- Verified compatibility with Unity Ads SDK 3.0.0.

#### Version 2.3.0.0
- Verified compatibility with Unity Ads SDK 2.3.0.

#### Version 2.2.1.1
- Added `adapterDidCompletePlayingRewardBasedVideoAd:` callback to the adapter.

#### Version 2.2.1.0
- Verified compatibility with Unity Ads SDK 2.2.1.

#### Version 2.2.0.0
- Verified compatibility with Unity Ads SDK 2.2.0.

#### Version 2.1.2.0
- Verified compatibility with Unity Ads SDK 2.1.2.
- Removed the support for 'armv7s' architecture.

#### Version 2.1.1.0
- Verified compatibility with Unity Ads SDK 2.1.1.

#### Version 2.1.0.0
- Updated the adapter to make it compatible with Unity Ads SDK 2.1.0.

#### Version 2.0.8.0
- Verified compatibility with Unity Ads SDK 2.0.8.

#### Version 2.0.7.0
- Adapter now tracks Unity Ads clicks so the AdMob and the Unity Ads click
  statistics can match up.
- Apps now get `interstitialWillLeaveApplication:` and
  `rewardBasedVideoAdWillLeaveApplication:` callbacks.

#### Version 2.0.6.0
- Verified compatibility with Unity Ads SDK 2.0.6.

#### Version 2.0.5.0
- Verified compatibility with Unity Ads SDK 2.0.5.

#### Version 2.0.4.0
- Changed the version naming system to
  [Unity Ads SDK version].[adapter patch version].
- Updated the minimum required Unity Ads SDK to v2.0.4.
- Updated the minimum required Google Mobile Ads SDK to v7.10.1.

#### Version 1.0.2
- Made the user reward item's key non nil. The reward key will always be an
  empty or a valid string.

#### Version 1.0.1
- Fixed bug where the `rewardBasedVideoAdDidOpen:` callback wasn’t getting called.

#### Version 1.0.0
- Supports interstitial and reward-based video ads.
