## AppLovin iOS Mediation Adapter Changelog

#### Next Version
* Fix RTB rewarded videos not being able to show even if loaded.
* Fix adapter disallowing future ad loads of a previously-loaded zone that has been timed out by AdMob or not shown by the publisher.
* Fix native ads not working when passing SDK key from server.
* Validate SDK key from server, then fallback to Info.plist if server’s SDK key is invalid (e.g. in case of placeholder values being sent down).
* Validate custom zone IDs from server (e.g. in case of placeholder values being sent down).
* Remove placements API.

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
