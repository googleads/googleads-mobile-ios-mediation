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

import AdSurgeSDK
import Foundation
import ObjectiveC
import UIKit

/// Forwards calls to the AdSurge SDK. Each loader uses its own instance, which keeps the loaded ad.
///
/// This class is `@unchecked Sendable` because its stored ads are only accessed from the main
/// thread and from SDK callbacks.
final class AdSurgeClientImpl: AdSurgeClient, @unchecked Sendable {

  func setAgeRestrictedUser(_ ageRestrictedUser: NSNumber) {
    AdSurgePrivacyConfiguration.configuration().ageRestrictedUser = ageRestrictedUser
  }

  func initialize(appId: String) async -> (success: Bool, error: AdSurgeSDKError?) {
    let config = AdSurgeSDKConfig()
    config.appId = appId
    return await withCheckedContinuation { continuation in
      AdSurgeAdSdk.shared().initialize(with: config) { success, error in
        continuation.resume(returning: (success, error.map(AdSurgeSDKError.init)))
      }
    }
  }

  func getBidderToken() async -> (token: String?, error: AdSurgeSDKError?) {
    return await withCheckedContinuation { continuation in
      AdSurgeAdSdk.shared().getBidderToken { token, error in
        continuation.resume(returning: (token, error.map(AdSurgeSDKError.init)))
      }
    }
  }

  func version() -> String {
    return AdSurgeAdSdkVersion
  }

  @MainActor private var bannerView: AdSurgeBannerAdView?

