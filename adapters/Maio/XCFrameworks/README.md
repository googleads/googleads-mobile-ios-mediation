# XCFrameworks

XCFramework includes frameworks with different ARCH.
To resolve the Framework Path, the Xcode Project needs to be aware of the XCFramework.

Cannot search recursively using `FRAMEWORK_SEARCH_PATHS`.
This is because the build system chooses a framework with the wrong architecture.

Below is a list of dependent frameworks.
Drop all necessary frameworks in this folder.

## Dependencies

- [GoogleMobileAds](https://developers.google.com/admob/ios/download)
    - GoogleMobileAds.xcframework
    - GoogleAppMeasurement.framework
    - GoogleUtilities.xcframework
    - nanopb.xcframework
- [MaioOB](https://github.com/imobile-maio/maio-iOS-SDK/releases/tag/ob-alpha)
    - MaioOB.xcframework
- [Maio](https://github.com/imobile-maio/maio-iOS-SDK/releases/tag/v1.5.6)
    - Maio.framework

