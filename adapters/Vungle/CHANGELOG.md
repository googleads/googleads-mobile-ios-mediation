# Vungle Adapter for Google Mobile Ads SDK for iOS Changelog

## VERSION 6.3.2.2
- Fixed a bug where the Vungle adapter would never load rewarded ads if Vungle SDK initialization failed. Now, the adapter will try to re-initialize the Vungle SDK on subsequent rewarded ad requests.
- Now requires Google Mobile Ads SDK version 7.42.2 or higher.

## VERSION 6.3.2.1
- Updated the adapter to use new rewarded API.
- Now requires Google Mobile Ads SDK version 7.41.0 or higher.

## VERSION 6.3.2.0
- Verified compatibility with Vungle SDK 6.3.2.

## VERSION 6.3.0.0
- Verified compatibility with Vungle SDK 6.3.0.
- Updated `updateConsentStatus` method to `updateConsentStatus:consentMessageVersion:` in `VungleRouterConsent` class.

## VERSION 6.2.0.3
- Added `adapterDidCompletePlayingRewardBasedVideoAd:` callback to the adapter.

## VERSION 6.2.0.2
- Added `VungleRouterConsent` class which contains `updateConsentStatus` and `getConsentStatus` methods.

## VERSION 6.2.0.1
- Updated Vungle SDK initializer correctly.

## VERSION 6.2.0.0
- Verified compatibility with Vungle SDK 6.2.0.

## VERSION 5.4.0.0
- Verified compatibility with Vungle SDK 5.4.0.
- Updated adapter to correctly report clicks to the Google Mobile Ads SDK.

## VERSION 5.3.2.0
- Added two new extras to `VungleAdNetworkExtras`:
  - `ordinal` - An integer indicating the order in which this ad was shown in
    the game session.
  - `flexViewAutoDismissSeconds` - Sets Flex View ads to automatically close in
    the specified amount of seconds.
- Verified compatibility with Vungle SDK 5.3.2.

## VERSION 5.3.0.0
- Updated the deployment target to iOS 8.
- Verified compatibility with Vungle SDK 5.3.0.

## VERSION 5.2.0.0
- Verified compatibility with Vungle SDK 5.2.0.

## VERSION 5.1.1.0
- Verified compatibility with Vungle SDK 5.1.1.

## VERSION 5.1.0.0
- Verified compatibility with Vungle SDK 5.1.0.

## Earlier versions
- Added support for interstitial and rewarded video ad formats.
