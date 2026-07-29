import AdapterUnitTestKit
import GoogleMobileAds
import MolocoSDK
import XCTest

@testable import MolocoAdapter

final class MolocoBannerAdTest: XCTestCase {

  /// An ad unit ID used in testing.
  static let testAdUnitID = "12345"
  /// A bid response received by the adapter to load the ad.
  static let testBidResponse = "bid_response"

  static let testWatermarkData = Data()

  @MainActor
  @available(iOS 13.0, *)
  func testFakeBannerFactory() throws {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adConfiguration = MediationBannerAdConfiguration()
    let bannerLoader = BannerAdLoader(
      adConfiguration: adConfiguration, molocoBannerFactory: molocoBannerFactory
    ) { ad, error in
      return nil
    }
    let banner = molocoBannerFactory.createBanner(
      for: Self.testAdUnitID, size: .standard, delegate: bannerLoader,
      watermarkData: MolocoBannerAdTest.testWatermarkData)
    let fakeMolocoBanner = try XCTUnwrap(banner as? FakeMolocoBanner)

    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, Self.testAdUnitID)
    XCTAssertTrue(fakeMolocoBanner.isReady)
    XCTAssertNotNil(fakeMolocoBanner.bannerDelegate)
    XCTAssertEqual(fakeMolocoBanner.frame, CGRect.zero)
  }

  func testBannerLoadSuccess() {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    AUTKWaitAndAssertLoadBannerAd(adapter, mediationAdConfig)
    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, Self.testAdUnitID)
    XCTAssertEqual(
      molocoBannerFactory.fakeMolocoBanner?.bidResponseUsedToLoadMolocoAd, Self.testBidResponse
    )
  }

  func testMRECLoadSuccess() {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    mediationAdConfig.adSize = AdSizeMediumRectangle
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    AUTKWaitAndAssertLoadBannerAd(adapter, mediationAdConfig)
    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, Self.testAdUnitID)
    XCTAssertEqual(
      molocoBannerFactory.fakeMolocoBanner?.bidResponseUsedToLoadMolocoAd, Self.testBidResponse
    )
    // The MREC ad size resolves to the MREC banner format. (The loaded
    // MolocoBannerAdSize itself is opaque to the test, so routing is asserted at
    // the resolver.)
    if #available(iOS 13.0, *) {
      XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: mediationAdConfig.adSize), .mrec)
    }
  }

  func testBannerLoadFailure() {
    let loadError = NSError(domain: "moloco_sdk_domain", code: 1002)
    let molocoBannerFactory = FakeMolocoBannerFactory(loadError: loadError)
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, mediationAdConfig, loadError)
  }

  func testInterstitialLoadFailure_ifBidResponseIsMissing() {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials

    let expectedError = NSError(
      domain: MolocoConstants.adapterErrorDomain,
      code: MolocoAdapterErrorCode.nilBidResponse.rawValue)
    AUTKWaitAndAssertLoadBannerAdFailure(adapter, mediationAdConfig, expectedError)
  }

  func testBannerLoadFailure_ifAdUnitIdIsMissing() {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    let expectedError = NSError(
      domain: MolocoConstants.adapterErrorDomain,
      code: MolocoAdapterErrorCode.invalidAdUnitId.rawValue)
    AUTKWaitAndAssertLoadBannerAdFailure(adapter, mediationAdConfig, expectedError)
  }

  func testBannerLoadTriggersExpectedLifecycleEvents() throws {
    let molocoBannerFactory = FakeMolocoBannerFactory()
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    let adEventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, mediationAdConfig)

    XCTAssertNil(adEventDelegate.didFailToPresentError)
    let bannerAd = try XCTUnwrap(adEventDelegate.bannerAd)
    XCTAssertEqual(bannerAd.view, molocoBannerFactory.fakeMolocoBanner)
    XCTAssertEqual(adEventDelegate.reportClickInvokeCount, 1)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 1)
  }

  func testBannerShowFailureWithError() throws {
    let showError = NSError(domain: "moloco_sdk_domain", code: 1002)
    let molocoBannerFactory = FakeMolocoBannerFactory(showError: showError)
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    let adEventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, mediationAdConfig)
    let didFailToPresentError = try XCTUnwrap(adEventDelegate.didFailToPresentError as? NSError)

    XCTAssertEqual(didFailToPresentError.domain, "moloco_sdk_domain")
    XCTAssertEqual(didFailToPresentError.code, 1002)
    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, Self.testAdUnitID)
    XCTAssertEqual(
      molocoBannerFactory.fakeMolocoBanner?.bidResponseUsedToLoadMolocoAd, Self.testBidResponse
    )
    XCTAssertNotNil(adEventDelegate.didFailToPresentError)
    let bannerAd = try XCTUnwrap(adEventDelegate.bannerAd)
    XCTAssertEqual(bannerAd.view, molocoBannerFactory.fakeMolocoBanner)
    XCTAssertEqual(adEventDelegate.reportClickInvokeCount, 0)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 0)
  }

  func testBannerShowFailureWithDefaultError() throws {
    let molocoBannerFactory = FakeMolocoBannerFactory(shouldFailToShow: true)
    let adapter = MolocoMediationAdapter(molocoBannerFactory: molocoBannerFactory)
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.adUnitIdKey: Self.testAdUnitID]
    mediationAdConfig.credentials = credentials
    mediationAdConfig.bidResponse = Self.testBidResponse

    let adEventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, mediationAdConfig)
    let didFailToPresentError = try XCTUnwrap(adEventDelegate.didFailToPresentError as? NSError)

    XCTAssertEqual(didFailToPresentError.domain, MolocoConstants.adapterErrorDomain)
    XCTAssertEqual(didFailToPresentError.code, MolocoAdapterErrorCode.adFailedToShow.rawValue)
    XCTAssertEqual(molocoBannerFactory.adUnitIDUsedToCreateMolocoAd, Self.testAdUnitID)
    XCTAssertEqual(
      molocoBannerFactory.fakeMolocoBanner?.bidResponseUsedToLoadMolocoAd, Self.testBidResponse
    )
    XCTAssertNotNil(adEventDelegate.didFailToPresentError)
    let bannerAd = try XCTUnwrap(adEventDelegate.bannerAd)
    XCTAssertEqual(bannerAd.view, molocoBannerFactory.fakeMolocoBanner)
    XCTAssertEqual(adEventDelegate.reportClickInvokeCount, 0)
    XCTAssertEqual(adEventDelegate.reportImpressionInvokeCount, 0)
  }

  func testViewWhenAdDidNotLoad() throws {
    let adEventDelegate = AUTKMediationBannerAdEventDelegate()
    let mediationAdConfig = AUTKMediationBannerAdConfiguration()
    let molocoBannerFactory = FakeMolocoBannerFactory(shouldFailToShow: true)
    adEventDelegate.bannerAd = BannerAdLoader(
      adConfiguration: mediationAdConfig, molocoBannerFactory: molocoBannerFactory,
      loadCompletionHandler: { _, _ in nil })

    let bannerAd = try XCTUnwrap(adEventDelegate.bannerAd)
    XCTAssertNotEqual(bannerAd.view, molocoBannerFactory.fakeMolocoBanner)
    XCTAssertFalse(bannerAd.view is FakeMolocoBanner)
  }

  // MARK: - Banner Format Resolution Tests

  static let testWidth: CGFloat = 375

  /// Asserts an anchored adaptive `AdSize` resolves to `.anchoredAdaptive`.
  /// Skips (rather than fails) when the anchored height for this device equals a
  /// fixed banner height (50 / 90): the resolver deliberately maps that overlap
  /// to `.standard`, so the outcome is device-dependent by design.
  @available(iOS 13.0, *)
  private func assertResolvesToAnchored(_ adSize: AdSize) throws {
    let height = adSize.size.height
    try XCTSkipIf(
      height == AdSizeBanner.size.height || height == AdSizeLeaderboard.size.height,
      "Anchored height (\(height)) collides with a fixed banner height on this device; the "
        + "resolver maps it to .standard by design.")
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSize), .anchoredAdaptive)
  }

  @available(iOS 13.0, *)
  func testStandardBannerResolvesToStandard() {
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: AdSizeBanner), .standard)
  }

  @available(iOS 13.0, *)
  func testMediumRectangleResolvesToMREC() {
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: AdSizeMediumRectangle), .mrec)
  }

  @available(iOS 13.0, *)
  func testFullWidthFixedHeightBannerResolvesToStandard() {
    let adSize = adSizeFor(cgSize: CGSize(width: 408, height: AdSizeBanner.size.height))
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSize), .standard)
  }

  @available(iOS 13.0, *)
  func testLeaderboardResolvesToStandard() {
    // Moloco has no leaderboard type; a leaderboard-height banner is treated as
    // a fixed (standard) banner rather than adaptive.
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: AdSizeLeaderboard), .standard)
  }

  @available(iOS 13.0, *)
  func testFullWidthLeaderboardHeightBannerResolvesToStandard() {
    let adSize = adSizeFor(cgSize: CGSize(width: 408, height: AdSizeLeaderboard.size.height))
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSize), .standard)
  }

  @available(iOS 13.0, *)
  func testLargeAnchoredResolvesToAnchored() throws {
    try assertResolvesToAnchored(largeAnchoredAdaptiveBanner(width: Self.testWidth))
  }

  @available(iOS 13.0, *)
  func testLargePortraitAnchoredResolvesToAnchored() throws {
    try assertResolvesToAnchored(largePortraitAnchoredAdaptiveBanner(width: Self.testWidth))
  }

  @available(iOS 13.0, *)
  func testLargeLandscapeAnchoredResolvesToAnchored() throws {
    try assertResolvesToAnchored(largeLandscapeAnchoredAdaptiveBanner(width: Self.testWidth))
  }

  @available(iOS 13.0, *)
  func testInlineAdaptiveResolvesToInline() {
    let adSize = inlineAdaptiveBanner(width: Self.testWidth, maxHeight: 400)
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSize), .inlineAdaptive)
  }

  @available(iOS 13.0, *)
  func testDegenerateSizeResolvesToStandard() {
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSizeFor(cgSize: .zero)), .standard)
  }

  @available(iOS 13.0, *)
  func testOutOfRangeWidthResolvesToStandard() {
    // A finite-but-huge width (e.g. a fluid / invalid sentinel) must be rejected
    // by the width bound so it never reaches the `Int(width)` conversion. The
    // height (250) is neither a fixed nor an anchored height, so without the
    // bound this would resolve to `.inlineAdaptive` — pinning the guard.
    let adSize = adSizeFor(cgSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 250))
    XCTAssertEqual(BannerAdLoader.resolvedBannerFormat(from: adSize), .standard)
  }

}
