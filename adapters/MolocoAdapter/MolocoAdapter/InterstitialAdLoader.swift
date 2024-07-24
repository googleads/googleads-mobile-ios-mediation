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

/// Loads and presents interstitial ads on Moloco ads SDK.
final class InterstitialAdLoader: NSObject {

  /// The interstitial ad configuration.
  private let adConfiguration: GADMediationInterstitialAdConfiguration

  /// The ad event delegate which is used to report interstitial related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: GADMediationInterstitialAdEventDelegate?

  init(
    adConfiguration: GADMediationInterstitialAdConfiguration,
    loadCompletionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    super.init()
  }

  func loadAd() {
    // TODO: implement and make sure to call |interstitialAdLoadCompletionHandler| after loading an ad.
  }

}

// MARK: - GADMediationInterstitialAd

extension InterstitialAdLoader: GADMediationInterstitialAd {

  func present(from viewController: UIViewController) {
    eventDelegate?.willPresentFullScreenView()
    // TODO: implement
  }

}

// MARK: - <OtherProtocol>
// TODO: extend and implement any other protocol, if any.
