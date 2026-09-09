import AdapterUnitTestKit
import BigoADS
import XCTest

@testable import BigoAdapter

final class BigoBannerAdTests: XCTestCase {

  var fakeClient: FakeBigoClient!
  var adapter: BigoAdapter!

  override func setUp() {
    super.setUp()
    adapter = BigoAdapter()
    fakeClient = FakeBigoClient()
    BigoClientFactory.debugClient = fakeClient
  }

  override func tearDown() {
    BigoClientFactory.debugClient = nil
    super.tearDown()
  }

  func testLoadBannerAd_succeeds_withBannerSize() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSizeBanner
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    AUTKWaitAndAssertLoadBannerAd(adapter, config)
  }

  func testLoadBannerAd_succeeds_withMediumRectangleSize() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSizeMediumRectangle
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    AUTKWaitAndAssertLoadBannerAd(adapter, config)
  }

  func testLoadBannerAd_succeeds_withLargeBannerSize() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSizeLargeBanner
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    AUTKWaitAndAssertLoadBannerAd(adapter, config)
  }

  func testLoadBannerAd_succeeds_withLeaderboardSize() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSizeLeaderboard
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    AUTKWaitAndAssertLoadBannerAd(adapter, config)
  }

  func testLoadBannerAd_succeeds_withFlexibleBanner() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = currentOrientationInlineAdaptiveBanner(width: 320)
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    AUTKWaitAndAssertLoadBannerAd(adapter, config)
  }

  func testLoadBannerAd_succeeds_withAnchoredAdaptiveBanner() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = currentOrientationAnchoredAdaptiveBanner(width: 375)
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    AUTKWaitAndAssertLoadBannerAd(adapter, config)
  }

  func testLoadBannerAd_succeeds_withLeaderboardAdaptiveBanner() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = currentOrientationAnchoredAdaptiveBanner(width: 728)
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    AUTKWaitAndAssertLoadBannerAd(adapter, config)
  }

  func testAdSize_mapping() throws {
    let bannerSize = try Util.adSize(for: AdSizeBanner)
    XCTAssertEqual(bannerSize.width, BigoAdSize.banner().width)
    XCTAssertEqual(bannerSize.height, BigoAdSize.banner().height)

    let mediumRectangleSize = try Util.adSize(for: AdSizeMediumRectangle)
    XCTAssertEqual(mediumRectangleSize.width, BigoAdSize.medium_RECTANGLE().width)
    XCTAssertEqual(mediumRectangleSize.height, BigoAdSize.medium_RECTANGLE().height)

    let largeBannerSize = try Util.adSize(for: AdSizeLargeBanner)
    XCTAssertEqual(largeBannerSize.width, BigoAdSize.mobile_LARGE_LEADERBOARD().width)
    XCTAssertEqual(largeBannerSize.height, BigoAdSize.mobile_LARGE_LEADERBOARD().height)

    let leaderboardSize = try Util.adSize(for: AdSizeLeaderboard)
    XCTAssertEqual(leaderboardSize.width, BigoAdSize.leaderboard().width)
    XCTAssertEqual(leaderboardSize.height, BigoAdSize.leaderboard().height)

    let anchoredAdaptiveSize = try Util.adSize(
      for: currentOrientationAnchoredAdaptiveBanner(width: 375))
    XCTAssertEqual(anchoredAdaptiveSize.width, BigoAdSize.banner().width)
    XCTAssertEqual(anchoredAdaptiveSize.height, BigoAdSize.banner().height)

    let leaderboardAdaptiveSize = try Util.adSize(
      for: currentOrientationAnchoredAdaptiveBanner(width: 728))
    XCTAssertEqual(leaderboardAdaptiveSize.width, BigoAdSize.leaderboard().width)
    XCTAssertEqual(leaderboardAdaptiveSize.height, BigoAdSize.leaderboard().height)

    let inlineAdaptiveSize = try Util.adSize(
      for: currentOrientationInlineAdaptiveBanner(width: 320))
    XCTAssertEqual(inlineAdaptiveSize.width, BigoAdSize.banner().width)
    XCTAssertEqual(inlineAdaptiveSize.height, BigoAdSize.banner().height)
  }

  func testLoadBannerAd_fails_whenMissingBidResposne() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.adSize = AdSizeBanner
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  func testLoadBannerAd_fails_whenWatermarkIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.adSize = AdSizeBanner
    config.credentials = credentials
    config.bidResponse = "test"
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  func testLoadBannerAd_fails_whenMissingSlotId() {
    let credentials = AUTKMediationCredentials()
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSizeBanner
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  func testLoadBannerAd_fails_whenBigoADSFailsToLoad() {
    fakeClient.shouldAdLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSizeBanner
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = NSError(domain: "com.google.mediation.bigo", code: 12345, userInfo: [:])

    AUTKWaitAndAssertLoadBannerAdFailure(adapter, config, expectedError)
  }

  func testBannerAdEvents() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSizeBanner
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    let eventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, config)
    XCTAssertNotNil(eventDelegate.bannerAd)
    let interactionDelegate = eventDelegate.bannerAd as! BigoAdInteractionDelegate
    interactionDelegate.onAdImpression?(BigoAd())
    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
    interactionDelegate.onAdClicked?(BigoAd())
    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

}
