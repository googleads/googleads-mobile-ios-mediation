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
    // TODO: implement
    completionHandler(nil)
  }

  @objc
  static func networkExtrasClass() -> (any AdNetworkExtras.Type)? {
    return VerveAdapterExtras.self
  }

  @objc
  static func adapterVersion() -> VersionNumber {
    // TODO: implement
    return VersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
  }

  @objc
  static func adSDKVersion() -> VersionNumber {
    // TODO: implement
    return VersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
  }

  // TODO: Implement if the adapter conforms to GADRTBAdapter. Otherwise, remove.
  @objc
  func collectSignals(
    for params: RTBRequestParameters, completionHandler: @escaping GADRTBSignalCompletionHandler
  ) {
    // TODO: implement
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
