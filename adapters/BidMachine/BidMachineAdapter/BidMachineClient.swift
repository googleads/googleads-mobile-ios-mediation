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

  /// Collects the signals for the specified placement IDs.
  func collectSignals(
    placementIds: [String],
    completionHandler: @escaping (String?, NSError?) -> Void)

  /// Loads a waterfall  banner ad.
  func loadWaterfallBannerAd(
    size: AdSize, delegate: BidMachine.BannerViewDelegate, placementId: String?,
    completionHandler: @escaping (BidMachine.BannerView?, NSError?) -> Void)
    throws

  /// Loads a RTB banner ad.
  func loadRTBBannerAd(
    with bidResponse: String, size: AdSize, delegate: BidMachine.BannerViewDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.BannerView?, NSError?) -> Void) throws

  /// Loads a RTB interstitial ad.
  func loadRTBInterstitialAd(
    with bidResponse: String, delegate: BidMachine.InterstitialAdDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.InterstitialAd?, NSError?) -> Void) throws

  /// Loads a waterfall interstitial ad.
  func loadWaterfallInterstitialAd(
    delegate: BidMachine.InterstitialAdDelegate, placementId: String?,
    completionHandler: @escaping (BidMachine.InterstitialAd?, NSError?) -> Void) throws

  /// Presents the loaded interstitial ad.
  @MainActor
  func present(_ interstitialAd: BidMachine.InterstitialAd?, from viewController: UIViewController)
    throws(BidMachineAdapterError)

  /// Loads a waterfall rewarded ad.
  func loadWaterfallRewardedAd(
    delegate: BidMachine.RewardedAdDelegate, placementId: String?,
    completionHandler: @escaping (BidMachine.RewardedAd?, NSError?) -> Void) throws

  /// Loads a RTB rewarded ad.
  func loadRTBRewardedAd(
    with bidResponse: String, delegate: BidMachine.RewardedAdDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.RewardedAd?, NSError?) -> Void) throws

  /// Presents the loaded rewarded ad.
  @MainActor
  func present(_ rewardedAd: BidMachine.RewardedAd?, from viewController: UIViewController)
    throws(BidMachineAdapterError)

  /// Loads a waterfall native ad.
  func loadWaterfallNativeAd(
    delegate: BidMachine.NativeAdDelegate, placementId: String?,
    completionHandler: @escaping (BidMachine.NativeAd?, NSError?) -> Void) throws

  /// Loads a RTB native ad.
  func loadRTBNativeAd(
    with bidResponse: String, delegate: BidMachine.NativeAdDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.NativeAd?, NSError?) -> Void) throws
}

final class BidMachineClientImpl: NSObject, BidMachineClient {

  private static let watermarkExtraKey = "google_watermark"

  nonisolated(unsafe) private static var instance: BidMachineInstance?

  func version() -> String {
    return BidMachineSdk.sdkVersion
  }

  /// Returns the BidMachine instance created during the adapter set up.
  private static func initializedInstance() throws(BidMachineAdapterError) -> BidMachineInstance {
    guard let instance else {
      throw BidMachineAdapterError(
        errorCode: .bidMachineSDKNotInitialized,
        description: "BidMachine SDK is not initialized.")
    }
    return instance
  }

  func initialize(with sourceId: String, isCOPPA: Bool?) {
    if let isCOPPA {
      BidMachineSdk.consentProvider = ConsentProviderImpl(coppa: isCOPPA)
    }

    let configuration = BidMachine.Configuration()
    configuration.mediationInfo = MediationInfo(
      name: "google",
      version: string(for: MobileAds.shared.versionNumber),
      adapterVersion: BidMachineAdapter.adapterVersionString)
    Self.instance = BidMachineSdk.initialize(sourceId: sourceId, configuration: configuration)
  }

  func collectSignals(
    placementIds: [String],
    completionHandler: @escaping (String?, NSError?) -> Void
  ) {
    let instance: BidMachineInstance
    do {
      instance = try Self.initializedInstance()
    } catch {
      completionHandler(nil, error.toNSError())
      return
    }
    let placements = placementIds.map { BidMachine.Placement(id: $0) }
    instance.collectToken(placements: placements) { token, error in
      completionHandler(token, error)
    }
  }

