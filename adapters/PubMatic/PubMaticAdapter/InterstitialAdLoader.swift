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
import OpenWrapSDK

final class InterstitialAdLoader: NSObject {

  /// The interstitial ad configuration.
  private let adConfiguration: MediationInterstitialAdConfiguration

  /// The ad event delegate which is used to report interstitial related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationInterstitialAdEventDelegate?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationInterstitialLoadCompletionHandler?

  /// OpenWrapSDKClient used to manage an interstitial ad.
  private let client: OpenWrapSDKClient

  init(
    adConfiguration: MediationInterstitialAdConfiguration,
    loadCompletionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationInterstitialAdLoadCompletionQueue")
    self.client = OpenWrapSDKClientFactory.createClient()
    super.init()
  }

  func loadAd() {
    if adConfiguration.bidResponse != nil {
      loadRTBAd()
    } else {
      loadWaterfallAd()
    }
  }

  private func loadRTBAd() {
    guard let bidResponse = adConfiguration.bidResponse,
      let watermark = adConfiguration.watermark
    else {
      handleLoadedAd(
        nil,
        error: PubMaticAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is invalid."
        ).toNSError())
      return
    }
    client.loadRtbInterstitial(
      bidResponse: bidResponse, delegate: self, watermarkData: watermark)
  }

  private func loadWaterfallAd() {
    do {
      let publisherId = try Util.publisherId(from: adConfiguration)
      let profileId = try Util.profileId(from: adConfiguration)
      let adUnitId = try Util.adUnitId(from: adConfiguration)
      client.loadWaterfallInterstitial(
        publisherId: publisherId, profileId: profileId, adUnitId: adUnitId, delegate: self)
    } catch {
      handleLoadedAd(nil, error: error.toNSError())
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
      try client.presentInterstitial(from: viewController)
    } catch let error {
      eventDelegate?.didFailToPresentWithError(error.toNSError())
    }
  }

}

// MARK: - POBInterstitialDelegate

extension InterstitialAdLoader: POBInterstitialDelegate {

  func interstitialDidReceiveAd(_ interstitial: POBInterstitial) {
    handleLoadedAd(self, error: nil)
  }

  func interstitial(_ interstitial: POBInterstitial, didFailToReceiveAdWithError error: any Error) {
    handleLoadedAd(nil, error: error as NSError)
  }

  func interstitialWillPresentAd(_ interstitial: POBInterstitial) {
    eventDelegate?.willPresentFullScreenView()
  }

  func interstitial(_ interstitial: POBInterstitial, didFailToShowAdWithError error: any Error) {
    eventDelegate?.didFailToPresentWithError(error as NSError)
  }

  func interstitialDidRecordImpression(_ interstitial: POBInterstitial) {
    eventDelegate?.reportImpression()
  }

  func interstitialDidClickAd(_ interstitial: POBInterstitial) {
    eventDelegate?.reportClick()
  }

  func interstitialDidDismissAd(_ interstitial: POBInterstitial) {
    eventDelegate?.didDismissFullScreenView()
  }

}
