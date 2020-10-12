## Facebook iOS Mediation Adapter Changelog

#### Version 6.0.0.0
- Verified compatibility with FAN SDK 6.0.0.
- Now requires Google Mobile Ads SDK version 7.66.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.66.0.
- FAN SDK version 6.0.0.

#### Version 5.10.1.0
- Verified compatibility with FAN SDK 5.10.1.
- Now requires Google Mobile Ads SDK version 7.62.0 or higher.
- Fixed a bug where adapterWillLeaveApplication: was not being called for interstitial ads for non-open bidding.

Built and tested with
- Google Mobile Ads SDK version 7.62.0.
- FAN SDK version 5.10.1.

#### Version 5.10.0.0
- Verified compatibility with FAN SDK 5.10.0.
- Now requires Google Mobile Ads SDK version 7.61.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.61.0.
- FAN SDK version 5.10.0.

#### Version 5.9.0.1
- Added support for rewarded interstitial ads.
- Now requires Google Mobile Ads SDK version 7.60.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.60.0.
- FAN SDK version 5.9.0.

#### Version 5.9.0.0
- Verified compatibility with FAN SDK 5.9.0.
- Now requires Google Mobile Ads SDK version 7.59.0 or higher.

Built and tested with
- Google Mobile Ads SDK version 7.59.0.
- FAN SDK version 5.9.0.

#### Version 5.8.0.2
- Adapter now calls adapterWillPresentScreen: immediately followed by adapterDidDismissScreen: if interstitial ads fail to present.
- Fixed a bug where some banner requests failed with reason "Display format doesn't match".

Built and tested with
- Google Mobile Ads SDK version 7.58.0.
- FAN SDK version 5.8.0.

#### Version 5.8.0.1
- Fix bug introduced in 5.6.1.0 where `tagForChildDirectedTreatment` was incorrectly mapped to Facebook's `setMixedAudience` method.

Built and tested with
- Google Mobile Ads SDK version 7.57.0.
- FAN SDK version 5.8.0

#### Version 5.8.0.0 (Deprecated, use 5.8.0.1 or newer)
- Verified compatibility with FAN SDK 5.8.0.
- Adapter now returns a non-zero `mediaContent` aspect ratio regardless if the media view is rendered or not.

Built and tested with
- Google Mobile Ads SDK version 7.57.0.
- FAN SDK version 5.8.0.

#### Version 5.7.1.2 (Deprecated, use 5.8.0.1 or newer)
- Added standardized adapter error codes and messages.

Built and tested with
- Google Mobile Ads SDK version 7.56.0.
- FAN SDK version 5.7.1.

#### Version 5.7.1.1 (Deprecated, use 5.8.0.1 or newer)
- Removed support for the i386 architecture.

Built and tested with
- Google Mobile Ads SDK version 7.56.0.
- FAN SDK version 5.7.1.

#### Version 5.7.1.0 (Deprecated, use 5.8.0.1 or newer)
- Verified compatibility with FAN SDK 5.7.1.
- Added support for Facebook native banner ads when using open bidding.
- Native ads now return a `GADNativeAdImage` for the icon asset.

Built and tested with
- Google Mobile Ads SDK version 7.55.1.
- FAN SDK version 5.7.1.

#### Version 5.7.0.0 (Deprecated, use 5.8.0.1 or newer)
- Verified compatibility with FAN SDK 5.7.0.

Built and tested with
- Google Mobile Ads SDK version 7.55.1.
- FAN SDK version 5.7.0.

#### Version 5.6.1.0 (Deprecated, use 5.8.0.1 or newer)
- Verified compatibility with FAN SDK 5.6.1.

Built and tested with
- Google Mobile Ads SDK version 7.53.1.
- FAN SDK version 5.6.1.

#### Version 5.6.0.0
- Verified compatibility with FAN SDK 5.6.0.

Built and tested with
- Google Mobile Ads SDK version 7.51.0.
- FAN SDK version 5.6.0.

#### Version 5.5.1.1
- Adapter now returns a non-zero `mediaContent` aspect ratio once the media view is rendered in a view.
- Added additional logging for open bidding.

#### Version 5.5.1.0
- Verified compatibility with FAN SDK 5.5.1.

#### Version 5.5.0.0
- Verified compatibility with FAN SDK 5.5.0.
- Now requires Google Mobile Ads SDK version 7.46.0 or higher.
- Added support for Facebook's native banner ads.
- Added code to properly handle the completion handlers after called.
- Modified the code to follow Google's Objective-C code-style.

#### Version 5.4.0.0
- Verified compatibility with FAN SDK 5.4.0.

#### Version 5.3.2.0
- Verified compatibility with FAN SDK 5.3.2.

