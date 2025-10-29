## Unity Ads iOS Mediation Adapter Changelog

#### Next version
- Adapter now automatically forwards GDPR consent found inside `IABTCF_AddtlConsent` to the Unity Ads SDK if GDPR applies.

#### [Version 4.16.3.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.16.3.0.zip)
- Verified compatibility with Unity Ads SDK 4.16.3.

Built and tested with:
- Google Mobile Ads SDK version 12.12.0.
- Unity Ads SDK version 4.16.3.

#### [Version 4.16.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.16.2.0.zip)
- Updated ad loading methods to wait for the Unity Ads SDK to be fully initialized before attempting to load an ad.
- Resolved a race condition where completion callbacks could potentially be dropped if multiple initializations are in progress.
- Verified compatibility with Unity Ads SDK 4.16.2.

Built and tested with:
- Google Mobile Ads SDK version 12.12.0.
- Unity Ads SDK version 4.16.2.

#### [Version 4.16.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.16.1.0.zip)
- Verified compatibility with Unity Ads SDK 4.16.1.

Built and tested with:
- Google Mobile Ads SDK version 12.9.0.
- Unity Ads SDK version 4.16.1.

#### [Version 4.16.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.16.0.0.zip)
- Now requires minimum iOS version `13.0`.
- Verified compatibility with Unity Ads SDK 4.16.0.

Built and tested with:
- Google Mobile Ads SDK version 12.8.0.
- Unity Ads SDK version 4.16.0.

#### [Version 4.15.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.15.1.0.zip)
- Verified compatibility with Unity Ads SDK 4.15.1.

Built and tested with:
- Google Mobile Ads SDK version 12.6.0.
- Unity Ads SDK version 4.15.1.

#### [Version 4.15.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.15.0.0.zip)
- Added error code `111: Unsupported ad format`.
- Verified compatibility with Unity Ads SDK 4.15.0.

Built and tested with:
- Google Mobile Ads SDK version 12.5.0.
- Unity Ads SDK version 4.15.0.

#### [Version 4.14.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.14.2.0.zip)
- Verified compatibility with Unity Ads SDK 4.14.2.

Built and tested with:
- Google Mobile Ads SDK version 12.3.0.
- Unity Ads SDK version 4.14.2.

#### [Version 4.14.1.1](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.14.1.1.zip)
- For bidding, the adapter no longer checks the banner ad size.
- For waterfall, the adapter now checks whether the loaded Unity Ads banner ad aspect ratio matches with the requested banner ad size.

Built and tested with:
- Google Mobile Ads SDK version 12.2.0.
- Unity Ads SDK version 4.14.1.

#### [Version 4.14.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.14.1.0.zip)
- Verified compatibility with Unity Ads SDK 4.14.1.

Built and tested with:
- Google Mobile Ads SDK version 12.2.0.
- Unity Ads SDK version 4.14.1.

#### [Version 4.14.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.14.0.0.zip)
- Enabled `-fobjc-arc` and `-fstack-protector-all` flags.
- Verified compatibility with Unity Ads SDK 4.14.0.

Built and tested with:
- Google Mobile Ads SDK version 12.2.0.
- Unity Ads SDK version 4.14.0.

#### [Version 4.13.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.13.2.0.zip)
- Verified compatibility with Unity Ads SDK 4.13.2.

Built and tested with:
- Google Mobile Ads SDK version 12.1.0.
- Unity Ads SDK version 4.13.2.

#### [Version 4.13.1.1](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.13.1.1.zip)
- Now requires Google Mobile Ads SDK version 12.0.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 12.0.0.
- Unity Ads SDK version 4.13.1.

#### [Version 4.13.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.13.1.0.zip)
- Added the `GADMediationAdapterUnity.testMode` property to indicate whether the Unity Ads SDK should be initialized in test mode. This flag must be set before initializing the Google Mobile Ads SDK.
- Updated to report the Unity Ads SDK's error code when an ad fails to load.

Built and tested with:
- Google Mobile Ads SDK version 11.13.0.
- Unity Ads SDK version 4.13.1.

#### [Version 4.13.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.13.0.0.zip)
- Verified compatibility with Unity Ads SDK 4.13.0.

