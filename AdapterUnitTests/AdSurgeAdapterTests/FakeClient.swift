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

final class FakeClient: NSObject, Client, @unchecked Sendable {

  var ageRestrictedUser: NSNumber?
  var applicationId: String?
  var initializeShouldSucceed: Bool = true
  var bidderTokenToReturn: String? = "mock_bidder_token"
  var sdkVersionString: String = "1.9.2"

  func setAgeRestrictedUser(_ ageRestrictedUser: NSNumber?) {
    self.ageRestrictedUser = ageRestrictedUser
  }

  func initialize(with appId: String) async throws {
    self.applicationId = appId
    guard initializeShouldSucceed else {
      throw AdSurgeAdapterError(
        errorCode: .serverConfigurationMissingApplicationId,
        description: "Fake initialization failed.")
    }
  }

  func getBidderToken() async throws -> String {
    guard let token = bidderTokenToReturn else {
      throw AdSurgeAdapterError(
        errorCode: .invalidRTBRequestParameters,
        description: "Fake bidder token retrieval failed.")
    }
    return token
  }

  func version() -> String {
    return sdkVersionString
  }

  // MARK: - Banner Mock

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

  // MARK: - Interstitial Mock

  var loadInterstitialShouldSucceed: Bool = true
  var loadedInterstitialAdUnitId: String?
  var loadedInterstitialBidPayload: String?
  weak var interstitialDelegate: (any InterstitialAdClientDelegate)?
  var showInterstitialCount: Int = 0
  var lastPresentedViewController: UIViewController?

  func loadInterstitialAd(
    for adUnitId: String,
    bidPayload: String,
    delegate: any InterstitialAdClientDelegate
  ) {
    loadedInterstitialAdUnitId = adUnitId
    loadedInterstitialBidPayload = bidPayload
    interstitialDelegate = delegate
    if loadInterstitialShouldSucceed {
      delegate.interstitialDidLoad()
    } else {
      let error = AdSurgeAdapterError(
        errorCode: .internalError,
        description: "Simulated interstitial load failure."
      ).toNSError()
      delegate.interstitialDidFailToLoad(with: error)
    }
  }

  func showInterstitialAd(from rootViewController: UIViewController) {
    showInterstitialCount += 1
    lastPresentedViewController = rootViewController
  }

  func simulateInterstitialDisplay(error: (any Error)? = nil) {
    if let error {
      interstitialDelegate?.interstitialDidFailToDisplay(with: error)
    } else {
      interstitialDelegate?.interstitialDidDisplay()
    }
  }

  func simulateInterstitialClick() {
    interstitialDelegate?.interstitialDidClick()
  }

  func simulateInterstitialHide() {
    interstitialDelegate?.interstitialDidHide()
  }

  func simulateInterstitialPayRevenue() {
    interstitialDelegate?.interstitialDidPayRevenue()
  }

  // MARK: - Rewarded Mock

  var loadRewardedShouldSucceed: Bool = true
  var loadedRewardedAdUnitId: String?
  var loadedRewardedBidPayload: String?
  weak var rewardedDelegate: (any RewardedAdClientDelegate)?
  var showRewardedCount: Int = 0
  var lastPresentedRewardedViewController: UIViewController?

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

  func showRewardedAd(from rootViewController: UIViewController) {
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
    applicationId = nil
    initializeShouldSucceed = true
    bidderTokenToReturn = "mock_bidder_token"
    sdkVersionString = "1.9.2"
    loadBannerShouldSucceed = true
    createdBannerAdUnitId = nil
    loadedBannerBidPayload = nil
    loadedBannerViewController = nil
    bannerDelegate = nil
    mockBannerView = nil
    loadInterstitialShouldSucceed = true
    loadedInterstitialAdUnitId = nil
    loadedInterstitialBidPayload = nil
    interstitialDelegate = nil
    showInterstitialCount = 0
    lastPresentedViewController = nil
    loadRewardedShouldSucceed = true
    loadedRewardedAdUnitId = nil
    loadedRewardedBidPayload = nil
    rewardedDelegate = nil
    showRewardedCount = 0
    lastPresentedRewardedViewController = nil
  }

}