#### Version 5.3.0.0
- Changed the mediation service string include adapter version.
- Fixed a bug for native ads where AdOptions wasn't initialized correctly.

#### Version 5.2.0.2
- Added open bidding capability to the adapter for all ad formats.

#### Version 5.2.0.1
- Updated the adapter to use the new rewarded API.
- Now requires Google Mobile Ads SDK version 7.41.0 or higher.

#### Version 5.2.0.0
- Verified compatibility with FAN SDK 5.2.0.
- Replaced FBAdChoicesView with FBAdOptionsView.

#### Version 5.1.1.1
- Added support to populate advertiser name asset for Unified Native Ads.

#### Version 5.1.1.0
- Verified compatibility with FAN SDK 5.1.1.

#### Version 5.1.0.0
- Verified compatibility with FAN SDK 5.1.0.

#### Version 5.0.1.0
- Verified compatibility with FAN SDK 5.0.1.

#### Version 5.0.0.0
- Verified compatibility with FAN SDK 5.0.0.

#### Version 4.99.3.0
- Verified compatibility with FAN SDK 4.99.3.

#### Version 4.99.2.0
- Verified compatibility with FAN SDK 4.99.2.

#### Version 4.99.1.0
- Verified compatibility with FAN SDK 4.99.1.

#### Version 4.28.1.2
- Added `adapterDidCompletePlayingRewardBasedVideoAd:` callback to the adapter.

#### Version 4.28.1.1
- Set mediation service for Facebook adapter.

#### Version 4.28.1.0
- Verified compatibility with FAN SDK 4.28.1.
- Updated rewarded video delegate method.

#### Version 4.28.0.0
- Verified compatibility with FAN SDK 4.28.0.
- Added support for Google Unified Native Ads.

#### Version 4.27.2.0
- Verified compatibility with FAN SDK 4.27.2.

#### Version 4.27.1.0
- Verified compatibility with FAN SDK 4.27.1.

#### Version 4.27.0.0
- Verified compatibility with FAN SDK 4.27.0.

#### Version 4.26.1.0
- Verified compatibility with FAN SDK 4.26.1.

#### Version 4.26.0.0
- Added support for rewarded video ads.
- Added support for native video ads.
- Verified compatibility with FAN SDK 4.26.0.

#### Version 4.25.0.0
- Updated the adapter's view tracking for native ads to register individual
  asset views with the Facebook SDK rather than the entire ad view. This means
  that background (or "whitespace") clicks on the native ad will no longer
  result in clickthroughs.
- Verified compatibility with FAN SDK v4.25.0.

#### Version 4.24.0.0
- Verified compatibility with FAN SDK 4.24.0.

#### Version 4.23.0.1
- Added support for the `backgroundShown` property on Facebook's AdChoices view
  via network extras.
- Updated the default AdChoices icon behaviour. The adapter lets Facebook set
  the default behaviour if no extras are provided.

#### Version 4.23.0.0
- Verified compatibility with FAN SDK 4.23.0.

#### Version 4.22.1.0
- Verified compatibility with FAN SDK 4.22.1.
- Removed the support for `armv7s` architecture.

#### Version 4.22.0.0
- Verified compatibility with FAN SDK 4.22.0.

#### Version 4.21.0.0
- Verified compatibility with FAN SDK 4.21.0.

#### Version 4.20.2.0
- Verified compatibility with FAN SDK 4.20.2.

#### Version 4.20.1.0
- Verified compatibility with FAN SDK 4.20.1.

#### Version 4.20.0.0
- Verified compatibility with FAN SDK 4.20.0.

#### Version 4.19.0.0
- Verified compatibility with FAN SDK 4.19.0.

#### Version 4.18.0.0
- Verified compatibility with FAN SDK 4.18.0.
- Fixed a bug for native ads where AdChoices icon was rendering out of bounds.

#### Version 4.17.0.0
- Changed the version naming system to
  [FAN SDK version].[adapter patch version].
- Updated the minimum required Google Mobile Ads SDK to v7.12.0.
- Added support for native ads.

#### Version 1.4.0
- Requires Google Mobile Ads SDK 7.8.0 or higher.
- Requires FAN SDK 4.13.1 or higher.
- Adapter now uses [kFBAdSizeInterstitial] instead of [kFBAdSizeInterstital].
- Enabled bitcode.

#### Version 1.2.1
- Fixed a bug where interstitial presented and interstitial leaving application
  callbacks were not properly invoked.

#### Version 1.2.0
- Sends callbacks when an ad is presented and dismissed.

#### Version 1.1.0
- Added support for full width x 250 format when request is
  for `kGADAdSizeMediumRectangle`.

#### Version 1.0.1
- Added support for `kGADAdSizeSmartBanner`.

#### Version 1.0.0
- Initial release.
