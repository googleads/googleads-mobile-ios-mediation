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

final class RewardedAdLoader: NSObject, MediationRewardedAd, RewardedAdClientDelegate,
  @unchecked Sendable
{

  private let adConfiguration: MediationRewardedAdConfiguration
  private var adLoadCompletionHandler: GADMediationRewardedLoadCompletionHandler?
  private weak var eventDelegate: MediationRewardedAdEventDelegate?
  private let client: any Client

  init(
    adConfiguration: MediationRewardedAdConfiguration,
    loadCompletionHandler: @escaping GADMediationRewardedLoadCompletionHandler,
    client: any Client = ClientFactory.createClient()
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.client = client
    super.init()
  }

  func loadAd() {
    do {
      let adUnitId = try Util.adUnitID(from: adConfiguration)
      let bidResponse = try Util.bidResponse(from: adConfiguration)
      client.loadRewardedAd(
        for: adUnitId,
        bidPayload: bidResponse,
        delegate: self
      )
    } catch {
      _ = adLoadCompletionHandler?(nil, error.toNSError())
      adLoadCompletionHandler = nil
    }
  }

  func present(from viewController: UIViewController) {
    client.showRewardedAd(from: viewController)
  }

  // MARK: - RewardedAdClientDelegate

  func rewardedDidLoad() {
    eventDelegate = adLoadCompletionHandler?(self, nil)
    adLoadCompletionHandler = nil
  }

  func rewardedDidFailToLoad(with error: any Error) {
    _ = adLoadCompletionHandler?(nil, error.toNSError())
    adLoadCompletionHandler = nil
  }

  func rewardedDidDisplay() {
    eventDelegate?.willPresentFullScreenView()
    eventDelegate?.reportImpression()
  }

  func rewardedDidFailToDisplay(with error: any Error) {
    eventDelegate?.didFailToPresentWithError(error.toNSError())
  }

  func rewardedDidClick() {
    eventDelegate?.reportClick()
  }

  func rewardedDidHide() {
    eventDelegate?.willDismissFullScreenView()
    eventDelegate?.didDismissFullScreenView()
  }

  func rewardedDidRewardUser() {
    eventDelegate?.didRewardUser()
  }

  func rewardedDidPayRevenue() {
    eventDelegate?.reportImpression()
  }

}
