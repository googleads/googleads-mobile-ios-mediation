// Copyright 2025 Google LLC.
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
import Foundation
import GoogleMobileAds
import Testing

@testable import AdSurgeAdapter

@MainActor
@Suite("AdSurge adapter tests", .serialized)
final class AdSurgeAdapterTests {

  private let fakeClient: FakeClient

  init() {
    let client = FakeClient()
    fakeClient = client
    ClientFactory.debugClient = client
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil
  }

  // MARK: - Adapter Information

  @Test("Adapter version validation")
  func adapterVersion_validates() {
    let version = AdSurgeAdapter.adapterVersion()
    #expect(version.majorVersion == 1)
    #expect(version.minorVersion == 9)
    #expect(version.patchVersion == 200)
  }

  @Test("Ad SDK version validation")
  func adSdkVersion_validates() {
    let version = AdSurgeAdapter.adSDKVersion()
    #expect(version.majorVersion == 1)
    #expect(version.minorVersion == 9)
    #expect(version.patchVersion == 2)
  }

  @Test("Network extras class validation")
  func networkExtrasClass_validates() {
    let extrasClass = AdSurgeAdapter.networkExtrasClass()
    let isNil = extrasClass == nil
    #expect(isNil)
  }

  // MARK: - Adapter Set Up

  @Test("Set up succeeds")
  func setUp_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_app_id"]
    let config = AUTKMediationServerConfiguration()
    config.credentials = [credentials]

    await confirmation("wait for setUp") { setUpCompleted in
      await withCheckedContinuation { continuation in
        AdSurgeAdapter.setUp(with: config) { error in
          #expect(error == nil)
          continuation.resume()
        }
      }
      setUpCompleted()
    }

    #expect(fakeClient.applicationId == "test_app_id")
  }

  @Test("Set up succeeds with age restricted user")
  func setUp_succeeds_withAgeRestrictedUser() async {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_app_id"]
    let config = AUTKMediationServerConfiguration()
    config.credentials = [credentials]

    await confirmation("wait for setUp") { setUpCompleted in
      await withCheckedContinuation { continuation in
        AdSurgeAdapter.setUp(with: config) { error in
          #expect(error == nil)
          continuation.resume()
        }
      }
      setUpCompleted()
    }

    #expect(fakeClient.applicationId == "test_app_id")
    #expect(fakeClient.ageRestrictedUser == 1)
  }

  @Test("Set up fails when missing application ID")
  func setUp_fails_whenMissingApplicationId() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [:]
    let config = AUTKMediationServerConfiguration()
    config.credentials = [credentials]

    await confirmation("wait for setUp failure") { setUpCompleted in
      await withCheckedContinuation { continuation in
        AdSurgeAdapter.setUp(with: config) { error in
          #expect(error != nil)
          let nsError = error as? NSError
          let expectedCode =
            AdSurgeAdapterError.ErrorCode.serverConfigurationMissingApplicationId.rawValue
          #expect(nsError?.code == expectedCode)
          continuation.resume()
        }
      }
      setUpCompleted()
    }
  }

  @Test("Set up fails when client initialization fails")
  func setUp_fails_whenClientInitializationFails() async {
    fakeClient.initializeShouldSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_app_id"]
    let config = AUTKMediationServerConfiguration()
    config.credentials = [credentials]

    await confirmation("wait for setUp failure") { setUpCompleted in
      await withCheckedContinuation { continuation in
        AdSurgeAdapter.setUp(with: config) { error in
          #expect(error != nil)
          continuation.resume()
        }
      }
      setUpCompleted()
    }
  }

  // MARK: - Signal Collection

  @Test("The adapter collects signals for banner successfully")
  func collectSignals_succeeds_forBanner() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .banner
    let signalConfig = AUTKRTBMediationSignalsConfiguration()
    signalConfig.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = signalConfig

    let adapter = AdSurgeAdapter()
    await confirmation("wait for signal collection") { collectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signal, error in
          #expect(signal == "mock_bidder_token")
          #expect(error == nil)
          continuation.resume()
        }
      }
      collectionCompleted()
    }
  }

  @Test("The adapter collects signals for interstitial successfully")
  func collectSignals_succeeds_forInterstitial() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .interstitial
    let signalConfig = AUTKRTBMediationSignalsConfiguration()
    signalConfig.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = signalConfig

    let adapter = AdSurgeAdapter()
    await confirmation("wait for signal collection") { collectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signal, error in
          #expect(signal == "mock_bidder_token")
          #expect(error == nil)
          continuation.resume()
        }
      }
      collectionCompleted()
    }
  }

  @Test("The adapter collects signals for rewarded successfully")
  func collectSignals_succeeds_forRewarded() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .rewarded
    let signalConfig = AUTKRTBMediationSignalsConfiguration()
    signalConfig.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = signalConfig

    let adapter = AdSurgeAdapter()
    await confirmation("wait for signal collection") { collectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signal, error in
          #expect(signal == "mock_bidder_token")
          #expect(error == nil)
          continuation.resume()
        }
      }
      collectionCompleted()
    }
  }

  @Test("The adapter fails signal collection for unsupported native format")
  func collectSignals_fails_forUnsupportedNativeFormat() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .native
    let signalConfig = AUTKRTBMediationSignalsConfiguration()
    signalConfig.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = signalConfig

    let adapter = AdSurgeAdapter()
    await confirmation("wait for signal collection failure") { collectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signal, error in
          #expect(signal == nil)
          #expect(error != nil)
          let nsError = error as? NSError
          #expect(nsError?.domain == AdSurgeAdapterError.domain)
          let expectedCode =
            AdSurgeAdapterError.ErrorCode.invalidRTBRequestParameters.rawValue
          #expect(nsError?.code == expectedCode)
          continuation.resume()
        }
      }
      collectionCompleted()
    }
  }

}
