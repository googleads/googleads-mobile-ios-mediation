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
import UIKit

/// Factory that creates Bigo client.
final class BigoClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: BigoClient?
  #endif

  static func createClient() -> BigoClient {
    #if DEBUG
      return debugClient ?? BigoClientImpl()
    #else
      return BigoClientImpl()
    #endif
  }

}

protocol BigoClient: NSObject {

  /// Initializes the BigoADS SDK.
  func initialize(with applicationId: String, testMode: Bool, completion: @escaping () -> Void)

  /// Gets a bidder token from BigoADS.
  func getBidderToken() -> String?

  /// Loads a RTB interstitial ad from BigoADS.
  func loadRTBInterstitialAd(
    for slotId: String, bidPayLoad: String, delegate: BigoInterstitialAdLoaderDelegate)

  /// Presents the Bigo interstitial ad.
  func presentInterstitialAd(
    _ ad: BigoInterstitialAd, viewController: UIViewController,
    interactionDelegate: BigoAdInteractionDelegate)

  /// Loads a RTB reward ad from BigoADS.
  func loadRTBRewardVideoAd(
    for slotId: String, bidPayLoad: String, delegate: BigoRewardVideoAdLoaderDelegate)

  /// Presents the Bigo reward video ad.
  func presentRewardVideoAd(
    _ ad: BigoRewardVideoAd, viewController: UIViewController,
    interactionDelegate: BigoRewardVideoAdInteractionDelegate)

  /// Loads a RTB app splash ad from BigoADS.
  func loadRTBSplashAd(for slotId: String, bidPayLoad: String, delegate: BigoSplashAdLoaderDelegate)

  /// Presents the Bigo splash ad.
  func presentSplashAd(
    _ ad: BigoSplashAd, viewController: UIViewController,
    interactionDelegate: BigoSplashAdInteractionDelegate)

  /// Loads a RTB banner ad from BigoADS.
  func loadRTBBannerAd(
    for slotId: String, bidPayLoad: String, adSize: BigoAdSize, delegate: BigoBannerAdLoaderDelegate
  )

  /// Loads a RTB native ad from BigoADS.
  func loadRTBNativeAd(for slotId: String, bidPayLoad: String, delegate: BigoNativeAdLoaderDelegate)
}

final class BigoClientImpl: NSObject, BigoClient {

  private var interstitialAdLoader: BigoInterstitialAdLoader?
  private var rewardVideoAdLoader: BigoRewardVideoAdLoader?
  private var splashAdLoader: BigoSplashAdLoader?
  private var bannerAdLoader: BigoBannerAdLoader?
  private var nativeAdLoader: BigoNativeAdLoader?

  func initialize(
    with applicationId: String,
    testMode: Bool,
    completion: @escaping () -> Void
  ) {
    let adConfig = BigoAdConfig(appId: applicationId)
    adConfig.testMode = testMode
    BigoAdSdk.sharedInstance().initializeSdk(with: adConfig) {
      completion()
    }
  }

  func getBidderToken() -> String? {
    return BigoAdSdk.sharedInstance().getBidderToken()
  }

  func loadRTBInterstitialAd(
    for slotId: String, bidPayLoad: String, delegate: BigoInterstitialAdLoaderDelegate
  ) {
    let request = BigoInterstitialAdRequest(slotId: slotId)
    request.setServerBidPayload(bidPayLoad)
    interstitialAdLoader = BigoInterstitialAdLoader(interstitialAdLoaderDelegate: delegate)
    interstitialAdLoader?.loadAd(request)
  }

  func presentInterstitialAd(
    _ ad: BigoInterstitialAd, viewController: UIViewController,
    interactionDelegate: BigoAdInteractionDelegate
  ) {
    ad.setAdInteractionDelegate(interactionDelegate)
    ad.show(viewController)
  }

  func loadRTBRewardVideoAd(
    for slotId: String,
    bidPayLoad: String,
    delegate: any BigoRewardVideoAdLoaderDelegate
  ) {
    let request = BigoRewardVideoAdRequest(slotId: slotId)
    request.setServerBidPayload(bidPayLoad)
    rewardVideoAdLoader = BigoRewardVideoAdLoader(rewardVideoAdLoaderDelegate: delegate)
    rewardVideoAdLoader?.loadAd(request)
  }

  func presentRewardVideoAd(
    _ ad: BigoRewardVideoAd,
    viewController: UIViewController,
    interactionDelegate: any BigoRewardVideoAdInteractionDelegate
  ) {
    ad.setRewardVideoAdInteractionDelegate(interactionDelegate)
    ad.show(viewController)
  }

  func loadRTBSplashAd(
    for slotId: String,
    bidPayLoad: String,
    delegate: any BigoSplashAdLoaderDelegate
  ) {
    let request = BigoSplashAdRequest(slotId: slotId)
    request.setServerBidPayload(bidPayLoad)
    splashAdLoader = BigoSplashAdLoader(splashAdLoaderDelegate: delegate)
    splashAdLoader?.loadAd(request)
  }

  func presentSplashAd(
    _ ad: BigoSplashAd,
    viewController: UIViewController,
    interactionDelegate: any BigoSplashAdInteractionDelegate
  ) {
    ad.setSplashAdInteractionDelegate(interactionDelegate)
    ad.show(viewController)
  }

  func loadRTBBannerAd(
    for slotId: String,
    bidPayLoad: String,
    adSize: BigoAdSize,
    delegate: any BigoBannerAdLoaderDelegate
  ) {
    let request = BigoBannerAdRequest(slotId: slotId, adSizes: [adSize])
    request.setServerBidPayload(bidPayLoad)
    bannerAdLoader = BigoBannerAdLoader(bannerAdLoaderDelegate: delegate)
    bannerAdLoader?.loadAd(request)
  }

  func loadRTBNativeAd(
    for slotId: String,
    bidPayLoad: String,
    delegate: any BigoNativeAdLoaderDelegate
  ) {
    let request = BigoNativeAdRequest(slotId: slotId)
    request.setServerBidPayload(bidPayLoad)
    nativeAdLoader = BigoNativeAdLoader(nativeAdLoaderDelegate: delegate)
    nativeAdLoader?.loadAd(request)
  }

}
