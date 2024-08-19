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

/// Loads and presents rewarded ads on Moloco ads SDK.
final class RewardedAdLoader: NSObject {

  /// The rewarded ad configuration.
  private let adConfiguration: GADMediationRewardedAdConfiguration

  /// The ad event delegate which is used to report rewarded related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: GADMediationRewardedAdEventDelegate?

  /// The completion handler to call when the rewarded ad loading succeeds or fails.
  private let loadCompletionHandler: GADMediationRewardedLoadCompletionHandler

  init(
    adConfiguration: GADMediationRewardedAdConfiguration,
    loadCompletionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.loadCompletionHandler = loadCompletionHandler
    super.init()
  }

  func loadAd() {
    guard #available(iOS 13.0, *) else {
      let error = MolocoUtils.error(
        code: MolocoAdapterErrorCode.adServingNotSupported,
        description: "Moloco SDK does not support serving ads on iOS 12 and below")
      _ = loadCompletionHandler(nil, error)
      return
    }

    let molocoAdUnitID = MolocoUtils.getAdUnitId(from: adConfiguration)
    guard let molocoAdUnitID = molocoAdUnitID else {
      let error = MolocoUtils.error(
        code: MolocoAdapterErrorCode.invalidAdUnitId, description: "Missing required parameter")
      _ = loadCompletionHandler(nil, error)
      return
    }

    // TODO(kricheso): Load the ad.
  }

}

// MARK: - GADMediationRewardedAd

extension RewardedAdLoader: GADMediationRewardedAd {

  func present(from viewController: UIViewController) {
    eventDelegate?.willPresentFullScreenView()
    // TODO: implement
  }

}

// MARK: - <OtherProtocol>
// TODO: extend and implement any other protocol, if any.
