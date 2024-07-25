import AdapterUnitTestKit
import GoogleMobileAds
import MolocoAdapter
import MolocoSDK
import XCTest

/// Tests for MolocoMediationAdapter.
final class MolocoMediationAdapterTest: XCTestCase {

  /// A test app key used in the tests.
  let appKey1 = "app_key_12345"

  /// Another test app key used in the tests.
  let appKey2 = "app_key_6789"

  /// A fake implementation of MolocoInitializer protocol that mimics successful initialization.
  class MolocoInitializerThatSucceeds: MolocoInitializer {

    var expectedAppKey: String

    init(expectedAppKey: String) {
      self.expectedAppKey = expectedAppKey
    }

    @available(iOS 13.0, *)
    func initialize(
      initParams: MolocoSDK.MolocoInitParams, completion: ((Bool, (any Error)?) -> Void)?
    ) {
      XCTAssertEqual(initParams.appKey, expectedAppKey)
      completion?(true, nil)
    }

    func isInitialized() -> Bool {
      // Stub to return false.
      return false
    }
  }

  func testSetUpSuccess() throws {
    MolocoMediationAdapter.setMolocoInitializer(
      MolocoInitializerThatSucceeds(expectedAppKey: appKey1))
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.appIDKey: appKey1]

    AUTKWaitAndAssertAdapterSetUpWithCredentials(MolocoMediationAdapter.self, credentials)
  }

  func testSetUpSuccess_evenIfMultipleAppKeysFoundInCredentials() throws {
    MolocoMediationAdapter.setMolocoInitializer(
      MolocoInitializerThatSucceeds(expectedAppKey: appKey1))
    let credentials1 = AUTKMediationCredentials()
    credentials1.settings = [MolocoConstants.appIDKey: appKey1]
    let credentials2 = AUTKMediationCredentials()
    credentials2.settings = [MolocoConstants.appIDKey: appKey2]
    let mediationServerConfig = AUTKMediationServerConfiguration()
    mediationServerConfig.credentials = [credentials1, credentials2]

    AUTKWaitAndAssertAdapterSetUpWithConfiguration(
      MolocoMediationAdapter.self, mediationServerConfig)
  }

  /// A fake implementation of MolocoInitializer protocol that is already initialized.
  class MolocoInitializerAlreadyInitialized: MolocoInitializer {

    @available(iOS 13.0, *)
    func initialize(
      initParams: MolocoSDK.MolocoInitParams, completion: ((Bool, (any Error)?) -> Void)?
    ) {
      completion?(true, nil)
    }

    func isInitialized() -> Bool {
      return true
    }
  }

  func testSetUpSuccess_ifMolocoAlreadyInitialized() throws {
    MolocoMediationAdapter.setMolocoInitializer(MolocoInitializerAlreadyInitialized())
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.appIDKey: appKey1]

    AUTKWaitAndAssertAdapterSetUpWithCredentials(MolocoMediationAdapter.self, credentials)
  }

  /// A fake implementation of MolocoInitializer protocol that mimics initialization failure.
  class MolocoInitializerThatFailsToInitialize: MolocoInitializer {

    @available(iOS 13.0, *)
    func initialize(
      initParams: MolocoSDK.MolocoInitParams, completion: ((Bool, (any Error)?) -> Void)?
    ) {
      let initializationError = NSError.init(domain: "moloco_sdk_domain", code: 1001)
      completion?(false, initializationError)
    }

    func isInitialized() -> Bool {
      // Stub to return false.
      return false
    }
  }

  func testSetUpFailure_ifMolocoInitializationFails() throws {
    MolocoMediationAdapter.setMolocoInitializer(MolocoInitializerThatFailsToInitialize())
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.appIDKey: appKey1]
    let mediationServerConfig = AUTKMediationServerConfiguration()
    mediationServerConfig.credentials = [credentials]

    let expectedError = NSError.init(domain: "moloco_sdk_domain", code: 1001)
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      MolocoMediationAdapter.self, mediationServerConfig, expectedError)
  }

  func testSetUpFailure_ifAppKeyIsMissing() throws {
    let mediationServerConfig = AUTKMediationServerConfiguration()
    mediationServerConfig.credentials = [AUTKMediationCredentials()]

    let expectedError = NSError.init(
      domain: MolocoConstants.adapterErrorDomain, code: MolocoAdapterErrorCode.invalidAppID.rawValue
    )
    AUTKWaitAndAssertAdapterSetUpFailureWithConfiguration(
      MolocoMediationAdapter.self, mediationServerConfig, expectedError)
  }

}
