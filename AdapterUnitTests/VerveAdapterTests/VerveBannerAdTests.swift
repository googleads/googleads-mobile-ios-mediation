import AdapterUnitTestKit
import HyBid
import XCTest

@testable import VerveAdapter

final class VerveBannerAdTests: XCTestCase {

  var adapter: VerveAdapter!

  override func setUp() {
    adapter = VerveAdapter()
  }

  override func tearDown() {
    HybidClientFactory.debugClient = nil
  }

  func testBannerLoad_succeeds() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSize(size: CGSize(width: 320, height: 50), flags: 1)
    AUTKWaitAndAssertLoadBannerAd(adapter, config)
  }

  func testBannerLoad_fails_whenMissingBidResponse() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationBannerAdConfiguration()
    config.adSize = AdSize(size: CGSize(width: 320, height: 50), flags: 1)
    AUTKWaitAndAssertLoadBannerAdFailure(
      adapter, config,
      VerveAdapterError(
        errorCode: .invalidAdConfiguration,
        description: "The ad configuration is missing bid response."
      ).toNSError())
  }

  func testBannerLoad_fails_whenHyBidFailsToLoad() {
    let debugClient = FakeHyBidClient()
    debugClient.shouldAdLoadSucceed = false
    HybidClientFactory.debugClient = debugClient

    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSize(size: CGSize(width: 320, height: 50), flags: 1)
    AUTKWaitAndAssertLoadBannerAdFailure(
      adapter, config, NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
  }

  func testImpression() {
    let fakeClient = FakeHyBidClient()
    HybidClientFactory.debugClient = fakeClient

    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSize(size: CGSize(width: 320, height: 50), flags: 1)
    let eventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, config)
    fakeClient.bannerDelegate?.adViewDidTrackImpression(nil)
    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
  }

  func testClick() {
    let fakeClient = FakeHyBidClient()
    HybidClientFactory.debugClient = fakeClient

    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "test"
    config.adSize = AdSize(size: CGSize(width: 320, height: 50), flags: 1)
    let eventDelegate = AUTKWaitAndAssertLoadBannerAd(adapter, config)
    fakeClient.bannerDelegate?.adViewDidTrackClick(nil)
    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

}
