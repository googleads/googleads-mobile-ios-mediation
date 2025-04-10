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

final class BannerAdLoader: NSObject, MediationBannerAd, @unchecked Sendable {

  /// The banner ad configuration.
  private let adConfiguration: MediationBannerAdConfiguration

  /// The ad event delegate which is used to report banner related information to the Google Mobile
  /// Ads SDK.
  private weak var eventDelegate: MediationBannerAdEventDelegate?

  /// The completion handler that needs to be called upon finishing loading an ad.
  private var bannerAdLoadCompletionHandler: ((MediationBannerAd?, NSError?) -> Void)?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationBannerLoadCompletionHandler?

  private let client: BidMachineClient

  var view: UIView

  @MainActor
  init(
    adConfiguration: MediationBannerAdConfiguration,
    loadCompletionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationBannerAdLoadCompletionQueue")
    self.view = UIView()
    self.client = BidMachineClientFactory.createClient()
    super.init()
  }

  func loadAd() {
    guard let bidResponse = adConfiguration.bidResponse else {
      handleLoadedAd(
        nil,
        error: BidMachineAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing bid response."
        ).toNSError())
      return
    }

    do {
      try client.loadRTBBannerAd(with: bidResponse, delegate: self) {
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
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      eventDelegate = adLoadCompletionHandler(ad, error)
      self.adLoadCompletionHandler = nil
    }
  }

}

// MARK: - BidMachineAdDelegate

extension BannerAdLoader: BidMachineAdDelegate {

  func didLoadAd(_ ad: any BidMachine.BidMachineAdProtocol) {
    guard let bannerAd = ad as? UIView else {
      // Technically, should never get here.
      handleLoadedAd(
        nil,
        error: BidMachineAdapterError(
          errorCode: .bidMachineReturnedNonBannerAd,
          description: "Received non-banner ad in the banner's didLoadAd delegate method."))
      return
    }

    view = bannerAd
    handleLoadedAd(self, error: nil)
  }

  func didFailLoadAd(_ ad: any BidMachine.BidMachineAdProtocol, _ error: any Error) {
    handleLoadedAd(nil, error: error)
  }

  func didTrackImpression(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.reportImpression()
  }

  func didTrackInteraction(_ ad: any BidMachineAdProtocol) {
    eventDelegate?.reportClick()
  }

  func didFailPresentAd(_ ad: any BidMachineAdProtocol, _ error: any Error) {
    eventDelegate?.didFailToPresentWithError(error)
  }

}
