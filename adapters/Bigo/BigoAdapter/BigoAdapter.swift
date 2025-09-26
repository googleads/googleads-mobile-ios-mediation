// Copyright 2025 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import BigoADS
import GoogleMobileAds

@objc(GADMediationAdapterBigo)
final class BigoAdapter: NSObject, RTBAdapter {

  private static let adapterVersionString = "4.9.3.0"

  /// The app open ad loader.
  private var appOpenAdLoader: AppOpenAdLoader?

  /// The banner ad loader.
  private var bannerAdLoader: BannerAdLoader?

  /// The interstitial ad loader.
  private var interstitialAdLoader: InterstitialAdLoader?

  /// The rewarded ad loader.
  private var rewardedAdLoader: RewardedAdLoader?

  /// The native ad loader.
  private var nativeAdLoader: NativeAdLoader?

  @objc static func setUp(
    with configuration: MediationServerConfiguration,
    completionHandler: @escaping GADMediationAdapterSetUpCompletionBlock
  ) {
    Util.log("Start setting up BigoAdapter")

    if let coppa = MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment {
      // For Bigo, a value of "YES" indicates that the user is not a child
      // under 13 years old, and a value of "NO" indicates that the user is a
      // child under 13 years old.
      let isChildUser = !coppa.boolValue
      Util.log("Setting BigoConsentOptionsCOPPA to \(isChildUser)")
      BigoAdSdk.setUserConsentWithOption(BigoConsentOptionsCOPPA, consent: isChildUser)
    }

    if BigoAdSdk.sharedInstance().isInitialized() {
      Util.log("BigoAdSdk is already initialized")
      completionHandler(nil)
      return
    }

    do {
      let applicationId = try Util.applicationId(from: configuration)
      BigoClientFactory.createClient().initialize(
        with: applicationId, testMode: BigoAdapterExtras.testMode
      ) {
        Util.log("Successfully initialized BigoAdSdk")
        completionHandler(nil)
      }
    } catch {
      Util.log("Failed to set up BigoAdapter with error \(error.description)")
      completionHandler(error.toNSError())
    }
  }

  @objc static func networkExtrasClass() -> (any AdNetworkExtras.Type)? {
    return BigoAdapterExtras.self
  }

  @objc static func adapterVersion() -> VersionNumber {
    let adapterVersion = Self.adapterVersionString.components(separatedBy: ".").compactMap {
      Int($0)
    }
    guard adapterVersion.count == 4 else {
      return VersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
    }
    return VersionNumber(
      majorVersion: adapterVersion[0],
      minorVersion: adapterVersion[1],
      patchVersion: adapterVersion[2] * 100 + adapterVersion[3]
    )
  }

  @objc static func adSDKVersion() -> VersionNumber {
    let adSDKVersion = BigoAdSdk.sharedInstance().getVersionName().components(separatedBy: ".")
      .compactMap {
        Int($0)
      }
    guard adSDKVersion.count == 3 else {
      return VersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
    }
    return VersionNumber(
      majorVersion: adSDKVersion[0], minorVersion: adSDKVersion[1], patchVersion: adSDKVersion[2])
  }

  @objc func collectSignals(
    for params: RTBRequestParameters,
    completionHandler: @escaping GADRTBSignalCompletionHandler
  ) {

  }

  @objc
  func loadAppOpenAd(
    for adConfiguration: GADMediationAppOpenAdConfiguration,
    completionHandler: @escaping GADMediationAppOpenLoadCompletionHandler
  ) {
    appOpenAdLoader = AppOpenAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    appOpenAdLoader?.loadAd()
  }

  @objc
  func loadBanner(
    for adConfiguration: MediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    nonisolated(unsafe) let adConfiguration = adConfiguration
    nonisolated(unsafe) let completionHandler = completionHandler
    nonisolated(unsafe) let nonisolatedSelf = self
    DispatchQueue.main.async {
      nonisolatedSelf.bannerAdLoader = BannerAdLoader(
        adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
      nonisolatedSelf.bannerAdLoader?.loadAd()
    }
  }

  @objc
  func loadInterstitial(
    for adConfiguration: MediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    interstitialAdLoader = InterstitialAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    interstitialAdLoader?.loadAd()
  }

  @objc
  func loadRewardedAd(
    for adConfiguration: MediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    rewardedAdLoader = RewardedAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    rewardedAdLoader?.loadAd()
  }

  // TODO: Remove if not needed. If removed, then remove the |NativeAdLoader| class as well.
  @objc
  func loadNativeAd(
    for adConfiguration: MediationNativeAdConfiguration,
    completionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    nativeAdLoader = NativeAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    nativeAdLoader?.loadAd()
  }

}
