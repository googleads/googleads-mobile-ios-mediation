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

  private let client: BigoClient

  private var nativeAd: BigoNativeAd?

  private var bigoMediaView: BigoAdMediaView?

  init(
    adConfiguration: MediationNativeAdConfiguration,
    loadCompletionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.adLoadCompletionQueue = DispatchQueue(
      label: "com.google.mediationNativeAdLoadCompletionQueue")
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

    do {
      let slotId = try Util.slotId(from: adConfiguration)
      client.loadRTBNativeAd(for: slotId, bidPayLoad: bidResponse, delegate: self)
    } catch {
      handleLoadedAd(nil, error: error.toNSError())
    }
  }

  private func handleLoadedAd(_ ad: MediationNativeAd?, error: NSError?) {
    adLoadCompletionQueue.sync { [weak self] in
      guard let adLoadCompletionHandler = self?.adLoadCompletionHandler else { return }
      self?.eventDelegate = adLoadCompletionHandler(ad, error)
      self?.adLoadCompletionHandler = nil
    }
  }

}

// MARK: - BigoNativeAdLoaderDelegate

extension NativeAdLoader: BigoNativeAdLoaderDelegate {

  func onNativeAdLoaded(_ ad: BigoNativeAd) {
    ad.setAdInteractionDelegate(self)
    nativeAd = ad
    handleLoadedAd(self, error: nil)
  }

  func onNativeAdLoadError(_ error: BigoAdError) {
    handleLoadedAd(nil, error: Util.NSError(from: error))
  }

}

// MARK: - BigoAdInteractionDelegate

extension NativeAdLoader: BigoAdInteractionDelegate {

  func onAd(_ ad: BigoAd, error: BigoAdError) {
    // Google does not have equivalent callback function.
    Util.log(
      "Encountered an issue for the native ad with error code: \(error.errorCode) with following message: \(error.errorMsg)"
    )
  }

  func onAdImpression(_ ad: BigoAd) {
    eventDelegate?.reportImpression()
  }

  func onAdClicked(_ ad: BigoAd) {
    eventDelegate?.reportClick()
  }

  func onAdOpened(_ ad: BigoAd) {
    // Google does not have equivalent callback function.
    Util.log("The native ad has been opened.")
  }

  func onAdClosed(_ ad: BigoAd) {
    // Google does not have equivalent callback function.
    Util.log("The native ad has been closed.")
  }

}

// MARK: - BGVideoLifeCallbackDelegate

extension NativeAdLoader: BGVideoLifeCallbackDelegate {

  func onVideoStart(_ videoController: BigoVideoController) {
    Util.log("The native ad starts video.")
  }

  func onVideoPlay(_ videoController: BigoVideoController) {
    Util.log("The native ad plays video.")
  }

  func onVideoPause(_ videoController: BigoVideoController) {
    Util.log("The native ad pauses video.")
  }

  func onVideoEnd(_ videoController: BigoVideoController) {
    Util.log("The native ad ends video.")
  }

  func onVideo(_ videoController: BigoVideoController, mute: Bool) {
    Util.log("The native ad muted: \(mute)")
  }

}

// MARK: - GADMediationNativeAd

extension NativeAdLoader: MediationNativeAd {

  var headline: String? {
    return nativeAd?.title()
  }

  var images: [NativeAdImage]? {
    return nil
  }

  var body: String? {
    return nativeAd?.adDescription()
  }

  var icon: NativeAdImage? {
    return nil
  }

  var mediaView: UIView? {
    if let bigoMediaView {
      return bigoMediaView
    }

    bigoMediaView = BigoAdMediaView()
    bigoMediaView?.bigoNativeAdViewTag = .media
    bigoMediaView?.videoController.delegate = self
    return bigoMediaView
  }

  var callToAction: String? {
    return nativeAd?.callToAction()
  }

  var advertiser: String? {
    return nativeAd?.advertiser()
  }

  var mediaContentAspectRatio: CGFloat {
    return nativeAd?.getMediaContentAspectRatio() ?? 0
  }

  var hasVideoContent: Bool {
    guard let creativeType = nativeAd?.getCreativeType() else { return false }
    return creativeType == .video
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
    view.bigoNativeAdViewTag = .nativeAdView

    // Add Bigo tags for clickable views.
    var iconImageView: UIImageView?
    for (identifier, view) in clickableAssetViews {
      switch identifier {
      case .headlineAsset:
        view.bigoNativeAdViewTag = .title
      case .callToActionAsset:
        view.bigoNativeAdViewTag = .callToAction
      case .iconAsset:
        view.bigoNativeAdViewTag = .icon
        iconImageView = view as? UIImageView
      case .bodyAsset:
        view.bigoNativeAdViewTag = .description
      case .mediaViewAsset:
        view.bigoNativeAdViewTag = .media
      default:
        break
      }
    }

    if iconImageView == nil {
      for (identifier, view) in nonclickableAssetViews {
        if identifier == .iconAsset {
          iconImageView = view as? UIImageView
          break
        }
      }
    }

    let nativeAdViewWidth = view.bounds.width
    let optionsView = BigoAdOptionsView(frame: CGRectMake(nativeAdViewWidth - 20, 0, 20, 20))
    optionsView.bigoNativeAdViewTag = .option
    view.addSubview(optionsView)

    nativeAd?.registerView(
      forInteraction: view,
      mediaView: bigoMediaView,
      adIconView: iconImageView,
      adOptionsView: optionsView,
      clickableViews: Array(clickableAssetViews.values))
  }

  var starRating: NSDecimalNumber? {
    // Bigo does not support.
    return nil
  }

  var store: String? {
    // Bigo does not support.
    return nil
  }

  var price: String? {
    // Bigo does not support.
    return nil
  }

  var extraAssets: [String: Any]? {
    // Bigo does not support.
    return nil
  }

}
