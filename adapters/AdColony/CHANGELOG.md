## AdColony iOS Mediation Adapter Changelog

#### Version 4.1.4.1
- Added standardized adapter error codes and messages.
- Removed support for the i386 architecture.

Built and tested with
- Google Mobile Ads SDK version 7.57.0.
- AdColony SDK version 4.1.4.

#### Version 4.1.4.0
- Verified compatibility with AdColony SDK 4.1.4.

Built and tested with
- Google Mobile Ads SDK version 7.56.0.
- AdColony SDK version 4.1.4.

#### Version 4.1.3.1
- Fixed AdColony mediation network adapter version string.

Built and tested with
- Google Mobile Ads SDK version 7.55.0.
- AdColony SDK version 4.1.3.

#### Version 4.1.3.0 (Deprecated)
- Known issue: Incorrectly reports the mediation adapter version as 4.1.2.0.
  Please use version 4.1.3.1 or higher.
- Verified compatibility with AdColony SDK 4.1.3.
- Adding code to re-request ads for OB requests when the AdColony ad expires.

Built and tested with
- Google Mobile Ads SDK version 7.55.0.
- AdColony SDK version 4.1.3.

#### Version 4.1.2.0
- Verified compatibility with AdColony SDK 4.1.2.
- Added support for banner ads.

Built and tested with
- Google Mobile Ads SDK version 7.52.0.
- AdColony SDK version 4.1.2.

#### Version 4.1.1.0
- Verified compatibility with AdColony SDK 4.1.1.
- Added support for banner ads.

Built and tested with
- Google Mobile Ads SDK version 7.52.0.
- AdColony SDK version 4.1.1.

#### Version 3.3.8.1.0
- Updating AdColony adapter to version 3.3.8.1.
- Linting the code to follow Google's Objective-C code-style and guard against potential crashes.

Built and tested with
- Google Mobile Ads SDK version 7.51.0
- AdColony SDK version 3.3.8.1

#### Version 3.3.7.3
- Added checks to the credentials before initializing the AdColony SDK.

#### Version 3.3.7.2
- Fixed an issue where the `GADMediationAdapterAdColony` header was not made public.

#### Version 3.3.7.1
- Added open bidding capability to the adapter for interstitial and rewarded ads.

#### Version 3.3.7.0
- Verified compatibility with AdColony SDK 3.3.7.
- Fixed a crash in case of failed to fetch rewarded ad.

#### Version 3.3.6.1
- Updated the adapter to use the new rewarded API.
- Now requires Google Mobile Ads SDK version 7.41.0 or higher.

#### Version 3.3.6.0
- Verified compatibility with AdColony SDK 3.3.6.

#### Version 3.3.5.0
- Verified compatibility with AdColony SDK 3.3.5.
- Added `adapterDidCompletePlayingRewardBasedVideoAd:` callback to the adapter.

#### Version 3.3.4.0
- Verified compatibility with AdColony SDK 3.3.4.

#### Version 3.3.0.0
- Verified compatibility with AdColony SDK 3.3.0.

#### Version 3.2.1.1
- Added `testMode` to extras. Publishers can use this property to mark AdColony
  requests as test requests.

#### Version 3.2.1.0
- Verified compatibility with AdColony SDK 3.2.1.

#### Version 3.2.0.0
- Verified compatibility with AdColony SDK 3.2.0.

#### Version 3.1.1.1
- Removed support for the `armv7s` architecture.
- Fixed an issue that caused the adapter to incorrectly invoke the rewarded
  callback when used with recent versions of the AdColony SDK.

#### Version 3.1.1.0
- Verified compatibility with AdColony SDK 3.1.1.

#### Version 3.1.0.0
- Verified compatibility with AdColony SDK 3.1.0.

#### Version 3.0.6.0
- Changed the version naming system to
  [AdColony SDK version].[adapter patch version].
- Updated the minimum required AdColony SDK to v3.0.6.

#### Earlier Versions
