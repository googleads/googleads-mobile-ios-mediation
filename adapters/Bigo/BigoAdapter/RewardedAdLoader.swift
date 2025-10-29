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

import BigoADS
import Foundation
import GoogleMobileAds

final class RewardedAdLoader: NSObject {

  /// The rewarded ad configuration.
  private let adConfiguration: MediationRewardedAdConfiguration

  /// The ad event delegate which is used to report rewarded related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationRewardedAdEventDelegate?

  /// The completion handler that needs to be called upon finishing loading an ad.
  private var rewardedAdLoadCompletionHandler: ((MediationRewardedAd?, NSError?) -> Void)?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationRewardedLoadCompletionHandler?

  private let client: BigoClient

  private var rewardAd: BigoRewardVideoAd?

  init(
    adConfiguration: MediationRewardedAdConfiguration,
    loadCompletionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationRewardedAdLoadCompletionQueue")
    self.client = BigoClientFactory.createClient()
    super.init()
  }

  func loadAd() {
    guard let bidResponse = adConfiguration.bidResponse else {
      handleLoadedAd(
        nil,
        error: BigoAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing bid response."
        ).toNSError())
      return
    }

    guard let watermark = adConfiguration.watermark else {
      handleLoadedAd(
        nil,
        error: BigoAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing watermark."
        ).toNSError())
      return
    }

    do {
      let slotId = try Util.slotId(from: adConfiguration)
      client.loadRTBRewardVideoAd(
        for: slotId, bidPayLoad: bidResponse, watermark: watermark, delegate: self)
    } catch {
      handleLoadedAd(nil, error: error.toNSError())
    }
  }

  private func handleLoadedAd(_ ad: MediationRewardedAd?, error: Error?) {
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      eventDelegate = adLoadCompletionHandler(ad, error)
      self.adLoadCompletionHandler = nil
    }
  }

}

// MARK: - BigoRewardVideoAdLoaderDelegate

extension RewardedAdLoader: BigoRewardVideoAdLoaderDelegate {

  func onRewardVideoAdLoaded(_ ad: BigoRewardVideoAd) {
    rewardAd = ad
    handleLoadedAd(self, error: nil)
  }

  func onRewardVideoAdLoadError(_ error: BigoAdError) {
    handleLoadedAd(nil, error: Util.NSError(from: error))
  }

}

// MARK: - BigoRewardVideoAdInteractionDelegate

extension RewardedAdLoader: BigoRewardVideoAdInteractionDelegate {

  func onAd(_ ad: BigoAd, error: BigoAdError) {
    Util.log(
      "Encountered an issue for the rewarded ad with error code: \(error.errorCode) with following message: \(error.errorMsg)"
    )
    eventDelegate?.didFailToPresentWithError(Util.NSError(from: error))
  }

  func onAdImpression(_ ad: BigoAd) {
    eventDelegate?.reportImpression()
  }

  func onAdClicked(_ ad: BigoAd) {
    eventDelegate?.reportClick()
  }

  func onAdOpened(_ ad: BigoAd) {
    // Google does not have equivalent callback function.
    Util.log("The rewarded ad has been opened.")
  }

  func onAdClosed(_ ad: BigoAd) {
    eventDelegate?.didDismissFullScreenView()
    rewardAd?.destroy()
    rewardAd = nil
  }

  func onAdRewarded(_ ad: BigoRewardVideoAd) {
    eventDelegate?.didRewardUser()
  }

}

// MARK: - GADMediationRewardAd

extension RewardedAdLoader: MediationRewardedAd {

  func present(from viewController: UIViewController) {
    guard let rewardAd else {
      eventDelegate?.didFailToPresentWithError(
        BigoAdapterError(
          errorCode: .adIsNotReadyForPresentation, description: "Rewarded ad is not available."))
      return
    }

    guard !rewardAd.isExpired() else {
      eventDelegate?.didFailToPresentWithError(
        BigoAdapterError(
          errorCode: .adIsNotReadyForPresentation, description: "Rewarded ad has been expired."))
      return
    }

    eventDelegate?.willPresentFullScreenView()
    client.presentRewardVideoAd(
      rewardAd, viewController: viewController, interactionDelegate: self)
  }

}
