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

/// A fake implementation of MolocoNativeFactory that creates a FakeMolocoNative.
final class FakeMolocoNativeFactory {

  let loadError: Error?

  let isReadyToBeShown: Bool

  let showError: Error?

  /// Var to capture the ad unit ID that was used to create the Moloco  ad object.
  /// Used for assertion. It is initlialized to a value that is never asserted for.
  var adUnitIDUsedToCreateMolocoAd: String = ""

  var fakeMolocoNative: FakeMolocoNativeAd?

  /// The parameters passed here are used to create FakeMolocoNative. See FakeMolocoNative for
  /// how these parameters are used.
  init(
    loadError: Error?, isReadyToBeShown: Bool = true, showError: Error? = nil
  ) {
    self.loadError = loadError
    self.isReadyToBeShown = isReadyToBeShown
    self.showError = showError
  }

}

// MARK: - MolocoNativeFactory

extension FakeMolocoNativeFactory: MolocoNativeFactory {
  func createNativeAd(
    for adUnit: String, delegate: any MolocoSDK.MolocoNativeAdDelegate, watermarkData: Data?
  ) -> (
    any MolocoSDK.MolocoNativeAd
  )? {
    adUnitIDUsedToCreateMolocoAd = adUnit
    fakeMolocoNative = FakeMolocoNativeAd(
      nativeDelegate: delegate, loadError: loadError, isReadyToBeShown: isReadyToBeShown,
      showError: showError)
    return fakeMolocoNative
  }

}
