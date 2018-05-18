//
// Copyright (C) 2017 Google, Inc.
//
// SampleMediatedNativeAdSwift.swift
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

/// This class is responsible for "mapping" a native ad to the interface
/// expected by the Google Mobile Ads SDK. The names and data types of assets provided
/// by a mediated network don't always line up with the ones expected by the Google
/// Mobile Ads SDK (one might have "title" while the other expects "headline," for
/// example). It's the job of this "mapper" class to smooth out those wrinkles.
class SampleMediatedUnifiedNativeAdSwift : NSObject {
  // You may notice that this class and the Mediation Adapter's
  // SampleAdapterMediatedNativeAd class look an awful lot alike. That's not
  // by accident. They're the same class, with the same methods and properties,
  // but with two different names.
  //
  // Mediation adapters and custom events map their native ads for the
  // Google Mobile Ads SDK using an extension of GADMediatedUnifiedNativeAd. Because both
  // the adapter and custom event in this example are mediating the same Sample
  // SDK, they both need the same work done: take a native ad object from the
  // Sample SDK and map it to the interface the Google Mobile Ads SDK expects.
  // Thus, the same classes work for both.
  //
  // Because we wanted this project to have a complete example of an
  // adapter and a complete example of a custom event (and we didn't want to
  // share code between them), they each get their own copies of this class,
  // with slightly different names.

  var sampleAd : SampleNativeAd
  var mappedImages = [GADNativeAdImage]()
  var mappedIcon: GADNativeAdImage?
  var extras = [String:Any]()
  var nativeAdViewAdOptions: GADNativeAdViewAdOptions?
  let adInfoView = SampleAdInfoView()
  var sampleMediaView : SampleMediaView?
  init(sampleNativeAd : SampleNativeAd, nativeAdViewAdOptions : GADNativeAdViewAdOptions?) {
    sampleAd = sampleNativeAd
    super.init()
    extras = [SampleCustomEventConstantsSwift.awesomenessKey: sampleAd.degreeOfAwesomeness ?? ""]
    if let image = sampleAd.image {
      mappedImages = [GADNativeAdImage(image : image)]
    }
    else {
      let imageUrl = URL(fileURLWithPath : sampleAd.imageURL)
      mappedImages = [GADNativeAdImage(url : imageUrl, scale : sampleAd.imageScale)]
    }
    if let icon = sampleAd.icon {
      mappedIcon = GADNativeAdImage(image : icon)
    }
    else {
      let iconURL = URL(fileURLWithPath : sampleNativeAd.iconURL)
      mappedIcon = GADNativeAdImage(url : iconURL, scale : sampleAd.iconScale)
    }
    self.nativeAdViewAdOptions = nativeAdViewAdOptions
    self.sampleMediaView = self.sampleAd.mediaView
  }

}

/// This is a concrete implementation for the GADMediatedUnifiedNativeAd protocol.
extension SampleMediatedUnifiedNativeAdSwift : GADMediatedUnifiedNativeAd {
  var advertiser : String? {
    return sampleAd.advertiser
  }

  var headline : String? {
    return sampleAd.headline
  }

  var images : [GADNativeAdImage]? {
    return mappedImages
  }

  var body : String? {
    return sampleAd.body
  }

  var icon : GADNativeAdImage? {
    return mappedIcon
  }

  var callToAction : String? {
    return sampleAd.callToAction
  }

  var starRating : NSDecimalNumber? {
    return sampleAd.starRating
  }

  var store : String? {
    return sampleAd.store
  }

  var price : String? {
    return sampleAd.price
  }

  var adChoicesView : UIView? {
    return adInfoView
  }

  var extraAssets : [String : Any]? {
    return extras
  }

  var mediaView : UIView?{
    return self.sampleMediaView!
  }

  var hasVideoContent : Bool {
    return self.sampleAd.mediaView != nil
  }

  func didRecordImpression() {
    sampleAd.recordImpression()
  }

  // Because the Sample SDK has click and impression tracking via methods on its native ad object
  // which the developer is required to call, there's no need to pass it a reference to the UIView
  // being used to display the native ad. So there's no need to implement
  // mediatedNativeAd:didRenderInView:viewController:clickableAssetViews:nonClickableAssetViews here.
  // If your mediated network does need a reference to the view, this method can be used to provide
  // one.
  // You can also access the clickable and non-clickable views by asset key if the mediation network
  // needs this information.
  func didRender(in view: UIView, clickableAssetViews: [GADUnifiedNativeAssetIdentifier : UIView],
                               nonclickableAssetViews: [GADUnifiedNativeAssetIdentifier : UIView],
                                       viewController: UIViewController) {
    // This method is called when the native ad view is rendered. Here you would pass the UIView
    // back to the mediated network's SDK.
    self.sampleAd.mediaView.playMedia()
  }

  func didRecordClickOnAsset(withName assetName: GADUnifiedNativeAssetIdentifier, view: UIView, viewController: UIViewController) {
    sampleAd.handleClick(on: view)
  }

  func didUntrackView(_ view: UIView?) {
    // This method is called when the mediatedNativeAd is no longer rendered in the provided view.
    // Here you would remove any tracking from the view that has mediated native ad.
  }
}
