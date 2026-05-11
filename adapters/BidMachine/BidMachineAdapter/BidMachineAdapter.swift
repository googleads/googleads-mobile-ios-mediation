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

@objc(GADMediationAdapterBidMachine)
final class BidMachineAdapter: NSObject, RTBAdapter {

  private static let adapterVersionString = "3.6.1.0"

  private static let supportedFormats: [AdFormat] = [
    .banner, .interstitial, .rewarded, .native,
  ]

  /// The banner ad loader.
  var bannerAdLoader: BannerAdLoader?

  /// The interstitial ad loader.
  var interstitialAdLoader: InterstitialAdLoader?

  /// The rewarded ad loader.
  var rewardedAdLoader: RewardedAdLoader?

  /// The native ad loader.
  var nativeAdLoader: NativeAdLoader?

  @objc static func setUp(
    with configuration: MediationServerConfiguration,
    completionHandler: @escaping GADMediationAdapterSetUpCompletionBlock
  ) {
    do {
      let sourceId = try Util.sourceId(from: configuration)

      // Sets COPPA compliance based on MobileAds configuration.
      // - If ageRestrictedTreatment is set to .child, treat as COPPA-compliant (true).
      // - If either tag (TFCD or TFUA) is true, treat as COPPA-compliant (true).
      // - If either tag (TFCD or TFUA) is false (and neither is true), treat as not COPPA-compliant (false).
      // - Otherwise, leave as nil.
      let ageRestrictedTreatment = MobileAds.shared.requestConfiguration.ageRestrictedTreatment
      let isChild = MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment?.boolValue
      let isUnderAge = MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent?.boolValue
      var isCOPPA: Bool?
      if isChild == true || isUnderAge == true || ageRestrictedTreatment == .child {
        isCOPPA = true
      } else if isChild == false || isUnderAge == false {
        isCOPPA = false
      }

      BidMachineClientFactory.createClient().initialize(with: sourceId, isCOPPA: isCOPPA)
      completionHandler(nil)
    } catch {
      completionHandler(error.toNSError())
    }
  }

  @objc static func networkExtrasClass() -> (any AdNetworkExtras.Type)? {
    return BidMachineAdapterExtras.self
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
    let adSDKVersion = BidMachineClientFactory.createClient().version().components(
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

  @objc func collectSignals(
    for params: RTBRequestParameters,
    completionHandler: @escaping GADRTBSignalCompletionHandler
  ) {
    Task {
      do {
        let format = try Util.adFormat(from: params)
        try BidMachineClientFactory.createClient().collectSignals(for: format) { signals in
          Task { @MainActor in
            completionHandler(signals, nil)
          }
        }
      } catch let error as BidMachineAdapterError {
        Task { @MainActor in
          completionHandler(nil, error.toNSError())
        }
      } catch {
        Task { @MainActor in
          completionHandler(nil, error as NSError)
        }
      }
    }
  }

  @objc
  func loadBanner(
    for adConfiguration: MediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    Task {
      @MainActor in
      self.bannerAdLoader = BannerAdLoader(
        adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
      self.bannerAdLoader?.loadAd()
    }
  }

  @objc
  func loadInterstitial(
    for adConfiguration: MediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    Task {
      @MainActor in
      self.interstitialAdLoader = InterstitialAdLoader(
        adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
      self.interstitialAdLoader?.loadAd()
    }
  }

  @objc
  func loadRewardedAd(
    for adConfiguration: MediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    Task {
      @MainActor in
      self.rewardedAdLoader = RewardedAdLoader(
        adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
      self.rewardedAdLoader?.loadAd()
    }
  }

  @objc
  func loadNativeAd(
    for adConfiguration: MediationNativeAdConfiguration,
    completionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    Task {
      @MainActor in
      self.nativeAdLoader = NativeAdLoader(
        adConfiguration: adConfiguration, loadCompletionHandler: completionHandler)
      self.nativeAdLoader?.loadAd()
    }
  }

}
