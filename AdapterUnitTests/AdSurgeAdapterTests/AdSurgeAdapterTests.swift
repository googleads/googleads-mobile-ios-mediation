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

  private let fakeClient: FakeAdSurgeClient

  init() {
    let client = FakeAdSurgeClient()
    fakeClient = client
    AdSurgeClientFactory.debugClient = client
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .unspecified
  }

  deinit {
    AdSurgeClientFactory.debugClient = nil
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil
    MobileAds.shared.requestConfiguration.ageRestrictedTreatment = .unspecified
  }

  // MARK: - Adapter Information

  @Test("Adapter version validation")
  func adapterVersion_validates() {
    let version = AdSurgeAdapter.adapterVersion()
    #expect(version.majorVersion == 2)
    #expect(version.minorVersion == 0)
    #expect(version.patchVersion == 100)
  }

  @Test("Ad SDK version validation")
  func adSdkVersion_validates() {
    let version = AdSurgeAdapter.adSDKVersion()
    #expect(version.majorVersion == 2)
    #expect(version.minorVersion == 0)
    #expect(version.patchVersion == 1)
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

  @Test("Set up does not set the age restriction when it is unspecified")
  func setUp_doesNotSetAgeRestrictedUser_whenUnspecified() async {
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

    #expect(fakeClient.setAgeRestrictedUserCallCount == 0)
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

  @Test("Set up fails with the SDK error when initialization fails")
  func setUp_fails_withSDKError_whenInitializationFails() async {
    fakeClient.initializeResult = (false, AdSurgeSDKError(code: 2, message: "Network error."))

    let error = await setUpAdapter()

    #expect(error?.domain == "com.adsurge.adn")
    #expect(error?.code == 2)
    #expect(error?.localizedDescription == "Network error.")
  }

  @Test("Set up fails with an internal error when initialization fails without an SDK error")
  func setUp_failsWithInternalError_whenInitializationFailsWithoutSDKError() async {
    fakeClient.initializeResult = (false, nil)

    let error = await setUpAdapter()

    #expect(error?.domain == AdSurgeAdapterError.domain)
    #expect(error?.code == AdSurgeAdapterError.ErrorCode.internalError.rawValue)
    #expect(error?.localizedDescription == "AdSurge SDK failed to initialize.")
  }

  @Test("Set up succeeds when the SDK reports success along with an error")
  func setUp_succeeds_whenSDKReportsSuccessWithError() async {
    fakeClient.initializeResult = (true, AdSurgeSDKError(code: 2, message: "Network error."))

    let error = await setUpAdapter()

    #expect(error == nil)
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

  @Test("Signal collection forwards the age restriction")
  func collectSignals_setsAgeRestrictedUser() async {
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false
    let credentials = AUTKMediationCredentials()
    credentials.format = .banner
    let signalConfig = AUTKRTBMediationSignalsConfiguration()
    signalConfig.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = signalConfig

    let adapter = AdSurgeAdapter()
    await confirmation("wait for signal collection") { collectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { _, error in
          #expect(error == nil)
          continuation.resume()
        }
      }
      collectionCompleted()
    }

    #expect(fakeClient.setAgeRestrictedUserCallCount == 1)
    #expect(fakeClient.ageRestrictedUser == 0)
  }

  @Test("Signal collection does not set the age restriction when it is unspecified")
  func collectSignals_doesNotSetAgeRestrictedUser_whenUnspecified() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .banner
    let signalConfig = AUTKRTBMediationSignalsConfiguration()
    signalConfig.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = signalConfig

    let adapter = AdSurgeAdapter()
    await confirmation("wait for signal collection") { collectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { _, error in
          #expect(error == nil)
          continuation.resume()
        }
      }
      collectionCompleted()
    }

    #expect(fakeClient.setAgeRestrictedUserCallCount == 0)
  }

  @Test("Signal collection fails with the SDK error when the SDK returns no token")
  func collectSignals_fails_withSDKError() async {
    fakeClient.bidderTokenResult = (nil, AdSurgeSDKError(code: 3, message: "Server error."))

    let (signal, error) = await collectBannerSignals()

    #expect(signal == nil)
    #expect(error?.domain == "com.adsurge.adn")
    #expect(error?.code == 3)
    #expect(error?.localizedDescription == "Server error.")
  }

  @Test("Signal collection fails with an internal error when the SDK returns no token or error")
  func collectSignals_failsWithInternalError_whenSDKReturnsNoTokenOrError() async {
    fakeClient.bidderTokenResult = (nil, nil)

    let (signal, error) = await collectBannerSignals()

    #expect(signal == nil)
    #expect(error?.domain == AdSurgeAdapterError.domain)
    #expect(error?.code == AdSurgeAdapterError.ErrorCode.internalError.rawValue)
    #expect(error?.localizedDescription == "Failed to retrieve bidder token.")
  }

  @Test("Signal collection returns the token when the SDK returns a token along with an error")
  func collectSignals_returnsToken_whenSDKReturnsTokenWithError() async {
    fakeClient.bidderTokenResult = ("token", AdSurgeSDKError(code: 3, message: "Server error."))

    let (signal, error) = await collectBannerSignals()

    #expect(signal == "token")
    #expect(error == nil)
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

  // MARK: - Helpers

  /// Sets up the adapter with an application ID and returns the error it reports, if any.
  private func setUpAdapter() async -> NSError? {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["application_id": "test_app_id"]
    let config = AUTKMediationServerConfiguration()
    config.credentials = [credentials]
    return await withCheckedContinuation { continuation in
      AdSurgeAdapter.setUp(with: config) { error in
        continuation.resume(returning: error as NSError?)
      }
    }
  }

  /// Collects banner signals and returns the signal and the error the adapter reports.
  private func collectBannerSignals() async -> (signal: String?, error: NSError?) {
    let credentials = AUTKMediationCredentials()
    credentials.format = .banner
    let signalConfig = AUTKRTBMediationSignalsConfiguration()
    signalConfig.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = signalConfig
    let adapter = AdSurgeAdapter()
    return await withCheckedContinuation { continuation in
      adapter.collectSignals(for: requestParams) { signal, error in
        continuation.resume(returning: (signal, error as NSError?))
      }
    }
  }

}
