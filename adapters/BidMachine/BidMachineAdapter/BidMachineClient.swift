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

/// Factory that creates Client.
final class BidMachineClientFactory {

  private init() {}

  #if DEBUG
    /// This property will be returned by |createClient| function if set in Debug mode.
    nonisolated(unsafe) static var debugClient: BidMachineClient?
  #endif

  static func createClient() -> BidMachineClient {
    #if DEBUG
      return debugClient ?? BidMachineClientImpl()
    #else
      return BidMachineClientImpl()
    #endif
  }

}

protocol BidMachineClient: NSObject {

  /// Returns a version string of BidMachine SDK.
  func version() -> String

  /// Initializes the BidMachine SDK.
  func initialize(with sourceId: String, isCOPPA: Bool?)

  /// Collects the signals  for the specified ad format.
  func collectSignals(
    for adFormat: GoogleMobileAds.AdFormat, completionHandler: @escaping (String?) -> Void)
    throws

  /// Loads a waterfall  banner ad.
  func loadWaterfallBannerAd(
    size: AdSize, delegate: BidMachineAdDelegate, completionHandler: @escaping (NSError?) -> Void)
    throws

  /// Loads a RTB banner ad.
  func loadRTBBannerAd(
    with bidResponse: String, delegate: BidMachineAdDelegate, watermark: String,
    completionHandler: @escaping (NSError?) -> Void) throws

  /// Loads a RTB interstitial ad.
  func loadRTBInterstitialAd(
    with bidResponse: String, delegate: BidMachineAdDelegate, watermark: String,
    completionHandler: @escaping (NSError?) -> Void) throws

  /// Loads a waterfall interstitial ad.
  func loadWaterfallInterstitialAd(
    delegate: BidMachineAdDelegate, completionHandler: @escaping (NSError?) -> Void) throws

  /// Presents the loaded interstitial ad.
  func present(_ interstitialAd: BidMachineInterstitial?, from viewController: UIViewController)
    throws(BidMachineAdapterError)

  /// Loads a waterfall rewarded ad.
  func loadWaterfallRewardedAd(
    delegate: BidMachineAdDelegate, completionHandler: @escaping (NSError?) -> Void) throws

  /// Loads a RTB rewarded ad.
  func loadRTBRewardedAd(
    with bidResponse: String, delegate: BidMachineAdDelegate, watermark: String,
    completionHandler: @escaping (NSError?) -> Void) throws

  /// Presents the loaded rewarded ad.
  func present(_ rewardedAd: BidMachineRewarded?, from viewController: UIViewController)
    throws(BidMachineAdapterError)

  /// Loads a waterfall native ad.
  func loadWaterfallNativeAd(
    delegate: BidMachineAdDelegate, completionHandler: @escaping (NSError?) -> Void) throws

  /// Loads a RTB native ad.
  func loadRTBNativeAd(
    with bidResponse: String, delegate: BidMachineAdDelegate, watermark: String,
    completionHandler: @escaping (NSError?) -> Void) throws
}

final class BidMachineClientImpl: NSObject, BidMachineClient {

  private static let watermarkExtraKey = "google_watermark"

  private var bidMachineBanner: BidMachineBanner?
  private var bidMachineInterstitial: BidMachineInterstitial?
  private var bidMachineRewarded: BidMachineRewarded?
  private var bidMachineNative: BidMachineNative?

  func version() -> String {
    return BidMachineSdk.sdkVersion
  }

  func initialize(with sourceId: String, isCOPPA: Bool?) {
    if let isCOPPA {
      BidMachineSdk.shared.regulationInfo.populate {
        $0.withCOPPA(isCOPPA)
      }
    }

    BidMachineSdk.shared.initializeSdk(sourceId)
  }

