# Steps to generate universal static library and framework

**Note:** These build scripts are intended only for publishers who want to
modify and rebuild the Yahoo adapter framework. If you just want to use the
Yahoo adapter, simply add `pod 'GoogleMobileAdsMediationYahoo'` to
your Podfile and run `pod install --repo-update`.

## Prerequisites
- Xcode 14.0 or higher
- Deployment target of 11.0 or higher
- Google Mobile Ads SDK
- Yahoo Mobile SDK
- Yahoo Adapter Source Code

## Setup Instructions
- Drop GoogleMobileAds framework to
  Project Directory->Drop_Framework_And_Headers.
- Drop all frameworks found inside [Yahoo Mobile SDK](https://sdk.yahooinc.com/yahoo-ads/integration.html) in to
  Project Directory->Drop_Framework_And_Headers.

## Build Instructions
- To build a static library, select target scheme (Adapter). Edit scheme to
  Release OR Build.
- Clean and Run/Archive.
- To build a framework, select target scheme (Framework). Edit scheme to
  Release OR Build.
- Clean and Run/Archive.

**Note:** New adapter file and/or framework will be generated in your
Project Directory->Library folder.
