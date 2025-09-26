import AdapterUnitTestKit
import XCTest

@testable import BigoAdapter

final class BigoRewardedAdTests: XCTestCase {

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

  func testLoadRtbRewardedAd_succeeds() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials

    AUTKWaitAndAssertLoadRewardedAd(adapter, config)
  }

  func testLoadRtbRewardedAd_fails_whenBigoADSFailsToLoad() {
    fakeClient.shouldAdLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    let expectedError = NSError(domain: "com.google.mediation.bigo", code: 12345, userInfo: [:])

    AUTKWaitAndAssertLoadRewardedAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbRewardedAd_fails_whenSlotIdIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadRewardedAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbRewardedAd_fails_whenBidResponseIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationRewardedAdConfiguration()
    config.credentials = credentials
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadRewardedAdFailure(adapter, config, expectedError)
  }

  func testShowRewardedAd_succeeds() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials

    let delegate = AUTKWaitAndAssertLoadRewardedAd(adapter, config)
    let rewardedAd = delegate.rewardedAd! as MediationRewardedAd
    rewardedAd.present(from: UIViewController())

    XCTAssertEqual(delegate.willPresentFullScreenViewInvokeCount, 1)
    XCTAssertEqual(delegate.reportImpressionInvokeCount, 1)
    XCTAssertEqual(delegate.reportClickInvokeCount, 1)
    XCTAssertEqual(delegate.didDismissFullScreenViewInvokeCount, 1)
    XCTAssertEqual(delegate.didRewardUserInvokeCount, 1)
  }

  func testShowRewardedAd_fails() {
    fakeClient.shouldAdShowSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials

    let delegate = AUTKWaitAndAssertLoadRewardedAd(adapter, config)
    let rewardedAd = delegate.rewardedAd! as MediationRewardedAd
    rewardedAd.present(from: UIViewController())

    XCTAssertNotNil(delegate.didFailToPresentError)
  }

}
