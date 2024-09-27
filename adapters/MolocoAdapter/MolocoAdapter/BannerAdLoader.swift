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

/// Loads banner ads on Moloco ads SDK.
final class BannerAdLoader: NSObject {

  /// The banner ad configuration.
  private let adConfiguration: GADMediationBannerAdConfiguration

  /// The ad event delegate which is used to report banner related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: GADMediationBannerAdEventDelegate?

  /// The completion handler to call when the rewarded ad loading succeeds or fails.
  private let loadCompletionHandler: GADMediationBannerLoadCompletionHandler

  /// The factory class used to create banner ads.
  private let molocoBannerFactory: MolocoBannerFactory

  init(
    adConfiguration: GADMediationBannerAdConfiguration,
    molocoBannerFactory: MolocoBannerFactory,
    loadCompletionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.loadCompletionHandler = loadCompletionHandler
    self.molocoBannerFactory = molocoBannerFactory
    super.init()
  }

  func loadAd() {
    // TODO: implement and make sure to call |loadCompletionHandler| after loading an ad with
    // |molocoBannerFactory|.
  }

}

// MARK: - GADMediationBannerAd

extension BannerAdLoader: GADMediationBannerAd {
  var view: UIView {
    // TODO: implement
    return UIView()
  }
}

// MARK: - MolocoBannerDelegate

extension BannerAdLoader: MolocoBannerDelegate {

  func didLoad(ad: MolocoAd) {
    // TODO: b/368608855 - Add Implementation.
  }

  func failToLoad(ad: MolocoAd, with error: Error?) {
    // TODO: b/368608855 - Add Implementation.
  }

  func didShow(ad: MolocoAd) {
    // TODO: b/368608855 - Add Implementation.
  }

  func failToShow(ad: MolocoAd, with error: Error?) {
    // TODO: b/368608855 - Add Implementation.
  }

  func didHide(ad: MolocoAd) {
    // TODO: b/368608855 - Add Implementation.
  }

  func didClick(on ad: MolocoAd) {
    // TODO: b/368608855 - Add Implementation.
  }

}
