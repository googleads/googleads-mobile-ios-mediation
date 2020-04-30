## Vungle iOS Mediation Adapter Changelog

#### Version 6.5.3.0
- Verified compatibility with Vungle SDK 6.5.3.
- Now requires Google Mobile Ads SDK version 7.58.0 or higher.
- Added support for Smart and Adaptive Banner ads.
- Added support for Banner (320x50, 300x50, 728x90) ads.
- Added video orientation option when play ads.
- Fix a bug where failed to call report_ad after the first refresh.
- Fix ad availability delays issue with longer waterfall.
- Remove support for i386 architecture.

Build and tested with
- Google Mobile Ads SDK version 7.58.0.
- Vungle SDK version 6.5.3.

#### Version 6.4.6.0
- Verified compatibility with Vungle SDK 6.4.6.
- Added support for banner (MREC) ads.
- Fixed a bug where didReceiveInterstitial: callback is called more than once.
- Removed callbacks to adapterWillLeaveApplication, which were previously not invoked at the correct time.

Build and tested with
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
