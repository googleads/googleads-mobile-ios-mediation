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

/// A fake implementation of MolocoRewarded.
final class FakeMolocoRewarded {

  /// The load error that occured.
  let loadError: Error?

  /// Var to capture the bid response that was used to load the ad on Moloco SDK. Used for
  /// assertion. It is initlialized to a value that is never asserted for.
  var bidResponseUsedToLoadMolocoAd: String = "nil"

  // MolocoSDK.MolocoRewardedInterstitial properties.
  var rewardedDelegate: (any MolocoSDK.MolocoRewardedDelegate)?
  var fullscreenViewController: UIViewController?
  var isReady: Bool

  /// If loadError is nil, this fake mimics load success. If loadError is not nil, this fake mimics
  /// load failure.
  init(rewardedDelegate: any MolocoSDK.MolocoRewardedDelegate, loadError: Error?) {
    self.rewardedDelegate = rewardedDelegate
    self.loadError = loadError
    self.isReady = false
  }

}

// MARK: - MolocoSDK.MolocoRewardedInterstitial

extension FakeMolocoRewarded: MolocoSDK.MolocoRewardedInterstitial {

  func show(from viewController: UIViewController) {
    // No-op.
  }

  func show(from viewController: UIViewController, muted: Bool) {
    // No-op.
  }

  func load(bidResponse: String) {
    bidResponseUsedToLoadMolocoAd = bidResponse
    guard let loadError else {
      rewardedDelegate?.didLoad(ad: self)
      return
    }
    rewardedDelegate?.failToLoad(ad: self, with: loadError)
  }

  func destroy() {
    // No-op.
  }

}
