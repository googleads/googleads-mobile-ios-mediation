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

import GoogleMobileAds
import UIKit

@_implementationOnly import HyBid

/// Factory that creates Client.
final class HybidClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: HybidClient?
  #endif

  static func createClient() -> HybidClient {
    #if DEBUG
      return debugClient ?? HybidClientImpl()
    #else
      return HybidClientImpl()
    #endif
  }

}

protocol HybidClient: NSObject {

  /// Returns a version string of HyBid SDK.
  func version() -> String

  /// Initializes the HyBid SDK. The completion handle is called without an error object if HyBid
  /// SDK was initialized successfully.
  func initialize(
    with appToken: String, COPPA: Bool?, TFUA: Bool?,
    completionHandler: @escaping (VerveAdapterError?) -> Void)

  /// Collects the bidding signals.
  func collectSignals() -> String

  /// Verifies the given banner size.
  func isValidBannerSize(_ size: CGSize) -> Bool

  /// Loads a RTB banner ad.
  func loadRTBBannerAd(with bidResponse: String, size: CGSize, delegate: Any)
    throws(VerveAdapterError)

  /// Loads a RTB interstitial ad.
  func loadRTBInterstitialAd(with bidResponse: String, delegate: Any)

  /// Presents the interstitial ad.
  func presentInterstitialAd(from viewController: UIViewController) throws(VerveAdapterError)

  /// Loads a RTB rewarded ad.
  func loadRTBRewardedAd(with bidResponse: String, delegate: Any)

  /// Presents the rewarded ad.
  func presentRewardedAd(from viewController: UIViewController) throws(VerveAdapterError)

  /// Loads a RTB native ad.
  func loadRTBNativeAd(with bidResponse: String, delegate: Any)

  /// Fetches assets for the provided native ad.
  func fetchAssets(for nativeAd: Any, delegate: Any)
}

private class HybidClientImpl: NSObject, HybidClient {

  private var adView: Any?
  private var interstitialAd: Any?
  private var rewardedAd: Any?
  private var nativeAdLoader: Any?

  func version() -> String {
    return HyBid.sdkVersion()
  }

  func initialize(
    with appToken: String,
    COPPA: Bool?,
    TFUA: Bool?,
    completionHandler: @escaping (VerveAdapterError?) -> Void
  ) {
    if let COPPA {
      guard !COPPA else {
        HyBid.setCoppa(true)
        completionHandler(
          VerveAdapterError(errorCode: .childUser, description: "Verve does not serve child user."))
        return
      }
      HyBid.setCoppa(false)
    }

    if let TFUA {
      guard !TFUA else {
        completionHandler(
          VerveAdapterError(errorCode: .childUser, description: "Verve does not serve child user."))
        return
      }
    }

    HyBid.initWithAppToken(appToken) { success in
      guard success else {
        completionHandler(
          VerveAdapterError(
            errorCode: .failedToInitializeHyBidSDK, description: "Verve SDK failed to initialize."))
        return
      }
      completionHandler(nil)
    }
  }

  func collectSignals() -> String {
    return HyBid.getEncodedCustomRequestSignalData("Admob") ?? ""
  }

  func isValidBannerSize(_ size: CGSize) -> Bool {
    return (try? getBannerSize(size)) != nil
  }

  private func getBannerSize(_ size: CGSize) throws(VerveAdapterError) -> HyBidAdSize {
    let width = size.width
    let height = size.height

    switch (width, height) {
    case (320, 50): return .size_320x50
    case (300, 250): return .size_300x250
    case (300, 50): return .size_300x50
    case (320, 480): return .size_320x480
    case (1024, 768): return .size_1024x768
    case (768, 1024): return .size_768x1024
    case (728, 90): return .size_728x90
    case (160, 600): return .size_160x600
    case (250, 250): return .size_250x250
    case (300, 600): return .size_300x600
    case (320, 100): return .size_320x100
    case (480, 320): return .size_480x320
    default:
      throw VerveAdapterError(
        errorCode: .unsupportedBannerSize,
        description: "Unsupported banner size. Width: \(width) Height: \(height)")
    }
  }

