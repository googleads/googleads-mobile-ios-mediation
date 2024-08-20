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

/// A fake implementation of MolocoInterstitialFactory that creates a FakeMolocoInterstitial.
final class FakeMolocoInterstitialFactory: MolocoInterstitialFactory {

  let loadError: NSError?

  let isReadyToBeShown: Bool

  let showShallSucceed: Bool

  let showError: NSError?

  /// Var to capture the ad unit ID that was used to create the Moloco interstitial ad object.
  /// Used for assertion. It is initlialized to a value that is never asserted for.
  var adUnitIDUsedToCreateMolocoAd: String = ""

  var fakeMolocoInterstitial: FakeMolocoInterstitial?

  /// The parameters passed here are used to create FakeMolocoInterstitial. See FakeMolocoInterstitial for
  /// how these parameters are used.
  init(
    loadError: NSError?, isReadyToBeShown: Bool = false, showShallSucceed: Bool = true,
    showError: NSError? = nil
  ) {
    self.loadError = loadError
    self.isReadyToBeShown = isReadyToBeShown
    self.showShallSucceed = showShallSucceed
    self.showError = showError
  }

  func createInterstitial(
    for adUnit: String, delegate: any MolocoSDK.MolocoInterstitialDelegate
  ) -> (any MolocoInterstitial)? {
    adUnitIDUsedToCreateMolocoAd = adUnit
    fakeMolocoInterstitial = FakeMolocoInterstitial(
      interstitialDelegate: delegate, loadError: loadError, isReadyToBeShown: isReadyToBeShown,
      showShallSucceed: showShallSucceed,
      showError: showError)
    return fakeMolocoInterstitial
  }

  func getCreatedMolocoInterstital() -> FakeMolocoInterstitial? {
    return fakeMolocoInterstitial
  }
}
