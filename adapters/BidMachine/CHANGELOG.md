## BidMachine iOS Mediation Adapter Changelog

#### Version 3.5.1.2 (In progress)
- Updated the minimum iOS version to 13

#### Version 3.5.1.1 (In progress)
- BidMachineAdDelegate conformance sections were modified to align with BidMachine SDK callback behavior.
- Added support for forwarding the tagForUnderAgeOfConsent Google Mobile Ads SDK parameter to the BidMachine SDK.

#### [Version 3.5.1.0](https://dl.google.com/googleadmobadssdk/mediation/ios/bidmachine/BidMachineAdapter-3.5.1.0.zip)
- Verified compatibility with BidMachine SDK version 3.5.1.

Built and tested with:
- Google Mobile Ads SDK version 12.14.0.
- BidMachine SDK version 3.5.1.

#### [Version 3.5.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/bidmachine/BidMachineAdapter-3.5.0.0.zip)
- Verified compatibility with BidMachine SDK version 3.5.0.

Built and tested with:
- Google Mobile Ads SDK version 12.12.0.
- BidMachine SDK version 3.5.0.

#### [Version 3.4.0.2](https://dl.google.com/googleadmobadssdk/mediation/ios/bidmachine/BidMachineAdapter-3.4.0.2.zip)
- Added waterfall support for banner, interstitial, rewarded and native ad formats.
- Removed the `isTestMode` static property from `BidMachineAdapterExtras`.
- Added banner ad size validation for waterfall banner ads.

Built and tested with:
- Google Mobile Ads SDK version 12.12.0.
- BidMachine SDK version 3.4.0.

#### [Version 3.4.0.1](https://dl.google.com/googleadmobadssdk/mediation/ios/bidmachine/BidMachineAdapter-3.4.0.1.zip)
- Test mode is now available in Objective-C through the `GADMediationAdapterBidMachineExtras.isTestMode` property.

Built and tested with:
- Google Mobile Ads SDK version 12.0.0.
- BidMachine SDK version 3.4.0.

#### [Version 3.4.0.0](https://dl.google.com/googleadmobadssdk/mediation/ios/bidmachine/BidMachineAdapter-3.4.0.0.zip)
- Initial release.
- Added bidding support for banner, interstitial, rewarded and native ad formats.
- Verified compatibility with BidMachine SDK version 3.4.0.

Built and tested with:
- Google Mobile Ads SDK version 12.8.0.
- BidMachine SDK version 3.4.0.
