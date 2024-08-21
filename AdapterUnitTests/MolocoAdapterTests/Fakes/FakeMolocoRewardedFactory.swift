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
import MolocoAdapter
import MolocoSDK

/// A fake implementation of MolocoRewardedFactory that creates a FakeMolocoRewarded.
final class FakeMolocoRewardedFactory {

  let loadError: Error?

  let isReadyToBeShown: Bool

  let showShallSucceed: Bool

  let showError: Error?

  /// Var to capture the ad unit ID that was used to create the Moloco interstitial ad object.
  /// Used for assertion. It is initlialized to a value that is never asserted for.
  var adUnitIDUsedToCreateMolocoAd: String = ""

  var fakeMolocoRewarded: FakeMolocoRewarded?

  /// The parameters passed here are used to create FakeMolocoRewarded. See FakeMolocoRewarded for
  /// how these parameters are used.
  init(
    loadError: Error?, isReadyToBeShown: Bool = false, showShallSucceed: Bool = true,
    showError: Error? = nil
  ) {
    self.loadError = loadError
    self.isReadyToBeShown = isReadyToBeShown
    self.showShallSucceed = showShallSucceed
    self.showError = showError
  }

}

// MARK: - MolocoRewardedFactory

extension FakeMolocoRewardedFactory: MolocoRewardedFactory {

  func createRewarded(for adUnit: String, delegate: any MolocoSDK.MolocoRewardedDelegate) -> (
    any MolocoSDK.MolocoRewardedInterstitial
  )? {
    adUnitIDUsedToCreateMolocoAd = adUnit
    fakeMolocoRewarded = FakeMolocoRewarded(rewardedDelegate: delegate, loadError: loadError)
    return fakeMolocoRewarded
  }

}