Built and tested with:
- Google Mobile Ads SDK version 11.13.0.
- Unity Ads SDK version 4.13.0.

#### [Version 4.12.5.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.12.5.0.zip)
- Verified compatibility with Unity Ads SDK 4.12.5.

Built and tested with:
- Google Mobile Ads SDK version 11.12.0.
- Unity Ads SDK version 4.12.5.

#### [Version 4.12.4.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.12.4.0.zip)
- Verified compatibility with Unity Ads SDK 4.12.4.

Built and tested with:
- Google Mobile Ads SDK version 11.12.0.
- Unity Ads SDK version 4.12.4.

#### [Version 4.12.3.1](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.12.3.1.zip)
- Updated `CFBundleShortVersionString` to have three components instead of four.

Built and tested with:
- Google Mobile Ads SDK version 11.10.0.
- Unity Ads SDK version 4.12.3.

#### [Version 4.12.3.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.12.3.0.zip)
- Verified compatibility with Unity Ads SDK 4.12.3.

Built and tested with:
- Google Mobile Ads SDK version 11.10.0.
- Unity Ads SDK version 4.12.3.

#### [Version 4.12.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.12.2.0.zip)
- Verified compatibility with Unity Ads SDK 4.12.2.

Built and tested with:
- Google Mobile Ads SDK version 11.7.0.
- Unity Ads SDK version 4.12.2.

#### [Version 4.12.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.12.1.0.zip)
- Verified compatibility with Unity Ads SDK 4.12.1.

Built and tested with:
- Google Mobile Ads SDK version 11.6.0.
- Unity Ads SDK version 4.12.1.

#### [Version 4.12.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.12.0.0.zip)
- Verified compatibility with Unity Ads SDK 4.12.0.

Built and tested with:
- Google Mobile Ads SDK version 11.5.0.
- Unity Ads SDK version 4.12.0.

#### [Version 4.11.3.1](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.11.3.1.zip)
- Added bidding support for banner, interstitial and rewarded ad formats.

Built and tested with:
- Google Mobile Ads SDK version 11.5.0.
- Unity Ads SDK version 4.11.3.

#### [Version 4.11.3.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.11.3.0.zip)
- Verified compatibility with Unity Ads SDK 4.11.3.

Built and tested with:
- Google Mobile Ads SDK version 11.4.0.
- Unity Ads SDK version 4.11.3.

#### [Version 4.11.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.11.2.0.zip)
- Verified compatibility with Unity Ads SDK 4.11.2.

Built and tested with:
- Google Mobile Ads SDK version 11.4.0.
- Unity Ads SDK version 4.11.2.

#### [Version 4.10.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.10.0.0.zip)
- Verified compatibility with Unity Ads SDK 4.10.0.

Built and tested with:
- Google Mobile Ads SDK version 11.2.0.
- Unity Ads SDK version 4.10.0.

#### [Version 4.9.3.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.9.3.0.zip)
- Verified compatibility with Unity Ads SDK 4.9.3.
- Now requires minimum iOS version 12.0.
- Now requires Google Mobile Ads SDK version 11.0 or higher.
- Included `Info.plist` in the frameworks within `UnityAdapter.xcframework`.

Built and tested with:
- Google Mobile Ads SDK version 11.0.1.
- Unity Ads SDK version 4.9.3.

#### [Version 4.9.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.9.2.0.zip)
- Verified compatibility with Unity Ads SDK 4.9.2.

Built and tested with:
- Google Mobile Ads SDK version 10.13.0.
- Unity Ads SDK version 4.9.2.

#### [Version 4.9.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.9.1.0.zip)
- Verified compatibility with Unity Ads SDK 4.9.1.

Built and tested with:
- Google Mobile Ads SDK version 10.12.0.
- Unity Ads SDK version 4.9.1.

#### [Version 4.9.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.9.0.0.zip)
- Removed `GADMAdNetworkAdapter` conformance and dependency from the Unity adapter.
- Added report impression method invocation in `unityAdsShowStart` delegate method.
- Verified compatibility with Unity Ads SDK 4.9.0.

