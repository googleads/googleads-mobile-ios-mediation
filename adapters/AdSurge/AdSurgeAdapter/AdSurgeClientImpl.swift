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

final class AdSurgeClientImpl: AdSurgeClient, @unchecked Sendable {

  func setAgeRestrictedUser(_ ageRestrictedUser: NSNumber?) {
    if let ageRestrictedUser {
      AdSurgePrivacyConfiguration.configuration().ageRestrictedUser = ageRestrictedUser
    }
  }

  func initialize(with appId: String) async throws {
    try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<Void, any Error>) in
      let config = AdSurgeSDKConfig()
      config.appId = appId
      AdSurgeAdSdk.shared().initialize(with: config) { success, error in
        if success {
          continuation.resume()
        } else {
          continuation.resume(throwing: Self.initializationError(from: error))
        }
      }
    }
  }

  /// Returns the error to report when the AdSurge SDK fails to initialize.
  ///
  /// Errors reported by the SDK keep the SDK's error code in the AdSurge SDK error domain. If the
  /// SDK fails without an error, returns the adapter's internal error.
  static func initializationError(from sdkError: AdSurgeError?) -> NSError {
    guard let sdkError else {
      return AdSurgeAdapterError(
        errorCode: .internalError,
        description: "AdSurge SDK failed to initialize."
      ).toNSError()
    }
    return sdkError.toSDKNSError()
  }

  /// Returns the error to report when the AdSurge SDK fails to return a bidder token.
  ///
  /// Errors reported by the SDK keep the SDK's error code in the AdSurge SDK error domain. If the
  /// SDK fails without an error, returns the adapter's internal error.
  static func bidderTokenError(from sdkError: AdSurgeError?) -> NSError {
    guard let sdkError else {
      return AdSurgeAdapterError(
        errorCode: .internalError,
        description: "Failed to retrieve bidder token."
      ).toNSError()
    }
    return sdkError.toSDKNSError()
  }

  func getBidderToken() async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
      AdSurgeAdSdk.shared().getBidderToken { token, error in
        if let token {
          continuation.resume(returning: token)
        } else {
          continuation.resume(throwing: Self.bidderTokenError(from: error))
        }
      }
    }
  }

  func version() -> String {
    return AdSurgeAdSdkVersion
  }

  @MainActor func createBannerAdView(for adUnitId: String) -> UIView {
    return AdSurgeBannerAdView(adUnitIdentifier: adUnitId)
  }

  @MainActor func loadBannerAd(
    _ bannerView: UIView,
    bidPayload: String,
    viewController: UIViewController?,
    delegate: any BannerAdClientDelegate
  ) {
    guard let banner = bannerView as? AdSurgeBannerAdView else {
      delegate.bannerDidFailToLoad(
        with: AdSurgeAdapterError(
          errorCode: .internalError,
          description: "Invalid banner view type."
        ).toNSError()
      )
      return
    }
    banner.viewController = viewController
    let bridge = BannerDelegateBridge(delegate: delegate)
    banner.delegate = bridge
    objc_setAssociatedObject(
      banner,
      &bannerBridgeAssociatedKey,
      bridge,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
    let config = AdSurgeAdConfig(adFormat: AdSurgeAdFormat.banner)
    config.payload = bidPayload
    banner.loadAd(config)
  }

  private var interstitialAd: AdSurgeInterstitialAd?
  private var rewardedAd: AdSurgeRewardedAd?

  func loadInterstitialAd(
    for adUnitId: String,
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

  func showInterstitialAd(from rootViewController: UIViewController) throws(AdSurgeAdapterError) {
    guard let interstitialAd, interstitialAd.isValid else {
      throw AdSurgeAdapterError(
        errorCode: .adNotReadyForPresentation,
        description: "AdSurge interstitial ad is not ready to be presented.")
    }
    interstitialAd.show(fromRootViewController: rootViewController)
  }

  func loadRewardedAd(
    for adUnitId: String,
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

  func showRewardedAd(from rootViewController: UIViewController) throws(AdSurgeAdapterError) {
    guard let rewardedAd, rewardedAd.isValid else {
      throw AdSurgeAdapterError(
        errorCode: .adNotReadyForPresentation,
        description: "AdSurge rewarded ad is not ready to be presented.")
    }
    rewardedAd.show(fromRootViewController: rootViewController)
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
    delegate?.bannerDidLoad()
  }

  func didFailToLoadAd(
    forAdUnitIdentifier adUnitIdentifier: String, withError error: AdSurgeError
  ) {
    delegate?.bannerDidFailToLoad(with: error.toSDKNSError())
  }

  func didHide(_ ad: AdSurgeAd) {
    delegate?.bannerDidHide()
  }

  func didClick(_ ad: AdSurgeAd) {
    delegate?.bannerDidClick()
  }

  func didPayRevenue(for ad: AdSurgeAd) {
    delegate?.bannerDidPayRevenue()
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
    delegate?.interstitialDidLoad()
  }

  func didFailToLoadAd(
    forAdUnitIdentifier adUnitIdentifier: String, withError error: AdSurgeError
  ) {
    delegate?.interstitialDidFailToLoad(with: error.toSDKNSError())
  }

  func didDisplay(_ ad: AdSurgeAd, withError error: AdSurgeError?) {
    if let error {
      delegate?.interstitialDidFailToDisplay(with: error.toSDKNSError())
    } else {
      delegate?.interstitialDidDisplay()
    }
  }

  func didHide(_ ad: AdSurgeAd) {
    delegate?.interstitialDidHide()
  }

  func didClick(_ ad: AdSurgeAd) {
    delegate?.interstitialDidClick()
  }

  func didPayRevenue(for ad: AdSurgeAd) {
    delegate?.interstitialDidPayRevenue()
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
    delegate?.rewardedDidLoad()
  }

  func didFailToLoadAd(
    forAdUnitIdentifier adUnitIdentifier: String, withError error: AdSurgeError
  ) {
    delegate?.rewardedDidFailToLoad(with: error.toSDKNSError())
  }

  func didDisplay(_ ad: AdSurgeAd, withError error: AdSurgeError?) {
    if let error {
      delegate?.rewardedDidFailToDisplay(with: error.toSDKNSError())
    } else {
      delegate?.rewardedDidDisplay()
    }
  }

  func didHide(_ ad: AdSurgeAd) {
    delegate?.rewardedDidHide()
  }

  func didClick(_ ad: AdSurgeAd) {
    delegate?.rewardedDidClick()
  }

  func didRewardUser(for ad: AdSurgeAd, with reward: AdSurgeReward) {
    delegate?.rewardedDidRewardUser()
  }

  func didPayRevenue(for ad: AdSurgeAd) {
    delegate?.rewardedDidPayRevenue()
  }

}

extension AdSurgeError {

  /// Converts an error reported by the AdSurge SDK into an `NSError` in the AdSurge SDK error
  /// domain, keeping the SDK's own error code and message.
  func toSDKNSError() -> NSError {
    return Util.error(withDomain: Util.sdkErrorDomain, code: code.rawValue, description: message)
  }

}
