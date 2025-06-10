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

import GoogleMobileAds

@objc(GADMediationAdapterVerve)
final class VerveAdapter: NSObject, RTBAdapter {

  private static let version = "3.2.0.0"

  /// The banner ad loader.
  private var bannerAdLoader: BannerAdLoader?

  /// The interstitial ad loader.
  private var interstitialAdLoader: InterstitialAdLoader?

  /// The rewarded ad loader.
  private var rewardedAdLoader: RewardedAdLoader?

  /// The native ad loader.
  private var nativeAdLoader: NativeAdLoader?

  @objc
  static func setUp(
    with configuration: MediationServerConfiguration,
    completionHandler: @escaping GADMediationAdapterSetUpCompletionBlock
  ) {
    do {
      let sourceId = try Util.appToken(from: configuration)
      let isTestMode = VerveAdapterExtras.isTestMode
      var isCOPPA: Bool?
      if let COPPA = MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment {
        isCOPPA = COPPA.boolValue
      }
      var isTFUA: Bool?
      if let TFUA = MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent {
        isTFUA = TFUA.boolValue
      }

      HybidClientFactory.createClient().initialize(
        with: sourceId, testMode: isTestMode, COPPA: isCOPPA, TFUA: isTFUA
      ) { error in
        completionHandler(error?.toNSError())
      }
    } catch {
      completionHandler(error.toNSError())
    }
  }

  @objc
  static func networkExtrasClass() -> (any AdNetworkExtras.Type)? {
    return VerveAdapterExtras.self
  }

  @objc
  static func adapterVersion() -> VersionNumber {
    let adapterVersion = Self.version.components(separatedBy: ".").compactMap {
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

  @objc
  static func adSDKVersion() -> VersionNumber {
    let adSDKVersion = HybidClientFactory.createClient().version().components(
      separatedBy: "."
    )
    .compactMap { Int($0) }
    guard adSDKVersion.count == 3 else {
      return VersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
    }
    return VersionNumber(
      majorVersion: adSDKVersion[0],
      minorVersion: adSDKVersion[1],
      patchVersion: adSDKVersion[2]
    )
  }

  @objc
  func collectSignals(
    for params: RTBRequestParameters,
    completionHandler: @escaping GADRTBSignalCompletionHandler
  ) {
    do throws(VerveAdapterError) {
      // The ad size is GADAdSizeInvalid for non-banner requests. If banner,
      // then check whether the request size is supported by HyBid SDK.
      if !isAdSizeEqualToSize(size1: params.adSize, size2: AdSizeInvalid) {
        try HybidClientFactory.createClient().getBannerSize(params.adSize.size)
      }
      completionHandler(HybidClientFactory.createClient().collectSignals(), nil)
    } catch {
      completionHandler(nil, error.toNSError())
    }
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

  @objc
  func loadRewardedInterstitialAd(
    for adConfiguration: MediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    // Reuse rewarded ad.
    loadRewardedAd(for: adConfiguration, completionHandler: completionHandler)
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
