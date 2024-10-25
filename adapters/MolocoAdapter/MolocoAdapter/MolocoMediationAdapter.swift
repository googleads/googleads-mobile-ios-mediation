// Copyright 2024 Google LLC.
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
import MolocoSDK
import OSLog

/// Adapter for Google Mobile Ads SDK to render ads on Moloco ads SDK.
@objc(GADMediationAdapterMoloco)
public final class MolocoMediationAdapter: NSObject, GADRTBAdapter {

  /// The banner ad loader.
  private var bannerAdLoader: BannerAdLoader?

  /// The interstitial ad loader.
  private var interstitialAdLoader: InterstitialAdLoader?

  /// The rewarded ad loader.
  private var rewardedAdLoader: RewardedAdLoader?

  /// The native ad loader.
  private var nativeAdLoader: NativeAdLoader?

  /// An instance of MolocoSdkImpl. MolocoSdkImpl implements calls to Moloco SDK.
  private static let molocoSdkImpl = MolocoSdkImpl()

  /// Used to initialize the Moloco SDK.
  private static var molocoInitializer: MolocoInitializer = molocoSdkImpl

  /// Used to create Moloco interstitial ads.
  private var molocoInterstitialFactory: MolocoInterstitialFactory = MolocoMediationAdapter
    .molocoSdkImpl

  /// Used to create Moloco rewarded ads.
  private var molocoRewardedFactory: MolocoRewardedFactory = MolocoMediationAdapter.molocoSdkImpl

  /// Used to create Moloco banner ads.
  private var molocoBannerFactory: MolocoBannerFactory = MolocoMediationAdapter.molocoSdkImpl

  private var molocoBidTokenGetter: MolocoBidTokenGetter = MolocoMediationAdapter.molocoSdkImpl

  public override init() {
    // Conform to GADMediationAdapter protocol.
  }

  /// Initializer used only for testing purpose.
  init(molocoInterstitialFactory: MolocoInterstitialFactory) {
    self.molocoInterstitialFactory = molocoInterstitialFactory
  }

  /// Initializer used only for testing purpose.
  init(molocoRewardedFactory: MolocoRewardedFactory) {
    self.molocoRewardedFactory = molocoRewardedFactory
  }

  /// Initializer used only for testing purpose.
  init(molocoBannerFactory: MolocoBannerFactory) {
    self.molocoBannerFactory = molocoBannerFactory
  }

  /// Initializer used only for testing purpose.
  init(molocoBidTokenGetter: MolocoBidTokenGetter) {
    self.molocoBidTokenGetter = molocoBidTokenGetter
  }

  /// Setter used only for testing purpose.
  static func setMolocoInitializer(_ fakeMolocoInitializer: MolocoInitializer) {
    molocoInitializer = fakeMolocoInitializer
  }

  @objc public static func setUpWith(
    _ configuration: GADMediationServerConfiguration,
    completionHandler: @escaping GADMediationAdapterSetUpCompletionBlock
  ) {
    guard #available(iOS 13.0, *) else {
      completionHandler(
        MolocoUtils.error(
          code: .adServingNotSupported,
          description: "Moloco SDK does not support serving ads on iOS 12 and below"))
      return
    }

    guard !molocoInitializer.isInitialized() else {
      completionHandler(nil)
      return
    }

    let appIDs = Set(
      configuration.credentials.compactMap {
        $0.settings[MolocoConstants.appIDKey] as? String
      }.filter { !$0.isEmpty })

    guard let appID = appIDs.first else {
      MolocoUtils.log("Not initializing Moloco SDK because because appId is invalid/missing")
      completionHandler(
        MolocoUtils.error(
          code: .invalidAppID, description: "Missing/Invalid App ID"))
      return
    }

    if appIDs.count > 1 {
      MolocoUtils.log(
        "Found multiple application IDs. Please remove unused application IDs from the AdMob UI. Application IDs: \(appIDs)"
      )
    }

    MolocoUtils.log("Initializing Moloco SDK with app ID [\(appID)]")

    // Initialize Moloco SDK
    molocoInitializer.initialize(initParams: .init(appKey: appID)) { done, err in
      done ? completionHandler(nil) : completionHandler(err)
    }
  }

  @objc public static func networkExtrasClass() -> GADAdNetworkExtras.Type? {
    return nil
  }

  @objc public static func adapterVersion() -> GADVersionNumber {
    // TODO: implement
    return GADVersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
  }

  @objc public static func adSDKVersion() -> GADVersionNumber {
    // TODO: implement
    return GADVersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)
  }

  @objc public func collectSignals(
    for params: GADRTBRequestParameters, completionHandler: @escaping GADRTBSignalCompletionHandler
  ) {
    molocoBidTokenGetter.getBidToken { bidToken, error in
      if error != nil {
        completionHandler(nil, error)
      } else {
        completionHandler(bidToken, nil)
      }
    }
  }

  @objc public func loadBanner(
    for adConfiguration: GADMediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    bannerAdLoader = BannerAdLoader(
      adConfiguration: adConfiguration, molocoBannerFactory: molocoBannerFactory,
      loadCompletionHandler: completionHandler)
    bannerAdLoader?.loadAd()
  }

  @objc public func loadInterstitial(
    for adConfiguration: GADMediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    interstitialAdLoader = InterstitialAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler,
      molocoInterstitialFactory: molocoInterstitialFactory)
    interstitialAdLoader?.loadAd()
  }

  @objc public func loadRewardedAd(
    for adConfiguration: GADMediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    rewardedAdLoader = RewardedAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler,
      molocoRewardedFactory: molocoRewardedFactory)
    rewardedAdLoader?.loadAd()
  }

  // TODO: Remove if not needed. If removed, then remove the |NativeAdLoader| class as well.
  @objc public func loadNativeAd(
    for adConfiguration: GADMediationNativeAdConfiguration,
    completionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    nativeAdLoader = NativeAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    nativeAdLoader?.loadAd()
  }

}
