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
import GoogleMobileAds
import ObjectiveC
import UIKit

/// Factory that creates Client.
final class ClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: (any Client)?
  #endif

  static func createClient() -> any Client {
    #if DEBUG
      return debugClient ?? ClientImpl()
    #else
      return ClientImpl()
    #endif
  }

}

/// Delegate protocol for banner ad lifecycle events from the AdSurge client.
protocol BannerAdClientDelegate: AnyObject, Sendable {

  /// Called when a banner ad has been successfully loaded.
  func bannerDidLoad()

  /// Called when a banner ad fails to load.
  func bannerDidFailToLoad(with error: any Error)

  /// Called when a banner ad is clicked.
  func bannerDidClick()

  /// Called when a banner ad is hidden.
  func bannerDidHide()

  /// Called when a banner ad generates revenue (impression).
  func bannerDidPayRevenue()

}

/// Delegate protocol for interstitial ad lifecycle events from the AdSurge client.
protocol InterstitialAdClientDelegate: AnyObject, Sendable {

  /// Called when an interstitial ad has been successfully loaded.
  func interstitialDidLoad()

  /// Called when an interstitial ad fails to load.
  func interstitialDidFailToLoad(with error: any Error)

  /// Called when an interstitial ad is displayed.
  func interstitialDidDisplay()

  /// Called when an interstitial ad fails to display.
  func interstitialDidFailToDisplay(with error: any Error)

  /// Called when an interstitial ad is clicked.
  func interstitialDidClick()

  /// Called when an interstitial ad is hidden.
  func interstitialDidHide()

  /// Called when an interstitial ad generates revenue (impression).
  func interstitialDidPayRevenue()

}

/// Delegate protocol for receiving rewarded ad callbacks from Client.
protocol RewardedAdClientDelegate: AnyObject, Sendable {

  /// Called when a rewarded ad loads successfully.
  func rewardedDidLoad()

  /// Called when a rewarded ad fails to load.
  func rewardedDidFailToLoad(with error: any Error)

  /// Called when a rewarded ad is displayed.
  func rewardedDidDisplay()

  /// Called when a rewarded ad fails to display.
  func rewardedDidFailToDisplay(with error: any Error)

  /// Called when a rewarded ad is clicked.
  func rewardedDidClick()

  /// Called when a rewarded ad is hidden.
  func rewardedDidHide()

  /// Called when a rewarded ad grants a reward.
  func rewardedDidRewardUser()

  /// Called when a rewarded ad generates revenue (impression).
  func rewardedDidPayRevenue()

}

protocol Client: AnyObject, Sendable {

  /// Sets user age restriction privacy status.
  func setAgeRestrictedUser(_ ageRestrictedUser: NSNumber?)

  /// Initializes the AdSurge SDK with an application ID.
  func initialize(with appId: String) async throws

  /// Retrieves a bidder token from the AdSurge SDK.
  func getBidderToken() async throws -> String

  /// Returns the SDK version string.
  func version() -> String

  /// Creates a banner ad view for the given ad unit identifier.
  @MainActor func createBannerAdView(for adUnitId: String) -> UIView

  /// Loads a banner ad into the provided banner view.
  @MainActor func loadBannerAd(
    _ bannerView: UIView,
    bidPayload: String,
    viewController: UIViewController?,
    delegate: any BannerAdClientDelegate
  )

  /// Loads an interstitial ad from AdSurge.
  func loadInterstitialAd(
    for adUnitId: String,
    bidPayload: String,
    delegate: any InterstitialAdClientDelegate
  )

  /// Shows the loaded interstitial ad.
  func showInterstitialAd(from rootViewController: UIViewController)

  /// Loads a rewarded ad from AdSurge.
  func loadRewardedAd(
    for adUnitId: String,
    bidPayload: String,
    delegate: any RewardedAdClientDelegate
  )

  /// Shows the loaded rewarded ad.
  func showRewardedAd(from rootViewController: UIViewController)

}

final class ClientImpl: Client, @unchecked Sendable {

  func setAgeRestrictedUser(_ ageRestrictedUser: NSNumber?) {
    if let ageRestrictedUser {
      AdSurgePrivacyConfiguration().ageRestrictedUser = ageRestrictedUser
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
          let nsError: NSError
          if let error {
            nsError = Util.error(
              withDomain: AdSurgeAdapterError.domain,
              code: error.code.rawValue,
              description: error.message)
          } else {
            nsError = AdSurgeAdapterError(
              errorCode: .serverConfigurationMissingApplicationId,
              description: "AdSurge SDK failed to initialize."
            ).toNSError()
          }
          continuation.resume(throwing: nsError)
        }
      }
    }
  }

  func getBidderToken() async throws -> String {
    return try await withCheckedThrowingContinuation { continuation in
      AdSurgeAdSdk.shared().getBidderToken { token, error in
        if let token {
          continuation.resume(returning: token)
        } else {
          let nsError: NSError
          if let error {
            nsError = Util.error(
              withDomain: AdSurgeAdapterError.domain,
              code: error.code.rawValue,
              description: error.message)
          } else {
            nsError = AdSurgeAdapterError(
              errorCode: .invalidRTBRequestParameters,
              description: "Failed to retrieve bidder token."
            ).toNSError()
          }
          continuation.resume(throwing: nsError)
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
    delegate: any InterstitialAdClientDelegate
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

  func showInterstitialAd(from rootViewController: UIViewController) {
    guard let interstitialAd, interstitialAd.isValid else {
      return
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

  func showRewardedAd(from rootViewController: UIViewController) {
    guard let rewardedAd, rewardedAd.isValid else {
      return
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
    let nsError = Util.error(
      withDomain: AdSurgeAdapterError.domain,
      code: error.code.rawValue,
      description: error.message
    )
    delegate?.bannerDidFailToLoad(with: nsError)
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

  private weak var delegate: (any InterstitialAdClientDelegate)?

  init(delegate: any InterstitialAdClientDelegate) {
    self.delegate = delegate
  }

  func didLoad(_ ad: AdSurgeAd) {
    delegate?.interstitialDidLoad()
  }

  func didFailToLoadAd(
    forAdUnitIdentifier adUnitIdentifier: String, withError error: AdSurgeError
  ) {
    let nsError = Util.error(
      withDomain: AdSurgeAdapterError.domain,
      code: error.code.rawValue,
      description: error.message
    )
    delegate?.interstitialDidFailToLoad(with: nsError)
  }

  func didDisplay(_ ad: AdSurgeAd, withError error: AdSurgeError?) {
    if let error {
      let nsError = Util.error(
        withDomain: AdSurgeAdapterError.domain,
        code: error.code.rawValue,
        description: error.message
      )
      delegate?.interstitialDidFailToDisplay(with: nsError)
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
    let nsError = Util.error(
      withDomain: AdSurgeAdapterError.domain,
      code: error.code.rawValue,
      description: error.message
    )
    delegate?.rewardedDidFailToLoad(with: nsError)
  }

  func didDisplay(_ ad: AdSurgeAd, withError error: AdSurgeError?) {
    if let error {
      let nsError = Util.error(
        withDomain: AdSurgeAdapterError.domain,
        code: error.code.rawValue,
        description: error.message
      )
      delegate?.rewardedDidFailToDisplay(with: nsError)
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
