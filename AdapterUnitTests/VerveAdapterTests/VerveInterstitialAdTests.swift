import AdapterUnitTestKit
import HyBid
import XCTest

@testable import VerveAdapter

final class VerveInterstitialAdTests: XCTestCase {

  var adapter: VerveAdapter!

  override func setUp() {
    adapter = VerveAdapter()
  }

  override func tearDown() {
    HybidClientFactory.debugClient = nil
  }

  func testInterstitialLoad_succeeds() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"

    AUTKWaitAndAssertLoadInterstitialAd(adapter, config)
  }

  func testInterstitialLoad_fails_whenBidresponseIsMissing() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationInterstitialAdConfiguration()

    AUTKWaitAndAssertLoadInterstitialAdFailure(
      adapter, config,
      VerveAdapterError(
        errorCode: .invalidAdConfiguration,
        description: "The ad configuration is missing bid response."
      ).toNSError())
  }

  func testInterstitialLoad_fails_whenHyBidFailsToLoad() {
    let debugClient = FakeHyBidClient()
    debugClient.shouldAdLoadSucceed = false
    HybidClientFactory.debugClient = debugClient

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"

    AUTKWaitAndAssertLoadInterstitialAdFailure(
      adapter, config, NSError(domain: "com.test.verveadapter", code: 12345, userInfo: nil))
  }

  func testPresentation_succeeds() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, config)
    (eventDelegate.interstitialAd! as MediationInterstitialAd).present(from: UIViewController())
    XCTAssertNil(eventDelegate.didFailToPresentError)
  }

  func testPresentation_fails() {
    let debugClient = FakeHyBidClient()
    debugClient.shouldPresentationSucceed = false
    HybidClientFactory.debugClient = debugClient

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, config)
    (eventDelegate.interstitialAd! as MediationInterstitialAd).present(from: UIViewController())
    XCTAssertNotNil(eventDelegate.didFailToPresentError)
  }

  func testImpression() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, config)
    (eventDelegate.interstitialAd as! HyBidInterstitialAdDelegate).interstitialDidTrackImpression()
    XCTAssertEqual(eventDelegate.reportImpressionInvokeCount, 1)
  }

  func testClick() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, config)
    (eventDelegate.interstitialAd as! HyBidInterstitialAdDelegate).interstitialDidTrackClick()
    XCTAssertEqual(eventDelegate.reportClickInvokeCount, 1)
  }

  func testDismiss() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "test"

    let eventDelegate = AUTKWaitAndAssertLoadInterstitialAd(adapter, config)
    (eventDelegate.interstitialAd as! HyBidInterstitialAdDelegate).interstitialDidDismiss()
    XCTAssertEqual(eventDelegate.didDismissFullScreenViewInvokeCount, 1)
  }

}
