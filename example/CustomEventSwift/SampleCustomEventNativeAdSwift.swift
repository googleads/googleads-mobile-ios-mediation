//
// Copyright (C) 2017 Google, Inc.
//
// SampleCustomEventNativeAdSwift.swift
// Mediation Example
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import GoogleMobileAds
import SampleAdSDK

class SampleCustomEventNativeAdSwift: NSObject, GADMediationNativeAd {
  var nativeAd: SampleNativeAd?

  var headline: String? {
    return nativeAd?.headline
  }

  var images: [GADNativeAdImage]?

  var body: String? {
    return nativeAd?.body
  }

  var icon: GADNativeAdImage?

  var callToAction: String? {
    return nativeAd?.callToAction
  }

  var starRating: NSDecimalNumber? {
    return nativeAd?.starRating
  }

  var store: String? {
    return nativeAd?.store
  }

  var price: String? {
    return nativeAd?.price
  }

  var advertiser: String? {
    return nativeAd?.advertiser
  }

  var extraAssets: [String: Any]?

  var adChoicesView: UIView?

  var mediaView: UIView? {
    return nativeAd?.mediaView
  }

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  var delegate: GADMediationNativeAdEventDelegate?

  /// Completion handler called after ad load
  var completionHandler: GADMediationNativeLoadCompletionHandler?

  required override init() {
    super.init()
  }

  func loadNativeAd(
    for adConfiguration: GADMediationNativeAdConfiguration,
    completionHandler: @escaping GADMediationNativeLoadCompletionHandler
  ) {
    let adLoader = SampleNativeAdLoader()
    let sampleRequest = SampleNativeAdRequest()

    // The Google Mobile Ads SDK requires the image assets to be downloaded automatically unless
    // the publisher specifies otherwise by using the GADNativeAdImageAdLoaderOptions object's
    // disableImageLoading property. If your network doesn't have an option like this and instead
    // only ever returns URLs for images (rather than the images themselves), your adapter should
    // download image assets on behalf of the publisher. This should be done after receiving the
    // native ad object from your network's SDK, and before calling the connector's
    // adapter:didReceiveMediatedNativeAd: method.
    sampleRequest.shouldDownloadImages = true
    sampleRequest.preferredImageOrientation = NativeAdImageOrientation.any
    sampleRequest.shouldRequestMultipleImages = false
    let options = adConfiguration.options
    for loaderOptions: GADAdLoaderOptions in options {
      if let imageOptions = loaderOptions as? GADNativeAdImageAdLoaderOptions {
        sampleRequest.shouldRequestMultipleImages = imageOptions.shouldRequestMultipleImages
        // If the GADNativeAdImageAdLoaderOptions' disableImageLoading property is
        // YES, the adapter should send just the URLs for the images.
        sampleRequest.shouldDownloadImages = !imageOptions.disableImageLoading
      } else if let mediaOptions = loaderOptions as? GADNativeAdMediaAdLoaderOptions {
        switch mediaOptions.mediaAspectRatio {
        case GADMediaAspectRatio.landscape:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientation.landscape
        case GADMediaAspectRatio.portrait:
          sampleRequest.preferredImageOrientation = NativeAdImageOrientation.portrait
        default: sampleRequest.preferredImageOrientation = NativeAdImageOrientation.any
        }
      }
    }
    // This custom event uses the server parameter to carry an ad unit ID, which is the most common
    // use case.
    adLoader.delegate = self
    adLoader.adUnitID = adConfiguration.credentials.settings["parameter"] as? String
    self.completionHandler = completionHandler
    adLoader.fetchAd(sampleRequest)
  }

  // Indicates if the custom event handles user clicks. Return YES if the custom event should handle
  // user clicks.
  func handlesUserClicks() -> Bool {
    return false
  }
  func handlesUserImpressions() -> Bool {
    return false
  }
}

extension SampleCustomEventNativeAdSwift: SampleNativeAdLoaderDelegate {
  func adLoader(_ adLoader: SampleNativeAdLoader, didReceive nativeAd: SampleNativeAd) {
    extraAssets = [
      SampleCustomEventConstantsSwift.awesomenessKey: nativeAd.degreeOfAwesomeness ?? ""
    ]

    if let image = nativeAd.image {
      images = [GADNativeAdImage(image: image)]
    } else {
      let imageUrl = URL(fileURLWithPath: nativeAd.imageURL)
      images = [GADNativeAdImage(url: imageUrl, scale: nativeAd.imageScale)]
    }
    if let mappedIcon = nativeAd.icon {
      icon = GADNativeAdImage(image: mappedIcon)
    } else {
      let iconURL = URL(fileURLWithPath: nativeAd.iconURL)
      icon = GADNativeAdImage(url: iconURL, scale: nativeAd.iconScale)
    }

    adChoicesView = SampleAdInfoView()
    self.nativeAd = nativeAd
    if let handler = completionHandler {
      delegate = handler(self, nil)
    }
  }

  func adLoader(_ adLoader: SampleNativeAdLoader, didFailToLoadAdWith errorCode: SampleErrorCode) {
    let error = SampleCustomEventUtilsSwift.SampleCustomEventErrorWithCodeAndDescription(
      code: SampleCustomEventErrorCodeSwift.SampleCustomEventErrorAdLoadFailureCallback,
      description: "Sample SDK returned an ad load failure callback with error code: \(errorCode)")
    if let handler = completionHandler {
      delegate = handler(nil, error)
    }
  }

  // Because the Sample SDK has click and impression tracking via methods on its native ad object
  // which the developer is required to call, there's no need to pass it a reference to the UIView
  // being used to display the native ad. So there's no need to implement
  // mediatedNativeAd:didRenderInView:viewController:clickableAssetViews:nonClickableAssetViews here.
  // If your mediated network does need a reference to the view, this method can be used to provide
  // one.
  // You can also access the clickable and non-clickable views by asset key if the mediation network
  // needs this information.
  func didRender(
    in view: UIView, clickableAssetViews: [GADNativeAssetIdentifier: UIView],
    nonclickableAssetViews: [GADNativeAssetIdentifier: UIView],
    viewController: UIViewController
  ) {
    // This method is called when the native ad view is rendered. Here you would pass the UIView
    // back to the mediated network's SDK.
    self.nativeAd?.mediaView.playMedia()
  }

  func didRecordClickOnAsset(
    withName assetName: GADNativeAssetIdentifier, view: UIView, viewController: UIViewController
  ) {
    self.nativeAd?.handleClick(on: view)
  }

  func didRecordImpression() {
    nativeAd?.recordImpression()
  }

  func didUntrackView(_ view: UIView?) {
    // This method is called when the mediatedNativeAd is no longer rendered in the provided view.
    // Here you would remove any tracking from the view that has mediated native ad.
  }
}
