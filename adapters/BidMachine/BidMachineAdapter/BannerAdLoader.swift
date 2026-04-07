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
      try client.loadWaterfallBannerAd(size: adConfiguration.adSize, delegate: self) {
        [weak self] error in
        guard let self else { return }
        guard error == nil else {
          self.handleLoadedAd(nil, error: error)
          return
        }
      }
    } catch let error as BidMachineAdapterError {
      handleLoadedAd(nil, error: error.toNSError())
    } catch {
      handleLoadedAd(nil, error: error)
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
        with: bidResponse, delegate: self, watermark: watermark
      ) {
        [weak self] error in
        guard let self else { return }
        guard error == nil else {
          self.handleLoadedAd(nil, error: error)
          return
        }
      }
    } catch {
      handleLoadedAd(nil, error: error)
    }
  }

  private func handleLoadedAd(_ ad: MediationBannerAd?, error: Error?) {
    guard let adLoadCompletionHandler else { return }
    eventDelegate = adLoadCompletionHandler(ad, error)
    self.adLoadCompletionHandler = nil
  }

}

// MARK: - BidMachineAdDelegate

extension BannerAdLoader: @preconcurrency BidMachineAdDelegate {

  func didLoadAd(_ ad: any BidMachineAdProtocol) {
    guard let bidMachineBannerAd = ad as? UIView else {
      // Technically, should never get here.
      handleLoadedAd(
        nil,
        error: BidMachineAdapterError(
          errorCode: .bidMachineReturnedNonBannerAd,
          description: "Received non-banner ad in the banner's didLoadAd delegate method."))
      return
    }

    let bannerAd = BannerAd(bannerView: bidMachineBannerAd)
    self.bannerAd = bannerAd
    handleLoadedAd(bannerAd, error: nil)
  }

  func didFailLoadAd(_ ad: any BidMachineAdProtocol, _ error: any Error) {
    handleLoadedAd(nil, error: error)
  }

  func didTrackImpression(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.reportImpression()
  }

  func didTrackInteraction(_ ad: any BidMachineAdProtocol) {
    // Is called only on first click. If you need to track every click use didUserInteraction instead
  }

  func didUserInteraction(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.reportClick()
  }

  func didFailPresentAd(_ ad: any BidMachineAdProtocol, _ error: any Error) {
    eventDelegate?.didFailToPresentWithError(error)
  }

  func willPresentScreen(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.willPresentFullScreenView()
  }

  func didDismissScreen(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.willDismissFullScreenView()
    eventDelegate?.didDismissFullScreenView()
  }
}

// MARK: - MediationBannerAd
@MainActor
final class BannerAd: NSObject, MediationBannerAd {
  var view: UIView

  init(bannerView: UIView) {
    view = bannerView
  }
}
