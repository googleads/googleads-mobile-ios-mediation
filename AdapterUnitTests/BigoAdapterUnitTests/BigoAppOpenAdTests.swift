import AdapterUnitTestKit
import XCTest

@testable import BigoAdapter

final class BigoAppOpenAdTests: XCTestCase {

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

  func testLoadRtbAppOpenAd_succeeds() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationAppOpenAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    AUTKWaitAndAssertLoadAppOpenAd(adapter, config)
  }

  func testLoadRtbAppOpenAd_fails_whenBigoADSFailsToLoad() {
    fakeClient.shouldAdLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationAppOpenAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = NSError(domain: "com.google.mediation.bigo", code: 12345, userInfo: [:])

    AUTKWaitAndAssertLoadAppOpenAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbAppOpenAd_fails_whenSlotIdIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let config = AUTKMediationAppOpenAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadAppOpenAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbAppOpenAd_fails_whenBidResponseIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationAppOpenAdConfiguration()
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadAppOpenAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbAppOpenAd_fails_whenWatermarkIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationAppOpenAdConfiguration()
    config.credentials = credentials
    config.bidResponse = "test"
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadAppOpenAdFailure(adapter, config, expectedError)
  }

  func testShowAppOpenAd_succeeds() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationAppOpenAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    let delegate = AUTKWaitAndAssertLoadAppOpenAd(adapter, config)
    let appOpenAd = delegate.appOpenAd! as MediationAppOpenAd
    appOpenAd.present(from: UIViewController())

    XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1)
    XCTAssertEqual(delegate.reportImpressionInvokeCount, 1)
    XCTAssertEqual(delegate.reportClickInvokeCount, 1)
    XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1)
  }

  func testShowAppOpenAd_fails() {
    fakeClient.shouldAdShowSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationAppOpenAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    let delegate = AUTKWaitAndAssertLoadAppOpenAd(adapter, config)
    let appOpenAd = delegate.appOpenAd! as MediationAppOpenAd
    appOpenAd.present(from: UIViewController())

    XCTAssertNotNil(delegate.didFailToPresentError)
  }

}