Built and tested with:
- Google Mobile Ads SDK version 10.12.0.
- Unity Ads SDK version 4.9.0.

#### [Version 4.8.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.8.0.0.zip)
- Added support for impression events for banner ads.
- Verified compatibility with Unity Ads SDK 4.8.0.

Built and tested with:
- Google Mobile Ads SDK version 10.7.0.
- Unity Ads SDK version 4.8.0.

#### [Version 4.7.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.7.1.0.zip)
- Verified compatibility with Unity Ads SDK 4.7.1.

Built and tested with:
- Google Mobile Ads SDK version 10.5.0.
- Unity Ads SDK version 4.7.1.

#### [Version 4.7.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.7.0.0.zip)
- Verified compatibility with Unity Ads SDK 4.7.0.
- Now requires minimum iOS version 11.0.
- Now requires Google Mobile Ads SDK version 10.4.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 10.4.0.
- Unity Ads SDK version 4.7.0.

#### [Version 4.6.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.6.1.0.zip)
- Verified compatibility with Unity Ads SDK 4.6.1.

Built and tested with:
- Google Mobile Ads SDK version 10.2.0.
- Unity Ads SDK version 4.6.1.

#### [Version 4.6.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.6.0.0.zip)
- Verified compatibility with Unity Ads SDK 4.6.0.
- Added support for forwarding COPPA information to the Unity Ads SDK.
- Removed support for the `armv7` architecture.
- Now requires Google Mobile Ads SDK version 10.0.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 10.2.0.
- Unity Ads SDK version 4.6.0.

#### [Version 4.5.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.5.0.0.zip)
- Verified compatibility with Unity Ads SDK 4.5.0.

Built and tested with:
- Google Mobile Ads SDK version 9.14.0.
- Unity Ads SDK version 4.5.0.

#### [Version 4.4.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.4.1.0.zip)
- Verified compatibility with Unity Ads SDK 4.4.1.

Built and tested with:
- Google Mobile Ads SDK version 9.11.0.
- Unity Ads SDK version 4.4.1.

#### [Version 4.4.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.4.0.0.zip)
- Updated the adapter to use the `didRewardUser` API.
- Now requires Google Mobile Ads SDK version 9.8.0 or higher.
- Verified compatibility with Unity Ads SDK 4.4.0.

Built and tested with:
- Google Mobile Ads SDK version 9.10.0.
- Unity Ads SDK version 4.4.0.

#### [Version 4.3.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.3.0.0.zip)
- Verified compatibility with Unity Ads SDK 4.3.0.

Built and tested with:
- Google Mobile Ads SDK version 9.8.0.
- Unity Ads SDK version 4.3.0.

#### [Version 4.2.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.2.1.0.zip)
- Verified compatibility with Unity Ads SDK 4.2.1.

Built and tested with:
- Google Mobile Ads SDK version 9.4.0.
- Unity Ads SDK version 4.2.1.

#### [Version 4.1.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.1.0.0.zip)
- Verified compatibility with Unity Ads SDK 4.1.0.

Built and tested with:
- Google Mobile Ads SDK version 9.2.0.
- Unity Ads SDK version 4.1.0.

#### [Version 4.0.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.0.1.0.zip)
- Verified compatibility with Unity Ads SDK 4.0.1.

Built and tested with:
- Google Mobile Ads SDK version 9.0.0.
- Unity Ads SDK version 4.0.1.

#### [Version 4.0.0.2](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.0.0.2.zip)
- Added support for the arm64 simulator architecture.

Built and tested with:
- Google Mobile Ads SDK version 9.0.0.
- Unity Ads SDK version 4.0.0.

#### [Version 4.0.0.1](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.0.0.1.zip)
- Verified compatibility with Google Mobile Ads SDK version 9.0.0.
- Now requires Google Mobile Ads SDK version 9.0.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 9.0.0.
- Unity Ads SDK version 4.0.0.

#### [Version 4.0.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-4.0.0.0.zip)
- Verified compatibility with Unity Ads SDK 4.0.0.
- Now requires minimum iOS version 10.0.

Built and tested with
- Google Mobile Ads SDK version 8.13.0.
- Unity Ads SDK version 4.0.0.

