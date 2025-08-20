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

/// A factory class that creates a NativeAdProxy.
final class NativeAdProxyFactory {

  private init() {}

  #if DEBUG
    /// This property will be used by |createProxy| function if set in Debug mode.
    nonisolated(unsafe) static var debugProxy: NativeAdProxy?
  #endif

  static func createProxy(
    with ad: POBNativeAd
  ) -> NativeAdProxy {
    #if DEBUG
      return debugProxy ?? NativeAdProxyImpl(nativeAd: ad)
    #else
      return NativeAdProxyImpl(nativeAd: ad)
    #endif
  }

}

/// A proxy object that translates POBNativeAd properties to MediationNativeAd properties.
/// It also handles downloading images from string URLs because POBNativeAd does not provide image
/// as UIImage.
protocol NativeAdProxy: NSObject, MediationNativeAd, POBNativeAdDelegate {

  /// This view controller should be used to present modal views for the ad.
  @MainActor var viewController: UIViewController { get }

  /// The ad event delegate which is used to report native related information to the Google Mobile Ads SDK.
  var eventDelegate: MediationNativeAdEventDelegate? { get set }

  /// Downloads all the image assets needed for the native ad this proxy represents.
  func downLoadImageAssets(completionHandler: @escaping (PubMaticAdapterError?) -> Void)

}

class NativeAdProxyImpl: NSObject, NativeAdProxy, @unchecked Sendable {

  private let nativeAd: POBNativeAd
  private let imageLoadDispatchGroup: DispatchGroup

  /// An actual view controller used to render the native ad. This only becomes avaialbe after Google Mobile
  /// Ads SDK calls didRender method.
  private var nativeAdViewController: UIViewController?

  var eventDelegate: (any MediationNativeAdEventDelegate)?

  @MainActor var viewController: UIViewController {
    return nativeAdViewController ?? Util.rootViewController()
  }

  init(nativeAd: POBNativeAd) {
    imageLoadDispatchGroup = DispatchGroup()
    self.nativeAd = nativeAd
    super.init()
    self.nativeAd.setAdDelegate(self)
  }

  // MARK: - MediationNativeAd

  var images: [NativeAdImage]?

  var icon: NativeAdImage?

  var adChoicesView: UIView? {
    return nativeAd.adInfoIconView()
  }

  var headline: String? {
    return nativeAd.titleAsset().text
  }

  var body: String? {
    return nativeAd.descriptionAsset().value
  }

  var callToAction: String? {
    return nativeAd.callToActionAsset().value
  }

  var price: String? {
    return nativeAd.priceAsset().value
  }

  var advertiser: String? {
    return nativeAd.advertiserAsset().value
  }

  var starRating: NSDecimalNumber? {
    let rating = NSDecimalNumber(string: nativeAd.ratingAsset().value)
    guard rating != NSDecimalNumber.notANumber else { return nil }
    return rating
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

  // POBNativeAd does not have an equivalent property.
  var extraAssets: [String: Any]?

  // POBNativeAd does not have an equivalent property.
  var store: String?

  func didRender(
    in view: UIView,
    clickableAssetViews: [GADNativeAssetIdentifier: UIView],
    nonclickableAssetViews: [GADNativeAssetIdentifier: UIView],
    viewController: UIViewController
  ) {
    nativeAdViewController = viewController
    nativeAd.registerView(forInteractions: view, clickableViews: Array(clickableAssetViews.values))
  }

  // MARK: - POBNativeAdDelegate

  func nativeAdDidRecordImpression(_ nativeAd: any POBNativeAd) {
    eventDelegate?.reportImpression()
  }

  func nativeAdDidRecordClick(_ nativeAd: any POBNativeAd) {
    eventDelegate?.reportClick()
  }

  func nativeAdWillPresentModal(_ nativeAd: any POBNativeAd) {
    eventDelegate?.willPresentFullScreenView()
  }

  func nativeAdDidDismissModal(_ nativeAd: any POBNativeAd) {
    eventDelegate?.didDismissFullScreenView()
  }

  // MARK: - NativeAdProxy

  func downLoadImageAssets(
    completionHandler: @escaping (PubMaticAdapterError?) -> Void
  ) {
    // Load an icon image
    nonisolated(unsafe) var nativeAdIcon: NativeAdImage?
    nonisolated(unsafe) var nativeAdIconDownloadError: PubMaticAdapterError?
    imageLoadDispatchGroup.enter()
    downloadImage(from: nativeAd.iconAsset().imageURL) { [weak self] image, error in
      nativeAdIconDownloadError = error
      if let image {
        nativeAdIcon = NativeAdImage(image: image)
      }
      self?.imageLoadDispatchGroup.leave()
    }

    // Load a main image.
    nonisolated(unsafe) var nativeAdImage: NativeAdImage?
    nonisolated(unsafe) var nativeAdImageDownloadError: PubMaticAdapterError?
    imageLoadDispatchGroup.enter()
    downloadImage(from: nativeAd.mainImageAsset().imageURL) { [weak self] image, error in
      nativeAdImageDownloadError = error
      if let image {
        nativeAdImage = NativeAdImage(image: image)
      }
      self?.imageLoadDispatchGroup.leave()
    }

    // Upon completing the image loads, calls the completion handler.
    imageLoadDispatchGroup.notify(queue: .main) { [weak self] in
      guard let self else { return }

      guard nativeAdIconDownloadError == nil else {
        completionHandler(nativeAdIconDownloadError!)
        return
      }

      guard nativeAdImageDownloadError == nil else {
        completionHandler(nativeAdImageDownloadError!)
        return
      }

      // Set the downloaded image assets.
      self.icon = nativeAdIcon
      if let nativeAdImage {
        self.images = [nativeAdImage]
      }
      completionHandler(nil)
    }

  }

  private func downloadImage(
    from urlString: String?,
    completionHandler: @Sendable @escaping (UIImage?, PubMaticAdapterError?) -> Void
  ) {
    guard let urlString else {
      // Not failure. An image does not exists for the loaded native ad.
      completionHandler(nil, nil)
      return
    }

    guard let url = URL(string: urlString) else {
      completionHandler(
        nil,
        PubMaticAdapterError(
          errorCode: .failedToLoadNativeAdImageSource,
          description: "Invalid image URL. URL: \(urlString)"))
      return
    }

    URLSession.shared.dataTask(with: url) { data, _, error in
      guard let data, error == nil else {
        completionHandler(
          nil,
          PubMaticAdapterError(
            errorCode: .failedToLoadNativeAdImageSource,
            description: "Failed to load a native ad image source."))
        return
      }

      guard let image = UIImage(data: data) else {
        completionHandler(
          nil,
          PubMaticAdapterError(
            errorCode: .failedToLoadNativeAdImageSource,
            description: "Downloaded asset is not an image."))
        return
      }
      completionHandler(image, nil)
    }.resume()
  }

}