  func loadRTBBannerAd(
    with bidResponse: String,
    size: CGSize,
    delegate: Any
  ) throws(VerveAdapterError) {
    guard let delegate = delegate as? HyBidAdViewDelegate else { return }

    let view = HyBidAdView(size: try getBannerSize(size))
    view?.delegate = delegate

    if let wrapper = view as? HyBidAdViewWrapper {
      wrapper.stopAutoRefresh()
      wrapper.autoShowOnLoad = true
      wrapper.renderAd(withContent: bidResponse, with: delegate)
    }
    self.adView = view
  }

  func loadRTBInterstitialAd(
    with bidResponse: String,
    delegate: Any
  ) {
    guard let delegate = delegate as? HyBidInterstitialAdDelegate else { return }
    let ad = HyBidInterstitialAd(delegate: delegate)
    (ad as? HyBidAdWrapper)?.prepareAdWithContent(adContent: bidResponse)
    self.interstitialAd = ad
  }

  func presentInterstitialAd(from viewController: UIViewController) throws(VerveAdapterError) {
    guard let wrapper = interstitialAd as? HyBidAdWrapper, wrapper.isReady else {
      throw VerveAdapterError(
        errorCode: .notReadyForPresentation,
        description:
          "The interstitial ad is not ready for presentation. isReady: \(String(describing: (interstitialAd as? HyBidAdWrapper)?.isReady))"
      )
    }
    wrapper.show(from: viewController)
  }

  func loadRTBRewardedAd(
    with bidResponse: String,
    delegate: Any
  ) {
    guard let delegate = delegate as? HyBidRewardedAdDelegate else { return }
    let ad = HyBidRewardedAd(delegate: delegate)
    (ad as? HyBidAdWrapper)?.prepareAdWithContent(adContent: bidResponse)
    self.rewardedAd = ad
  }

  func presentRewardedAd(from viewController: UIViewController) throws(VerveAdapterError) {
    guard let wrapper = rewardedAd as? HyBidAdWrapper, wrapper.isReady else {
      throw VerveAdapterError(
        errorCode: .notReadyForPresentation,
        description:
          "The rewarded ad is not ready for presentation. isReady: \(String(describing: (rewardedAd as? HyBidAdWrapper)?.isReady))"
      )
    }
    wrapper.show(from: viewController)
  }

  func loadRTBNativeAd(
    with bidResponse: String,
    delegate: Any
  ) {
    guard let delegate = delegate as? HyBidNativeAdLoaderDelegate else { return }
    let loader = HyBidNativeAdLoader()

    if let wrapper = loader as? HyBidNativeLoaderWrapper {
      wrapper.stopAutoRefresh()
      wrapper.prepareNativeAd(with: delegate, withContent: bidResponse)
    }
    self.nativeAdLoader = loader
  }

  func fetchAssets(
    for nativeAd: Any,
    delegate: Any
  ) {
    (nativeAd as? HyBidNativeAdWrapper)?.fetchAssets(with: delegate)
  }
}

// MARK: - Dynamic Dispatch Wrappers

// These local @objc protocols force the Swift compiler to use objc_msgSend. This bypasses "Dispatch Thunk" linker errors caused by linking a stable Swift binary (Distribution=YES) against the raw HyBid source code provided by CocoaPods.

@objc private protocol HyBidAdWrapper {
  var isReady: Bool { get }
  func prepareAdWithContent(adContent: String)
  func show(from: UIViewController)
}

@objc private protocol HyBidAdViewWrapper {
  func renderAd(withContent: String, with: Any)
  func stopAutoRefresh()
  var autoShowOnLoad: Bool { get set }
}

@objc private protocol HyBidNativeLoaderWrapper {
  func prepareNativeAd(with: Any, withContent: String)
  func stopAutoRefresh()
}

@objc private protocol HyBidNativeAdWrapper {
  func fetchAssets(with: Any)
}
