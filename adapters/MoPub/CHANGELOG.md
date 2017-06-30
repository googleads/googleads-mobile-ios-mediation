# MoPub Ads Mediation Adapter for Google Mobile Ads SDK for iOS

## Version 4.15.0.0
- Verified compatibility with MoPub SDK 4.15.0.

## Version 4.14.0.0
- Verified compatibility with MoPub SDK 4.14.0.
- Removed the support for `armv7s` architecture.
- Fixed a bug where Native Ads failed to load MoPub privacy icon when MoPub SDK
  is linked using CocoaPods and having `use_frameworks!` in the Podfile for
  Swift projects.

## Version 4.13.1.1
- Fixed a bug where native ads failed to detect clicks when loaded from the same
  `GADAdLoader` instance.

## Version 4.13.1.0
- Verified compatibility with MoPub SDK 4.13.1.

## Version 4.13.0.0
- Verified compatibility with MoPub SDK 4.13.0.

## Version 4.12.0.0
- Verified compatibility with MoPub SDK 4.12.0.
- Added support for accessing MoPub native demand on Google Mobile Ads
  mediation.
- Added support to configure the privacy icon size for MoPub's native ads.
- Updated banner and interstitial ad formats per Google Mobile Ads latest
  mediation APIs.
- Adapter is now distributed as a framework.

## Previous Versions
- Support for MoPub banner and interstitial ads.
