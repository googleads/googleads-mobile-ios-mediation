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
import GoogleMobileAds
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

  /// Sets BIGO COPPA consent.
  func setUserConsent(
    with tagForChildDirectedTreatment: NSNumber?, tagForUnderAgeOfConsent: NSNumber?)

  /// Initializes the BigoADS SDK.
  func initialize(with applicationId: String, testMode: Bool, completion: @escaping () -> Void)

  /// Gets a bidder token from BigoADS.
  func getBidderToken() -> String?

  /// Loads a RTB interstitial ad from BigoADS.
  func loadRTBInterstitialAd(
    for slotId: String, bidPayLoad: String, watermark: Data,
    delegate: BigoInterstitialAdLoaderDelegate)

  /// Presents the Bigo interstitial ad.
  func presentInterstitialAd(
    _ ad: BigoInterstitialAd, viewController: UIViewController,
    interactionDelegate: BigoAdInteractionDelegate)

  /// Loads a RTB reward ad from BigoADS.
  func loadRTBRewardVideoAd(
    for slotId: String, bidPayLoad: String, watermark: Data,
    delegate: BigoRewardVideoAdLoaderDelegate)

  /// Presents the Bigo reward video ad.
  func presentRewardVideoAd(
    _ ad: BigoRewardVideoAd, viewController: UIViewController,
    interactionDelegate: BigoRewardVideoAdInteractionDelegate)

  /// Loads a RTB app splash ad from BigoADS.
  func loadRTBSplashAd(
    for slotId: String, bidPayLoad: String, watermark: Data, delegate: BigoSplashAdLoaderDelegate)

  /// Presents the Bigo splash ad.
  func presentSplashAd(
    _ ad: BigoSplashAd, viewController: UIViewController,
    interactionDelegate: BigoSplashAdInteractionDelegate)

  /// Loads a RTB banner ad from BigoADS.
  func loadRTBBannerAd(
    for slotId: String, bidPayLoad: String, adSize: BigoAdSize, watermark: Data,
    delegate: BigoBannerAdLoaderDelegate
  )

  /// Loads a RTB native ad from BigoADS.
  func loadRTBNativeAd(
    for slotId: String, bidPayLoad: String, watermark: Data, delegate: BigoNativeAdLoaderDelegate)

}

final class BigoClientImpl: NSObject, BigoClient {

  static let extString: String = {
    let extDict = [
      "mediationName": "GoogleBigoAdapter",
      "mediationVersion": "\(MobileAds.version())",
      "adapterVersion": BigoAdapter.adapterVersionString,
    ]

    guard let jsonData = try? JSONSerialization.data(withJSONObject: extDict),
      let jsonString = String(data: jsonData, encoding: .utf8)
    else {
      Util.log("Failed to serialize extension dictionary.")
      return ""
    }

    return jsonString
  }()

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
    for slotId: String,
    bidPayLoad: String,
    watermark: Data,
    delegate: BigoInterstitialAdLoaderDelegate
  ) {
    let request = BigoInterstitialAdRequest(slotId: slotId)
    request.setServerBidPayload(bidPayLoad)
    request.encodedImageData = watermark
    interstitialAdLoader = BigoInterstitialAdLoader(interstitialAdLoaderDelegate: delegate)
    interstitialAdLoader?.ext = Self.extString
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
    watermark: Data,
    delegate: any BigoRewardVideoAdLoaderDelegate
  ) {
    let request = BigoRewardVideoAdRequest(slotId: slotId)
    request.setServerBidPayload(bidPayLoad)
    request.encodedImageData = watermark
    rewardVideoAdLoader = BigoRewardVideoAdLoader(rewardVideoAdLoaderDelegate: delegate)
    rewardVideoAdLoader?.ext = Self.extString
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
    watermark: Data,
    delegate: any BigoSplashAdLoaderDelegate
  ) {
    let request = BigoSplashAdRequest(slotId: slotId)
    request.setServerBidPayload(bidPayLoad)
    request.encodedImageData = watermark
    splashAdLoader = BigoSplashAdLoader(splashAdLoaderDelegate: delegate)
    splashAdLoader?.ext = Self.extString
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
    watermark: Data,
    delegate: any BigoBannerAdLoaderDelegate
  ) {
    let request = BigoBannerAdRequest(slotId: slotId, adSizes: [adSize])
    request.setServerBidPayload(bidPayLoad)
    request.encodedImageData = watermark
    bannerAdLoader = BigoBannerAdLoader(bannerAdLoaderDelegate: delegate)
    bannerAdLoader?.ext = Self.extString
    bannerAdLoader?.loadAd(request)
  }

  func loadRTBNativeAd(
    for slotId: String,
    bidPayLoad: String,
    watermark: Data,
    delegate: any BigoNativeAdLoaderDelegate
  ) {
    let request = BigoNativeAdRequest(slotId: slotId)
    request.setServerBidPayload(bidPayLoad)
    request.encodedImageData = watermark
    nativeAdLoader = BigoNativeAdLoader(nativeAdLoaderDelegate: delegate)
    nativeAdLoader?.ext = Self.extString
    nativeAdLoader?.loadAd(request)
  }

  func setUserConsent(
    with tagForChildDirectedTreatment: NSNumber?, tagForUnderAgeOfConsent: NSNumber?
  ) {
    let isChild = tagForChildDirectedTreatment?.boolValue
    let isUnderAge = tagForUnderAgeOfConsent?.boolValue

    // https://www.bigossp.com/guide/sdk/ios/document#pass-mediation-sdk-info
    // A value of "YES" indicates that the user is not a child under 13 years
    // old, and a value of "NO" indicates that the user is a child under 13
    // years old.
    if isChild == true || isUnderAge == true {
      Util.log("Setting BigoConsentOptionsCOPPA to false")
      BigoAdSdk.setUserConsentWithOption(BigoConsentOptionsCOPPA, consent: false)
    } else if isChild == false || isUnderAge == false {
      Util.log("Setting BigoConsentOptionsCOPPA to true")
      BigoAdSdk.setUserConsentWithOption(BigoConsentOptionsCOPPA, consent: true)
    }
  }

}
