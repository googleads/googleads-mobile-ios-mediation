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

import Foundation
import GoogleMobileAds
import UIKit

/// An error reported by the AdSurge SDK, as plain values so that no SDK types are needed outside
/// `AdSurgeClientImpl`.
struct AdSurgeSDKError: Error, Equatable {

  /// The SDK's error code.
  let code: Int

  /// The SDK's error message.
  let message: String

}

/// Factory that creates `AdSurgeClient` instances.
final class AdSurgeClientFactory {

  private init() {}

  #if DEBUG
    /// If set, `createClient()` returns this client instead of a new `AdSurgeClientImpl`.
    nonisolated(unsafe) static var debugClient: (any AdSurgeClient)?
  #endif

  static func createClient() -> any AdSurgeClient {
    #if DEBUG
      return debugClient ?? AdSurgeClientImpl()
    #else
      return AdSurgeClientImpl()
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

/// Receives the events of a full-screen (interstitial or rewarded) ad from the AdSurge client.
protocol FullScreenAdClientDelegate: AnyObject, Sendable {

  /// Called when the ad has been successfully loaded.
  func didLoad()

  /// Called when the ad fails to load.
  func didFailToLoad(error: AdSurgeSDKError)

  /// Called when the ad is presented on screen, or fails to be presented (for example, when the
  /// user declines the AdSurge consent page), in which case `error` is the SDK's error.
  func didDisplay(error: AdSurgeSDKError?)

  /// Called when the ad is clicked.
  func didClick()

  /// Called when the ad is hidden.
  func didHide()

  /// Called when AdSurge counts an impression for the ad.
  func didPayRevenue()

}

/// Receives the events of a rewarded ad from the AdSurge client.
protocol RewardedAdClientDelegate: FullScreenAdClientDelegate {

  /// Called when the ad grants a reward.
  func didRewardUser()

}

/// Everything the adapter needs from the AdSurge SDK.
protocol AdSurgeClient: AnyObject, Sendable {

  /// Sets user age restriction privacy status.
  func setAgeRestrictedUser(_ ageRestrictedUser: NSNumber)

  /// Initializes the AdSurge SDK with an application ID.
  ///
  /// - Returns: Whether initialization succeeded, and the error the SDK reported, if any.
  func initialize(appId: String) async -> (success: Bool, error: AdSurgeSDKError?)

  /// Retrieves a bidder token from the AdSurge SDK.
  ///
  /// - Returns: The bidder token and the error the SDK reported, either of which may be `nil`.
  func getBidderToken() async -> (token: String?, error: AdSurgeSDKError?)

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

  /// Loads an interstitial ad from AdSurge. The ad reports its events to `delegate`.
  func loadInterstitialAd(
    adUnitId: String,
    bidPayload: String,
    delegate: any FullScreenAdClientDelegate
  )

  /// Returns whether the loaded interstitial ad is ready to be shown.
  func isInterstitialAdReady() -> Bool

  /// Shows the loaded interstitial ad.
  func showInterstitialAd(from rootViewController: UIViewController)

  /// Loads a rewarded ad from AdSurge. The ad reports its events to `delegate`.
  func loadRewardedAd(
    adUnitId: String,
    bidPayload: String,
    delegate: any RewardedAdClientDelegate
  )

  /// Returns whether the loaded rewarded ad is ready to be shown.
  func isRewardedAdReady() -> Bool

  /// Shows the loaded rewarded ad.
  func showRewardedAd(from rootViewController: UIViewController)

}
