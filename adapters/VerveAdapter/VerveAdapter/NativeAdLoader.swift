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

final class NativeAdLoader: NSObject {

  /// The native ad configuration.
  private let adConfiguration: MediationNativeAdConfiguration

  /// The ad event delegate which is used to report native related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationNativeAdEventDelegate?

  /// The completion handler that needs to be called upon finishing loading an ad.
  private var nativeAdLoadCompletionHandler: ((MediationNativeAd?, NSError?) -> Void)?

  /// The queue for processing an ad load completion.
  private let adLoadCompletionQueue: DispatchQueue

  /// The ad load completion handler the must be run after ad load completion.
  private var adLoadCompletionHandler: GADMediationNativeLoadCompletionHandler?

  private let client: HybidClient

  private var nativeAd: HyBidNativeAd?

  init(
    adConfiguration: MediationNativeAdConfiguration,
    loadCompletionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationNativeAdLoadCompletionQueue")
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
    client.loadRTBNativeAd(with: bidResponse, delegate: self)
  }

  private func handleLoadedAd(_ ad: MediationNativeAd?, error: NSError?) {
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      eventDelegate = adLoadCompletionHandler(ad, error)
      self.adLoadCompletionHandler = nil
    }
  }

}

// MARK: - GADMediationNativeAd

extension NativeAdLoader: MediationNativeAd {

  var headline: String? {
    return nativeAd?.title
  }

  var body: String? {
    return nativeAd?.body
  }

  var images: [NativeAdImage]? {
    guard let bannerImage = nativeAd?.bannerImage else {
      return nil
    }
    return [NativeAdImage(image: bannerImage)]
  }

  var icon: NativeAdImage? {
    guard let iconImage = nativeAd?.icon else { return nil }
    return NativeAdImage(image: iconImage)
  }

  var callToAction: String? {
    return nativeAd?.callToActionTitle
  }

  var starRating: NSDecimalNumber? {
    guard let ratingNumber = nativeAd?.rating else {
      return nil
    }
    return NSDecimalNumber(decimal: ratingNumber.decimalValue)
  }

  var adChoicesView: UIView? {
    return nativeAd?.contentInfo
  }

  // Not supported by HyBid.
  var store: String? {
    return nil
  }

  // Not supported by HyBid.
  var price: String? {
    return nil
  }

  // Not supported by HyBid.
  var advertiser: String? {
    return nil
  }

  // Not supported by HyBid.
  var extraAssets: [String: Any]? {
    return nil
  }

  var hasVideoContent: Bool {
    return false
  }

  func handlesUserClicks() -> Bool {
    return true
  }

  func handlesUserImpressions() -> Bool {
    return true
  }

  func didRender(
    in view: UIView,
    clickableAssetViews: [GADNativeAssetIdentifier: UIView],
    nonclickableAssetViews: [GADNativeAssetIdentifier: UIView],
    viewController: UIViewController
  ) {
    nativeAd?.startTrackingView(view, with: self)
  }

  func didUntrackView(_ view: UIView?) {
    nativeAd?.stopTracking()
  }

}

// MARK: - HyBidNativeAdLoaderDelegate

extension NativeAdLoader: HyBidNativeAdLoaderDelegate {

  func nativeLoaderDidLoad(with nativeAd: HyBidNativeAd!) {
    self.nativeAd = nativeAd
    client.fetchAssets(for: nativeAd, delegate: self)
  }

  func nativeLoaderDidFailWithError(_ error: (any Error)!) {
    handleLoadedAd(nil, error: error as NSError)
  }

}

// MARK: - HyBidNativeAdFetchDelegate

extension NativeAdLoader: HyBidNativeAdFetchDelegate {

  func nativeAdDidFinishFetching(_ nativeAd: HyBidNativeAd!) {
    handleLoadedAd(self, error: nil)
  }

  func nativeAd(
    _ nativeAd: HyBidNativeAd!,
    didFailFetchingWithError error: (any Error)!
  ) {
    handleLoadedAd(nil, error: error as NSError)
  }

}

// MARK: - HyBidNativeAdDelegate

extension NativeAdLoader: HyBidNativeAdDelegate {

  func nativeAd(
    _ nativeAd: HyBidNativeAd!,
    impressionConfirmedWith view: UIView!
  ) {
    eventDelegate?.reportImpression()
  }

  func nativeAdDidClick(_ nativeAd: HyBidNativeAd!) {
    eventDelegate?.reportClick()
  }

}
