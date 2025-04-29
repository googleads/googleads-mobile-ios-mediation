// Copyright 2024 Google LLC.
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
import MolocoSDK

/// Loads and presents rewarded ads on Moloco ads SDK.
final class RewardedAdLoader: NSObject {

  /// The rewarded ad configuration.
  private let adConfiguration: MediationRewardedAdConfiguration

  /// The ad event delegate which is used to report rewarded related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationRewardedAdEventDelegate?

  /// The completion handler to call when the rewarded ad loading succeeds or fails.
  private let loadCompletionHandler: GADMediationRewardedLoadCompletionHandler

  /// The factory class used to create rewarded ads.
  private let molocoRewardedFactory: MolocoRewardedFactory

  /// The rewarded ad.
  private var rewardedAd: MolocoRewardedInterstitial?

  init(
    adConfiguration: MediationRewardedAdConfiguration,
    loadCompletionHandler: @escaping GADMediationRewardedLoadCompletionHandler,
    molocoRewardedFactory: MolocoRewardedFactory
  ) {
    self.adConfiguration = adConfiguration
    self.loadCompletionHandler = loadCompletionHandler
    self.molocoRewardedFactory = molocoRewardedFactory
    super.init()
  }

  func loadAd() {
    guard #available(iOS 13.0, *) else {
      let error = MolocoUtils.error(
        code: .adServingNotSupported,
        description: "Moloco SDK does not support serving ads on iOS 12 and below")
      _ = loadCompletionHandler(nil, error)
      return
    }

    let molocoAdUnitID = MolocoUtils.getAdUnitId(from: adConfiguration)
    guard let molocoAdUnitID else {
      let error = MolocoUtils.error(
        code: .invalidAdUnitId, description: "Missing required parameter")
      _ = loadCompletionHandler(nil, error)
      return
    }

    guard let bidResponse = adConfiguration.bidResponse else {
      let error = MolocoUtils.error(code: .nilBidResponse, description: "Nil bid response.")
      _ = loadCompletionHandler(nil, error)
      return
    }

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      self.rewardedAd = self.molocoRewardedFactory.createRewarded(
        for: molocoAdUnitID, delegate: self, watermarkData: adConfiguration.watermark)
      self.rewardedAd?.load(bidResponse: bidResponse)
    }
  }

}

// MARK: - MediationRewardedAd

extension RewardedAdLoader: MediationRewardedAd {

  func present(from viewController: UIViewController) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      guard let rewardedAd = self.rewardedAd, rewardedAd.isReady else {
        let error = MolocoUtils.error(
          code: .adNotReadyForShow, description: "Ad is not ready to be shown")
        self.eventDelegate?.didFailToPresentWithError(error)
        return
      }

      self.eventDelegate?.willPresentFullScreenView()
      rewardedAd.show(from: viewController)
    }
  }

}

// MARK: - MolocoRewardedDelegate

extension RewardedAdLoader: MolocoRewardedDelegate {

  func userRewarded(ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.didRewardUser()
  }

  func rewardedVideoStarted(ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.didStartVideo()
  }

  func rewardedVideoCompleted(ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.didEndVideo()
  }

  func didLoad(ad: any MolocoSDK.MolocoAd) {
    eventDelegate = loadCompletionHandler(self, nil)
  }

  func failToLoad(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
    _ = loadCompletionHandler(nil, error)
  }

  func didShow(ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.reportImpression()
  }

  func failToShow(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
    let showError =
      error
      ?? MolocoUtils.error(
        code: .adFailedToShow, description: "Ad failed to show")
    eventDelegate?.didFailToPresentWithError(showError)
  }

  func didHide(ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.didDismissFullScreenView()
  }

  func didClick(on ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.reportClick()
  }

}
