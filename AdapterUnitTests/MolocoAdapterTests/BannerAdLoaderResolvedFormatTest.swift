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

import GoogleMobileAds
import XCTest

@testable import MolocoAdapter

/// Tests for `BannerAdLoader.resolvedBannerFormat(from:)`, the pure mapping from
/// a Google `AdSize` to the Moloco banner format.
@available(iOS 13.0, *)
final class BannerAdLoaderResolvedFormatTest: XCTestCase {

  static let testWidth: CGFloat = 375

  /// Asserts an anchored adaptive `AdSize` resolves to `.anchoredAdaptive`.
  /// Skips (rather than fails) when the anchored height for this device equals a
  /// fixed banner height (50 / 90): the resolver deliberately maps that overlap
  /// to `.standard`, so the outcome is device-dependent by design.
  private func assertResolvesToAnchored(_ adSize: AdSize) throws {
    let height = adSize.size.height
    try XCTSkipIf(
      height == AdSizeBanner.size.height || height == AdSizeLeaderboard.size.height,
      "Anchored height (\(height)) collides with a fixed banner height on this device; the "
        + "resolver maps it to .standard by design.")
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSize), .anchoredAdaptive)
  }

  func testStandardBannerResolvesToStandard() {
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: AdSizeBanner), .standard)
  }

  func testMediumRectangleResolvesToMREC() {
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: AdSizeMediumRectangle), .mrec)
  }

  func testFullWidthFixedHeightBannerResolvesToStandard() {
    let adSize = adSizeFor(cgSize: CGSize(width: 408, height: AdSizeBanner.size.height))
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSize), .standard)
  }

  func testLeaderboardResolvesToStandard() {
    // Moloco has no leaderboard type; a leaderboard-height banner is treated as
    // a fixed (standard) banner rather than adaptive.
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: AdSizeLeaderboard), .standard)
  }

  func testFullWidthLeaderboardHeightBannerResolvesToStandard() {
    let adSize = adSizeFor(cgSize: CGSize(width: 408, height: AdSizeLeaderboard.size.height))
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSize), .standard)
  }

  func testLargeAnchoredResolvesToAnchored() throws {
    try assertResolvesToAnchored(largeAnchoredAdaptiveBanner(width: Self.testWidth))
  }

  func testLargePortraitAnchoredResolvesToAnchored() throws {
    try assertResolvesToAnchored(largePortraitAnchoredAdaptiveBanner(width: Self.testWidth))
  }

  func testLargeLandscapeAnchoredResolvesToAnchored() throws {
    try assertResolvesToAnchored(largeLandscapeAnchoredAdaptiveBanner(width: Self.testWidth))
  }

  func testInlineAdaptiveResolvesToInline() {
    let adSize = inlineAdaptiveBanner(width: Self.testWidth, maxHeight: 400)
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSize), .inlineAdaptive)
  }

  func testDegenerateSizeResolvesToStandard() {
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSizeFor(cgSize: .zero)), .standard)
  }

  func testOutOfRangeWidthResolvesToStandard() {
    // A finite-but-huge width (e.g. a fluid / invalid sentinel) must be rejected
    // by the width bound so it never reaches the `Int(width)` conversion. The
    // height (250) is neither a fixed nor an anchored height, so without the
    // bound this would resolve to `.inlineAdaptive` — pinning the guard.
    let adSize = adSizeFor(cgSize: CGSize(width: .greatestFiniteMagnitude, height: 250))
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSize), .standard)
  }

}
