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

// FIX(placement_id): every `collectSignals` / `load*` member below gained a
// `placementId: String?` parameter so the publisher's placement ID can reach the
// BidMachineSdk placement. It is optional: nil means the publisher configured no placement ID.
protocol BidMachineClient: NSObject {

  /// Returns a version string of BidMachine SDK.
  func version() -> String

  /// Initializes the BidMachine SDK.
  func initialize(with sourceId: String, isCOPPA: Bool?)

  /// Collects the signals  for the specified ad format.
  func collectSignals(
    for adFormat: GoogleMobileAds.AdFormat, size: AdSize?, placementId: String?,
    completionHandler: @escaping (String?) -> Void)
    throws

  /// Loads a waterfall  banner ad.
  func loadWaterfallBannerAd(
    size: AdSize, placementId: String?, delegate: BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void)
    throws

  /// Loads a RTB banner ad.
  func loadRTBBannerAd(
    with bidResponse: String, size: AdSize, placementId: String?, delegate: BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void) throws

  /// Loads a RTB interstitial ad.
  func loadRTBInterstitialAd(
    with bidResponse: String, placementId: String?, delegate: BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void) throws

  /// Loads a waterfall interstitial ad.
  func loadWaterfallInterstitialAd(
    placementId: String?, delegate: BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void) throws

  /// Presents the loaded interstitial ad.
  func present(_ interstitialAd: BidMachineInterstitial?, from viewController: UIViewController)
    throws(BidMachineAdapterError)

  /// Loads a waterfall rewarded ad.
  func loadWaterfallRewardedAd(
    placementId: String?, delegate: BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void) throws

  /// Loads a RTB rewarded ad.
  func loadRTBRewardedAd(
    with bidResponse: String, placementId: String?, delegate: BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void) throws

  /// Presents the loaded rewarded ad.
  func present(_ rewardedAd: BidMachineRewarded?, from viewController: UIViewController)
    throws(BidMachineAdapterError)

  /// Loads a waterfall native ad.
  func loadWaterfallNativeAd(
    placementId: String?, delegate: BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void) throws

  /// Loads a RTB native ad.
  func loadRTBNativeAd(
    with bidResponse: String, placementId: String?, delegate: BidMachineAdDelegate,
    watermark: String,
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

  // FIX(placement_id): new helper. THIS IS THE CORE OF THE FIX.
  //
  // Previously every placement was created with `BidMachineSdk.shared.placement(from: format)`,
  // omitting the optional builder block. That left BidMachinePlacement.placementId == nil, which
  // BidMachine's SDK serializes as an empty string:
  //
  //     builder.placementID = ProtoTransformer.String.with(placement.id ?? "")
  //
  // so the `placement_id` field in the bid request was always blank and BidMachine's reporting
  // showed nothing for iOS. Android forwards the ID via AdPlacementConfig.withPlacementId().
  //
  /// Creates a BidMachine placement for the provided format, forwarding the publisher's placement
  /// ID when one was configured in the ad unit's mediation settings.
  ///
  /// BidMachine reports on the placement ID, so it must be set on every placement the adapter
  /// creates - for bid token collection as well as for ad requests.
  private static func placement(for format: PlacementFormat, placementId: String?) throws
    -> BidMachinePlacement
  {
    return try BidMachineSdk.shared.placement(from: format) { builder in
      if let placementId {
        builder.withPlacementId(placementId)
      }
    }
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
    for adFormat: GoogleMobileAds.AdFormat, size: AdSize?, placementId: String?,
    completionHandler: @escaping (String?) -> Void
  ) throws {
    let placementFormat = try adFormat.toBiddingPlacementFormat(size: size)
    // FIX(placement_id): was `BidMachineSdk.shared.placement(from: placementFormat)`.
    // The bid token request must carry the placement ID too, like Android's getBidToken().
    let placement = try Self.placement(for: placementFormat, placementId: placementId)
    BidMachineSdk.shared.token(placement: placement) { token in
      completionHandler(token)
    }
  }

  func loadWaterfallBannerAd(
    size: AdSize,
    placementId: String?,
    delegate: any BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    let bannerFormat = try size.toWaterfallPlacementFormat()
    try loadBannerAd(
      with: nil, placementFormat: bannerFormat, placementId: placementId, delegate: delegate,
      watermark: nil,
      completionHandler: completionHandler)
  }

  func loadRTBBannerAd(
    with bidResponse: String,
    size: AdSize,
    placementId: String?,
    delegate: BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    let bannerFormat = try size.toBiddingPlacementFormat()
    try loadBannerAd(
      with: bidResponse, placementFormat: bannerFormat, placementId: placementId,
      delegate: delegate, watermark: watermark,
      completionHandler: completionHandler)
  }

  private func loadBannerAd(
    with bidResponse: String?,
    placementFormat: PlacementFormat,
    placementId: String?,
    delegate: BidMachineAdDelegate,
    watermark: String?,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    // FIX(placement_id): was `BidMachineSdk.shared.placement(from: placementFormat)`.
    let placement = try Self.placement(for: placementFormat, placementId: placementId)
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
      Task {
        @MainActor in
        bidMachineBanner.delegate = delegate
        if let watermark {
          bidMachineBanner.rendererConfiguration.extras[Self.watermarkExtraKey] = watermark
        }
        bidMachineBanner.controller = Util.rootViewController()
        bidMachineBanner.loadAd()
      }
    }
  }
  func loadWaterfallInterstitialAd(
    placementId: String?,
    delegate: any BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadInterstitialAd(
      with: nil, placementId: placementId, delegate: delegate, watermark: nil,
      completionHandler: completionHandler)
  }

