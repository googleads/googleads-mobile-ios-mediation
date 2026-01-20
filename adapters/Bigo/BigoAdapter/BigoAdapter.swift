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

  static let adapterVersionString = "5.0.0.0"

  /// The app open ad loader.
  private var appOpenAdLoader: AppOpenAdLoader?

  /// The banner ad loader.
  private var bannerAdLoader: BannerAdLoader?

  /// The interstitial ad loader.
  private var interstitialAdLoader: InterstitialAdLoader?

  /// The rewarded ad loader.
  private var rewardedAdLoader: RewardedAdLoader?

  /// The rewarded interstitial ad loader, which is identical to RewardedAd.
  private var rewardedInterstitialAdLoader: RewardedAdLoader?

  /// The native ad loader.
  private var nativeAdLoader: NativeAdLoader?

  @objc static func setUp(
    with configuration: MediationServerConfiguration,
    completionHandler: @escaping GADMediationAdapterSetUpCompletionBlock
  ) {
    Util.log("Start setting up BigoAdapter")

    if BigoAdSdk.sharedInstance().isInitialized() {
      Util.log("BigoAdSdk is already initialized")
      completionHandler(nil)
      return
    }

    do {
      let applicationId = try Util.applicationId(from: configuration)
      let client = BigoClientFactory.createClient()
      let requestConfiguration = MobileAds.shared.requestConfiguration
      client.setUserConsent(
        with: requestConfiguration.tagForChildDirectedTreatment,
        tagForUnderAgeOfConsent: requestConfiguration.tagForUnderAgeOfConsent)
      client.initialize(
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
    Util.log("Collecting signals.")
    let token = BigoClientFactory.createClient().getBidderToken()
    completionHandler(token, nil)
  }

  @objc
  func loadAppOpenAd(
    for adConfiguration: GADMediationAppOpenAdConfiguration,
    completionHandler: @escaping GADMediationAppOpenLoadCompletionHandler
  ) {
    Util.log("Start loading app open ad")
    appOpenAdLoader = AppOpenAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    appOpenAdLoader?.loadAd()
  }

  @objc
  func loadBanner(
    for adConfiguration: MediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    Util.log("Start loading banner ad")
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
    Util.log("Start loading interstitial ad")
    interstitialAdLoader = InterstitialAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    interstitialAdLoader?.loadAd()
  }

  @objc
  func loadRewardedAd(
    for adConfiguration: MediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    Util.log("Start loading rewarded ad")
    rewardedAdLoader = RewardedAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    rewardedAdLoader?.loadAd()
  }

  @objc
  func loadRewardedInterstitialAd(
    for adConfiguration: MediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    Util.log("Start loading rewarded interstitial ad")
    // Reuse rewarded ad.
    rewardedInterstitialAdLoader = RewardedAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    rewardedInterstitialAdLoader?.loadAd()
  }

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
