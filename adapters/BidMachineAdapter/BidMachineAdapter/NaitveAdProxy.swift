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

  static func createProxy(
    with ad: BidMachineAdProtocol
  ) throws(BidMachineAdapterError) -> NativeAdProxy {
    #if DEBUG
      if let debugProxy {
        return debugProxy
      }
      return try NativeAdProxyImpl(nativeAd: ad)
    #else
      return try NativeAdProxyImpl(nativeAd: ad)
    #endif
  }

}

/// A proxy object that translates BidMachineNative properties to MediationNativeAd properties.
/// It also handles downloading images from string URLs because BidMachineNative does not provide
/// images as UIImage.
protocol NativeAdProxy: NSObject, MediationNativeAd, BidMachineNativeAdRendering {

  /// Downloads all the image assets needed for the native ad this proxy represents.
  func downLoadImageAssets(completionHandler: @escaping (BidMachineAdapterError?) -> Void)

}

final class NativeAdProxyImpl: NSObject, NativeAdProxy, @unchecked Sendable {

  private let nativeAd: BidMachineNative
  private let imageLoadDispatchGroup: DispatchGroup

  // MARK: - BidMachineNativeAdRendering

  var titleLabel: UILabel?

  var callToActionLabel: UILabel?

  var descriptionLabel: UILabel?

  var iconView: UIImageView?

  var mediaContainerView: UIView?

  var adChoiceView: UIView?

  // MARK: -  GADMediationNativeAd

  var headline: String? { nativeAd.title }
  var body: String? { nativeAd.description }
  var callToAction: String? { nativeAd.cta }
  private(set) var icon: NativeAdImage?
  private(set) var images: [NativeAdImage]?

  var starRating: NSDecimalNumber?  // Not supported by BidMachine
  var advertiser: String?  // Not supported by BidMachine
  var store: String?  // Not supported by BidMachine
  var price: String?  // Not supported by BidMachine
  var extraAssets: [String: Any]?  // Not supported by BidMachine

  var hasVideoContent: Bool { nativeAd.isVideo }

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
    nativeAd.controller = viewController

    var interactableAssetTypes = [BidMachineNativeAdRenderingAssetType]()
    for (assetIdentifier, clickableView) in clickableAssetViews {
      switch assetIdentifier {
      case .headlineAsset:
        interactableAssetTypes.append(.titleLabel)
        titleLabel = clickableView as? UILabel
      case .bodyAsset:
        interactableAssetTypes.append(.descriptionLabel)
        descriptionLabel = clickableView as? UILabel
      case .callToActionAsset:
        interactableAssetTypes.append(.callToActionLabel)
        callToActionLabel = clickableView as? UILabel
      case .iconAsset:
        interactableAssetTypes.append(.iconView)
        iconView = clickableView as? UIImageView
      case .imageAsset:
        interactableAssetTypes.append(.mediaContainerView)
        mediaContainerView = clickableView
      case .mediaViewAsset:
        interactableAssetTypes.append(.mediaContainerView)
        mediaContainerView = clickableView
      case .adChoicesViewAsset:
        interactableAssetTypes.append(.adChoiceView)
        adChoiceView = clickableView
      default:
        // Non translatable view.
        continue
      }
    }
    nativeAd.registerAssetsForInteraction(interactableAssetTypes.map { $0.rawValue })

    for (assetIdentifier, nonclickableView) in nonclickableAssetViews {
      switch assetIdentifier {
      case .headlineAsset:
        titleLabel = nonclickableView as? UILabel
      case .bodyAsset:
        descriptionLabel = nonclickableView as? UILabel
      case .callToActionAsset:
        callToActionLabel = nonclickableView as? UILabel
      case .iconAsset:
        iconView = nonclickableView as? UIImageView
      case .imageAsset:
        mediaContainerView = nonclickableView
      case .mediaViewAsset:
        mediaContainerView = nonclickableView
      case .adChoicesViewAsset:
        adChoiceView = nonclickableView
      default:
        // Non translatable view.
        continue
      }
    }

    do {
      try nativeAd.presentAd(view, self)
    } catch {
      Util.log("Failed to present native ad with error: \(error)")
    }
  }

  // MARK: - NativeAdProxy

  fileprivate init(nativeAd: BidMachineAdProtocol) throws(BidMachineAdapterError) {
    guard let nativeAd = nativeAd as? BidMachineNative else {
      throw BidMachineAdapterError(
        errorCode: .bidMachineReturnedNonNativeAd,
        description: "Received non-native ad in the native's didLoadAd delegate method.")
    }
    imageLoadDispatchGroup = DispatchGroup()
    self.nativeAd = nativeAd
  }

  func downLoadImageAssets(completionHandler: @escaping (BidMachineAdapterError?) -> Void) {
    // Load an icon image.
    nonisolated(unsafe) var nativeAdIcon: NativeAdImage?
    nonisolated(unsafe) var nativeAdIconDownloadError: BidMachineAdapterError?
    imageLoadDispatchGroup.enter()
    downloadImage(from: nativeAd.icon) { [weak self] image, error in
      nativeAdIconDownloadError = error
      if let image {
        nativeAdIcon = NativeAdImage(image: image)
      }
      self?.imageLoadDispatchGroup.leave()
    }

    // Load a main image.
    nonisolated(unsafe) var nativeAdImage: NativeAdImage?
    nonisolated(unsafe) var nativeAdImageDownloadError: BidMachineAdapterError?
    imageLoadDispatchGroup.enter()
    downloadImage(from: nativeAd.main) { [weak self] image, error in
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
    completionHandler: @Sendable @escaping (UIImage?, BidMachineAdapterError?) -> Void
  ) {
    guard let urlString else {
      // Not failure. An image does not exists for the loaded native ad.
      completionHandler(nil, nil)
      return
    }

    guard let url = URL(string: urlString) else {
      completionHandler(
        nil,
        BidMachineAdapterError(
          errorCode: .failedToLoadNativeAdImageSource,
          description: "Invalid image URL. URL: \(urlString)"))
      return
    }

    URLSession.shared.dataTask(with: url) { data, _, error in
      guard let data, error == nil else {
        completionHandler(
          nil,
          BidMachineAdapterError(
            errorCode: .failedToLoadNativeAdImageSource,
            description: "Failed to load a native ad image source."))
        return
      }

      guard let image = UIImage(data: data) else {
        completionHandler(
          nil,
          BidMachineAdapterError(
            errorCode: .failedToLoadNativeAdImageSource,
            description: "Downloaded asset is not an image."))
        return
      }
      completionHandler(image, nil)
    }.resume()
  }

}
