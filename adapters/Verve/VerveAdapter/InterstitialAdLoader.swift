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
import HyBid

final class InterstitialAdLoader: NSObject {

  /// The interstitial ad configuration.
  private let adConfiguration: MediationInterstitialAdConfiguration

  /// The ad event delegate which is used to report interstitial related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationInterstitialAdEventDelegate?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationInterstitialLoadCompletionHandler?

  private let client: HybidClient

  init(
    adConfiguration: MediationInterstitialAdConfiguration,
    loadCompletionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationInterstitialAdLoadCompletionQueue")
    self.client = HybidClientFactory.createClient()
    super.init()
  }

  func loadAd() {
    guard let bidResponse = adConfiguration.bidResponse else {
      handleLoadedAd(
        nil,
        error: VerveAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing bid response."
        ).toNSError())
      return
    }
    client.loadRTBInterstitialAd(with: bidResponse, delegate: self)
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
    do throws(VerveAdapterError) {
      eventDelegate?.willPresentFullScreenView()
      try client.presentInterstitialAd(from: viewController)
    } catch let error {
      eventDelegate?.didFailToPresentWithError(error.toNSError())
    }
  }

}

// MARK: - HyBidInterstitialAdDelegate
extension InterstitialAdLoader: HyBidInterstitialAdDelegate {

  func interstitialDidLoad() {
    handleLoadedAd(self, error: nil)
  }

  func interstitialDidFailWithError(_ error: (any Error)!) {
    handleLoadedAd(nil, error: error as NSError)
  }

  func interstitialDidTrackImpression() {
    eventDelegate?.reportImpression()
  }

  func interstitialDidTrackClick() {
    eventDelegate?.reportClick()
  }

  func interstitialDidDismiss() {
    eventDelegate?.didDismissFullScreenView()
  }

}
