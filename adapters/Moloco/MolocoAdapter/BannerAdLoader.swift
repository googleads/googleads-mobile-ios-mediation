// Copyright 2024 Google LLC.
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
import MolocoSDK

/// Loads banner ads on Moloco ads SDK.
final class BannerAdLoader: NSObject {

  /// The banner ad configuration.
  private let adConfiguration: MediationBannerAdConfiguration

  /// The ad event delegate which is used to report banner related information to the Google Mobile Ads SDK.
  private weak var eventDelegate: MediationBannerAdEventDelegate?

  /// The completion handler to call when the rewarded ad loading succeeds or fails.
  private let loadCompletionHandler: GADMediationBannerLoadCompletionHandler

  /// The factory class used to create banner ads.
  private let molocoBannerFactory: MolocoBannerFactory

  /// The MolocoBannerAdView. MolocoBannerAdView type on iOS 13+, otherwise nil.
  private var bannerAdView: (UIView & MolocoAd)?

  init(
    adConfiguration: MediationBannerAdConfiguration,
    molocoBannerFactory: MolocoBannerFactory,
    loadCompletionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.loadCompletionHandler = loadCompletionHandler
    self.molocoBannerFactory = molocoBannerFactory
    super.init()
  }

  func loadAd() {
    guard #available(iOS 13.0, *) else {
      let error = MolocoUtils.error(
        code: .adServingNotSupported,
        description: "Moloco SDK does not support serving ads on iOS 12 and below")
      _ = loadCompletionHandler(nil, error)
      return
    }

    let molocoAdUnitID = MolocoUtils.getAdUnitId(from: adConfiguration)
    guard let molocoAdUnitID else {
      let error = MolocoUtils.error(
        code: .invalidAdUnitId, description: "Missing required parameter")
      _ = loadCompletionHandler(nil, error)
      return
    }

    guard let bidResponse = adConfiguration.bidResponse else {
      let error = MolocoUtils.error(code: .nilBidResponse, description: "Nil bid response.")
      _ = loadCompletionHandler(nil, error)
      return
    }