  func collectSignals(
    for adFormat: GoogleMobileAds.AdFormat, completionHandler: @escaping (String?) -> Void
  ) throws {
    let placementFormat = try adFormat.toPlacementFormat()
    let placement = try BidMachineSdk.shared.placement(from: placementFormat)
    BidMachineSdk.shared.token(placement: placement) { token in
      completionHandler(token)
    }
  }

  func loadWaterfallBannerAd(
    size: AdSize,
    delegate: any BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    let closestAdSize = closestValidSizeForAdSizes(
      original: size,
      possibleAdSizes: [
        nsValue(for: AdSizeBanner), nsValue(for: AdSizeMediumRectangle),
        nsValue(for: AdSizeLeaderboard),
      ])
    let bannerFormat: PlacementFormat
    if isAdSizeEqualToSize(size1: closestAdSize, size2: AdSizeBanner) {
      bannerFormat = .banner320x50
    } else if isAdSizeEqualToSize(size1: closestAdSize, size2: AdSizeMediumRectangle) {
      bannerFormat = .banner300x250
    } else if isAdSizeEqualToSize(size1: closestAdSize, size2: AdSizeLeaderboard) {
      bannerFormat = .banner728x90
    } else {
      throw BidMachineAdapterError(
        errorCode: .unsupportedBannerSize, description: "Unsupported banner size.")
    }

    try loadBannerAd(
      with: nil, placementFormat: bannerFormat, delegate: delegate, watermark: nil,
      completionHandler: completionHandler)
  }

  func loadRTBBannerAd(
    with bidResponse: String,
    delegate: BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadBannerAd(
      with: bidResponse, placementFormat: .banner, delegate: delegate, watermark: watermark,
      completionHandler: completionHandler)
  }

  private func loadBannerAd(
    with bidResponse: String?,
    placementFormat: PlacementFormat,
    delegate: BidMachineAdDelegate,
    watermark: String?,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    let placement = try BidMachineSdk.shared.placement(from: placementFormat)
    let request = BidMachineSdk.shared.auctionRequest(placement: placement) { builder in
      if let bidResponse {
        builder.withPayload(bidResponse)
      }
    }

    BidMachineSdk.shared.banner(request: request) { [weak self] bidMachineBanner, error in
      guard let bidMachineBanner, error == nil else {
        let error = error as? NSError
        completionHandler(error)
        return
      }
      self?.bidMachineBanner = bidMachineBanner
      nonisolated(unsafe) let nonisolatedDelegate = delegate
      DispatchQueue.main.async {
        bidMachineBanner.delegate = nonisolatedDelegate
        if let watermark {
          bidMachineBanner.rendererConfiguration.extras[Self.watermarkExtraKey] = watermark
        }
        bidMachineBanner.controller = Util.rootViewController()
        bidMachineBanner.loadAd()
      }
    }
  }
  func loadWaterfallInterstitialAd(
    delegate: any BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadInterstitialAd(
      with: nil, delegate: delegate, watermark: nil, completionHandler: completionHandler)
  }

  func loadRTBInterstitialAd(
    with bidResponse: String,
    delegate: BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadInterstitialAd(
      with: bidResponse, delegate: delegate, watermark: watermark,
      completionHandler: completionHandler)
  }

  private func loadInterstitialAd(
    with bidResponse: String?,
    delegate: BidMachineAdDelegate,
    watermark: String?,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    let placement = try BidMachineSdk.shared.placement(from: .interstitial)
    let request = BidMachineSdk.shared.auctionRequest(placement: placement) { builder in
      if let bidResponse {
        builder.withPayload(bidResponse)
      }
    }

    BidMachineSdk.shared.interstitial(request: request) { [weak self] interstitialAd, error in
      guard let interstitialAd, error == nil else {
        completionHandler(error as? NSError)
        return
      }
      self?.bidMachineInterstitial = interstitialAd

      interstitialAd.delegate = delegate
      if let watermark {
        interstitialAd.rendererConfiguration.extras[Self.watermarkExtraKey] = watermark
      }
      interstitialAd.loadAd()
    }
  }

