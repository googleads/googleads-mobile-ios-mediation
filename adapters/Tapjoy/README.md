Steps to generate universal static library and framework for iOS Devices and
Simulators with supported architectures.

Prerequisites:
- Xcode 6.0 or higher
- Deployment target of 6.0 or higher
- Google Mobile Ads SDK
- Tapjoy SDK
- Tapjoy Adapter Source Code

Setup Instructions:
- Drop GoogleMobileAds framework to
  Project Directory->Drop_Framework_And_Headers.
- Drop Tapjoy framework to Project Directory->Drop_Framework_And_Headers.

Build Instructions:
- To build a static library, select target scheme (FatAdapter). Edit scheme to
  Release OR Build.
- Clean and Run/Archive.
- To build a framework, select target scheme (Framework). Edit scheme to
  Release OR Build.
- Clean and Run/Archive.

Note: New adapter file and/or framework will be generated in your
      Project Directory->Library folder.