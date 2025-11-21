import AdapterUnitTestKit
import HyBid
import XCTest

@testable import VerveAdapter

final class VerveRewardedAdTests: XCTestCase {

  var adapter: VerveAdapter!

  override func setUp() {
    adapter = VerveAdapter()
  }

  override func tearDown() {
    HybidClientFactory.debugClient = nil
  }

  func testRewardedAdLoad_succeeds() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"

    AUTKWaitAndAssertLoadRewardedAd(adapter, config)
  }

  func testRewardedAdLoad_fails_whenBidresponseIsMissing() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationRewardedAdConfiguration()

    AUTKWaitAndAssertLoadRewardedAdFailure(
      adapter, config,
      VerveAdapterError(
        errorCode: .invalidAdConfiguration,
        description: "The ad configuration is missing bid response."
      ).toNSError())
  }

  func testRewardedAdLoad_fails_whenHyBidFailsToLoad() {
    let debugClient = FakeHyBidClient()
    debugClient.shouldAdLoadSucceed = false
    HybidClientFactory.debugClient = debugClient

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"

    AUTKWaitAndAssertLoadRewardedAdFailure(
      adapter, config, NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
  }

  func testPresentation_succeeds() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, config)
    (eventDelegate.rewardedAd! as MediationRewardedAd).present(from: UIViewController())
    XCTAssertNil(eventDelegate.didFailToPresentError)
  }

  func testPresentation_fails() {
    let debugClient = FakeHyBidClient()
    debugClient.shouldPresentationSucceed = false
    HybidClientFactory.debugClient = debugClient

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, config)
    (eventDelegate.rewardedAd! as MediationRewardedAd).present(from: UIViewController())
    XCTAssertNotNil(eventDelegate.didFailToPresentError)
  }

  func testImpression() {
    let fakeClient = FakeHyBidClient()
    HybidClientFactory.debugClient = fakeClient

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, config)
    fakeClient.rewardedAdDelegate?.rewardedDidTrackImpression()
    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
  }

  func testClick() {
    let fakeClient = FakeHyBidClient()
    HybidClientFactory.debugClient = fakeClient

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, config)
    fakeClient.rewardedAdDelegate?.rewardedDidTrackClick()
    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

  func testDismiss() {
    let fakeClient = FakeHyBidClient()
    HybidClientFactory.debugClient = fakeClient

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, config)
    fakeClient.rewardedAdDelegate?.rewardedDidDismiss()
    XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1)
  }

  func testReward() {
    let fakeClient = FakeHyBidClient()
    HybidClientFactory.debugClient = fakeClient

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadRewardedAd(adapter, config)
    fakeClient.rewardedAdDelegate?.onReward()
    XCTAssertEqual(eventDelegate.didRewardUserInvokeCount, 1)
  }

}
