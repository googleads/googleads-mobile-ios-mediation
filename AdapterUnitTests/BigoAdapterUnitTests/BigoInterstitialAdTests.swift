import AdapterUnitTestKit
import XCTest

@testable import BigoAdapter

final class BigoInterstitialAdTests: XCTestCase {

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

  func testLoadRtbInterstitialAd_succeeds() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials

    AUTKWaitAndAssertLoadInterstitialAd(adapter, config)
  }

  func testLoadRtbInterstitialAd_fails_whenBigoADSFailsToLoad() {
    fakeClient.shouldAdLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    let expectedError = NSError(domain: "com.google.mediation.bigo", code: 12345, userInfo: [:])

    AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbInterstitialAd_fails_whenSlotIdIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbInterstitialAd_fails_whenBidResponseIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationInterstitialAdConfiguration()
    config.credentials = credentials
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadInterstitialAdFailure(adapter, config, expectedError)
  }

  func testShowInterstitialAd_succeeds() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials

    let delegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, config)
    let interstitialAd = delegate.interstitialAd! as MediationInterstitialAd
    interstitialAd.present(from: UIViewController())

    XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1)
    XCTAssertEqual(delegate.reportImpressionInvokeCount, 1)
    XCTAssertEqual(delegate.reportClickInvokeCount, 1)
    XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1)
  }

  func testShowInterstialAd_fails() {
    fakeClient.shouldAdShowSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials

    let delegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, config)
    let interstitialAd = delegate.interstitialAd! as MediationInterstitialAd
    interstitialAd.present(from: UIViewController())

    XCTAssertNotNil(delegate.didFailToPresentError)
  }

}
