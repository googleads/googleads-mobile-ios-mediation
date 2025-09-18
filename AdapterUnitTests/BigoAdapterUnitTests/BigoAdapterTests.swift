import AdapterUnitTestKit
import XCTest

@testable import BigoAdapter

final class BigoAdapterTest: XCTestCase {

  var fakeClient: FakeBigoClient!

  override func setUp() {
    super.setUp()
    fakeClient = FakeBigoClient()
    BigoClientFactory.debugClient = fakeClient
  }

  override func tearDown() {
    BigoClientFactory.debugClient = nil
    BigoAdapterExtras.testMode = false
    super.tearDown()
  }

  func testAdapterVersion() {
    let version = BigoAdapter.adapterVersion()

    XCTAssertGreaterThan(version.majorVersion, 0)
    XCTAssertLessThanOrEqual(version.majorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.minorVersion, 0)
    XCTAssertLessThanOrEqual(version.minorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.patchVersion, 0)
    XCTAssertLessThanOrEqual(version.patchVersion, 9999)
  }

  func testAdSDKVersion() {
    let version = BigoAdapter.adSDKVersion()

    XCTAssertGreaterThan(version.majorVersion, 0)
    XCTAssertLessThanOrEqual(version.majorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.minorVersion, 0)
    XCTAssertLessThanOrEqual(version.minorVersion, 99)
    XCTAssertGreaterThanOrEqual(version.patchVersion, 0)
    XCTAssertLessThanOrEqual(version.patchVersion, 9999)
  }

  func testSetUp_succeeds_withTestModeOn() throws {
    BigoAdapterExtras.testMode = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let testMode = try XCTUnwrap(fakeClient.testMode)
    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(testMode)
  }

  func testSetUp_succeeds_withTestModeOff() throws {
    BigoAdapterExtras.testMode = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let testMode = try XCTUnwrap(fakeClient.testMode)
    XCTAssertEqual(applicationId, "test_id")
    XCTAssertFalse(testMode)
  }

  func testSetUp_fails_whenMissingApplicationId() throws {
    BigoAdapterExtras.testMode = false

    let credentials = AUTKMediationCredentials()
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      BigoAdapter.self, serverConfiguration,
      BigoAdapterError(errorCode: .serverConfigurationMissingApplicationID, description: "")
        .toNSError())

    XCTAssertNil(fakeClient.applicationId)
    XCTAssertNil(fakeClient.testMode)
  }

  func testCollectingSignals() {
    let adapter = BigoAdapter()
    let expectation = self.expectation(description: "signal collection")

    adapter.collectSignals(for: AUTKRTBRequestParameters()) { token, error in
      XCTAssertNotNil(token)
      XCTAssertNil(error)
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 10)
  }

}
