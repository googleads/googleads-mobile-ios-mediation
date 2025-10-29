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

import BigoADS
import Foundation
import GoogleMobileAds

final class AppOpenAdLoader: NSObject {

  /// The app open ad configuration.
  private let adConfiguration: GADMediationAppOpenAdConfiguration

  /// The ad event delegate which is used to report app open related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationAppOpenAdEventDelegate?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The completion handler that needs to be called upon finishing loading an ad.
  private var adLoadCompletionHandler: GADMediationAppOpenLoadCompletionHandler?

  private let client: BigoClient

  private var splashAd: BigoSplashAd?

  init(
    adConfiguration: GADMediationAppOpenAdConfiguration,
    loadCompletionHandler: @escaping GADMediationAppOpenLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationAppOpenAdLoadCompletionQueue")
    self.client = BigoClientFactory.createClient()
    super.init()
  }

  func loadAd() {
    guard let bidResponse = adConfiguration.bidResponse else {
      handleLoadedAd(
        nil,
        error: BigoAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing bid response."
        ).toNSError())
      return
    }

    guard let watermark = adConfiguration.watermark else {
      handleLoadedAd(
        nil,
        error: BigoAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is missing watermark."
        ).toNSError())
      return
    }

    do {
      let slotId = try Util.slotId(from: adConfiguration)
      client.loadRTBSplashAd(
        for: slotId, bidPayLoad: bidResponse, watermark: watermark, delegate: self)
    } catch {
      handleLoadedAd(nil, error: error.toNSError())
    }
  }

  private func handleLoadedAd(_ ad: MediationAppOpenAd?, error: NSError?) {
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      eventDelegate = adLoadCompletionHandler(ad, error)
      self.adLoadCompletionHandler = nil
    }
  }

}

// MARK: - BigoSplashAdLoaderDelegate

extension AppOpenAdLoader: BigoSplashAdLoaderDelegate {

  func onSplashAdLoaded(_ ad: BigoSplashAd) {
    splashAd = ad
    handleLoadedAd(self, error: nil)
  }

  func onSplashAdLoadError(_ error: BigoAdError) {
    handleLoadedAd(nil, error: Util.NSError(from: error))
  }

}

// MARK: - BigoSplashAdInteractionDelegate

extension AppOpenAdLoader: BigoSplashAdInteractionDelegate {

  func onAd(_ ad: BigoAd, error: BigoAdError) {
    Util.log(
      "Encountered an issue for the splash ad with error code: \(error.errorCode) with following message: \(error.errorMsg)"
    )
    eventDelegate?.didFailToPresentWithError(Util.NSError(from: error))
  }

  func onAdImpression(_ ad: BigoAd) {
    eventDelegate?.reportImpression()
  }

  func onAdClicked(_ ad: BigoAd) {
    eventDelegate?.reportClick()
  }

  func onAdSkipped(_ ad: BigoAd) {
    // Google does not have equivalent callback function.
    Util.log("The splash ad has been skipped.")
  }

  func onAdFinished(_ ad: BigoAd) {
    // Google does not have equivalent callback function.
    Util.log("The splash ad has been finished.")
  }

  func onAdOpened(_ ad: BigoAd) {
    // Google does not have equivalent callback function.
    Util.log("The splash ad has been opened.")
  }

  func onAdClosed(_ ad: BigoAd) {
    eventDelegate?.didDismissFullScreenView()
    splashAd?.destroy()
    splashAd = nil
  }

}

// MARK: - GADMediationAppOpenAd

extension AppOpenAdLoader: MediationAppOpenAd {

  func present(from viewController: UIViewController) {
    guard let splashAd else {
      eventDelegate?.didFailToPresentWithError(
        BigoAdapterError(
          errorCode: .adIsNotReadyForPresentation, description: "Splash ad is not available."))
      return
    }

    guard !splashAd.isExpired() else {
      eventDelegate?.didFailToPresentWithError(
        BigoAdapterError(
          errorCode: .adIsNotReadyForPresentation, description: "Splash ad has been expired."))
      return
    }

    eventDelegate?.willPresentFullScreenView()
    client.presentSplashAd(splashAd, viewController: viewController, interactionDelegate: self)
  }

}
