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

final class InterstitialAdLoader: NSObject, MediationInterstitialAd, @unchecked Sendable {

  private let adConfiguration: MediationInterstitialAdConfiguration
  private var adLoadCompletionHandler: GADMediationInterstitialLoadCompletionHandler?

  init(
    adConfiguration: MediationInterstitialAdConfiguration,
    loadCompletionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    super.init()
  }

  func loadAd() {
    _ = adLoadCompletionHandler?(
      nil,
      AdSurgeAdapterError(
        errorCode: .invalidAdConfiguration,
        description: "Interstitial ad loading not yet supported."
      ).toNSError())
    adLoadCompletionHandler = nil
  }

  func present(from viewController: UIViewController) {}

}
