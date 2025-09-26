//Copyright 2022 Google LLC
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

import Foundation
import GoogleMobileAds
import SampleAdSDK

@objc class SampleCustomEventSwift: NSObject, MediationAdapter {

  fileprivate var bannerAd: SampleCustomEventBannerSwift?

  fileprivate var interstitialAd: SampleCustomEventInterstitialSwift?

  fileprivate var nativeAd: SampleCustomEventNativeAdSwift?

  static func adSDKVersion() -> VersionNumber {
    let versionComponents = String(SampleSDKVersion).components(
      separatedBy: ".")

    if versionComponents.count >= 3 {
      let majorVersion = Int(versionComponents[0]) ?? 0
      let minorVersion = Int(versionComponents[1]) ?? 0
      let patchVersion = Int(versionComponents[2]) ?? 0

      return VersionNumber(
        majorVersion: majorVersion, minorVersion: minorVersion, patchVersion: patchVersion)
    }

    return VersionNumber()
  }

  static func adapterVersion() -> VersionNumber {
    let versionComponents = String(SampleAdSDK.SampleAdSDKVersionNumber).components(
      separatedBy: ".")
    var version = VersionNumber()
    if versionComponents.count == 4 {
      version.majorVersion = Int(versionComponents[0]) ?? 0
      version.minorVersion = Int(versionComponents[1]) ?? 0
      version.patchVersion =
        (Int(versionComponents[2]) ?? 0) * 100 + (Int(versionComponents[3]) ?? 0)
    }
    return version
  }

  static func networkExtrasClass() -> AdNetworkExtras.Type? {
    return nil
  }

  static func setUpWith(
    _ configuration: MediationServerConfiguration,
    completionHandler: @escaping GADMediationAdapterSetUpCompletionBlock
  ) {
    // This is where you you will initialize the SDK that this custom event is built for.
    // Upon finishing the SDK initialization, call the completion handler with success.
    completionHandler(nil)
  }

  required override init() {
    super.init()
  }

  func loadBanner(
    for adConfiguration: MediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    self.bannerAd = SampleCustomEventBannerSwift()
    self.bannerAd?.loadBanner(for: adConfiguration, completionHandler: completionHandler)
  }

  func loadInterstitial(
    for adConfiguration: MediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    self.interstitialAd = SampleCustomEventInterstitialSwift()
    self.interstitialAd?.loadInterstitial(
      for: adConfiguration, completionHandler: completionHandler)
  }

  func loadNativeAd(
    for adConfiguration: MediationNativeAdConfiguration,
    completionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    self.nativeAd = SampleCustomEventNativeAdSwift()
    self.nativeAd?.loadNativeAd(for: adConfiguration, completionHandler: completionHandler)
  }

}
