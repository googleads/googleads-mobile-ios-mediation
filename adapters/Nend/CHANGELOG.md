## nend iOS Mediation Adapter Changelog

#### Version 6.0.3.0
- Verified compatibility with nend SDK 6.0.3.
- Updated the minimum required Google Mobile Ads SDK version to 7.65.0.

Built and tested with
- Google Mobile Ads SDK version 7.65.0.
- Nend SDK version 6.0.3.

#### Version 6.0.2.0
- Verified compatibility with nend SDK 6.0.2.
- Updated the minimum required Google Mobile Ads SDK version to 7.64.0.

Built and tested with
- Google Mobile Ads SDK version 7.64.0.
- Nend SDK version 6.0.2.

#### Version 6.0.1.0
- Verified compatibility with nend SDK 6.0.1.

Built and tested with
- Google Mobile Ads SDK version 7.62.0.
- Nend SDK version 6.0.1.

#### Version 6.0.0.0
- Verified compatibility with nend SDK 6.0.0.
- Removed the `GADNendRewardedNetworkExtras` class. If you want to pass network
extras to the nend iOS adapter, please use the `GADMAdapterNendExtras` class.
- Renamed the following enums from the `GADMAdapterNendExtras` class:
  - `GADMNendInterstitialType` to `GADMAdapterNendInterstitialType`.
  - `GADMNendNativeType` to `GADMAdapterNendNativeType`.
- Updated the minimum required Google Mobile Ads SDK version to 7.62.0.

Built and tested with
- Google Mobile Ads SDK version 7.62.0.
- Nend SDK version 6.0.0.

#### Version 5.4.1.0
- Verified compatibility with nend SDK 5.4.1.
- Added support for native ads.
- Removed support for the i386 architecture.

Built and tested with
- Google Mobile Ads SDK version 7.58.0.
- Nend SDK version 5.4.1.

#### Version 5.3.1.0
- Verified compatibility with nend SDK 5.3.1.

Build and tested with
- Google Mobile Ads SDK version 7.52.0.
- Nend SDK version 5.3.1.

#### Version 5.3.0.0
- Verified compatibility with nend SDK 5.3.0.

Built and tested with:
- Google Mobile Ads SDK version 7.50.0.
- Nend SDK version 5.3.0.

#### Version 5.1.1.0
- Updated the adapter to use the new rewarded API.
- Now requires Google Mobile Ads SDK version 7.42.2 or higher.
- Verified compatibility with nend SDK 5.1.1.
- Changed condition that checking banner size.
  Appropriate size for SmartBanner
  - kGADAdSizeSmartBannerPortrait
    - iPhone: 320×50
    - iPad: 728×90 or 320×50
  - kGADAdSizeSmartBannerLandscape
    - iPad: 728×90 or 320×50
- Added support for flexible banner ad sizes.

#### Version 5.1.0.0
- Verified compatibility with nend SDK 5.1.0.

#### Version 5.0.3.0
- Verified compatibility with nend SDK 5.0.3.

#### Version 5.0.2.0
- Verified compatibility with nend SDK 5.0.2.

#### Version 5.0.1.0
- Verified compatibility with nend SDK 5.0.1.

#### Version 5.0.0.0
- Verified compatibility with nend SDK 5.0.0.

#### Version 4.0.6.0
- Verified compatibility with nend SDK 4.0.6.
- Remove to set userFeature property.

#### Version 4.0.5.0
- Verified compatibility with nend SDK 4.0.5.

#### Version 4.0.4.0
- Verified compatibility with nend SDK 4.0.4.

#### Version 4.0.3.0
- Verified compatibility with nend SDK 4.0.3.

#### Version 4.0.2.0
- First release in Google Mobile Ads mediation open source project.
- Added support for reward-based video ads.

#### Previous Versions
- Supports banner and interstitial ads.
