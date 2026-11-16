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

/// Delegate protocol for interstitial ad lifecycle events from the AdSurge client.
protocol FullScreenAdClientDelegate: AnyObject, Sendable {

  /// Called when an interstitial ad has been successfully loaded.
  func interstitialDidLoad()

  /// Called when an interstitial ad fails to load.
  func interstitialDidFailToLoad(with error: any Error)

  /// Called when an interstitial ad is presented on screen.
  func interstitialDidDisplay()

  /// Called when an interstitial ad fails to display, for example, when the user declines the
  /// AdSurge consent page.
  func interstitialDidFailToDisplay(with error: any Error)

  /// Called when an interstitial ad is clicked.
  func interstitialDidClick()

  /// Called when an interstitial ad is hidden.
  func interstitialDidHide()

  /// Called when AdSurge counts an impression for an interstitial ad.
  func interstitialDidPayRevenue()

}

/// Delegate protocol for receiving rewarded ad callbacks from the AdSurge client.
protocol RewardedAdClientDelegate: AnyObject, Sendable {

  /// Called when a rewarded ad loads successfully.
  func rewardedDidLoad()

  /// Called when a rewarded ad fails to load.
  func rewardedDidFailToLoad(with error: any Error)

  /// Called when a rewarded ad is presented on screen.
  func rewardedDidDisplay()

  /// Called when a rewarded ad fails to display, for example, when the user declines the AdSurge
  /// consent page.
  func rewardedDidFailToDisplay(with error: any Error)

  /// Called when a rewarded ad is clicked.
  func rewardedDidClick()

  /// Called when a rewarded ad is hidden.
  func rewardedDidHide()

  /// Called when a rewarded ad grants a reward.
  func rewardedDidRewardUser()

  /// Called when AdSurge counts an impression for a rewarded ad.
  func rewardedDidPayRevenue()

}

/// Everything the adapter needs from the AdSurge SDK.
protocol AdSurgeClient: AnyObject, Sendable {

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
    delegate: any FullScreenAdClientDelegate
  )

  /// Shows the loaded interstitial ad.
  ///
  /// - Throws: `AdSurgeAdapterError` with `.adNotReadyForPresentation` if no valid ad is loaded.
  func showInterstitialAd(from rootViewController: UIViewController) throws(AdSurgeAdapterError)

  /// Loads a rewarded ad from AdSurge.
  func loadRewardedAd(
    for adUnitId: String,
    bidPayload: String,
    delegate: any RewardedAdClientDelegate
  )

  /// Shows the loaded rewarded ad.
  ///
  /// - Throws: `AdSurgeAdapterError` with `.adNotReadyForPresentation` if no valid ad is loaded.
  func showRewardedAd(from rootViewController: UIViewController) throws(AdSurgeAdapterError)

}