  func loadWaterfallBannerAd(
    size: AdSize,
    delegate: any BidMachine.BannerViewDelegate,
    placementId: String?,
    completionHandler: @escaping (BidMachine.BannerView?, NSError?) -> Void
  ) throws {
    let instance = try Self.initializedInstance()
    let placement = placementId.map { BidMachine.Placement(id: $0) }
    instance.loadBanner(placement: placement, size: size.toBannerSize()) {
      banner, error in
      Self.handleLoadedBanner(
        banner, error: error, delegate: delegate, watermark: nil,
        completionHandler: completionHandler)
    }
  }

  func loadRTBBannerAd(
    with bidResponse: String,
    size: AdSize,
    delegate: any BidMachine.BannerViewDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.BannerView?, NSError?) -> Void
  ) throws {
    let instance = try Self.initializedInstance()
    instance.loadBanner(payload: bidResponse, size: size.toBannerSize()) { banner, error in
      Self.handleLoadedBanner(
        banner, error: error, delegate: delegate, watermark: watermark,
        completionHandler: completionHandler)
    }
  }

  /// Sets up the loaded banner and passes it to the completion handler.
  private static func handleLoadedBanner(
    _ banner: BidMachine.BannerView?,
    error: NSError?,
    delegate: any BidMachine.BannerViewDelegate,
    watermark: String?,
    completionHandler: @escaping (BidMachine.BannerView?, NSError?) -> Void
  ) {
    guard let banner else {
      completionHandler(nil, error)
      return
    }
    Task { @MainActor in
      banner.delegate = delegate
      if let watermark {
        banner.extras[Self.watermarkExtraKey] = watermark
      }
      banner.rootViewController = Util.rootViewController()
      completionHandler(banner, nil)
    }
  }

  func loadWaterfallInterstitialAd(
    delegate: any BidMachine.InterstitialAdDelegate,
    placementId: String?,
    completionHandler: @escaping (BidMachine.InterstitialAd?, NSError?) -> Void
  ) throws {
    let instance = try Self.initializedInstance()
    let placement = placementId.map { BidMachine.Placement(id: $0) }
    instance.loadInterstitial(placement: placement) { interstitialAd, error in
      Self.handleLoadedInterstitial(
        interstitialAd, error: error, delegate: delegate, watermark: nil,
        completionHandler: completionHandler)
    }
  }

  func loadRTBInterstitialAd(
    with bidResponse: String,
    delegate: any BidMachine.InterstitialAdDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.InterstitialAd?, NSError?) -> Void
  ) throws {
    let instance = try Self.initializedInstance()
    instance.loadInterstitial(payload: bidResponse) { interstitialAd, error in
      Self.handleLoadedInterstitial(
        interstitialAd, error: error, delegate: delegate, watermark: watermark,
        completionHandler: completionHandler)
    }
  }

  /// Sets up the loaded interstitial ad and passes it to the completion handler.
  private static func handleLoadedInterstitial(
    _ interstitialAd: BidMachine.InterstitialAd?,
    error: NSError?,
    delegate: any BidMachine.InterstitialAdDelegate,
    watermark: String?,
    completionHandler: @escaping (BidMachine.InterstitialAd?, NSError?) -> Void
  ) {
    guard let interstitialAd else {
      completionHandler(nil, error)
      return
    }
    Task { @MainActor in
      interstitialAd.delegate = delegate
      if let watermark {
        interstitialAd.extras[Self.watermarkExtraKey] = watermark
      }
      completionHandler(interstitialAd, nil)
    }
  }

  @MainActor
  func present(_ interstitialAd: BidMachine.InterstitialAd?, from viewController: UIViewController)
    throws(BidMachineAdapterError)
  {
    guard let interstitialAd, interstitialAd.canShow else {
      throw BidMachineAdapterError(
        errorCode: .adNotReadyForPresentation,
        description: "Interstitial ad is not ready for presentation.")
    }
    interstitialAd.show(from: viewController)
  }

  func loadWaterfallRewardedAd(
    delegate: any BidMachine.RewardedAdDelegate,
    placementId: String?,
    completionHandler: @escaping (BidMachine.RewardedAd?, NSError?) -> Void
  ) throws {
    let instance = try Self.initializedInstance()
    let placement = placementId.map { BidMachine.Placement(id: $0) }
    instance.loadRewarded(placement: placement) { rewardedAd, error in
      Self.handleLoadedRewarded(
        rewardedAd, error: error, delegate: delegate, watermark: nil,
        completionHandler: completionHandler)
    }
  }

  func loadRTBRewardedAd(
    with bidResponse: String,
    delegate: any BidMachine.RewardedAdDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.RewardedAd?, NSError?) -> Void
  ) throws {
    let instance = try Self.initializedInstance()
    instance.loadRewarded(payload: bidResponse) { rewardedAd, error in
      Self.handleLoadedRewarded(
        rewardedAd, error: error, delegate: delegate, watermark: watermark,
        completionHandler: completionHandler)
    }
  }

  /// Sets up the loaded rewarded ad and passes it to the completion handler.
  private static func handleLoadedRewarded(
    _ rewardedAd: BidMachine.RewardedAd?,
    error: NSError?,
    delegate: any BidMachine.RewardedAdDelegate,
    watermark: String?,
    completionHandler: @escaping (BidMachine.RewardedAd?, NSError?) -> Void
  ) {
    guard let rewardedAd else {
      completionHandler(nil, error)
      return
    }
    Task { @MainActor in
      rewardedAd.delegate = delegate
      if let watermark {
        rewardedAd.extras[Self.watermarkExtraKey] = watermark
      }
      completionHandler(rewardedAd, nil)
    }
  }

  @MainActor
  func present(_ rewardedAd: BidMachine.RewardedAd?, from viewController: UIViewController)
    throws(BidMachineAdapterError)
  {
    guard let rewardedAd, rewardedAd.canShow else {
      throw BidMachineAdapterError(
        errorCode: .adNotReadyForPresentation,
        description: "Rewarded ad is not ready for presentation.")
    }
    rewardedAd.show(from: viewController)
  }

  func loadWaterfallNativeAd(
    delegate: any BidMachine.NativeAdDelegate,
    placementId: String?,
    completionHandler: @escaping (BidMachine.NativeAd?, NSError?) -> Void
  ) throws {
    let instance = try Self.initializedInstance()
    let placement = placementId.map { BidMachine.Placement(id: $0) }
    instance.loadNative(placement: placement) { nativeAd, error in
      Self.handleLoadedNative(
        nativeAd, error: error, delegate: delegate, watermark: nil,
        completionHandler: completionHandler)
    }
  }

  func loadRTBNativeAd(
    with bidResponse: String,
    delegate: any BidMachine.NativeAdDelegate,
    watermark: String,
    completionHandler: @escaping (BidMachine.NativeAd?, NSError?) -> Void
  ) throws {
    let instance = try Self.initializedInstance()
    instance.loadNative(payload: bidResponse) { nativeAd, error in
      Self.handleLoadedNative(
        nativeAd, error: error, delegate: delegate, watermark: watermark,
        completionHandler: completionHandler)
    }
  }

  /// Sets up the loaded native ad and passes it to the completion handler.
  private static func handleLoadedNative(
    _ nativeAd: BidMachine.NativeAd?,
    error: NSError?,
    delegate: any BidMachine.NativeAdDelegate,
    watermark: String?,
    completionHandler: @escaping (BidMachine.NativeAd?, NSError?) -> Void
  ) {
    guard let nativeAd else {
      completionHandler(nil, error)
      return
    }
    Task { @MainActor in
      nativeAd.delegate = delegate
      if let watermark {
        nativeAd.extras[Self.watermarkExtraKey] = watermark
      }
      completionHandler(nativeAd, nil)
    }
  }

}

extension GoogleMobileAds.AdSize {

  /// Maps an ad size to a BidMachine banner size. The fixed sizes BidMachine serves are requested
  /// as is, any other size is requested as an adaptive banner. A size without a width is
  /// requested at the screen width.
  fileprivate func toBannerSize() -> BannerSize {
    if isAdSizeEqualToSize(size1: self, size2: AdSizeBanner) {
      return .banner
    } else if isAdSizeEqualToSize(size1: self, size2: AdSizeMediumRectangle) {
      return .mrec
    } else if isAdSizeEqualToSize(size1: self, size2: AdSizeLeaderboard) {
      return .leaderboard
    }
    let width = size.width > 0 ? size.width : UIScreen.main.bounds.width
    return .adaptive(width: UInt32(width), maxHeight: UInt32(max(0, size.height)))
  }
}

private final class ConsentProviderImpl: NSObject, ConsentProvider {

  let coppa: NSNumber?
  let gdprApplies: NSNumber? = nil
  let gdprConsent: NSNumber? = nil
  let nonPersonalized: NSNumber? = nil
  let gppString: String? = nil
  let gppSids: [NSNumber]? = nil

  init(coppa: Bool) {
    self.coppa = NSNumber(value: coppa)
  }
}
