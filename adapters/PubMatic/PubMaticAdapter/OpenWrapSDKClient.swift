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

import OpenWrapSDK
import UIKit

/// Factory that creates OpenWrapSDKClient.
struct OpenWrapSDKClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: OpenWrapSDKClient?
  #endif

  static func createClient() -> OpenWrapSDKClient {
    #if DEBUG
      return debugClient ?? OpenWrapSDKClientImpl()
    #else
      return OpenWrapSDKClientImpl()
    #endif
  }

}

/// A client for interacting with OpenWrapSDK.
protocol OpenWrapSDKClient: NSObject {

  /// Enable the OpenWrapSDK's COPPA configuration based on the provided boolean value. It enables if
  /// the passed boolean value is true. Otherwise disable the COPPA configuration.
  func enableCOPPA(_ enable: Bool)

  /// Returns a version of OpenWrapSDK.
  func version() -> String

  /// Set up the OpenWrapSDK using the publisher ID and the profile IDs.
  func setUp(
    publisherId: String, profileIds: [NSNumber], completionHandler: @escaping ((any Error)?) -> Void
  )

  /// Collect signals for bidding.
  @MainActor func collectSignals(for adFormat: POBAdFormat) -> String

  /// Load a banner ad.
  @MainActor func loadRtbBannerView(
    bidResponse: String, delegate: POBBannerViewDelegate, watermarkData: Data)

  /// Load a RTB interstitial ad.
  func loadRtbInterstitial(
    bidResponse: String, delegate: POBInterstitialDelegate, watermarkData: Data)

  /// Load a waterfall interstitial ad.
  func loadWaterfallInterstitial(
    publisherId: String, profileId: NSNumber, adUnitId: String, delegate: POBInterstitialDelegate)

  /// Load a RTB rewarded ad.
  func loadRtbRewardedAd(bidResponse: String, delegate: POBRewardedAdDelegate, watermarkData: Data)

  /// Load a waterfall rewarded ad.
  func loadWaterfallRewardedAd(
    publisherId: String, profileId: NSNumber, adUnitId: String, delegate: any POBRewardedAdDelegate)

  /// Load a native ad.
  func loadRtbNativeAd(
    bidResponse: String, delegate: POBNativeAdLoaderDelegate, watermarkData: Data)

  /// Present a POBInterstitial ad.
  func presentInterstitial(from viewController: UIViewController) throws(PubMaticAdapterError)

  /// Present a POBRewardedAd ad.
  func presentRewardedAd(from viewController: UIViewController) throws(PubMaticAdapterError)

}

final class OpenWrapSDKClientImpl: NSObject, OpenWrapSDKClient {

  var bannerView: POBBannerView?
  var interstitial: POBInterstitial?
  var rewardedAd: POBRewardedAd?
  var nativeAdLoader: POBNativeAdLoader?

  func version() -> String {
    return OpenWrapSDK.version()
  }

  func setUp(
    publisherId: String,
    profileIds: [NSNumber],
    completionHandler: @escaping ((any Error)?) -> Void
  ) {
    let config = OpenWrapSDKConfig(publisherId: publisherId, andProfileIds: profileIds)
    OpenWrapSDK.initialize(with: config) { _, error in
      completionHandler(error)
    }
  }

  func enableCOPPA(_ enable: Bool) {
    OpenWrapSDK.setCoppaEnabled(enable)
  }

  @MainActor
  func collectSignals(for adFormat: POBAdFormat) -> String {
    let config = POBSignalConfig(adFormat: adFormat)
    return POBSignalGenerator.generateSignal(for: .adMob, andConfig: config)
  }

  @MainActor
  func loadRtbBannerView(bidResponse: String, delegate: POBBannerViewDelegate, watermarkData: Data)
  {
    bannerView = POBBannerView()
    bannerView?.delegate = delegate
    bannerView?.addExtraInfo(withKey: kPOBAdMobWatermarkKey, andValue: watermarkData)
    bannerView?.pauseAutoRefresh()
    bannerView?.loadAd(withResponse: bidResponse, for: .adMob)
  }

  func loadRtbInterstitial(
    bidResponse: String,
    delegate: any POBInterstitialDelegate,
    watermarkData: Data
  ) {
    interstitial = POBInterstitial()
    interstitial?.delegate = delegate
    interstitial?.addExtraInfo(withKey: kPOBAdMobWatermarkKey, andValue: watermarkData)
    interstitial?.loadAd(withResponse: bidResponse, for: .adMob)
  }

  func loadWaterfallInterstitial(
    publisherId: String, profileId: NSNumber, adUnitId: String,
    delegate: any POBInterstitialDelegate
  ) {
    interstitial = POBInterstitial(
      publisherId: publisherId, profileId: profileId, adUnitId: adUnitId)
    interstitial?.delegate = delegate
    interstitial?.loadAd()
  }

  func loadRtbRewardedAd(
    bidResponse: String, delegate: any POBRewardedAdDelegate, watermarkData: Data
  ) {
    rewardedAd = POBRewardedAd()
    rewardedAd?.delegate = delegate
    rewardedAd?.addExtraInfo(withKey: kPOBAdMobWatermarkKey, andValue: watermarkData)
    rewardedAd?.load(withResponse: bidResponse, for: .adMob)
  }

  func loadWaterfallRewardedAd(
    publisherId: String, profileId: NSNumber, adUnitId: String, delegate: any POBRewardedAdDelegate
  ) {
    rewardedAd = POBRewardedAd(publisherId: publisherId, profileId: profileId, adUnitId: adUnitId)
    rewardedAd?.delegate = delegate
    rewardedAd?.loadAd()
  }

  func loadRtbNativeAd(
    bidResponse: String,
    delegate: POBNativeAdLoaderDelegate,
    watermarkData: Data
  ) {
    nativeAdLoader = POBNativeAdLoader()
    nativeAdLoader?.delegate = delegate
    nativeAdLoader?.addExtraInfo(withKey: kPOBAdMobWatermarkKey, andValue: watermarkData)
    nativeAdLoader?.loadAd(withResponse: bidResponse, for: .adMob)
  }

  func presentInterstitial(from viewController: UIViewController) throws(PubMaticAdapterError) {
    guard let interstitial, interstitial.isReady else {
      throw PubMaticAdapterError(
        errorCode: .interstitialAdNotReadyForPresentation,
        description: "Interstitial ad is not ready for presentation.")
    }
    interstitial.show(from: viewController)
  }

  func presentRewardedAd(from viewController: UIViewController) throws(PubMaticAdapterError) {
    guard let rewardedAd, rewardedAd.isReady else {
      throw PubMaticAdapterError(
        errorCode: .rewardedAdNotReadyForPresentation,
        description: "Rewarded ad is not ready for presentation.")
    }
    rewardedAd.show(from: viewController)
  }
}
