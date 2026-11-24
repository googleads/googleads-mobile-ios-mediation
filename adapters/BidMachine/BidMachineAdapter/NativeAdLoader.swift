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
final class NativeAdLoader: NSObject {

  /// The native ad configuration.
  private let adConfiguration: MediationNativeAdConfiguration

  /// The ad event delegate which is used to report native related information to the Google Mobile
  /// Ads SDK.
  private weak var eventDelegate: MediationNativeAdEventDelegate?

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
      try client.loadWaterfallNativeAd(
        delegate: self, placementId: Util.placementId(from: adConfiguration)
      ) {
        [weak self] nativeAd, error in
        self?.handleLoadedNative(nativeAd, error: error)
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
      try client.loadRTBNativeAd(
        with: bidResponse, delegate: self, watermark: watermark
      ) {
        [weak self] nativeAd, error in
        self?.handleLoadedNative(nativeAd, error: error)
      }
    } catch let error as BidMachineAdapterError {
      handleLoadedAd(nil, error: error.toNSError())
    } catch {
      handleLoadedAd(nil, error: error as NSError)
    }
  }

  /// Creates a proxy for the loaded native ad and reports the load result.
  private func handleLoadedNative(_ nativeAd: BidMachine.NativeAd?, error: NSError?) {
    guard let nativeAd else {
      handleLoadedAd(nil, error: error)
      return
    }
    nativeAdProxy = NativeAdProxyFactory.createProxy(with: nativeAd)
    handleLoadedAd(nativeAdProxy, error: nil)
  }

  private func handleLoadedAd(_ ad: MediationNativeAd?, error: NSError?) {
    guard let adLoadCompletionHandler else { return }
    eventDelegate = adLoadCompletionHandler(ad, error)
    self.adLoadCompletionHandler = nil
  }

}

// MARK: - NativeAdDelegate

extension NativeAdLoader: BidMachine.NativeAdDelegate {

  func didPresent(_ ad: BidMachine.NativeAd) {
  }

  func didFailPresent(_ ad: BidMachine.NativeAd, error: BidMachineError) {
    eventDelegate?.didFailToPresentWithError(error)
  }

  func didTrackImpression(_ ad: BidMachine.NativeAd) {
    eventDelegate?.reportImpression()
  }

  func didClick(_ ad: BidMachine.NativeAd) {
    eventDelegate?.reportClick()
  }

  func willPresentScreen(_ ad: BidMachine.NativeAd) {
    eventDelegate?.willPresentFullScreenView()
  }

  func didDismissScreen(_ ad: BidMachine.NativeAd) {
    eventDelegate?.willDismissFullScreenView()
    eventDelegate?.didDismissFullScreenView()
  }
}