  func loadRTBInterstitialAd(
    with bidResponse: String,
    placementId: String?,
    delegate: BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadInterstitialAd(
      with: bidResponse, placementId: placementId, delegate: delegate, watermark: watermark,
      completionHandler: completionHandler)
  }

  private func loadInterstitialAd(
    with bidResponse: String?,
    placementId: String?,
    delegate: BidMachineAdDelegate,
    watermark: String?,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    // FIX(placement_id): was `BidMachineSdk.shared.placement(from: .interstitial)`.
    let placement = try Self.placement(for: .interstitial, placementId: placementId)
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
    placementId: String?,
    delegate: any BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadRewardedAd(
      with: nil, placementId: placementId, delegate: delegate, watermark: nil,
      completionHandler: completionHandler)
  }

  func loadRTBRewardedAd(
    with bidResponse: String,
    placementId: String?,
    delegate: BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadRewardedAd(
      with: bidResponse, placementId: placementId, delegate: delegate, watermark: watermark,
      completionHandler: completionHandler)
  }

  private func loadRewardedAd(
    with bidResponse: String?,
    placementId: String?,
    delegate: BidMachineAdDelegate,
    watermark: String?,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    // FIX(placement_id): was `BidMachineSdk.shared.placement(from: .rewarded)`.
    let placement = try Self.placement(for: .rewarded, placementId: placementId)
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
    placementId: String?,
    delegate: any BidMachineAdDelegate,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadNativeAd(
      with: nil, placementId: placementId, delegate: delegate, watermark: nil,
      completionHandler: completionHandler)
  }

  func loadRTBNativeAd(
    with bidResponse: String,
    placementId: String?,
    delegate: any BidMachineAdDelegate,
    watermark: String,
    completionHandler: @escaping (NSError?) -> Void
  ) throws {
    try loadNativeAd(
      with: bidResponse, placementId: placementId, delegate: delegate, watermark: watermark,
      completionHandler: completionHandler)
  }

  private func loadNativeAd(
    with bidResponse: String?,
    placementId: String?,
    delegate: any BidMachineAdDelegate,
    watermark: String?,
    completionHandler: @escaping (NSError?) -> Void

  ) throws {
    // FIX(placement_id): was `BidMachineSdk.shared.placement(from: .native)`.
    let placement = try Self.placement(for: .native, placementId: placementId)
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

  fileprivate func toBiddingPlacementFormat(size: AdSize?) throws(BidMachineAdapterError)
    -> PlacementFormat
  {
    switch self {
    case .banner:
      guard let size else {
        throw BidMachineAdapterError(
          errorCode: .invalidRTBRequestParameters,
          description: "Banner ad format requires ad size.")
      }
      return try size.toBiddingPlacementFormat()
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

extension GoogleMobileAds.AdSize {

  /// Maps an ad size to a BidMachine placement format for waterfall requests.
  /// Uses Google's helper to find the closest valid standard size.
  fileprivate func toWaterfallPlacementFormat() throws(BidMachineAdapterError) -> PlacementFormat {
    let closestAdSize = closestValidSizeForAdSizes(
      original: self,
      possibleAdSizes: [
        nsValue(for: AdSizeBanner), nsValue(for: AdSizeMediumRectangle),
        nsValue(for: AdSizeLeaderboard),
      ])

    if isAdSizeEqualToSize(size1: closestAdSize, size2: AdSizeBanner) {
      return .banner320x50
    } else if isAdSizeEqualToSize(size1: closestAdSize, size2: AdSizeMediumRectangle) {
      return .banner300x250
    } else if isAdSizeEqualToSize(size1: closestAdSize, size2: AdSizeLeaderboard) {
      return .banner728x90
    } else {
      throw BidMachineAdapterError(
        errorCode: .unsupportedBannerSize, description: "Unsupported banner size.")
    }
  }

  /// Maps an ad size to a BidMachine placement format for bidding requests.
  /// Always returns one of the three supported placements based on dimensions.
  fileprivate func toBiddingPlacementFormat() throws(BidMachineAdapterError) -> PlacementFormat {
    // if the requested size is inline adaptive with no height restriction,
    // the height will be specified as 0.
    // Leaderboard size (728x90) might be used for large inline adaptive banners
    // and fixed size leaderboard banner
    if (self.size.height == 0 || self.size.height >= 90) && self.size.width >= 728 {
      return .banner728x90
      // MREC ad size (300x250) can'not be used for inline adaptive banners,
      // only fixed MREC size is allowed
    } else if self.size.width >= 300 && self.size.height >= 250 {
      return .banner300x250
      // Small banners (320x50) might be used for smaller container sizes, including adaptive inline
      // The smallest available sizes are 212x50 and 292x41.
      // BidMachine is using ad sizes passed from the bid request,
      // and the SDK will rely on actual creative size that will respond to the bid request passed value.
      // This legacy implementation with SDK-level passing ad size for bidding integration
      // is only used on the BidMachine's backend for additional size validation
    } else if (self.size.height == 0 && self.size.width >= 200)
      || (self.size.height >= 40 && self.size.width >= 200)
    {
      return .banner320x50
    } else {
      throw BidMachineAdapterError(
        errorCode: .unsupportedBannerSize, description: "Unsupported banner size.")
    }
  }
}
