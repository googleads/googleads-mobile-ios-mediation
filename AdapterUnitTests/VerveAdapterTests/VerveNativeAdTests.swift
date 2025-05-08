import AdapterUnitTestKit
import HyBid
import XCTest

@testable import VerveAdapter

final class VerveNativeAdTests: XCTestCase {

  var adapter: VerveAdapter!

  override func setUp() {
    adapter = VerveAdapter()
  }

  override func tearDown() {
    HybidClientFactory.debugClient = nil
  }

  func testRewardedAdLoad_succeeds() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "test"

    AUTKWaitAndAssertLoadNativeAd(adapter, config)
  }

  func testNativeAdLoad_fails_whenBidResponseIsMissing() {
    let config = AUTKMediationNativeAdConfiguration()

    AUTKWaitAndAssertLoadNativeAdFailure(
      adapter, config,
      VerveAdapterError(
        errorCode: .invalidAdConfiguration,
        description: "The ad configuration is missing bid response."
      ).toNSError())
  }

  func testNativeAdLoad_fails_whenHyBidFailsToLoad() {
    let debugClient = FakeHyBidClient()
    debugClient.shouldAdLoadSucceed = false
    HybidClientFactory.debugClient = debugClient

    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "test"

    AUTKWaitAndAssertLoadNativeAdFailure(
      adapter, config, NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
  }

  func testNativeAdLoad_fails_whenHyBidFailToFetchNativeAdAssets() {
    let debugClient = FakeHyBidClient()
    debugClient.shouldNativeAssetFetchSucceed = false
    HybidClientFactory.debugClient = debugClient

    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "test"

    AUTKWaitAndAssertLoadNativeAdFailure(
      adapter, config, NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
  }

  func testImpression() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadNativeAd(adapter, config)
    (eventDelegate.nativeAd as! HyBidNativeAdDelegate).nativeAd(
      HyBidNativeAd(), impressionConfirmedWith: UIView())
    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
  }

  func testClick() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadNativeAd(adapter, config)
    (eventDelegate.nativeAd as! HyBidNativeAdDelegate).nativeAdDidClick(HyBidNativeAd())
    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

}
