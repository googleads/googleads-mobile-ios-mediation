import AdapterUnitTestKit
import XCTest

@testable import BigoAdapter

final class BigoRewardedInterstitialAdTests: XCTestCase {

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

  func testLoadRtbRewardedInterstitialAd_succeeds() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)

    AUTKWaitAndAssertLoadRewardedInterstitialAd(adapter, config)
  }

  func testLoadRtbRewardedInterstitialAd_fails_whenBigoADSFailsToLoad() {
    fakeClient.shouldAdLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = NSError(domain: "com.google.mediation.bigo", code: 12345, userInfo: [:])

    AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbRewardedInterstitialAd_fails_whenSlotIdIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbRewardedInterstitialAd_fails_whenBidResponseIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationRewardedAdConfiguration()
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(adapter, config, expectedError)
  }

  func testLoadRtbRewardedInterstitialAd_fails_whenWatermarkIsMissing() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationRewardedAdConfiguration()
    config.credentials = credentials
    config.bidResponse = "test"
    let expectedError = BigoAdapterError(errorCode: .invalidAdConfiguration, description: "")
      .toNSError()

    AUTKWaitAndAssertLoadRewardedInterstitialAdFailure(adapter, config, expectedError)
  }

  func testShowRewardedAd_succeeds() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["slot_id": "test"]
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"
    config.credentials = credentials
    config.watermark = Data(repeating: 1, count: 1)
    let delegate = AUTKWaitAndAssertLoadRewardedInterstitialAd(adapter, config)
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
    config.watermark = Data(repeating: 1, count: 1)
    let delegate = AUTKWaitAndAssertLoadRewardedInterstitialAd(adapter, config)
    let rewardedAd = delegate.rewardedAd! as MediationRewardedAd
    rewardedAd.present(from: UIViewController())

    XCTAssertNotNil(delegate.didFailToPresentError)
  }

}
