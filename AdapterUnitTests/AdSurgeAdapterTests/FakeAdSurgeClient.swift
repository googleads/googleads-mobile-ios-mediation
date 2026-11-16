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

@testable import AdSurgeAdapter

final class FakeAdSurgeClient: NSObject, AdSurgeClient, @unchecked Sendable {

  var ageRestrictedUser: NSNumber?
  var setAgeRestrictedUserCallCount = 0
  var applicationId: String?

  /// The result `initialize` returns.
  var initializeResult: (success: Bool, error: AdSurgeSDKError?) = (true, nil)

  /// The result `getBidderToken` returns.
  var bidderTokenResult: (token: String?, error: AdSurgeSDKError?) = ("mock_bidder_token", nil)

  var sdkVersionString: String = "2.0.1"

  func setAgeRestrictedUser(_ ageRestrictedUser: NSNumber) {
    setAgeRestrictedUserCallCount += 1
    self.ageRestrictedUser = ageRestrictedUser
  }

  func initialize(appId: String) async -> (success: Bool, error: AdSurgeSDKError?) {
    applicationId = appId
    return initializeResult
  }

  func getBidderToken() async -> (token: String?, error: AdSurgeSDKError?) {
    return bidderTokenResult
  }

  func version() -> String {
    return sdkVersionString
  }

  // MARK: - Banner

  var loadBannerShouldSucceed: Bool = true
  var createdBannerAdUnitId: String?
  var loadedBannerBidPayload: String?
  var loadedBannerViewController: UIViewController?
  weak var bannerDelegate: (any BannerAdClientDelegate)?
  var mockBannerView: UIView?

  @MainActor func createBannerAdView(for adUnitId: String) -> UIView {
    createdBannerAdUnitId = adUnitId
    return mockBannerView ?? UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
  }

  @MainActor func loadBannerAd(
    _ bannerView: UIView,
    bidPayload: String,
    viewController: UIViewController?,
    delegate: any BannerAdClientDelegate
  ) {
    loadedBannerBidPayload = bidPayload
    loadedBannerViewController = viewController
    bannerDelegate = delegate
    if loadBannerShouldSucceed {
      delegate.bannerDidLoad()
    } else {
      let error = AdSurgeAdapterError(
        errorCode: .internalError,
        description: "Simulated banner load failure."
      ).toNSError()
      delegate.bannerDidFailToLoad(with: error)
    }
  }

  func simulateBannerClick() {
    bannerDelegate?.bannerDidClick()
  }

  func simulateBannerHide() {
    bannerDelegate?.bannerDidHide()
  }

  func simulateBannerPayRevenue() {
    bannerDelegate?.bannerDidPayRevenue()
  }

  // MARK: - Interstitial

  /// The error the interstitial ad reports after `loadInterstitialAd` returns, or `nil` to report a
  /// successful load.
  var interstitialLoadError: AdSurgeSDKError?
  var loadedInterstitialAdUnitId: String?
  var loadedInterstitialBidPayload: String?
  weak var interstitialDelegate: (any FullScreenAdClientDelegate)?
  var interstitialAdReady = true
  var showInterstitialCount = 0
  var lastPresentedViewController: UIViewController?

  func loadInterstitialAd(
    adUnitId: String,
    bidPayload: String,
    delegate: any FullScreenAdClientDelegate
  ) {
    loadedInterstitialAdUnitId = adUnitId
    loadedInterstitialBidPayload = bidPayload
    interstitialDelegate = delegate
    let loadError = interstitialLoadError
    // Reports the result asynchronously, like the AdSurge SDK.
    DispatchQueue.main.async { [weak delegate] in
      if let loadError {
        delegate?.didFailToLoad(error: loadError)
      } else {
        delegate?.didLoad()
      }
    }
  }

  func isInterstitialAdReady() -> Bool {
    return interstitialAdReady
  }

  func showInterstitialAd(from rootViewController: UIViewController) {
    showInterstitialCount += 1
    lastPresentedViewController = rootViewController
  }

  func simulateInterstitialDisplay(error: AdSurgeSDKError? = nil) {
    interstitialDelegate?.didDisplay(error: error)
  }

  func simulateInterstitialClick() {
    interstitialDelegate?.didClick()
  }

  func simulateInterstitialHide() {
    interstitialDelegate?.didHide()
  }

  func simulateInterstitialPayRevenue() {
    interstitialDelegate?.didPayRevenue()
  }

  // MARK: - Rewarded

  var loadRewardedShouldSucceed: Bool = true
  var loadedRewardedAdUnitId: String?
  var loadedRewardedBidPayload: String?
  weak var rewardedDelegate: (any RewardedAdClientDelegate)?
  var showRewardedCount: Int = 0
  var lastPresentedRewardedViewController: UIViewController?
  var showRewardedError: AdSurgeAdapterError?

  func loadRewardedAd(
    for adUnitId: String,
    bidPayload: String,
    delegate: any RewardedAdClientDelegate
  ) {
    loadedRewardedAdUnitId = adUnitId
    loadedRewardedBidPayload = bidPayload
    rewardedDelegate = delegate
    if loadRewardedShouldSucceed {
      delegate.rewardedDidLoad()
    } else {
      let error = AdSurgeAdapterError(
        errorCode: .internalError,
        description: "Simulated rewarded load failure."
      ).toNSError()
      delegate.rewardedDidFailToLoad(with: error)
    }
  }

  func showRewardedAd(from rootViewController: UIViewController) throws(AdSurgeAdapterError) {
    if let showRewardedError {
      throw showRewardedError
    }
    showRewardedCount += 1
    lastPresentedRewardedViewController = rootViewController
  }

  func simulateRewardedDisplay(error: (any Error)? = nil) {
    if let error {
      rewardedDelegate?.rewardedDidFailToDisplay(with: error)
    } else {
      rewardedDelegate?.rewardedDidDisplay()
    }
  }

  func simulateRewardedClick() {
    rewardedDelegate?.rewardedDidClick()
  }

  func simulateRewardedHide() {
    rewardedDelegate?.rewardedDidHide()
  }

  func simulateRewardedRewardUser() {
    rewardedDelegate?.rewardedDidRewardUser()
  }

  func simulateRewardedPayRevenue() {
    rewardedDelegate?.rewardedDidPayRevenue()
  }

  func reset() {
    ageRestrictedUser = nil
    setAgeRestrictedUserCallCount = 0
    applicationId = nil
    initializeResult = (true, nil)
    bidderTokenResult = ("mock_bidder_token", nil)
    sdkVersionString = "2.0.1"
    loadBannerShouldSucceed = true
    createdBannerAdUnitId = nil
    loadedBannerBidPayload = nil
    loadedBannerViewController = nil
    bannerDelegate = nil
    mockBannerView = nil
    interstitialLoadError = nil
    loadedInterstitialAdUnitId = nil
    loadedInterstitialBidPayload = nil
    interstitialDelegate = nil
    interstitialAdReady = true
    showInterstitialCount = 0
    lastPresentedViewController = nil
    loadRewardedShouldSucceed = true
    loadedRewardedAdUnitId = nil
    loadedRewardedBidPayload = nil
    rewardedDelegate = nil
    showRewardedError = nil
    showRewardedCount = 0
    lastPresentedRewardedViewController = nil
  }

}
