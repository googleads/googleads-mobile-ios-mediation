# AdColony Mediation Adapter for Google Mobile Ads SDK for iOS

## Prerequisites
- Xcode 7.0 or higher
- Deployment target of 7.0 or higher
- Google Mobile Ads SDK 7.10.1 or higher
- AdColony SDK 3.0.6 or higher

## Instructions
- Add the Google Mobile Ads SDK. See the
  [quick start guide](https://firebase.google.com/docs/admob/ios/quick-start)
  for detailed instructions on how to integrate the Google Mobile Ads SDK.
- Add or drag the adapter .framework into your Xcode project.
- Add the AdColony SDK into your Xcode project. You can find the AdColony SDK setup
  guide [here](https://github.com/AdColony/AdColony-iOS-SDK-3/wiki).
- Add AdColony to the mediation configuration for your AdMob ad unit.
- Please see the [set up guide](https://support.google.com/admob/answer/3124703)
  for detailed instructions on how to set up mediation.

The latest documentation and code samples for the Google Mobile Ads SDK are available [here](https://firebase.google.com/docs/admob/ios/quick-start).

### Optimizations
To ensure AdColony video ads are available as often as possible, you can initialize the AdColony SDK directly early in the application lifecycle and outside of the Google Mobile Ads SDK. To do so, insert the following code into the application:didFinishLaunchingWithOptions: method:

<pre><code>[AdColony configureWithAppID:@"your_adcolony_app_id"
                     zoneIDs:@[@"Zone_ID_1", @"Zone_ID_2"]
                     options:options
                  completion:nil];</code></pre>

### Videos-for-Virtual-Currency
You can optionally register a `GADMAdapterAdColonyExtras` class in the ad request to optionally configure userId and rewarded dialogs:

<pre><code>GADRequest *request = [GADRequest request];
GADMAdapterAdColonyExtras *extras = [[GADMAdapterAdColonyExtras alloc] init];
extras.userId = @"your_user_id";
extras.showPrePopup = YES;
extras.showPostPopup = YES;
[request registerAdNetworkExtras:extras];</code></pre>
