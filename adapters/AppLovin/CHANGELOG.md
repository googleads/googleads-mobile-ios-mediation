## AppLovin iOS Mediation Adapter Changelog

#### Version 6.14.6.0
- Verified compatibility with AppLovin SDK 6.14.6.
- Now requires Google Mobile Ads SDK version 7.67.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 7.67.0.
- AppLovin SDK version 6.14.6.

#### Version 6.14.5.0
- Verified compatibility with AppLovin SDK 6.14.5.

Built and tested with:
- Google Mobile Ads SDK version 7.66.0.
- AppLovin SDK version 6.14.5.

#### Version 6.14.4.0
- Verified compatibility with AppLovin SDK 6.14.4.
- Now requires Google Mobile Ads SDK version 7.66.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 7.66.0.
- AppLovin SDK version 6.14.4.

#### Version 6.14.3.0
- Verified compatibility with AppLovin SDK 6.14.3.

Built and tested with:
- Google Mobile Ads SDK version 7.65.0.
- AppLovin SDK version 6.14.3.

#### Version 6.14.2.0
- Verified compatibility with AppLovin SDK 6.14.2.

Built and tested with:
- Google Mobile Ads SDK version 7.65.0.
- AppLovin SDK version 6.14.2.

#### Version 6.13.4.1
- Now requires Google Mobile Ads SDK version 7.65.0 or higher.
- Removed support for 300x250 medium rectangle ads and native ads.

Built and tested with:
- Google Mobile Ads SDK version 7.65.0.
- AppLovin SDK version 6.13.4.

#### Version 6.13.4.0
- Verified compatibility with AppLovin SDK 6.13.4.

Built and tested with:
- Google Mobile Ads SDK version 7.64.0.
- AppLovin SDK version 6.13.4.

#### Version 6.13.1.0
- Verified compatibility with AppLovin SDK 6.13.1.
- Now requires Google Mobile Ads SDK version 7.64.0 or higher.
- Removed 728x90 as a supported format for iPhone devices.

Built and tested with:
- Google Mobile Ads SDK version 7.64.0.
- AppLovin SDK version 6.13.1.

#### Version 6.13.0.0
- Verified compatibility with AppLovin SDK 6.13.0.
- Now requires Google Mobile Ads SDK version 7.61.0 or higher.
- Removed 728x90 as a supported format for iPhone devices.

Built and tested with:
- Google Mobile Ads SDK version 7.61.0.
- AppLovin SDK version 6.13.0.

#### Version 6.12.8.0
- Verified compatibility with AppLovin SDK 6.12.8.

Built and tested with:
- Google Mobile Ads SDK version 7.60.0.
- AppLovin SDK version 6.12.8.

#### Version 6.12.7.0
- Verified compatibility with AppLovin SDK 6.12.7.
- Now requires Google Mobile Ads SDK version 7.60.0 or higher.

Built and tested with:
- Google Mobile Ads SDK version 7.60.0.
- AppLovin SDK version 6.12.7.

#### Version 6.12.6.0
- Verified compatibility with AppLovin SDK 6.12.6.

Built and tested with:
- Google Mobile Ads SDK version 7.59.0.
- AppLovin SDK version 6.12.6.

#### Version 6.12.5.0
- Verified compatibility with AppLovin SDK 6.12.5.
- Updated the minimum required Google Mobile Ads SDK version to 7.59.0.

Built and tested with:
- Google Mobile Ads SDK version 7.59.0.
- AppLovin SDK version 6.12.5.

#### Version 6.12.4.0
- Verified compatibility with AppLovin SDK 6.12.4.

Built and tested with:
- Google Mobile Ads SDK version 7.58.0.
- AppLovin SDK version 6.12.4.

#### Version 6.12.3.0
- Verified compatibility with AppLovin SDK 6.12.3.

Built and tested with:
- Google Mobile Ads SDK version 7.58.0.
- AppLovin SDK version 6.12.3.

#### Version 6.12.2.0
- Verified compatibility with AppLovin SDK 6.12.2.

Built and tested with:
- Google Mobile Ads SDK version 7.58.0.
- AppLovin SDK version 6.12.2.

#### Version 6.12.1.0
- Verified compatibility with AppLovin SDK 6.12.1.

Built and tested with:
- Google Mobile Ads SDK version 7.58.0.
- AppLovin SDK version 6.12.1.

#### Version 6.12.0.0
- Verified compatibility with AppLovin SDK 6.12.0.
- Added standardized adapter error codes and messages.