#### [Version 3.7.5.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.7.5.0.zip)
- Verified compatibility with Unity Ads SDK 3.7.5.

Built and tested with
- Google Mobile Ads SDK version 8.8.0.
- Unity Ads SDK version 3.7.5.

#### [Version 3.7.4.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.7.4.0.zip)
- Verified compatibility with Unity Ads SDK 3.7.4.

Built and tested with
- Google Mobile Ads SDK version 8.7.0.
- Unity Ads SDK version 3.7.4.

#### [Version 3.7.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.7.2.0.zip)
- Verified compatibility with Unity Ads SDK 3.7.2.
- Relaxed dependency to Google Mobile Ads SDK version 8.0.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 8.5.0.
- Unity Ads SDK version 3.7.2.

#### [Version 3.7.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.7.1.0.zip)
- Verified compatibility with Unity Ads SDK 3.7.1.
- Now requires Google Mobile Ads SDK version 8.4.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 8.4.0.
- Unity Ads SDK version 3.7.1.

#### [Version 3.6.2.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.6.2.0.zip)
- Updated the adapter to use the `.xcframework` format.
- Verified compatibility with Unity Ads SDK 3.6.2.
- Now requires Google Mobile Ads SDK version 8.2.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 8.2.0.
- Unity Ads SDK version 3.6.2.

#### [Version 3.6.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.6.0.0.zip)
- Verified compatibility with Unity Ads SDK 3.6.0.
- Now requires Google Mobile Ads SDK version 7.69.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.69.0.
- Unity Ads SDK version 3.6.0.

#### [Version 3.5.1.1](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.5.1.1.zip)
- Fixed a crash that sometimes occurred when the Unity Ads SDK finished initializing.

Built and tested with
- Google Mobile Ads SDK version 7.68.0.
- Unity Ads SDK version 3.5.1.

#### [Version 3.5.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.5.1.0.zip)
- Verified compatibility with Unity Ads SDK 3.5.1.

Built and tested with
- Google Mobile Ads SDK version 7.68.0.
- Unity Ads SDK version 3.5.1.

#### [Version 3.5.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.5.0.0.zip)
- Verified compatibility with Unity Ads SDK 3.5.0.
- Added support for Adaptive Banner ads.
- Now requires Google Mobile Ads SDK version 7.68.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.68.0.
- Unity Ads SDK version 3.5.0.

#### [Version 3.4.8.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.4.8.0.zip)
- Verified compatibility with Unity Ads SDK 3.4.8.
- Now requires Google Mobile Ads SDK version 7.63.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.63.0.
- Unity Ads SDK version 3.4.8.

#### [Version 3.4.6.0](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.4.6.0.zip)
- Verified compatibility with Unity Ads SDK 3.4.6.
- Now requires Google Mobile Ads SDK version 7.60.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.60.0.
- Unity Ads SDK version 3.4.6.

#### [Version 3.4.2.2](https://dl.google.com/googleadmobadssdk/mediation/ios/unity/UnityAdapter-3.4.2.2.zip)
- Added standardized adapter error codes and messages.
- Updated the minimum required Google Mobile Ads SDK version to 7.59.0.

Built and tested with
- Google Mobile Ads SDK version 7.59.0.
- Unity Ads SDK version 3.4.2.

#### Version 3.4.2.1
- Improved forwarding of Unity's errors to recognize initialization and ad load failures earlier and reduce timeouts.
- Removed support for the i386 architecture.

Built and tested with
- Google Mobile Ads SDK version 7.57.0.
- Unity Ads SDK version 3.4.2.

#### Version 3.4.2.0
- Verified compatibility with Unity Ads SDK 3.4.2.

Built and tested with
- Google Mobile Ads SDK version 7.55.1.
- Unity Ads SDK version 3.4.2.

#### Version 3.4.0.0
- Verified compatibility with Unity Ads SDK 3.4.0.
- Now supports loading multiple banner ads at once.

Built and tested with
- Google Mobile Ads SDK version 7.53.0.
- Unity Ads SDK version 3.4.0.

#### Version 3.3.0.0
- Verified compatibility with Unity Ads SDK 3.3.0.
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
