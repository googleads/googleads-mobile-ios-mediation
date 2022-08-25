# Google Mobile Ads SDK for iOS

The Google Mobile Ads SDK is the latest generation in Google mobile advertising
featuring refined ad formats and streamlined APIs for access to mobile ad
networks and advertising solutions. The SDK enables mobile app developers to
maximize their monetization in native mobile apps.

This repository is broken into two sections:

## Example adapter and custom event project

This repository contains the source code for a sample project demonstrating how
an ad network can plug into AdMob Mediation. There are four main components:

- **Sample SDK** - This is a mock SDK that stands in for a real ad network SDK.
    This project is intended to show developers how to use custom events and
    mediation adapters to adapt other ad networks' SDKs, so here we adapt a
    fake one.
- **Custom Event** - A sample custom event class that will request ads from the
    Sample SDK and pass them on to the Google Mobile Ads SDK.
- **Adapter** - A sample mediation adapter that will also request ads from the
    Sample SDK and pass them on to the Google Mobile Ads SDK.
- **MediationExample** - A simple, one-view application that displays
    ads loaded through the adapter and custom event. It can be used to test the
    functionality of both.

If you're just getting started developing a custom event or adapter, you can
replace the code inside this project's adapter and/or custom event classes
and (as long as you don't change the *names* of those two classes) test your
own implementation. The ad units provided as part of the project are keyed to
the names of the adapter and custom event classes.

### Building the example project

To build the project, follow these steps:

1.  Download or clone the source onto your local machine.
2.  Run 'pod update' in the project's root directory (this will download the
    SDK).
3.  Open the workspace file in Xcode.
4.  Run the project.

## Mediation Adapters

Open source adapters for mediating via the Google Mobile Ads SDK. A list of
these adapters is available on our
[Mediation](https://developers.google.com/admob/ios/mediation#choosing_your_mediation_networks)
page.

# Downloads

For prebuilt versions of these adapters, see our
[mediation developer site](https://developers.google.com/admob/ios/mediate#mediation-networks). 
Select an individual ad network's guide, and look for download links in the
Changelog. The ad network guides also explain how to include adapters via CocoaPods.

# Documentation

Check out our
[developer site](https://developers.google.com/admob/ios) for documentation on
using the SDK, and our
[mediation developer guide](https://developers.google.com/admob/ios/mediation-developer)
for information on how to create an adapter.
You can also join the developer community on
[our forum](https://groups.google.com/forum/#!forum/google-admob-ads-sdk).

# Suggesting improvements

To file bugs, make feature requests, or to suggest other improvements, please
use [github's issue tracker](https://github.com/googleads/googleads-mobile-ios-mediation/issues).

# License

[Apache 2.0 License](http://www.apache.org/licenses/LICENSE-2.0.html)
