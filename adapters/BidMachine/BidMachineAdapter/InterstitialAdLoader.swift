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

final class InterstitialAdLoader: NSObject {

  /// The interstitial ad configuration.
  private let adConfiguration: MediationInterstitialAdConfiguration

  /// The ad event delegate which is used to report interstitial related information to the
  /// Google Mobile Ads SDK.
  private weak var eventDelegate: MediationInterstitialAdEventDelegate?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationInterstitialLoadCompletionHandler?

  private let client: BidMachineClient

  private var interstitialAd: BidMachineInterstitial?

  init(
    adConfiguration: MediationInterstitialAdConfiguration,
    loadCompletionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationInterstitialAdLoadCompletionQueue")
    self.client = BidMachineClientFactory.createClient()
    super.init()
  }

  func loadAd() {
    guard let bidResponse = adConfiguration.bidResponse else {
      handleLoadedAd(
        nil,
        error: GoogleBidMachineAdapter.BidMachineAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing bid response."
        ).toNSError())
      return
    }

    guard let watermark = adConfiguration.watermark?.base64EncodedString() else {
      handleLoadedAd(
        nil,
        error: GoogleBidMachineAdapter.BidMachineAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing watermark."
        ).toNSError())
      return
    }

    do {
      try client.loadRTBInterstitialAd(with: bidResponse, delegate: self, watermark: watermark) {
        [weak self] error in
        guard let self else { return }
        guard error == nil else {
          self.handleLoadedAd(nil, error: error)
          return
        }
      }
    } catch {
      handleLoadedAd(nil, error: error as NSError)
    }
  }

  private func handleLoadedAd(_ ad: MediationInterstitialAd?, error: NSError?) {
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      eventDelegate = adLoadCompletionHandler(ad, error)
      self.adLoadCompletionHandler = nil
    }
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

// MARK: - BidMachineAdDelegate

extension InterstitialAdLoader: BidMachineAdDelegate {

  func didLoadAd(_ ad: any BidMachine.BidMachineAdProtocol) {
    interstitialAd = ad as? BidMachineInterstitial
    handleLoadedAd(self, error: nil)
  }

  func didFailLoadAd(_ ad: any BidMachine.BidMachineAdProtocol, _ error: any Error) {
    handleLoadedAd(nil, error: error as NSError)
  }

  func didTrackImpression(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.reportImpression()
  }

  func didTrackInteraction(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.reportClick()
  }

  func willPresentScreen(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.willPresentFullScreenView()
  }

  func didDismissAd(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.didDismissFullScreenView()
  }

  func didFailPresentAd(_ ad: any BidMachineAdProtocol, _ error: any Error) {
    eventDelegate?.didFailToPresentWithError(error)
  }

}
