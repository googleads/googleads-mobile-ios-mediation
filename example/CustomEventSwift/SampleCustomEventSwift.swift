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

@objc class SampleCustomEventSwift: NSObject, GADMediationAdapter {

  fileprivate var bannerAd: SampleCustomEventBannerSwift?

  fileprivate var interstitialAd: SampleCustomEventInterstitialSwift?

  fileprivate var nativeAd: SampleCustomEventNativeAdSwift?

  static func adapterVersion() -> GADVersionNumber {
    return GADVersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
  }

  static func adSDKVersion() -> GADVersionNumber {
    let majorVersion = Int(
      SampleAdSDK.SampleAdSDKVersionNumber.rounded(FloatingPointRoundingRule.down))
    let minorVersion = Int(
      SampleAdSDK.SampleAdSDKVersionNumber.truncatingRemainder(dividingBy: 1) * 100)
    return GADVersionNumber(majorVersion: majorVersion, minorVersion: minorVersion, patchVersion: 0)
  }

  static func networkExtrasClass() -> GADAdNetworkExtras.Type? {
    return nil
  }

  static func setUpWith(
    _ configuration: GADMediationServerConfiguration,
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
    for adConfiguration: GADMediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    self.bannerAd = SampleCustomEventBannerSwift()
    self.bannerAd?.loadBanner(for: adConfiguration, completionHandler: completionHandler)
  }

  func loadInterstitial(
    for adConfiguration: GADMediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    self.interstitialAd = SampleCustomEventInterstitialSwift()
    self.interstitialAd?.loadInterstitial(
      for: adConfiguration, completionHandler: completionHandler)
  }

  func loadNativeAd(
    for adConfiguration: GADMediationNativeAdConfiguration,
    completionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    self.nativeAd = SampleCustomEventNativeAdSwift()
    self.nativeAd?.loadNativeAd(for: adConfiguration, completionHandler: completionHandler)
  }

}