    DispatchQueue.main.async { [weak self] in
      guard let self else { return }

      let molocoSize = BannerAdLoader.molocoBannerAdSize(from: adConfiguration.adSize)
      self.bannerAdView = self.molocoBannerFactory.createBanner(
        for: molocoAdUnitID, size: molocoSize, delegate: self,
        watermarkData: adConfiguration.watermark)
      self.bannerAdView?.load(bidResponse: bidResponse)
    }
  }

  /// The banner format the adapter resolves a Google `AdSize` to.
  ///
  /// Extracted from `molocoBannerAdSize(from:)` as a pure, testable value:
  /// `MolocoBannerAdSize` keeps its format label internal to the Moloco SDK, so
  /// tests assert on this instead.
  enum ResolvedBannerFormat: Equatable {
    case standard
    case mrec
    case anchoredAdaptive
    case inlineAdaptive
  }

  /// Resolves a Google Mobile Ads `AdSize` to the banner format Moloco renders.
  ///
  /// 1. Non-finite / non-positive sizes → `.standard` (defensive; also avoids a
  ///    trap in the later `Int(width)` conversion for fluid / invalid sizes).
  /// 2. Exact fixed sizes → `.standard` / `.mrec`.
  /// 3. Full-width fixed-height banner → `.standard`. Google Mobile Ads iOS
  ///    normalizes a fixed banner to the container width while keeping a standard
  ///    banner height (50 / 90); once normalized the original fixed/adaptive
  ///    signal is not recoverable, so preserve pre-adaptive fixed behavior. This
  ///    is checked BEFORE anchored because anchored heights overlap the fixed
  ///    heights and, after normalization, the two are indistinguishable.
  /// 4. Height matches an anchored adaptive size for this width → `.anchoredAdaptive`,
  ///    matched by **height** (not `AdSizeEqualToSize`, since mediation can
  ///    normalize the width and size flags) against the current large anchored
  ///    variants.
  /// 5. Fallback (inline adaptive and other custom sizes) → `.inlineAdaptive`
  ///    (Google's inline-adaptive `height == 0` signal does not exist on iOS).
  @available(iOS 13.0, *)
  static func resolvedBannerFormat(from adSize: AdSize) -> ResolvedBannerFormat {
    let size = adSize.size
    // Reject non-finite, non-positive, and out-of-range widths (e.g. fluid /
    // invalid sizes, whose width can be a large finite sentinel) so the later
    // `Int(width)` conversion cannot trap.
    guard size.width.isFinite, size.width > 0, size.width < 10_000,
      size.height.isFinite, size.height > 0
    else {
      return .standard
    }
    if isAdSizeEqualToSize(size1: adSize, size2: AdSizeBanner) {
      return .standard
    }
    if isAdSizeEqualToSize(size1: adSize, size2: AdSizeMediumRectangle) {
      return .mrec
    }
    if isNormalizedFixedHeightBanner(adSize) {
      return .standard
    }
    if isAnchoredAdaptiveHeight(size.height, forWidth: size.width) {
      return .anchoredAdaptive
    }
    return .inlineAdaptive
  }

  /// Maps a Google Mobile Ads `AdSize` to the matching Moloco `MolocoBannerAdSize`.
  @available(iOS 13.0, *)
  static func molocoBannerAdSize(from adSize: AdSize) -> MolocoBannerAdSize {
    // `Int(width)` is evaluated only for the adaptive cases, which are reached
    // only after `resolvedBannerFormat` has validated the width is finite.
    switch resolvedBannerFormat(from: adSize) {
    case .standard:
      return .standard
    case .mrec:
      return .mrec
    case .anchoredAdaptive:
      return .anchoredAdaptive(width: Int(adSize.size.width))
    case .inlineAdaptive:
      return .inlineAdaptive(width: Int(adSize.size.width))
    }
  }

  /// Whether `height` matches an anchored adaptive banner height for `width`.
  /// Uses only the current (non-deprecated) large anchored variants; a small
  /// tolerance absorbs any rounding applied to the delivered size.
  @available(iOS 13.0, *)
  private static func isAnchoredAdaptiveHeight(_ height: CGFloat, forWidth width: CGFloat) -> Bool
  {
    let anchoredSizes = [
      largePortraitAnchoredAdaptiveBanner(width: width),
      largeLandscapeAnchoredAdaptiveBanner(width: width),
    ]
    return anchoredSizes.contains { abs($0.size.height - height) < 0.5 }
  }

  /// Whether Google Mobile Ads normalized a fixed banner to a larger container
  /// width while keeping a standard fixed banner height (50 / 90). Exact fixed
  /// sizes are matched earlier, so this only fires once the width has been
  /// stretched beyond the standard banner width.
  @available(iOS 13.0, *)
  private static func isNormalizedFixedHeightBanner(_ adSize: AdSize) -> Bool {
    guard adSize.size.width > AdSizeBanner.size.width else { return false }
    return adSize.size.height == AdSizeBanner.size.height
      || adSize.size.height == AdSizeLeaderboard.size.height
  }

}

// MARK: - MediationBannerAd

extension BannerAdLoader: MediationBannerAd {

  var view: UIView {
    guard #available(iOS 13.0, *) else {
      MolocoUtils.log(
        "The Moloco banner ad are only supported on iOS 13+. Returning a default UIView.")
      return UIView()
    }
    guard let bannerAdView else {
      MolocoUtils.log("The Moloco banner ad has not been loaded yet. Returning a default UIView.")
      return UIView()
    }
    return bannerAdView
  }

}

// MARK: - MolocoBannerDelegate

extension BannerAdLoader: MolocoBannerDelegate {

  func didLoad(ad: MolocoAd) {
    eventDelegate = loadCompletionHandler(self, nil)
  }

  func failToLoad(ad: MolocoAd, with error: Error?) {
    _ = loadCompletionHandler(nil, error)
  }

  func didShow(ad: MolocoAd) {
    eventDelegate?.reportImpression()
  }

  func failToShow(ad: MolocoAd, with error: Error?) {
    let showError =
      error
      ?? MolocoUtils.error(
        code: .adFailedToShow, description: "Ad failed to show")
    eventDelegate?.didFailToPresentWithError(showError)
  }

  func didHide(ad: MolocoAd) {
    MolocoUtils.log("The Moloco banner ad did hide.")
  }

  func didClick(on ad: MolocoAd) {
    eventDelegate?.reportClick()
  }

}
