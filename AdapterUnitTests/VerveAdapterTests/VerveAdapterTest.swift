import AdapterUnitTestKit
import HyBid
import XCTest

@testable import VerveAdapter

final class VerveAdapterTest: XCTestCase {

  override func tearDown() {
    VerveAdapterExtras.isTestMode = false
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

  func testCollectSignals() {
    HybidClientFactory.debugClient = FakeHyBidClient()

    let adapter = VerveAdapter()
    let expectation = expectation(description: "collect signals")

    adapter.collectSignals(for: AUTKRTBRequestParameters()) { signals, error in
      XCTAssertNotNil(signals)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation])
  }

}
