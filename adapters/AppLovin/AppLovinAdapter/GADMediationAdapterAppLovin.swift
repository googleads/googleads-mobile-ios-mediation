// Copyright 2026 Google LLC
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

import AppLovinSDK
import Foundation
import GoogleMobileAds
import UIKit

@MainActor
/// The AppLovin mediation adapter. Coordinates configuration, signal collection, and loading of
/// banner, interstitial, and rewarded ads.
@objc(GADMediationAdapterAppLovin)
public final class GADMediationAdapterAppLovin: NSObject, @preconcurrency RTBAdapter {

  private var waterfallBannerRenderer: GADMWaterfallAppLovinBannerRenderer?
  private var rtbInterstitialRenderer: GADMRTBAdapterAppLovinInterstitialRenderer?
  private var waterfallInterstitialRenderer: GADMWaterfallAppLovinInterstitialRenderer?
  private var rewardedRenderer: GADMAdapterAppLovinRewardedRenderer?

  public override init() {
    super.init()
  }

  @objc public static func setUp(
    with configuration: MediationServerConfiguration,
    completionHandler: @escaping GADMediationAdapterSetUpCompletionBlock
  ) {
    if GADMAdapterAppLovinUtils.isChildUser() {
      completionHandler(GADMAdapterAppLovinUtils.childUserError())
      return
    }

    // Compile all the SDK keys that should be initialized.
    var sdkKeys = Set<String>()

    // Compile SDK keys from configuration credentials.
    for credentials in configuration.credentials {
      if let sdkKey = credentials.settings[GADMAdapterAppLovinSDKKey] as? String,
        GADMAdapterAppLovinUtils.isValidAppLovinSDKKey(sdkKey)
      {
        sdkKeys.insert(sdkKey)
      }
    }

    guard !sdkKeys.isEmpty else {
      let errorString = "No SDK keys are found. Please add valid SDK keys in the AdMob UI."
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .missingSDKKey,
        description: errorString
      )
      completionHandler(error)
      return
    }

    guard let sdkKey = sdkKeys.first else { return }
    if sdkKeys.count > 1 {
      GADMAdapterAppLovinUtils.log(
        "More than one SDK key was found. The adapter will use \(sdkKey) to initialize the AppLovin SDK."
      )
    }

