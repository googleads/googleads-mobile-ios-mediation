// Copyright 2024 Google LLC.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import AdapterUnitTestKit
import GoogleMobileAds
import MolocoSDK
import XCTest

@testable import MolocoAdapter

/// Tests for MolocoMediationAdapter.
final class MolocoMediationAdapterTest: XCTestCase {

  /// A test app key used in the tests.
  let appKey1 = "app_key_12345"

  /// Another test app key used in the tests.
  let appKey2 = "app_key_6789"

  /// A fake implementation of MolocoInitializer protocol that mimics successful initialization.
  class MolocoInitializerThatSucceeds: MolocoInitializer {

    /// Var to capture the app ID that is used to initialize the Moloco SDK. Used for assertion. It
    /// is initlialized to a value that is never asserted for.
    var appIDUsedToInitializeMoloco: String = ""

    @available(iOS 13.0, *)
    func initialize(
      initParams: MolocoSDK.MolocoInitParams, completion: ((Bool, (any Error)?) -> Void)?
    ) {
      appIDUsedToInitializeMoloco = initParams.appKey
      completion?(true, nil)
    }

    func isInitialized() -> Bool {
      // Stub to return false.
      return false
    }
  }

  func testSetUpSuccess() throws {
    let molocoInitializer = MolocoInitializerThatSucceeds()
    MolocoMediationAdapter.setMolocoInitializer(molocoInitializer)
    let credentials = AUTKMediationCredentials()
    credentials.settings = [MolocoConstants.appIDKey: appKey1]

    AUTKWaitAndAssertAdapterSetUpWithCredentials(MolocoMediationAdapter.self, credentials)
    XCTAssertEqual(molocoInitializer.appIDUsedToInitializeMoloco, appKey1)
  }

  func testSetUpSuccess_evenIfMultipleAppKeysFoundInCredentials() throws {
    MolocoMediationAdapter.setMolocoInitializer(
      MolocoInitializerThatSucceeds())
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
