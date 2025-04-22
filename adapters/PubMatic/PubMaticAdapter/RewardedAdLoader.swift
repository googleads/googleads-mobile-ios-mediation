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
import OpenWrapSDK

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

  /// OpenWrapSDKClient used to manage a rewarded ad.
  private let client: OpenWrapSDKClient

  init(
    adConfiguration: MediationRewardedAdConfiguration,
    loadCompletionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationRewardedAdLoadCompletionQueue")
    self.client = OpenWrapSDKClientFactory.createClient()
    super.init()
  }

  func loadAd() {
    guard let bidResponse = adConfiguration.bidResponse, let watermark = adConfiguration.watermark
    else {
      handleLoadedAd(
        nil,
        error: PubMaticAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is invalid."
        ).toNSError())
      return
    }
    client.loadRtbRewardedAd(bidResponse: bidResponse, delegate: self, watermarkData: watermark)
  }

  private func handleLoadedAd(_ ad: MediationRewardedAd?, error: Error?) {
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      eventDelegate = adLoadCompletionHandler(ad, error)
      self.adLoadCompletionHandler = nil
    }
  }

}

// MARK: - GADMediationRewardedAd

extension RewardedAdLoader: MediationRewardedAd {

  func present(from viewController: UIViewController) {
    do {
      try client.presentRewardedAd(from: viewController)
    } catch let error {
      eventDelegate?.didFailToPresentWithError(error.toNSError())
    }
  }

}

// MARK: - POBRewardedAdDelegate

extension RewardedAdLoader: POBRewardedAdDelegate {

  func rewardedAdDidReceive(_ rewardedAd: POBRewardedAd) {
    handleLoadedAd(self, error: nil)
  }

  func rewardedAd(_ rewardedAd: POBRewardedAd, didFailToReceiveAdWithError error: any Error) {
    handleLoadedAd(nil, error: error as NSError)
  }

  func rewardedAdWillPresent(_ rewardedAd: POBRewardedAd) {
    eventDelegate?.willPresentFullScreenView()
  }

  func rewardedAd(_ rewardedAd: POBRewardedAd, didFailToShowAdWithError error: any Error) {
    eventDelegate?.didFailToPresentWithError(error as NSError)
  }

  func rewardedAdDidRecordImpression(_ rewardedAd: POBRewardedAd) {
    eventDelegate?.reportImpression()
  }

  func rewardedAdDidClick(_ rewardedAd: POBRewardedAd) {
    eventDelegate?.reportClick()
  }

  func rewardedAdDidDismiss(_ rewardedAd: POBRewardedAd) {
    eventDelegate?.didDismissFullScreenView()
  }

  func rewardedAd(_ rewardedAd: POBRewardedAd, shouldReward reward: POBReward) {
    eventDelegate?.didRewardUser()
  }

}
