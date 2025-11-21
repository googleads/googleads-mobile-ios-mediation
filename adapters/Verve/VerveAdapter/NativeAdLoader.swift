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

@_implementationOnly import HyBid

final class NativeAdLoader: NSObject, @unchecked Sendable {

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

  private var nativeAd: Any?

  private var delegateImpl: Any?

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

    let impl = HyBidNativeAdDelegateImpl(parent: self)
    self.delegateImpl = impl
    client.loadRTBNativeAd(with: bidResponse, delegate: impl)
  }

  private func handleLoadedAd(_ ad: MediationNativeAd?, error: NSError?) {
    adLoadCompletionQueue.sync {
      guard let adLoadCompletionHandler else { return }
      eventDelegate = adLoadCompletionHandler(ad, error)
      self.adLoadCompletionHandler = nil
    }
  }

  // MARK: - Fileprivate Handlers

  fileprivate func handleNativeLoaderDidLoad(_ nativeAd: HyBidNativeAd!) {
    self.nativeAd = nativeAd

    guard let impl = delegateImpl as? HyBidNativeAdFetchDelegate else { return }
    client.fetchAssets(for: nativeAd, delegate: impl)
  }

  fileprivate func handleNativeLoaderDidFail(_ error: Error!) {
    handleLoadedAd(nil, error: error as NSError)
  }

  fileprivate func handleFetchFinished() {
    handleLoadedAd(self, error: nil)
  }

  fileprivate func handleImpression() {
    eventDelegate?.reportImpression()
  }

  fileprivate func handleClick() {
    eventDelegate?.reportClick()
  }

}

// MARK: - GADMediationNativeAd

extension NativeAdLoader: MediationNativeAd {

  private var hybidAd: HyBidNativeAd? {
    return nativeAd as? HyBidNativeAd
  }

  var headline: String? {
    return hybidAd?.title
  }

  var body: String? {
    return hybidAd?.body
  }

  var images: [NativeAdImage]? {
    guard let bannerImage = hybidAd?.bannerImage else {
      return nil
    }
    return [NativeAdImage(image: bannerImage)]
  }

  var icon: NativeAdImage? {
    guard let iconImage = hybidAd?.icon else { return nil }
    return NativeAdImage(image: iconImage)
  }

  var callToAction: String? {
    return hybidAd?.callToActionTitle
  }

  var starRating: NSDecimalNumber? {
    guard let ratingNumber = hybidAd?.rating else {
      return nil
    }
    return NSDecimalNumber(decimal: ratingNumber.decimalValue)
  }

  var adChoicesView: UIView? {
    return hybidAd?.contentInfo
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
    guard let ad = hybidAd,
      let delegate = delegateImpl as? HyBidNativeAdDelegate
    else { return }
    ad.startTrackingView(view, with: delegate)
  }

  func didUntrackView(_ view: UIView?) {
    hybidAd?.stopTracking()
  }

}

// MARK: - HyBidNativeAdDelegateImpl

private class HyBidNativeAdDelegateImpl: NSObject,
  HyBidNativeAdLoaderDelegate,
  HyBidNativeAdFetchDelegate,
  HyBidNativeAdDelegate
{

  weak var parent: NativeAdLoader?

  init(parent: NativeAdLoader) {
    self.parent = parent
  }

  func nativeLoaderDidLoad(with nativeAd: HyBidNativeAd!) {
    parent?.handleNativeLoaderDidLoad(nativeAd)
  }

  func nativeLoaderDidFailWithError(_ error: (any Error)!) {
    parent?.handleNativeLoaderDidFail(error)
  }

  func nativeAdDidFinishFetching(_ nativeAd: HyBidNativeAd!) {
    parent?.handleFetchFinished()
  }

  func nativeAd(_ nativeAd: HyBidNativeAd!, didFailFetchingWithError error: (any Error)!) {
    parent?.handleNativeLoaderDidFail(error)
  }

  func nativeAd(_ nativeAd: HyBidNativeAd!, impressionConfirmedWith view: UIView!) {
    parent?.handleImpression()
  }

  func nativeAdDidClick(_ nativeAd: HyBidNativeAd!) {
    parent?.handleClick()
  }

}
