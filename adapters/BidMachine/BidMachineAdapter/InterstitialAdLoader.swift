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
final class InterstitialAdLoader: NSObject {

  /// The interstitial ad configuration.
  private let adConfiguration: MediationInterstitialAdConfiguration

  /// The ad event delegate which is used to report interstitial related information to the
  /// Google Mobile Ads SDK.
  private weak var eventDelegate: MediationInterstitialAdEventDelegate?

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationInterstitialLoadCompletionHandler?

  private let client: BidMachineClient

  private var interstitialAd: BidMachine.InterstitialAd?

  init(
    adConfiguration: MediationInterstitialAdConfiguration,
    loadCompletionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.client = BidMachineClientFactory.createClient()
    super.init()
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
      try client.loadWaterfallInterstitialAd(
        delegate: self, placementId: Util.placementId(from: adConfiguration)
      ) {
        [weak self] interstitialAd, error in
        self?.handleLoadedInterstitial(interstitialAd, error: error)
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
      try client.loadRTBInterstitialAd(
        with: bidResponse, delegate: self, watermark: watermark
      ) {
        [weak self] interstitialAd, error in
        self?.handleLoadedInterstitial(interstitialAd, error: error)
      }
    } catch let error as BidMachineAdapterError {
      handleLoadedAd(nil, error: error.toNSError())
    } catch {
      handleLoadedAd(nil, error: error as NSError)
    }
  }

  /// Stores the loaded interstitial ad and reports the load result.
  private func handleLoadedInterstitial(
    _ interstitialAd: BidMachine.InterstitialAd?, error: NSError?
  ) {
    guard let interstitialAd else {
      handleLoadedAd(nil, error: error)
      return
    }
    self.interstitialAd = interstitialAd
    handleLoadedAd(self, error: nil)
  }

  private func handleLoadedAd(_ ad: MediationInterstitialAd?, error: NSError?) {
    guard let adLoadCompletionHandler else { return }
    eventDelegate = adLoadCompletionHandler(ad, error)
    self.adLoadCompletionHandler = nil
  }

}

// MARK: - GADMediationInterstitialAd

extension InterstitialAdLoader: MediationInterstitialAd {

  func present(from viewController: UIViewController) {
    do {
      try client.present(interstitialAd, from: viewController)
    } catch {
      eventDelegate?.didFailToPresentWithError(error.toNSError())
    }
  }

}

// MARK: - InterstitialAdDelegate

extension InterstitialAdLoader: BidMachine.InterstitialAdDelegate {

  func didPresent(_ ad: BidMachine.InterstitialAd) {
    eventDelegate?.willPresentFullScreenView()
  }

  func didFailPresent(_ ad: BidMachine.InterstitialAd, error: BidMachineError) {
    eventDelegate?.didFailToPresentWithError(error)
  }

  func didDismiss(_ ad: BidMachine.InterstitialAd) {
    eventDelegate?.willDismissFullScreenView()
    eventDelegate?.didDismissFullScreenView()
  }

  func didClick(_ ad: BidMachine.InterstitialAd) {
    eventDelegate?.reportClick()
  }

  func didTrackImpression(_ ad: BidMachine.InterstitialAd) {
    eventDelegate?.reportImpression()
  }
}
