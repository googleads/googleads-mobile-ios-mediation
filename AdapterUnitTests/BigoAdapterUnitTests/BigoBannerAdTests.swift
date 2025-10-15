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

  func testLoadBannerAd_fails_withUnsupportedSize() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSizeSkyscraper
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = BigoAdapterError(errorCode: .unsupportedBannerSize, description: "")
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