Built and tested with:
- Google Mobile Ads SDK version 7.58.0.
- AppLovin SDK version 6.12.0.

#### Version 6.11.5.0
- Verified compatibility with AppLovin SDK 6.11.5.
- Removed support for the i386 architecture.

Built and tested with:
- Google Mobile Ads SDK version 7.56.0.
- AppLovin SDK version 6.11.5.

#### Version 6.11.4.0
- Verified compatibility with AppLovin SDK 6.11.4.

Built and tested with:
- Google Mobile Ads SDK version 7.55.1.
- AppLovin SDK version 6.11.4.

#### Version 6.11.3.0
- Verified compatibility with AppLovin SDK 6.11.3.

Built and tested with:
- Google Mobile Ads SDK version 7.55.0.
- AppLovin SDK version 6.11.3.

#### Version 6.11.1.0
- Verified compatibility with AppLovin SDK 6.11.1.
- Fixed an issue that caused native ads to fail to load.

Built and tested with:
- Google Mobile Ads SDK version 7.53.1.
- AppLovin SDK version 6.11.1.

#### Version 6.10.1.0
- Verified compatibility with AppLovin SDK 6.10.1.

Built and tested with:
- Google Mobile Ads SDK version 7.52.0.
- AppLovin SDK version 6.10.1.

#### Version 6.9.5.0
- Verified compatibility with AppLovin SDK 6.9.5.

Built and tested with:
- Google Mobile Ads SDK version 7.50.0.
- AppLovin SDK version 6.9.5.

#### Version 6.9.4.0
- Verified compatibility with AppLovin SDK 6.9.4.
- Fix RTB rewarded videos not being able to show even if loaded.
- Fix adapter disallowing future ad loads of a previously-loaded zone that has been timed out by AdMob or not shown by the publisher.
- Fix native ads not working when passing SDK key from server.
- Validate SDK key from server, then fallback to Info.plist if server’s SDK key is invalid (e.g. in case of placeholder values being sent down).
- Validate custom zone IDs from server (e.g. in case of placeholder values being sent down).
- Remove placements API.

Built and tested with:
- Google Mobile Ads SDK version 7.50.0.
- AppLovin SDK version 6.9.4.

#### Version 6.8.0.0
- Verified compatibility with AppLovin SDK 6.8.0.
- Removed support for Native App Install ad requests. Apps must use the Unified Native Ads API to request native ads.
- Now requires Google Mobile Ads SDK version 7.46.0 or higher.

#### Version 6.6.1.0
- Verified compatibility with AppLovin SDK 6.6.1.
- Fixed a crash caused by calling a completionHandler on a nil object.
- Updated the adapter to handle multiple interstitial requests.
- Added support for flexible banner ad sizes.

#### Version 6.3.0.0
- Verified compatibility with AppLovin SDK 6.3.0.
- Updated the adapter to use the new rewarded API.
- Now requires Google Mobile Ads SDK version 7.41.0 or higher.

#### Version 6.2.0.0
- Verified compatibility with AppLovin SDK 6.2.0.

#### Version 6.1.4.0
- Verified compatibility with AppLovin SDK 6.1.4.

#### Version 5.1.2.0
- Verified compatibility with AppLovin SDK 5.1.2.

#### Version 5.1.1.0
- Verified compatibility with AppLovin SDK 5.1.1.

#### Version 5.1.0.0
- Verified compatibility with AppLovin SDK 5.1.0.

#### Version 5.0.2.0
- Verified compatibility with AppLovin SDK 5.0.2.

#### Version 5.0.1.1
- Add support for native ads.
- Set AdMob as mediation provider on the AppLovin SDK.

#### Version 5.0.1.0
- Verified compatibility with Applovin SDK 5.0.1.

#### Version 4.8.4.0
- Verified compatibility with Applovin SDK 4.8.4.

#### Version 4.8.3.0
- Add support for zones and smart banners.

#### Version 4.7.0.0
- Verified compatibility with AppLovin SDK 4.7.0.

#### Version 4.6.1.0
- Verified compatibility with AppLovin SDK 4.6.1.

#### Version 4.6.0.0
- Verified compatibility with AppLovin SDK 4.6.0.

#### Version 4.5.1.0
- Verified compatibility with AppLovin SDK 4.5.1.

#### Version 4.4.1.1
- Added support for banner ads.

#### Version 4.4.1.0
- Verified compatibility with AppLovin SDK 4.4.1.

#### Version 4.3.1.0
- Added support for interstitial ads.

#### Earlier versions
- Added support for rewarded video ads.
