## LINE iOS Mediation Adapter Changelog

#### Next version
- Implemented FADCustomLayoutEventListener protocol in banner ad loader and removed FADAdViewEventListener protocol implementation.
- Implemented FADVideoRewardEventListener protocol in rewarded ad loader and removed FADAdViewEventListener protocol implementation.

#### [Version 2.7.20231115.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.7.20231115.0.zip)
- Verified compatibility with FiveAd SDK version 2.7.20231115.
- Included `GADMediationAdapterLineExtras` header in the modulemap.

Built and tested with:
- Google Mobile Ads SDK version 10.14.0.
- FiveAd SDK version 2.7.20231115.

#### [Version 2.6.20230609.1](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.6.20230609.1.zip)
- Added `GADMediationAdapterLineAudioState` to manage the initial audio state of the banner, interstitial, and rewarded ad when it is first displayed.

Built and tested with:
- Google Mobile Ads SDK version 10.14.0.
- FiveAd SDK version 2.6.20230609.

#### [Version 2.6.20230609.0](https://dl.google.com/googleadmobadssdk/mediation/ios/line/LineAdapter-2.6.20230609.0.zip)
- Initial release!
- Added waterfall support for banner, interstitial, rewarded, and native ad formats.
- Verified compatibility with FiveAd SDK version 2.6.20230609.

Built and tested with:
- Google Mobile Ads SDK version 10.9.0.
- FiveAd SDK version 2.6.20230609.