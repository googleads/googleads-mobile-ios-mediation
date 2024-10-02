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

  /// The MolocoBannerAdView. MolocoBannerAdView type on iOS 13+, otherwise nil.
  private var bannerAdView: AnyObject?

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

  @MainActor
  func loadAd() {
    guard #available(iOS 13.0, *) else {
      let error = MolocoUtils.error(
        code: MolocoAdapterErrorCode.adServingNotSupported,
        description: "Moloco SDK does not support serving ads on iOS 12 and below")
      _ = loadCompletionHandler(nil, error)
      return
    }

    let molocoAdUnitID = MolocoUtils.getAdUnitId(from: adConfiguration)
    guard let molocoAdUnitID else {
      let error = MolocoUtils.error(
        code: MolocoAdapterErrorCode.invalidAdUnitId, description: "Missing required parameter")
      _ = loadCompletionHandler(nil, error)
      return
    }

    let banner = self.molocoBannerFactory.createBanner(for: molocoAdUnitID, delegate: self)
    self.bannerAdView = banner
    banner?.load(bidResponse: self.adConfiguration.bidResponse ?? "")
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
    eventDelegate = loadCompletionHandler(self, nil)
  }

  func failToLoad(ad: MolocoAd, with error: Error?) {
    _ = loadCompletionHandler(nil, error)
  }

  func didShow(ad: MolocoAd) {
    // TODO: b/368608855 - Add Implementation.
  }

  func failToShow(ad: MolocoAd, with error: Error?) {
    // TODO: b/368608855 - Add Implementation.
  }

  func didHide(ad: MolocoAd) {
    MolocoUtils.log("The Moloco banner ad did hide.")
  }

  func didClick(on ad: MolocoAd) {
    eventDelegate?.reportClick()
  }

}
