Chartboost Ads Mediation Adapter for Google Mobile Ads SDK for iOS

Prerequisites:
- Xcode 5.1 or higher
- Deployment target of 6.0 or higher
- Google Mobile Ads SDK
- Chartboost SDK

Instructions:
- Add the AdMob SDK
- You can find the integration guide at
 https://developers.google.com/admob/ios/quick-start
- Add or drag the adapter .a into your Xcode project
- Drag the Chartboost Ads Frameowrk into your Xcode project
- You can find the SDK at
 https://answers.chartboost.com/hc/en-us/articles/201219435-iOS-SDK-Download
- Enable the Ad network in the Ad Network Mediation UI
- The latest documentation and code samples for the Google Mobile Ads SDK are
 available at https://developers.google.com/admob/ios/quick-start
- Adapter has a GADMChartboostExtras class to provide framework" and
 "frameworkVersion" parameters. The "framework" and "frameworkVersion" are used
 if you are using any custom framework in your application(for example, Unity).
- If you want to pass a custom CBFramework and frameworkVersion to the adapter,
 you can do this through the GADMChartboostExtras object. Here is an example of
 how to customize the Chartboost location in an ad request:

GADRequest *adRequest = [GADRequest request];
GADMChartboostExtras *cbExtras = [[GADMChartboostExtras alloc] init];
cbExtras.framework = CBFrameworkUnity;
cbExtras.frameworkVersion = @"4.2.0";
[request registerAdNetworkExtras:cbExtras];

The latest documentation and code samples for the Google Mobile Ads SDK are
available at:
https://developers.google.com/admob/ios/quick-start
