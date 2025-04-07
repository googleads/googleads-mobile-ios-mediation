# Steps to generate universal static library and framework

**Note:** These build scripts are intended only for publishers who want to
modify and rebuild the Moloco adapter framework.

## Prerequisites
- Xcode 15.2 or higher
- Deployment target of 12.0 or higher
- Google Mobile Ads SDK
- Moloco Ads SDK

## Setup Instructions
- Drop GoogleMobileAds framework to
Project Directory->Drop_Framework_And_Headers.
- Drop the Moloco Ads SDK framework to
Project Directory->Drop_Framework_And_Headers.

## Build Instructions
- To build a framework, select target scheme (Framework). Edit scheme to
Release OR Build.
- Clean and Run/Archive.

**Note:** New adapter libraries and/or frameworks will be generated in your
Project Directory->Library folder.
