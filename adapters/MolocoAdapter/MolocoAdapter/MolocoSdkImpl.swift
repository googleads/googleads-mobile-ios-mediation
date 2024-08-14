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

import MolocoSDK

/// Implementation of protocols that calls corresponding Moloco SDK methods.
class MolocoSdkImpl: MolocoInitializer {

  @available(iOS 13.0, *)
  func initialize(
    initParams: MolocoSDK.MolocoInitParams, completion: ((Bool, (any Error)?) -> Void)?
  ) {
    Moloco.shared.initialize(initParams: initParams, completion: completion)
  }

  func isInitialized() -> Bool {
    return Moloco.shared.state.isInitialized
  }

}

// MARK: - MolocoInterstitialFactory

extension MolocoSdkImpl: MolocoInterstitialFactory {

  @MainActor @available(iOS 13.0, *)
  func createInterstitial(for adUnit: String, delegate: any MolocoSDK.MolocoInterstitialDelegate)
    -> (any MolocoSDK.MolocoInterstitial)?
  {
    Moloco.shared.createInterstitial(for: adUnit, delegate: delegate)
  }

}

// MARK: - MolocoRewardedFactory

extension MolocoSdkImpl: MolocoRewardedFactory {

  @MainActor @available(iOS 13.0, *)
  func createRewarded(for adUnit: String, delegate: any MolocoSDK.MolocoRewardedDelegate) -> (
    any MolocoSDK.MolocoRewardedInterstitial
  )? {
    Moloco.shared.createRewarded(for: adUnit, delegate: delegate)
  }

}
