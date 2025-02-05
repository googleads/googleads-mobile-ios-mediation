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
public final class MolocoMediationAdapter: NSObject, RTBAdapter {

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

  private static var molocoSdkVersionProvider: MolocoSdkVersionProviding = molocoSdkImpl

  private static var molocoAgeRestrictedSetter: MolocoAgeRestrictedSetter = molocoSdkImpl

  public override init() {
    // Conform to MediationAdapter protocol.
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
  static func setMolocoAgeRestrictedSetter(_ molocoAgeRestrictedSetter: MolocoAgeRestrictedSetter) {
    self.molocoAgeRestrictedSetter = molocoAgeRestrictedSetter
  }

  /// Setter used only for testing purpose.
  static func setMolocoInitializer(_ fakeMolocoInitializer: MolocoInitializer) {
    molocoInitializer = fakeMolocoInitializer
  }

  /// Setter used only for testing purpose.
  static func setMolocoSdkVersionProvider(
    _ molocoSdkVersionProvider: MolocoSdkVersionProviding
  ) {
    self.molocoSdkVersionProvider = molocoSdkVersionProvider
  }

  @objc public static func setUp(
    with configuration: MediationServerConfiguration,
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

    // Set age-restricted-user bit before initializing Moloco SDK.
    // Note: If isAgeRestrictedUser() returns nil, it means the adapter doesn't know whether the
    // user is age-restricted or not. In that case, we don't set age-restricted-user bit on Moloco
    // SDK.
    if let isAgeRestrictedUser = isAgeRestrictedUser() {
      molocoAgeRestrictedSetter.setIsAgeRestrictedUser(isAgeRestrictedUser: isAgeRestrictedUser)
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

  /// Returns a boolean indicating whether the user is age-restricted or not. nil if not known.
  static func isAgeRestrictedUser() -> Bool? {
    let tagForChildDirectedTreatment = MobileAds.shared.requestConfiguration
      .tagForChildDirectedTreatment
    let tagForUnderAgeOfConsent = MobileAds.shared.requestConfiguration
      .tagForUnderAgeOfConsent
    // Check that either one of the bits is set. Else, return nil.
    guard tagForChildDirectedTreatment != nil || tagForUnderAgeOfConsent != nil else {
      return nil
    }
    return tagForChildDirectedTreatment?.boolValue == true
      || tagForUnderAgeOfConsent?.boolValue == true
  }

  @objc public static func networkExtrasClass() -> AdNetworkExtras.Type? {
    return nil
  }

  @objc public static func adapterVersion() -> VersionNumber {
    var adapterVersion = VersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)

    let adapterVersionParts = MolocoConstants.adapterVersion.split(separator: ".")

    // Adapter version has four parts: major.minor.patch.micro
    if adapterVersionParts.count == 4 {
      if let majorVersion = Int(adapterVersionParts[0]),
        let minorVersion = Int(adapterVersionParts[1]),
        let patchVersion = Int(adapterVersionParts[2]),
        let microVersion = Int(adapterVersionParts[3])
      {
        adapterVersion.majorVersion = majorVersion
        adapterVersion.minorVersion = minorVersion
        // VersionNumber doesn't have a micro version. So, we will include the adapter's micro
        // version into VersionNumber's patch version.
        adapterVersion.patchVersion = patchVersion * 100 + microVersion
      } else {
        MolocoUtils.log("Adapter version is not parsable")
      }
    } else {
      MolocoUtils.log("Adapter version is not in the expected format of major.minor.patch.micro")
    }

    return adapterVersion
  }

  @objc public static func adSDKVersion() -> VersionNumber {
    let adSDKVersionString = molocoSdkVersionProvider.sdkVersion()

    var adSDKVersion = VersionNumber(majorVersion: 0, minorVersion: 0, patchVersion: 0)

    let adSDKVersionParts = adSDKVersionString.split(separator: ".")

    // Note: Checking for ">= 3" here and not just "== 3" because we don't want version reporting
    // to break if Moloco SDK decides to add an extra part to their version.
    if adSDKVersionParts.count >= 3 {
      if let majorVersion = Int(adSDKVersionParts[0]), let minorVersion = Int(adSDKVersionParts[1]),
        let patchVersion = Int(adSDKVersionParts[2])
      {
        adSDKVersion.majorVersion = majorVersion
        adSDKVersion.minorVersion = minorVersion
        adSDKVersion.patchVersion = patchVersion
      } else {
        MolocoUtils.log("Moloco SDK version is not parsable")
      }
    } else {
      MolocoUtils.log("Moloco SDK version is not in the expected format of major.minor.patch")
    }

    return adSDKVersion
  }

  @objc public func collectSignals(
    for params: RTBRequestParameters, completionHandler: @escaping GADRTBSignalCompletionHandler
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
    for adConfiguration: MediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    bannerAdLoader = BannerAdLoader(
      adConfiguration: adConfiguration, molocoBannerFactory: molocoBannerFactory,
      loadCompletionHandler: completionHandler)
    bannerAdLoader?.loadAd()
  }

  @objc public func loadInterstitial(
    for adConfiguration: MediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    interstitialAdLoader = InterstitialAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler,
      molocoInterstitialFactory: molocoInterstitialFactory)
    interstitialAdLoader?.loadAd()
  }

  @objc public func loadRewardedAd(
    for adConfiguration: MediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    rewardedAdLoader = RewardedAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler,
      molocoRewardedFactory: molocoRewardedFactory)
    rewardedAdLoader?.loadAd()
  }

  // TODO: Remove if not needed. If removed, then remove the |NativeAdLoader| class as well.
  @objc public func loadNativeAd(
    for adConfiguration: MediationNativeAdConfiguration,
    completionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    nativeAdLoader = NativeAdLoader(
      adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
    nativeAdLoader?.loadAd()
  }

}
