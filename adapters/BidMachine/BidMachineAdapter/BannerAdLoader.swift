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

import BidMachine
import Foundation
import GoogleMobileAds

@MainActor
final class BannerAdLoader {

  /// The banner ad configuration.
  private let adConfiguration: MediationBannerAdConfiguration

  /// The ad event delegate which is used to report banner related information to the Google Mobile
  /// Ads SDK.
  private weak var eventDelegate: MediationBannerAdEventDelegate?

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationBannerLoadCompletionHandler?

  private let client: BidMachineClient

  private var bannerAd: MediationBannerAd?

  init(
    adConfiguration: MediationBannerAdConfiguration,
    loadCompletionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.client = BidMachineClientFactory.createClient()
  }

  func loadAd() {
    if let bidResponse = adConfiguration.bidResponse {
      loadRTBAd(with: bidResponse)
    } else {
      loadWaterfallAd()
    }
  }

  private func loadWaterfallAd() {
    do {
      try client.loadWaterfallBannerAd(
        size: adConfiguration.adSize, delegate: self,
        placementId: Util.placementId(from: adConfiguration)
      ) {
        [weak self] banner, error in
        self?.handleLoadedBanner(banner, error: error)
      }
    } catch let error as BidMachineAdapterError {
      handleLoadedAd(nil, error: error.toNSError())
    } catch {
      handleLoadedAd(nil, error: error as NSError)
    }
  }

  private func loadRTBAd(with bidResponse: String) {
    guard let watermark = adConfiguration.watermark?.base64EncodedString() else {
      handleLoadedAd(
        nil,
        error: BidMachineAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing watermark."
        ).toNSError())
      return
    }

    do {
      try client.loadRTBBannerAd(
        with: bidResponse, size: adConfiguration.adSize, delegate: self, watermark: watermark
      ) {
        [weak self] banner, error in
        self?.handleLoadedBanner(banner, error: error)
      }
    } catch let error as BidMachineAdapterError {
      handleLoadedAd(nil, error: error.toNSError())
    } catch {
      handleLoadedAd(nil, error: error as NSError)
    }
  }

  /// Wraps the loaded banner into a mediation banner ad and reports the load result.
  private func handleLoadedBanner(_ banner: BidMachine.BannerView?, error: NSError?) {
    guard let banner else {
      handleLoadedAd(nil, error: error)
      return
    }
    let bannerAd = BannerAd(bannerView: banner)
    self.bannerAd = bannerAd
    handleLoadedAd(bannerAd, error: nil)
  }

  private func handleLoadedAd(_ ad: MediationBannerAd?, error: NSError?) {
    guard let adLoadCompletionHandler else { return }
    eventDelegate = adLoadCompletionHandler(ad, error)
    self.adLoadCompletionHandler = nil
  }

}

// MARK: - BannerViewDelegate

extension BannerAdLoader: BidMachine.BannerViewDelegate {

  func didPresent(_ ad: BidMachine.BannerView) {
  }

  func didFailPresent(_ ad: BidMachine.BannerView, error: BidMachineError) {
    eventDelegate?.didFailToPresentWithError(error)
  }

  func didTrackImpression(_ ad: BidMachine.BannerView) {
    eventDelegate?.reportImpression()
  }

  func didClick(_ ad: BidMachine.BannerView) {
    eventDelegate?.reportClick()
  }

  func willPresentScreen(_ ad: BidMachine.BannerView) {
    eventDelegate?.willPresentFullScreenView()
  }

  func didDismissScreen(_ ad: BidMachine.BannerView) {
    eventDelegate?.willDismissFullScreenView()
    eventDelegate?.didDismissFullScreenView()
  }
}

// MARK: - MediationBannerAd

final class BannerAd: NSObject, MediationBannerAd {
  var view: UIView

  init(bannerView: UIView) {
    view = bannerView
  }
}
