# Unity Ads Mediation Adapter for Google Mobile Ads SDK for iOS

## Prerequisites
- Xcode 6.0 or higher
- Deployment target of 6.0 or higher
- Google Mobile Ads SDK 7.10.1 or higher
- Unity Ads SDK 2.0.7 or higher

## Instructions

### Using CocoaPods
- Add the following line to your project's Podfile:
 `pod 'GoogleMobileAdsMediationUnity'`.
- Run `pod install`.

**Note:** This pod will automatically download and resolve the Unity Ads SDK
 framework dependency in your project.

### Manual
- Add the Google Mobile Ads SDK. See the
  [quick start guide](https://firebase.google.com/docs/admob/ios/quick-start)
  for detailed instructions on how to integrate the Google Mobile Ads SDK.
- Add or drag the adapter .framework into your Xcode project.
- Drag the Unity Ads framework into your Xcode project. You can find the
  Unity Ads SDK [here](https://github.com/Unity-Technologies/unity-ads-ios).

## Caveats
- The Unity Ads SDK does not provide specific reward values for its rewarded
  video ads, so the adapter defaults to a reward of type "" with value 1. Please
  override the reward value in the AdMob console.
  For more information on setting reward values for AdMob ad units, see this
  [Help Center Article](https://support.google.com/admob/answer/3052638).

The latest documentation and code samples for the Google Mobile Ads SDK are
available [here](https://firebase.google.com/docs/admob/ios/quick-start).
