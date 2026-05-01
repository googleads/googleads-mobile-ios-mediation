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
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .unspecified
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

  func testSetUp_succeeds() throws {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertNil(coppaConsent)
  }

  func testSetUp_succeeds_withTagForChildTrue() throws {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == false)
  }

  func testSetUp_succeeds_withTagForChildFalse() throws {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == true)
  }

  func testSetUp_succeeds_withTagForUnderAgeTrue() throws {
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == false)
  }

  func testSetUp_succeeds_withTagForUnderAgeFalse() throws {
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == true)
  }

  func testSetUp_succeeds_withAgeRestrictedTreatmentChild() throws {
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .child

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == false)
  }

  func testSetUp_succeeds_withAgeRestrictedTreatmentTeen() throws {
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .teen

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == nil)
  }

  func testSetUp_succeeds_withTagForChildTrueUnderAgeFalseAndAgeRestrictedTreatmentTeen() throws {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .teen

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == false)
  }

  func testSetUp_succeeds_withTagForChildFalseUnderAgeTrueAndAgeRestrictedTreatmentTeen() throws {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .teen

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == false)
  }

  func testSetUp_succeeds_withTagForChildFalseUnderAgeFalseAndAgeRestrictedTreatmentChild() throws {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .child

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == false)
  }

  func testSetUp_succeeds_withTagForChildFalseUnderAgeFalseAndAgeRestrictedTreatmentTeen() throws {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .teen

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == true)
  }

  func testSetUp_succeeds_withTagForChildTrueUnderAgeTrueAndAgeRestrictedTreatmentChild() throws {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .child

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]
    AUTKWaitAndAssertAdapterSetUpWithConfiguration(BigoAdapter.self, serverConfiguration)

    let applicationId = try XCTUnwrap(fakeClient.applicationId)
    let coppaConsent = fakeClient.bigoConsentOptionsCOPPA

    XCTAssertEqual(applicationId, "test_id")
    XCTAssertTrue(coppaConsent == false)
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
