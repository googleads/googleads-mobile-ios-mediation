# MoPub Ads Mediation Adapter for Google Mobile Ads SDK for iOS

## Prerequisites
- Xcode 6.0 or higher
- iOS Deployment target of 7.0 or higher
- Minimum required Google Mobile Ads SDK 7.14.0
- Minimum required MoPub SDK 4.10.0

## Instructions

### Using CocoaPods
- Add the following line to your project's Podfile:
  `pod 'GoogleMobileAdsMediationMoPub'`.
- Run `pod update`.

### Manual
- Add the Google Mobile Ads SDK. See the
  [quick start guide](https://firebase.google.com/docs/admob/ios/quick-start)
  for detailed instructions on how to integrate the Google Mobile Ads SDK.
- Add or drag the MoPubAdapter.framework into your Xcode project.
- Add the MoPub SDK into your Xcode project. You can find the MoPub SDK at the
  [MoPub Github repo](https://github.com/mopub/mopub-ios-sdk).
- Enable the Ad network in the Ad Network Mediation UI. The latest
  documentation and code samples for the Google Mobile Ads SDK are
  available at the
  [AdMob Developer Docs](https://firebase.google.com/docs/admob/ios/quick-start).

You can optionally register a `GADMoPubNetworkExtras` class with the ad request
to set the desired size for the MoPub privacy icon in points. Values can range
from 10 to 30 inclusive. The default size for the privacy icon is 20.

<pre><code>GADRequest *request = [GADRequest request];
GADMoPubNetworkExtras *extras = [[GADMoPubNetworkExtras alloc] init];
extras.privacyIconSize = 15;
[request registerAdNetworkExtras:extras];</code></pre>

## Native Ads Notes

### Ad Rendering
- MoPub has 5 assets including icon, title, description, main image and
  CTA(call to action) text.
- Currently MoPub adapter is built to return app install ads via
  Google mediation. If you are requesting content ads only, there will be
  no ads returned.

### Impression and Click Tracking
- MoPub and Google Mobile Ads SDKs track impressions in their own
  way, so there may be discrepancies. Clicks are detected by the
  Google Mobile Ads SDK and are forwarded to MoPub SDK, so click reporting will
  be in sync.

The latest documentation and code samples for the Google Mobile Ads SDK are
available at the
[AdMob Developer Docs](https://firebase.google.com/docs/admob/ios/quick-start).
