//
// Copyright (C) 2017 Google, Inc.
//
// SampleMediatedNativeAppInstallAdSwift.swift
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

/// This class is responsible for "mapping" a native app install ad to the interface
/// expected by the Google Mobile Ads SDK. The names and data types of assets provided
/// by a mediated network don't always line up with the ones expected by the Google
/// Mobile Ads SDK (one might have "title" while the other expects "headline," for
/// example). It's the job of this "mapper" class to smooth out those wrinkles.
class SampleMediatedNativeAppInstallAdSwift: NSObject {
  // You may notice that this class and the Mediation Adapter's
  // SampleAdapterMediatedNativeAppInstallAd class look an awful lot alike. That's not
  // by accident. They're the same class, with the same methods and properties,
  // but with two different names.
  //
  // Mediation adapters and custom events map their native ads for the
  // Google Mobile Ads SDK using extensions of the same two classes:
  // GADMediatedNativeAppInstallAd and GADMediatedNativeContentAd. Because both
  // the adapter and custom event in this example are mediating the same Sample
  // SDK, they both need the same work done: take a native ad object from the
  // Sample SDK and map it to the interface the Google Mobile Ads SDK expects.
  // Thus, the same classes work for both.
  //
  // Because we wanted this project to have a complete example of an
  // adapter and a complete example of a custom event (and we didn't want to
  // share code between them), they each get their own copies of these classes,
  // with slightly different names.

  var sampleAd: SampleNativeAppInstallAd
  var mappedImages = [Any]()
  var mappedIcon: GADNativeAdImage?
  var extras = [AnyHashable: Any]()
  var nativeAdViewAdOptions: GADNativeAdViewAdOptions?
  let adInfoView = SampleAdInfoView()

  init(sampleNativeAppInstallAd: SampleNativeAppInstallAd, nativeAdViewAdOptions: GADNativeAdViewAdOptions?) {

    sampleAd = sampleNativeAppInstallAd
    super.init()

    extras = [SampleCustomEventConstantsSwift.awesomenessKey: sampleAd.degreeOfAwesomeness ?? ""]
    if let image = sampleAd.image {
      mappedImages = [GADNativeAdImage(image: image)]
    }
    else {
      let imageUrl = URL(fileURLWithPath: sampleAd.imageURL)
      mappedImages = [GADNativeAdImage(url: imageUrl, scale: sampleAd.imageScale)]
    }
    if let icon = sampleAd.icon {
      mappedIcon = GADNativeAdImage(image: icon)
    }
    else {
      let iconURL = URL(fileURLWithPath: sampleNativeAppInstallAd.iconURL)
      mappedIcon = GADNativeAdImage(url: iconURL, scale: sampleAd.iconScale)
    }
    self.nativeAdViewAdOptions = nativeAdViewAdOptions
  }

}

extension SampleMediatedNativeAppInstallAdSwift : GADMediatedNativeAppInstallAd {

  func headline() -> String? {
    return sampleAd.headline
  }

  func images() -> [Any]? {
    return mappedImages
  }

  func body() -> String? {
    return sampleAd.body
  }

  func icon() -> GADNativeAdImage? {
    return mappedIcon
  }

  func callToAction() -> String? {
    return sampleAd.callToAction
  }

  func starRating() -> NSDecimalNumber? {
    return sampleAd.starRating
  }

  func store() -> String? {
    return sampleAd.store
  }

  func price() -> String? {
    return sampleAd.price
  }

  func extraAssets() -> [AnyHashable : Any]? {
    return extras
  }

  func mediatedNativeAdDelegate() -> GADMediatedNativeAdDelegate? {
    return self
  }

  func adChoicesView() -> UIView? {
    return adInfoView
  }
}

extension SampleMediatedNativeAppInstallAdSwift: GADMediatedNativeAdDelegate {

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
