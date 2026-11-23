import AdapterUnitTestKit
import BigoADS
import XCTest

@testable import BigoAdapter

final class BigoNativeAdTests: XCTestCase {

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

  func testLoadRtbNativeAd_succeeds() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    AUTKWaitAndAssertLoadNativeAd(adapter, config)
  }

  func testLoadRtbNativeAd_fails_whenBigoADSFailsToLoad() {
    fakeClient.shouldAdLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = NSError(domain: "com.google.mediation.bigo", code: 12345, userInfo: [:])

    AUTKWaitAndAssertLoadNativeAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbNativeAd_fails_whenSlotIdIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadNativeAdFailure(adapter, config, expectedError)
  }

  func testLoadWaterfallNativeAd_succeeds_withoutBidResponse() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test", "application_id": "test_id"]
    let config = AUTKMediationNativeAdConfiguration()
    config.credentials = credentials

    AUTKWaitAndAssertLoadNativeAd(adapter, config)

    XCTAssertEqual(fakeClient.lastLoadWasWaterfall, true)
    XCTAssertEqual(fakeClient.lastLoadSlotId, "test")
    XCTAssertNil(fakeClient.applicationId)
  }

  func testLoadWaterfallNativeAd_fails_whenBigoADSFailsToLoad() {
    fakeClient.shouldAdLoadSucceed = false
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test", "application_id": "test_id"]
    let config = AUTKMediationNativeAdConfiguration()
    config.credentials = credentials
    let expectedError = NSError(domain: "com.google.mediation.bigo", code: 12345, userInfo: [:])

    AUTKWaitAndAssertLoadNativeAdFailure(adapter, config, expectedError)
    XCTAssertEqual(fakeClient.lastLoadWasWaterfall, true)
  }

  func testLoadRtbNativeAd_fails_whenWatermarkIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationNativeAdConfiguration()
    config.credentials = credentials
    config.bidResponse = "test"
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadNativeAdFailure(adapter, config, expectedError)
  }

  func testNativeAdInteraction() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    let delegate = AUTKWaitAndAssertLoadNativeAd(adapter, config)
    let interactionDelegate = delegate.nativeAd as! BigoAdInteractionDelegate
    interactionDelegate.onAdImpression?(BigoAd())
    XCTAssertEqual(delegate.reportImpressionInvokeCount, 1)
    interactionDelegate.onAdClicked?(BigoAd())
    XCTAssertEqual(delegate.reportClickInvokeCount, 1)
  }

}