  @MainActor func createBannerAdView(
    adUnitId: String,
    viewController: UIViewController?,
    delegate: any BannerAdClientDelegate
  ) -> UIView {
    let bannerView = AdSurgeBannerAdView(adUnitIdentifier: adUnitId)
    self.bannerView = bannerView
    bannerView.viewController = viewController
    let bridge = BannerDelegateBridge(delegate: delegate)
    bannerView.delegate = bridge
    objc_setAssociatedObject(
      bannerView,
      &bannerBridgeAssociatedKey,
      bridge,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
    return bannerView
  }

  @MainActor func loadBannerAd(bidPayload: String) {
    let config = AdSurgeAdConfig(adFormat: AdSurgeAdFormat.banner)
    config.payload = bidPayload
    bannerView?.loadAd(config)
  }

  private var interstitialAd: AdSurgeInterstitialAd?
  private var rewardedAd: AdSurgeRewardedAd?

  func loadInterstitialAd(
    adUnitId: String,
    bidPayload: String,
    delegate: any FullScreenAdClientDelegate
  ) {
    let ad = AdSurgeInterstitialAd(adUnitIdentifier: adUnitId)
    self.interstitialAd = ad
    let bridge = InterstitialDelegateBridge(delegate: delegate)
    ad.delegate = bridge
    objc_setAssociatedObject(
      ad,
      &interstitialBridgeAssociatedKey,
      bridge,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
    let config = AdSurgeAdConfig(adFormat: AdSurgeAdFormat.interstitial)
    config.payload = bidPayload
    ad.load(config)
  }

  func isInterstitialAdReady() -> Bool {
    return interstitialAd?.isValid ?? false
  }

  func showInterstitialAd(from rootViewController: UIViewController) {
    interstitialAd?.show(fromRootViewController: rootViewController)
  }

  func loadRewardedAd(
    adUnitId: String,
    bidPayload: String,
    delegate: any RewardedAdClientDelegate
  ) {
    let ad = AdSurgeRewardedAd(adUnitIdentifier: adUnitId)
    self.rewardedAd = ad
    let bridge = RewardedDelegateBridge(delegate: delegate)
    ad.delegate = bridge
    objc_setAssociatedObject(
      ad,
      &rewardedBridgeAssociatedKey,
      bridge,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
    let config = AdSurgeAdConfig(adFormat: AdSurgeAdFormat.rewarded)
    config.payload = bidPayload
    ad.load(config)
  }

  func isRewardedAdReady() -> Bool {
    return rewardedAd?.isValid ?? false
  }

  func showRewardedAd(from rootViewController: UIViewController) {
    rewardedAd?.show(fromRootViewController: rootViewController)
  }

}

nonisolated(unsafe) private var bannerBridgeAssociatedKey: UInt8 = 0
nonisolated(unsafe) private var interstitialBridgeAssociatedKey: UInt8 = 0
nonisolated(unsafe) private var rewardedBridgeAssociatedKey: UInt8 = 0

private final class BannerDelegateBridge: NSObject, AdSurgeBannerAdDelegate, @unchecked Sendable {

  private weak var delegate: (any BannerAdClientDelegate)?

  init(delegate: any BannerAdClientDelegate) {
    self.delegate = delegate
  }

  func didLoad(_ ad: AdSurgeAd) {
    delegate?.didLoad()
  }

  func didFailToLoadAd(
    forAdUnitIdentifier adUnitIdentifier: String, withError error: AdSurgeError
  ) {
    delegate?.didFailToLoad(error: AdSurgeSDKError(error))
  }

  func didHide(_ ad: AdSurgeAd) {
    delegate?.didHide()
  }

  func didClick(_ ad: AdSurgeAd) {
    delegate?.didClick()
  }

  func didPayRevenue(for ad: AdSurgeAd) {
    delegate?.didPayRevenue()
  }

}

private final class InterstitialDelegateBridge: NSObject, AdSurgeInterstitialAdDelegate,
  @unchecked Sendable
{

  private weak var delegate: (any FullScreenAdClientDelegate)?

  init(delegate: any FullScreenAdClientDelegate) {
    self.delegate = delegate
  }

  func didLoad(_ ad: AdSurgeAd) {
    delegate?.didLoad()
  }

  func didFailToLoadAd(
    forAdUnitIdentifier adUnitIdentifier: String, withError error: AdSurgeError
  ) {
    delegate?.didFailToLoad(error: AdSurgeSDKError(error))
  }

  func didDisplay(_ ad: AdSurgeAd, withError error: AdSurgeError?) {
    delegate?.didDisplay(error: error.map(AdSurgeSDKError.init))
  }

  func didHide(_ ad: AdSurgeAd) {
    delegate?.didHide()
  }

  func didClick(_ ad: AdSurgeAd) {
    delegate?.didClick()
  }

  func didPayRevenue(for ad: AdSurgeAd) {
    delegate?.didPayRevenue()
  }

}

private final class RewardedDelegateBridge: NSObject, AdSurgeRewardedAdDelegate,
  @unchecked Sendable
{

  private weak var delegate: (any RewardedAdClientDelegate)?

  init(delegate: any RewardedAdClientDelegate) {
    self.delegate = delegate
  }

  func didLoad(_ ad: AdSurgeAd) {
    delegate?.didLoad()
  }

  func didFailToLoadAd(
    forAdUnitIdentifier adUnitIdentifier: String, withError error: AdSurgeError
  ) {
    delegate?.didFailToLoad(error: AdSurgeSDKError(error))
  }

  func didDisplay(_ ad: AdSurgeAd, withError error: AdSurgeError?) {
    delegate?.didDisplay(error: error.map(AdSurgeSDKError.init))
  }

  func didHide(_ ad: AdSurgeAd) {
    delegate?.didHide()
  }

  func didClick(_ ad: AdSurgeAd) {
    delegate?.didClick()
  }

  func didRewardUser(for ad: AdSurgeAd, with reward: AdSurgeReward) {
    delegate?.didRewardUser()
  }

  func didPayRevenue(for ad: AdSurgeAd) {
    delegate?.didPayRevenue()
  }

}

extension AdSurgeSDKError {

  /// Creates an error with the code and message of an error reported by the AdSurge SDK.
  fileprivate init(_ sdkError: AdSurgeError) {
    self.init(code: sdkError.code.rawValue, message: sdkError.message)
  }

}
