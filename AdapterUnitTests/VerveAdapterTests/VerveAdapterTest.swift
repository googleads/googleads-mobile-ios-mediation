import AdapterUnitTestKit
import HyBid
import XCTest

@testable import VerveAdapter

final class VerveAdapterTest: XCTestCase {

  override func tearDown() {
    HybidClientFactory.debugClient = nil
  }

  func testAdapterVersion() {
    let version = VerveAdapter.adapterVersion()

    XCTAssertGreaterThan(version.majorVersion, 0)
    XCTAssertLessThanOrEqual(version.majorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.minorVersion, 0)
    XCTAssertLessThanOrEqual(version.minorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.patchVersion, 0)
    XCTAssertLessThanOrEqual(version.patchVersion, 9999)
  }

  func testAdSDKVersion() {
    let version = VerveAdapter.adSDKVersion()

    XCTAssertGreaterThan(version.majorVersion, 0)
    XCTAssertLessThanOrEqual(version.majorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.minorVersion, 0)
    XCTAssertLessThanOrEqual(version.minorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.patchVersion, 0)
    XCTAssertLessThanOrEqual(version.patchVersion, 9999)
  }

  func testAdapterSetUp_succeeds() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["AppToken": "AppToken"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(VerveAdapter.self, serverConfiguration)
  }

  func testAdapterSetUp_fails_whenCOPPAIsTrue() {
    HybidClientFactory.debugClient = nil
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["AppToken": "AppToken"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      VerveAdapter.self, serverConfiguration,
      VerveAdapterError(errorCode: .childUser, description: "some error message").toNSError())
  }

  func testAdapterSetUp_fails_whenTFUAIsTrue() {
    HybidClientFactory.debugClient = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["AppToken": "AppToken"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      VerveAdapter.self, serverConfiguration,
      VerveAdapterError(errorCode: .childUser, description: "some error message").toNSError())
  }

  func testAdapterSetUp_fails_whenAppTokenIsMissing() {
    HybidClientFactory.debugClient = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    let credentials = AUTKMediationCredentials()
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      VerveAdapter.self, serverConfiguration,
      VerveAdapterError(
        errorCode: .serverConfigurationMissingAppToken, description: "some error message"
      ).toNSError())
  }

  func testCollectionSignalsForBanner_succeeds_whenInvalidAdSize() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSizeInvalid

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs320x50() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 320, height: 50), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs300x250() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 300, height: 250), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs300x50() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 300, height: 50), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs320x480() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 320, height: 480), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs1024x768() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 1024, height: 768), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs768x1024() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 768, height: 1024), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs728x90() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 728, height: 90), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs160x600() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 160, height: 600), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs250x250() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 250, height: 250), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs300x600() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 300, height: 600), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs320x100() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 320, height: 100), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_succeeds_whenAdSizeIs480x320() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 480, height: 320), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

  func testCollectionSignalsForBanner_fail_whenAdSizeIsNotSupporteByHyBid() {
    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")
    let params = AUTKRTBRequestParameters()
    params.adSize = AdSize(size: CGSize(width: 123, height: 123), flags: 1)

    adapter.collectSignals(for: params) { signals, error in
      XCTAssertNil(signals)
      XCTAssertNotNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

}
