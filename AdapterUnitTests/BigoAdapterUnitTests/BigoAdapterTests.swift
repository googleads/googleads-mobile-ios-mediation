import AdapterUnitTestKit
import XCTest

@testable import BigoAdapter

final class BigoAdapterTest: XCTestCase {

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
    let fakeClient = FakeBigoClient()
    BigoClientFactory.debugClient = fakeClient
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
    let fakeClient = FakeBigoClient()
    BigoClientFactory.debugClient = fakeClient
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
    let fakeClient = FakeBigoClient()
    BigoClientFactory.debugClient = fakeClient
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

}
