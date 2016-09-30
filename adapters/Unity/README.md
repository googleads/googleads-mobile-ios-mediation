Unity Ads Mediation Adapter for Google Mobile Ads SDK for iOS

Prerequisites:
- Xcode 5.1 or higher
- Deployment target of 6.0 or higher
- Google Mobile Ads SDK 7.7.0 or higher
- Unity Ads SDK

Instructions:
- Add the AdMob SDK. Find the integration guide in the following link:
https://developers.google.com/admob/ios/quick-start
- Add or drag the adapter .a into your Xcode project.
- Drag the Unity Ads Framework & Unity Ads bundle into your Xcode project.
- You can find the SDK at https://github.com/Applifier/unity-ads-sdk

Caveats:
- The Unity Ads SDK does not provide a reward value when rewarded video completed,
  so the adapter defaults to a reward of type "" with value 1. Please override the
  reward value in the AdMob console.

The latest documentation and code samples for the Google Mobile Ads SDK are
available at https://developers.google.com/admob/ios/quick-start.
