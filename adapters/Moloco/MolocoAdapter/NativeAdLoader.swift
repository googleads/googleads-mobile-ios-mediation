// Copyright 2024 Google LLC.
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
import MolocoSDK

/// Loads native ads on Moloco ads SDK.
final class NativeAdLoader: NSObject {

  /// The native ad configuration.
  private let adConfiguration: MediationNativeAdConfiguration

  /// The completion handler to call when native ad loading succeeds or fails.
  private let loadCompletionHandler: GADMediationNativeLoadCompletionHandler

  /// The ad event delegate which is used to report native related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationNativeAdEventDelegate?

  private let molocoNativeFactory: MolocoNativeFactory?

  private var nativeAd: MolocoNativeAd?

  init(
    adConfiguration: MediationNativeAdConfiguration,
    loadCompletionHandler: @escaping GADMediationNativeLoadCompletionHandler,
    molocoNativeFactory: MolocoNativeFactory
  ) {
    self.adConfiguration = adConfiguration
    self.loadCompletionHandler = loadCompletionHandler
    self.molocoNativeFactory = molocoNativeFactory
    super.init()
  }

  func loadAd() {
    guard #available(iOS 13.0, *) else {
      let error = MolocoUtils.error(
        code: .adServingNotSupported,
        description: "Moloco SDK does not support serving ads on iOS 12 and below")
      _ = loadCompletionHandler(nil, error)
      return
    }

    let molocoAdUnitId = MolocoUtils.getAdUnitId(from: adConfiguration)
    guard let molocoAdUnitId = molocoAdUnitId else {
      let error = MolocoUtils.error(
        code: .invalidAdUnitId, description: "Missing required parameter")
      _ = loadCompletionHandler(nil, error)
      return
    }

    guard let bidResponse = adConfiguration.bidResponse else {
      let error = MolocoUtils.error(code: .nilBidResponse, description: "Nil bid response.")
      _ = loadCompletionHandler(nil, error)
      return
    }

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      self.nativeAd = self.molocoNativeFactory?.createNativeAd(
        for: molocoAdUnitId, delegate: self)
      guard self.nativeAd != nil else {
        let error = MolocoUtils.error(code: .invalidAdUnitId, description: "Ad not loaded.")
        _ = loadCompletionHandler(nil, error)
        return
      }
      self.nativeAd?.load(bidResponse: bidResponse)
    }

  }

}

// MARK: - MolocoNativeAdDelegate

extension NativeAdLoader: MolocoNativeAdDelegate {
  func didLoad(ad: any MolocoSDK.MolocoAd) {

    guard ad.isReady else {
      let error = MolocoUtils.error(code: .adNotReadyForShow, description: "Ad not ready to show.")
      _ = loadCompletionHandler(nil, error)
      return
    }

    eventDelegate = loadCompletionHandler(self, nil)
  }

  func failToLoad(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
    _ = loadCompletionHandler(nil, error)
  }

  func didShow(ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.reportImpression()
  }

  func failToShow(ad: any MolocoSDK.MolocoAd, with error: (any Error)?) {
    let showError =
      error
      ?? MolocoUtils.error(
        code: .adFailedToShow, description: "Ad failed to show")
    eventDelegate?.didFailToPresentWithError(showError)
  }

  func didHide(ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.didDismissFullScreenView()
  }

  func didClick(on ad: any MolocoSDK.MolocoAd) {
    eventDelegate?.reportClick()
  }

  func didHandleClick(ad: any MolocoAd) {
    eventDelegate?.reportClick()
  }

  func didHandleImpression(ad: any MolocoAd) {
    eventDelegate?.reportImpression()
  }

}

// MARK: - GADMediationNativeAd

extension NativeAdLoader: MediationNativeAd {

  var headline: String? {
    return self.nativeAd?.assets?.title
  }

  var images: [NativeAdImage]? {
    guard let mainImage = self.nativeAd?.assets?.mainImage else {
      return nil
    }
    return [NativeAdImage(image: mainImage)]
  }

  var mediaView: UIView? {
    guard let assets = self.nativeAd?.assets else {
      return nil
    }
    return assets.videoView ?? UIImageView(image: assets.mainImage)
  }

  var body: String? {
    return self.nativeAd?.assets?.description
  }

  var icon: NativeAdImage? {
    return self.nativeAd?.assets?.appIcon.map { .init(image: $0) }
  }

  var callToAction: String? {
    return self.nativeAd?.assets?.ctaTitle
  }

  var starRating: NSDecimalNumber? {
    if let rating: Double = self.nativeAd?.assets?.rating {
      return NSDecimalNumber(value: rating)
    }
    return nil
  }

  var store: String? {
    return nil
  }

  var price: String? {
    return nil
  }

  var advertiser: String? {
    return self.nativeAd?.assets?.sponsorText
  }

  var extraAssets: [String: Any]? {
    return nil
  }

  var hasVideoContent: Bool {
    return (self.nativeAd?.assets?.videoView != nil)
  }

  func handlesUserClicks() -> Bool {
    return false
  }

  func handlesUserImpressions() -> Bool {
    return false
  }

  func didRecordImpression() {
    nativeAd?.handleImpression()
  }

  func didRecordClickOnAsset(
    with assetName: GADNativeAssetIdentifier,
    view: UIView,
    viewController: UIViewController
  ) {
    nativeAd?.handleClick()
  }

}
