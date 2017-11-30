# Tapjoy Mediation Adapter for Google Mobile Ads SDK for iOS

## Prerequisites
- Xcode 6.0 or higher
- iOS Deployment target of 7.0 or higher
- Minimum required Google Mobile Ads SDK 7.10.1
- Minimum required Tapjoy SDK 11.9.1

## Instructions

### Using CocoaPods
- Add the following line to your project's Podfile:
  `pod 'GoogleMobileAdsMediationTapjoy'`.
- Run `pod install`.

### Manual
- Add the Google Mobile Ads SDK. See the
  [quick start guide](https://firebase.google.com/docs/admob/ios/quick-start)
  for detailed instructions on how to integrate the Google Mobile Ads SDK.
- Add or drag the adapter .framework into your Xcode project.
- Drag the Tapjoy framework into your Xcode project. You can find the
  Tapjoy SDK [here](http://dev.tapjoy.com/sdk-integration/ios).
- Enable the Ad network in the Ad Network Mediation UI.
- TapjoyAdapter framework has a `GADMTapjoyExtras` class to provide
  `debugEnabled` parameter. The `debugEnabled` is used to enable Tapjoy logging
  for debugging purposes only. It should not be turned on for production
  release.
- If you want to pass a value for `debugEnabled`to the adapter, you can do
  this through the `GADMTapjoyExtras` object. Here is
  an example of how to enable logging:

  <pre><code>GADRequest *adRequest = [GADRequest request];
  GADMTapjoyExtras *tjExtras = [[GADMTapjoyExtras alloc] init];
  tjExtras.debugEnabled = YES;
  [adRequest registerAdNetworkExtras:tjExtras];</code></pre>

### Unity Integration
For publishers who are using Unity IDE to develop games/apps for iOS platform
must follow the steps below.

- Export an Xcode project from Unity IDE.
- Add or drag the `TapjoyAdapter.framework` into your Xcode project.
- Add the Tapjoy SDK into your Xcode project. You can find the Tapjoy SDK setup
  guide [here](http://dev.tapjoy.com/sdk-integration/ios).
- Import `libz.tbd` library in the Build Phases of your Xcode project.

**Notes:**
- Different Placements must be used to load multiple ad units simultaneously.
  For example: when creating multiple instances of GADInterstitial,
  each instance will need to use a different adUnitID on init. If the same
  adUnitID  is used, only one instance will be able to load/show, the second
  instance will do nothing.
- The Tapjoy SDK does not pass specific reward values for rewarded
  video ads, the adapter defaults to a reward of type "" with value 0. Please
  override the reward value in the AdMob console.
  For more information on setting reward values for AdMob ad units, see the
  Rewarded Interstitial section of this article
  [Help Center Article](https://support.google.com/admob/answer/3052638).

The latest documentation and code samples for the Google Mobile Ads SDK are
available [here](https://firebase.google.com/docs/admob/ios/quick-start).
