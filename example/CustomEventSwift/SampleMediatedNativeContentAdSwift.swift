//
// Copyright (C) 2017 Google, Inc.
//
// SampleMediatedNativeContentAdSwift.swift
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

/// This class is responsible for "mapping" a native content ad to the interface
/// expected by the Google Mobile Ads SDK. The names and data types of assets provided
/// by a mediated network don't always line up with the ones expected by the Google
/// Mobile Ads SDK (one might have "title" while the other expects "headline," for
/// example). It's the job of this "mapper" class to smooth out those wrinkles.
class SampleMediatedNativeContentAdSwift: NSObject {

  var sampleAd: SampleNativeContentAd
  var mappedImages = [Any]()
  var mappedLogo: GADNativeAdImage?
  var extras = [AnyHashable: Any]()
  var nativeAdViewAdOptions: GADNativeAdViewAdOptions?
  let adInfoView = SampleAdInfoView()

  init(sampleNativeContentAd: SampleNativeContentAd, nativeAdViewAdOptions: GADNativeAdViewAdOptions?) {
    sampleAd = sampleNativeContentAd
    super.init()

    extras = [SampleCustomEventConstantsSwift.awesomenessKey: sampleAd.degreeOfAwesomeness ?? ""]
    if let image = sampleAd.image {
      mappedImages = [GADNativeAdImage(image: image)]
    }
    else {
      let imageUrl = URL(fileURLWithPath: sampleAd.imageURL)
      mappedImages = [GADNativeAdImage(url: imageUrl, scale: sampleAd.imageScale)]
    }
    if let logo = sampleAd.logo {
      mappedLogo = GADNativeAdImage(image: logo)
    }
    else {
      let logoURL = URL(fileURLWithPath: sampleAd.logoURL)
      mappedLogo = GADNativeAdImage(url: logoURL, scale: sampleAd.logoScale)
    }
    self.nativeAdViewAdOptions = nativeAdViewAdOptions
  }
}

extension SampleMediatedNativeContentAdSwift : GADMediatedNativeContentAd {

  func headline() -> String? {
    return sampleAd.headline
  }

  func body() -> String? {
    return sampleAd.body
  }

  func images() -> [Any]? {
    return mappedImages
  }

  func logo() -> GADNativeAdImage? {
    return mappedLogo
  }

  func callToAction() -> String? {
    return sampleAd.callToAction
  }

  func advertiser() -> String? {
    return sampleAd.advertiser
  }

  func extraAssets() -> [AnyHashable: Any]? {
    return extras
  }

  func mediatedNativeAdDelegate() -> GADMediatedNativeAdDelegate? {
    return self
  }

  func adChoicesView() -> UIView? {
    return adInfoView
  }

}

extension SampleMediatedNativeContentAdSwift: GADMediatedNativeAdDelegate {
  // Because the Sample SDK handles click and impression tracking via methods on its native
  // ad object, there's no need to pass it a reference to the UIView being used to display
  // the native ad. So there's no need to implement mediatedNativeAd:didRenderInView:viewController
  // here. If your mediated network does need a reference to the view, this method can be used to
  // provide one.
  func mediatedNativeAd(_ mediatedNativeAd: GADMediatedNativeAd, didRenderIn view: UIView, viewController: UIViewController) {
    // This method is called when the native ad view is rendered. Here you would pass the UIView back
    // to the mediated network's SDK.
  }

  func mediatedNativeAd(_ mediatedNativeAd: GADMediatedNativeAd, didUntrackView view: UIView) {
    // This method is called when the mediatedNativeAd is no longer rendered in the provided view.
    // Here you would remove any tracking from the view that has mediated native ad.
  }

  func mediatedNativeAdDidRecordImpression(_ mediatedNativeAd: GADMediatedNativeAd) {
    sampleAd.recordImpression()
  }

  func mediatedNativeAd(_ mediatedNativeAd: GADMediatedNativeAd, didRecordClickOnAssetWithName assetName: String, view: UIView, viewController: UIViewController) {
    sampleAd.handleClick(on: view)
  }
}

