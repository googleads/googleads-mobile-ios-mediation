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
import HyBid
import UIKit

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
    with appToken: String, testMode: Bool, COPPA: Bool?, TFUA: Bool?,
    completionHandler: @escaping (VerveAdapterError?) -> Void)

  /// Collects the bidding signals.
  func collectSignals() -> String

  /// Gets HyBidAdSize for the provided size. Throws an error if the size is not supported by HiBid SDK.
  @discardableResult
  func getBannerSize(_ size: CGSize) throws(VerveAdapterError) -> HyBidAdSize

  /// Loads a RTB banner ad.
  func loadRTBBannerAd(with bidResponse: String, size: CGSize, delegate: HyBidAdViewDelegate)
    throws(VerveAdapterError)

  /// Loads a RTB interstitial ad.
  func loadRTBInterstitialAd(with bidResponse: String, delegate: HyBidInterstitialAdDelegate)

  /// Presents the interstitial ad.
  func presentInterstitialAd(from viewController: UIViewController) throws(VerveAdapterError)

  /// Loads a RTB rewarded ad.
  func loadRTBRewardedAd(with bidResponse: String, delegate: HyBidRewardedAdDelegate)

  /// Presents the rewarded ad.
  func presentRewardedAd(from viewController: UIViewController) throws(VerveAdapterError)

  /// Loads a RTB native ad.
  func loadRTBNativeAd(with bidResponse: String, delegate: HyBidNativeAdLoaderDelegate)

  /// Fetches assets for the provided native ad.
  func fetchAssets(for nativeAd: HyBidNativeAd, delegate: HyBidNativeAdFetchDelegate)
}

final class HybidClientImpl: NSObject, HybidClient {

  private var adView: HyBidAdView?
  private var interstitialAd: HyBidInterstitialAd?
  private var rewardedAd: HyBidRewardedAd?
  private var nativeAdLoader: HyBidNativeAdLoader?

  func version() -> String {
    return HyBid.sdkVersion()
  }

  func initialize(
    with appToken: String,
    testMode: Bool,
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

    if testMode {
      HyBid.setTestMode(true)
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
    return HyBid.getCustomRequestSignalData("Admob") ?? ""
  }

  @discardableResult
  func getBannerSize(_ size: CGSize) throws(VerveAdapterError) -> HyBidAdSize {
    let width = size.width
    let height = size.height

    // For the full list of supported banner sizes, refer to HyBidAdSize.h.
    if width == 320 && height == 50 {
      return .size_320x50
    } else if width == 300 && height == 250 {
      return .size_300x250
    } else if width == 300 && height == 50 {
      return .size_300x50
    } else if width == 320 && height == 480 {
      return .size_320x480
    } else if width == 1024 && height == 768 {
      return .size_1024x768
    } else if width == 768 && height == 1024 {
      return .size_768x1024
    } else if width == 728 && height == 90 {
      return .size_728x90
    } else if width == 160 && height == 600 {
      return .size_160x600
    } else if width == 250 && height == 250 {
      return .size_250x250
    } else if width == 300 && height == 600 {
      return .size_300x600
    } else if width == 320 && height == 100 {
      return .size_320x100
    } else if width == 480 && height == 320 {
      return .size_480x320
    } else {
      throw VerveAdapterError(
        errorCode: .unsupportedBannerSize,
        description: "Unsupported banner size. Width: \(width) Height: \(height)")
    }
  }

  func loadRTBBannerAd(
    with bidResponse: String,
    size: CGSize,
    delegate: HyBidAdViewDelegate
  ) throws(VerveAdapterError) {
    adView = HyBidAdView(size: try getBannerSize(size))
    adView?.stopAutoRefresh()
    adView?.autoShowOnLoad = true
    adView?.delegate = delegate
    adView?.renderAd(withContent: bidResponse, with: delegate)
  }

  func loadRTBInterstitialAd(
    with bidResponse: String,
    delegate: HyBidInterstitialAdDelegate
  ) {
    interstitialAd = HyBidInterstitialAd(delegate: delegate)
    interstitialAd?.prepareAdWithContent(adContent: bidResponse)
  }

  func presentInterstitialAd(from viewController: UIViewController) throws(VerveAdapterError) {
    guard let interstitialAd, interstitialAd.isReady else {
      throw VerveAdapterError(
        errorCode: .notReadyForPresentation,
        description:
          "The interstitial ad is not ready for presentation. isReady: \(String(describing: interstitialAd?.isReady))"
      )
    }
    interstitialAd.show(from: viewController)
  }

  func loadRTBRewardedAd(
    with bidResponse: String,
    delegate: HyBidRewardedAdDelegate
  ) {
    rewardedAd = HyBidRewardedAd(delegate: delegate)
    rewardedAd?.prepareAdWithContent(adContent: bidResponse)
  }

  func presentRewardedAd(from viewController: UIViewController) throws(VerveAdapterError) {
    guard let rewardedAd, rewardedAd.isReady else {
      throw VerveAdapterError(
        errorCode: .notReadyForPresentation,
        description:
          "The rewarded ad is not ready for presentation. isReady: \(String(describing: rewardedAd?.isReady))"
      )
    }
    rewardedAd.show(from: viewController)
  }

  func loadRTBNativeAd(
    with bidResponse: String,
    delegate: any HyBidNativeAdLoaderDelegate
  ) {
    nativeAdLoader = HyBidNativeAdLoader()
    nativeAdLoader?.stopAutoRefresh()
    nativeAdLoader?.prepareNativeAd(with: delegate, withContent: bidResponse)
  }

  func fetchAssets(
    for nativeAd: HyBidNativeAd,
    delegate: HyBidNativeAdFetchDelegate
  ) {
    nativeAd.fetchAssets(with: delegate)
  }

}
