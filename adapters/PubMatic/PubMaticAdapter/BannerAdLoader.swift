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

final class BannerAdLoader: NSObject, MediationBannerAd, @unchecked Sendable {

  /// The banner ad configuration.
  private let adConfiguration: MediationBannerAdConfiguration

  /// The ad event delegate which is used to report banner related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationBannerAdEventDelegate?

  /// The completion handler that needs to be called upon finishing loading an ad.
  private var bannerAdLoadCompletionHandler: ((MediationBannerAd?, NSError?) -> Void)?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationBannerLoadCompletionHandler?

  /// OpenWrapSDKClient used to manage a banner ad.
  private let client: OpenWrapSDKClient

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
    guard let bidResponse = adConfiguration.bidResponse, let watermark = adConfiguration.watermark
    else {
      handleLoadedAd(
        nil,
        error: PubMaticAdapterError(
          errorCode: .invalidAdConfiguration,
          description: "The ad configuration is invalid."
        ).toNSError())
      return
    }
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.client.loadRtbBannerView(
        bidResponse: bidResponse, testMode: Util.testMode(from: adConfiguration), delegate: self,
        watermarkData: watermark)
    }
  }

  private func loadWaterfallAd() {
    do throws(PubMaticAdapterError) {
      guard let adSize = POBAdSize(cgSize: adConfiguration.adSize.size) else {
        throw PubMaticAdapterError(
          errorCode: .openWrapFailedToInstantiateAdSize,
          description: "The OpenWrapSDK fails to instantiate an ad size instance.")
      }
      let publisherId = try Util.publisherId(from: adConfiguration)
      let profileId = try Util.profileId(from: adConfiguration)
      let adUnitId = try Util.adUnitId(from: adConfiguration)
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        self.client.loadWaterfallBannerView(
          publisherId: publisherId, profileId: profileId, adUnitId: adUnitId, adSize: adSize,
          testMode: Util.testMode(from: adConfiguration),
          delegate: self)
      }
    } catch {
      handleLoadedAd(nil, error: error.toNSError())
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

// MARK: - POBBannerViewDelegate

extension BannerAdLoader: @preconcurrency POBBannerViewDelegate {

  @MainActor func bannerViewPresentationController() -> UIViewController {
    var responder: UIResponder? = view
    // Try to find the nearest UIViewController which this banner is attached.
    while responder != nil {
      responder = responder?.next
      if let viewController = responder as? UIViewController {
        return viewController
      }
    }

    // If failed to find the closest view controller, then find the app's root
    // view controller
    return Util.rootViewController()
  }

  func bannerViewDidReceiveAd(_ bannerView: POBBannerView) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.view = bannerView
      self.handleLoadedAd(self, error: nil)
    }
  }

  func bannerView(_ bannerView: POBBannerView, didFailToReceiveAdWithError error: any Error) {
    handleLoadedAd(nil, error: error as NSError)
  }

  func bannerViewDidRecordImpression(_ bannerView: POBBannerView) {
    eventDelegate?.reportImpression()
  }

  func bannerViewDidClickAd(_ bannerView: POBBannerView) {
    eventDelegate?.reportClick()
  }

}
