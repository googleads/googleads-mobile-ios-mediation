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

final class NativeAdLoader: NSObject {

  /// The native ad configuration.
  private let adConfiguration: MediationNativeAdConfiguration

  /// The ad event delegate which is used to report native related information to the Google Mobile
  /// Ads SDK.
  private weak var eventDelegate: MediationNativeAdEventDelegate?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationNativeLoadCompletionHandler?

  private let client: BidMachineClient

  private var nativeAdProxy: NativeAdProxy?

  init(
    adConfiguration: MediationNativeAdConfiguration,
    loadCompletionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationNativeAdLoadCompletionQueue")
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
      try client.loadWaterfallNativeAd(delegate: self) {
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
      try client.loadRTBNativeAd(with: bidResponse, delegate: self, watermark: watermark) {
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

  private func handleLoadedAd(_ ad: MediationNativeAd?, error: NSError?) {
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      eventDelegate = adLoadCompletionHandler(ad, error)
      self.adLoadCompletionHandler = nil
    }
  }

}

// MARK: - BidMachineAdDelegate

extension NativeAdLoader: BidMachineAdDelegate {

  func didLoadAd(_ ad: any BidMachineAdProtocol) {
    // BidMachine native ad's image assets come in string URLs. The adapter
    // needs to download them before notifying Google Mobile Ads SDK.
    do {
      nativeAdProxy = try NativeAdProxyFactory.createProxy(with: ad)
      nativeAdProxy?.downLoadImageAssets(completionHandler: { [weak self] error in
        guard let self else { return }

        guard error == nil else {
          self.handleLoadedAd(nil, error: error!.toNSError())
          return
        }

        self.handleLoadedAd(self.nativeAdProxy, error: nil)
      })
    } catch {
      handleLoadedAd(nil, error: error.toNSError())
    }
  }

  func didFailLoadAd(_ ad: any BidMachineAdProtocol, _ error: any Error) {
    handleLoadedAd(nil, error: error as NSError)
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