    GADMAdapterAppLovinUtils.log(
      "Found \(sdkKeys.count) SDK keys. Please remove any SDK keys you are not using from the AdMob UI."
    )
    GADMAdapterAppLovinInitializer.initialize(withSDKKey: sdkKey) {
      completionHandler(nil)
    }
  }

  @objc public static func adapterVersion() -> VersionNumber {
    let versionString = GADMAdapterAppLovinAdapterVersion
    let versionComponents = versionString.components(separatedBy: ".")
    GADMAdapterAppLovinUtils.log("AppLovin adapter version: \(versionString)")
    var version = VersionNumber()
    if versionComponents.count >= 4 {
      version.majorVersion = Int(versionComponents[0]) ?? 0
      version.minorVersion = Int(versionComponents[1]) ?? 0
      // Adapter versions have 2 patch versions. Multiply the first patch by 100.
      version.patchVersion =
        (Int(versionComponents[2]) ?? 0) * 100 + (Int(versionComponents[3]) ?? 0)
    }
    return version
  }

  @objc public static func adSDKVersion() -> VersionNumber {
    let versionString = ALSdk.version()
    let versionComponents = versionString.components(separatedBy: ".")
    GADMAdapterAppLovinUtils.log("AppLovin SDK version: \(versionString)")
    var version = VersionNumber()
    if versionComponents.count >= 3 {
      version.majorVersion = Int(versionComponents[0]) ?? 0
      version.minorVersion = Int(versionComponents[1]) ?? 0
      version.patchVersion = Int(versionComponents[2]) ?? 0
    }
    return version
  }

  @objc public static func networkExtrasClass() -> (any AdNetworkExtras.Type)? {
    return GADMAdapterAppLovinExtras.self
  }

  @objc dynamic public static func createInterstitialAd(with sdk: ALSdk) -> ALInterstitialAd {
    return ALInterstitialAd(sdk: sdk)
  }

  @objc dynamic public static func createIncentivizedInterstitialAd(
    with sdk: ALSdk
  ) -> ALIncentivizedInterstitialAd {
    return ALIncentivizedInterstitialAd(sdk: sdk)
  }

  @objc public func collectSignals(
    for params: RTBRequestParameters,
    completionHandler: @escaping GADRTBSignalCompletionHandler
  ) {
    guard !GADMAdapterAppLovinUtils.isChildUser() else {
      completionHandler(nil, GADMAdapterAppLovinUtils.childUserError())
      return
    }

    GADMAdapterAppLovinUtils.log("AppLovin adapter collecting signals.")
    // Check if supported ad format.
    if params.configuration.credentials.first?.format == .native {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .unsupportedAdFormat,
        description: "Requested to collect signal for unsupported native ad format. Ignoring..."
      )
      completionHandler(nil, error)
      return
    }

    guard let sharedSdk = ALSdk.shared() as ALSdk? else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .appLovinSDKNotInitialized,
        description: "AppLovin SDK not initialized."
      )
      completionHandler(nil, error)
      return
    }

    sharedSdk.adService.collectBidToken { bidToken, errorMessage in
      if let errorMessage = errorMessage {
        let error = GADMAdapterAppLovinUtils.error(
          withCode: .failedToReturnBidToken,
          description: errorMessage
        )
        completionHandler(nil, error)
        return
      }
      if let bidToken = bidToken, !bidToken.isEmpty {
        GADMAdapterAppLovinUtils.log("Generated bid token \(bidToken).")
        completionHandler(bidToken, nil)
      } else {
        let error = GADMAdapterAppLovinUtils.error(
          withCode: .emptyBidToken,
          description: "Bid token is empty."
        )
        completionHandler(nil, error)
      }
    }
  }

  // Note: Banner ads are supported by AppLovin only for Waterfall and not for Bidding. So, all banner
  // ad load requests are assumed to be for Waterfall.
  @objc public func loadBanner(
    for adConfiguration: MediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    guard !GADMAdapterAppLovinUtils.isChildUser() else {
      completionHandler(nil, GADMAdapterAppLovinUtils.childUserError())
      return
    }

    guard
      let sdkKey = GADMAdapterAppLovinUtils.retrieveSDKKey(
        fromCredentials: adConfiguration.credentials.settings)
    else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .missingSDKKey,
        description: "AppLovin SDK Key is missing."
      )
      completionHandler(nil, error)
      return
    }

    GADMAdapterAppLovinInitializer.initialize(withSDKKey: sdkKey) { [weak self] in
      guard let self else { return }
      let renderer = GADMWaterfallAppLovinBannerRenderer(adConfiguration: adConfiguration)
      self.waterfallBannerRenderer = renderer
      renderer.loadAd(withCompletion: completionHandler)
    }
  }

  @objc public func loadInterstitial(
    for adConfiguration: MediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    guard !GADMAdapterAppLovinUtils.isChildUser() else {
      completionHandler(nil, GADMAdapterAppLovinUtils.childUserError())
      return
    }

    if adConfiguration.bidResponse != nil {
      let renderer = GADMRTBAdapterAppLovinInterstitialRenderer(
        adConfiguration: adConfiguration,
        completionHandler: completionHandler
      )
      self.rtbInterstitialRenderer = renderer
      renderer.loadAd()
    } else {
      // In the case of waterfall, initialize Applovin SDK before loading ad.
      guard
        let sdkKey = GADMAdapterAppLovinUtils.retrieveSDKKey(
          fromCredentials: adConfiguration.credentials.settings)
      else {
        let error = GADMAdapterAppLovinUtils.error(
          withCode: .missingSDKKey,
          description: "AppLovin SDK Key is missing."
        )
        completionHandler(nil, error)
        return
      }

      GADMAdapterAppLovinInitializer.initialize(withSDKKey: sdkKey) { [weak self] in
        guard let self else { return }
        let renderer = GADMWaterfallAppLovinInterstitialRenderer(adConfiguration: adConfiguration)
        self.waterfallInterstitialRenderer = renderer
        renderer.loadAd(withCompletion: completionHandler)
      }
    }
  }

  @objc public func loadRewardedAd(
    for adConfiguration: MediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    guard !GADMAdapterAppLovinUtils.isChildUser() else {
      completionHandler(nil, GADMAdapterAppLovinUtils.childUserError())
      return
    }

    guard
      let sdkKey = GADMAdapterAppLovinUtils.retrieveSDKKey(
        fromCredentials: adConfiguration.credentials.settings)
    else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .missingSDKKey,
        description: "AppLovin SDK Key is missing."
      )
      completionHandler(nil, error)
      return
    }

    GADMAdapterAppLovinInitializer.initialize(withSDKKey: sdkKey) { [weak self] in
      guard let self else { return }
      let renderer = GADMAdapterAppLovinRewardedRenderer(
        adConfiguration: adConfiguration,
        completionHandler: completionHandler
      )
      self.rewardedRenderer = renderer
      renderer.requestRewardedAd()
    }
  }
}