  func present(_ interstitialAd: BidMachineInterstitial?, from viewController: UIViewController)
    throws(BidMachineAdapterError)
  {
    guard let interstitialAd, interstitialAd.canShow else {
      throw BidMachineAdapterError(
        errorCode: .adNotReadyForPresentation,
        description: "Interstitial ad is not ready for presentation.")
    }
    interstitialAd.controller = viewController
    interstitialAd.presentAd()
  }

  func loadWaterfallRewardedAd(
    delegate: any BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadRewardedAd(
      with: nil, delegate: delegate, watermark: nil, completionHandler: completionHandler)
  }

  func loadRTBRewardedAd(
    with bidResponse: String,
    delegate: BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadRewardedAd(
      with: bidResponse, delegate: delegate, watermark: watermark,
      completionHandler: completionHandler)
  }

  private func loadRewardedAd(
    with bidResponse: String?,
    delegate: BidMachineAdDelegate,
    watermark: String?,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    let placement = try BidMachineSdk.shared.placement(from: .rewarded)
    let request = BidMachineSdk.shared.auctionRequest(placement: placement) { builder in
      if let bidResponse {
        builder.withPayload(bidResponse)
      }
    }

    BidMachineSdk.shared.rewarded(request: request) { [weak self] rewardedAd, error in
      guard let rewardedAd, error == nil else {
        completionHandler(error as? NSError)
        return
      }
      self?.bidMachineRewarded = rewardedAd

      rewardedAd.delegate = delegate
      if let watermark {
        rewardedAd.rendererConfiguration.extras[Self.watermarkExtraKey] = watermark
      }
      rewardedAd.loadAd()
    }
  }

  func present(_ rewardedAd: BidMachineRewarded?, from viewController: UIViewController)
    throws(BidMachineAdapterError)
  {
    guard let rewardedAd, rewardedAd.canShow else {
      throw BidMachineAdapterError(
        errorCode: .adNotReadyForPresentation,
        description: "RTB rewarded ad is not ready for presentation.")
    }
    rewardedAd.controller = viewController
    rewardedAd.presentAd()
  }

  func loadWaterfallNativeAd(
    delegate: any BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadNativeAd(
      with: nil, delegate: delegate, watermark: nil, completionHandler: completionHandler)
  }

  func loadRTBNativeAd(
    with bidResponse: String,
    delegate: any BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadNativeAd(
      with: bidResponse, delegate: delegate, watermark: watermark,
      completionHandler: completionHandler)
  }

  private func loadNativeAd(
    with bidResponse: String?,
    delegate: any BidMachineAdDelegate,
    watermark: String?,
    completionHandler: @escaping (NSError?) -> Void

  ) throws {
    let placement = try BidMachineSdk.shared.placement(from: .native)
    let request = BidMachineSdk.shared.auctionRequest(placement: placement) { builder in
      if let bidResponse {
        builder.withPayload(bidResponse)
      }
    }

    BidMachineSdk.shared.native(request: request) { [weak self] nativeAd, error in
      guard let nativeAd, error == nil else {
        completionHandler(error as? NSError)
        return
      }
      self?.bidMachineNative = nativeAd

      completionHandler(nil)
      nativeAd.delegate = delegate
      if let watermark {
        nativeAd.rendererConfiguration.extras[Self.watermarkExtraKey] = watermark
      }
      nativeAd.loadAd()
    }
  }

}

extension GoogleMobileAds.AdFormat {

  fileprivate func toPlacementFormat() throws(BidMachineAdapterError) -> PlacementFormat {
    switch self {
    case .banner: return .banner
    case .interstitial: return .interstitial
    case .rewarded: return .rewarded
    case .native: return .native
    default:
      throw BidMachineAdapterError(
        errorCode: .invalidRTBRequestParameters,
        description: "Unsupported ad format. Provided format: \(self).")
    }
  }

}
