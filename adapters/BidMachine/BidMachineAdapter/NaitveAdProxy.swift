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

import BidMachine
import GoogleMobileAds
import UIKit

/// A factory class that creates a NativeAdProxy.
final class NativeAdProxyFactory {

  private init() {}

  #if DEBUG
    /// This property will be used by |createProxy| function if set in Debug mode.
    nonisolated(unsafe) static var debugProxy: NativeAdProxy?
  #endif

  @MainActor
  static func createProxy(with ad: BidMachine.NativeAd) -> NativeAdProxy {
    #if DEBUG
      if let debugProxy {
        return debugProxy
      }
      return NativeAdProxyImpl(nativeAd: ad)
    #else
      return NativeAdProxyImpl(nativeAd: ad)
    #endif
  }

}

/// A proxy object that translates BidMachineNative properties to MediationNativeAd properties.
protocol NativeAdProxy: NSObject, MediationNativeAd {
}

final class NativeAdProxyImpl: NSObject, NativeAdProxy {

  /// The native ad data provided to the Google Mobile Ads SDK.
  private struct Assets {

    let headline: String?
    let body: String?
    let callToAction: String?
    let icon: NativeAdImage?
    let images: [NativeAdImage]?
    let starRating: NSDecimalNumber?
    let advertiser: String?
    let mediaView: UIView
    let adChoicesView: UIView
    let hasVideoContent: Bool

    @MainActor
    init(nativeAd: BidMachine.NativeAd) {
      headline = nativeAd.title
      body = nativeAd.body
      callToAction = nativeAd.callToAction
      icon = Self.nativeAdImage(from: nativeAd.icon)
      images = Self.nativeAdImage(from: nativeAd.mainImage).map { [$0] }
      starRating = nativeAd.starRating.map { NSDecimalNumber(decimal: $0.decimalValue) }
      advertiser = nativeAd.advertiser
      mediaView = nativeAd.mediaView
      adChoicesView = nativeAd.adChoice
      hasVideoContent = nativeAd.hasVideoContent
    }

    /// Returns the preloaded image of the asset, or its URL if the image is not available.
    private static func nativeAdImage(from image: BidMachine.NativeAd.Image?) -> NativeAdImage? {
      if let preloadedImage = image?.image {
        return NativeAdImage(image: preloadedImage)
      }
      if let url = image?.url {
        return NativeAdImage(url: url, scale: 1.0)
      }
      return nil
    }

  }

  private let nativeAd: BidMachine.NativeAd
  private let assets: Assets

  // MARK: -  GADMediationNativeAd

  var headline: String? { assets.headline }
  var body: String? { assets.body }
  var callToAction: String? { assets.callToAction }
  var icon: NativeAdImage? { assets.icon }
  var images: [NativeAdImage]? { assets.images }
  var starRating: NSDecimalNumber? { assets.starRating }
  var advertiser: String? { assets.advertiser }
  var store: String?  // Not supported by BidMachine
  var price: String?  // Not supported by BidMachine
  var extraAssets: [String: Any]?  // Not supported by BidMachine

  var mediaView: UIView? { assets.mediaView }
  var adChoicesView: UIView? { assets.adChoicesView }
  var hasVideoContent: Bool { assets.hasVideoContent }

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
    var clickables = [BidMachine.NativeAd.Entry]()
    for (assetIdentifier, clickableView) in clickableAssetViews {
      switch assetIdentifier {
      case .headlineAsset:
        clickables.append(BidMachine.NativeAd.Entry(clickableView, as: .title))
      case .bodyAsset:
        clickables.append(BidMachine.NativeAd.Entry(clickableView, as: .body))
      case .callToActionAsset:
        clickables.append(BidMachine.NativeAd.Entry(clickableView, as: .callToAction))
      case .iconAsset:
        clickables.append(BidMachine.NativeAd.Entry(clickableView, as: .icon))
      case .imageAsset:
        clickables.append(BidMachine.NativeAd.Entry(clickableView, as: .mainImage))
      case .advertiserAsset:
        clickables.append(BidMachine.NativeAd.Entry(clickableView, as: .advertiser))
      case .starRatingAsset:
        clickables.append(BidMachine.NativeAd.Entry(clickableView, as: .starRating))
      default:
        // Non translatable view.
        continue
      }
    }

    let nativeAd = nativeAd
    Task { @MainActor in
      nativeAd.rootViewController = viewController
      nativeAd.bind(view, clickables: clickables)
    }
  }

  func didUntrackView(_ view: UIView?) {
    let nativeAd = nativeAd
    Task { @MainActor in
      nativeAd.unbind()
    }
  }

  // MARK: - NativeAdProxy

  @MainActor
  fileprivate init(nativeAd: BidMachine.NativeAd) {
    self.nativeAd = nativeAd
    self.assets = Assets(nativeAd: nativeAd)
  }

}
