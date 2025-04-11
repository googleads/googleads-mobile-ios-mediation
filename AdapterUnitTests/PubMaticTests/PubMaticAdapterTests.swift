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
import GoogleMobileAds
import Testing

@testable import PubMaticAdapter

@Suite("PubMatic adapter information")
final class PubMaticInformationTests {

  init() {
    OpenWrapSDKClientFactory.debugClient = FakeOpenWrapSDKClient()
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
  }

  deinit {
    OpenWrapSDKClientFactory.debugClient = nil
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
  }

  @Test("Adapter version validation")
  func adapterVersion_validates() {
    let adapterVersion = PubMaticAdapter.adapterVersion()
    #expect(adapterVersion.majorVersion > 0)
    #expect(adapterVersion.minorVersion >= 0)
    #expect(adapterVersion.patchVersion >= 0)
  }

  @Test("Ad SDK version validation")
  func adSdkVersion_validates() {
    let adSdkVersion = PubMaticAdapter.adSDKVersion()
    #expect(adSdkVersion.majorVersion > 0)
    #expect(adSdkVersion.minorVersion >= 0)
    #expect(adSdkVersion.patchVersion >= 0)
  }

  @Test("Extra class validation.")
  func extrasClass_validates() {
    #expect(PubMaticAdapter.networkExtrasClass() == PubMaticAdapterExtras.self)
  }

}

@Suite("PubMatic adapter set up")
final class PubMaticAdapterSetUpTests {

  private var debugClient: FakeOpenWrapSDKClient

  init() {
    debugClient = FakeOpenWrapSDKClient()
    OpenWrapSDKClientFactory.debugClient = debugClient
  }

  deinit {
    OpenWrapSDKClientFactory.debugClient = nil
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
  }

  @Test("Adapter set up successfully")
  func setUp_succeeds() async {
    debugClient.shouldSetUpSucceed = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["publisher_id": "test_publisher_id", "profile_id": "test_profile_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adpater setup") { adapterSetUpCompleted in
      await withCheckedContinuation { continuation in
        PubMaticAdapter.setUp(with: serverConfiguration) { error in
          #expect(error == nil)
          continuation.resume()
        }
      }
      adapterSetUpCompleted()
    }

    let client = OpenWrapSDKClientFactory.debugClient as! FakeOpenWrapSDKClient
    #expect(client.COPPAEnabled == false)
  }

  @Test("Adapter set up successfully with COPPA disabled ")
  func setUp_succeedsWithCOPPADisabled() async {
    debugClient.shouldSetUpSucceed = true
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["publisher_id": "test_publisher_id", "profile_id": "123"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adpater setup") { adapterSetUpCompleted in
      await withCheckedContinuation { continuation in
        PubMaticAdapter.setUp(with: serverConfiguration) { error in
          #expect(error == nil)
          continuation.resume()
        }
      }
      adapterSetUpCompleted()
    }

    let client = OpenWrapSDKClientFactory.debugClient as! FakeOpenWrapSDKClient
    #expect(client.COPPAEnabled == false)
  }

  @Test("Adapter set up successfully with COPPA enabled")
  func setUp_succeedsWithCOPPAEnabled() async {
    debugClient.shouldSetUpSucceed = true
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["publisher_id": "test_publisher_id", "profile_id": "123"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adpater setup") { adapterSetUpCompleted in
      await withCheckedContinuation { continuation in
        PubMaticAdapter.setUp(with: serverConfiguration) { error in
          #expect(error == nil)
          continuation.resume()
        }
      }
      adapterSetUpCompleted()
    }

    let client = OpenWrapSDKClientFactory.debugClient as! FakeOpenWrapSDKClient
    #expect(client.COPPAEnabled == true)
  }

  @Test("Adapter set up fails for missing a publisher ID")
  func setUp_fails_whenPublisherIDIsMissing() async {
    debugClient.shouldSetUpSucceed = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["profile_id": "123"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adpater setup") { adapterSetUpCompleted in
      await withCheckedContinuation { continuation in
        PubMaticAdapter.setUp(with: serverConfiguration) { error in
          let error = error as? NSError
          #expect(error != nil)
          #expect(
            error?.code
              == PubMaticAdapterError.ErrorCode.serverConfigurationMissingPublisherId.rawValue)
          continuation.resume()
        }
      }
      adapterSetUpCompleted()
    }
  }

  @Test("Adapter set up fails when OpenWrapSDK's set up function completes with an error")
  func setUp_fails_whenOpenWrapSDKSetUpFails() async {
    debugClient.shouldSetUpSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["publisher_id": "test_publisher_id", "profile_id": "123"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adpater setup") { adapterSetUpCompleted in
      await withCheckedContinuation { continuation in
        PubMaticAdapter.setUp(with: serverConfiguration) { error in
          #expect(error != nil)
          continuation.resume()
        }
      }
      adapterSetUpCompleted()
    }
  }

}

@Suite("PubMatic adapter signal collection")
final class PubMaticAdapterSignalCollectionTests {

  init() {
    OpenWrapSDKClientFactory.debugClient = FakeOpenWrapSDKClient()
  }

  @Test("The adapter collects signals for a banner request successfully.")
  func signalCollection_succeeds_whenRequestFormatIsBannner() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .banner
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = PubMaticAdapter()
    await confirmation("wait for the adpater collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(error == nil)
          #expect(signals != nil)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
  }

  @Test("The adapter collects signals for an interstitial ad request successfully.")
  func signalCollection_succeeds_whenRequestFormatIsInterstitial() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .interstitial
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = PubMaticAdapter()
    await confirmation("wait for the adpater collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(error == nil)
          #expect(signals != nil)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
  }

  @Test("The adapter collects signals for a rewarded ad request successfully.")
  func signalCollection_succeeds_whenRequestFormatIsRewarded() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .rewarded
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = PubMaticAdapter()
    await confirmation("wait for the adpater collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(error == nil)
          #expect(signals != nil)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
  }

  @Test("The adapter collects signals for a native ad request successfully.")
  func signalCollection_succeeds_whenRequestFormatIsNative() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .native
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = PubMaticAdapter()
    await confirmation("wait for the adpater collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(error == nil)
          #expect(signals != nil)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
  }

  @Test("The adapter collects signals for an app open ad request unsuccessfully.")
  func signalCollection_fails_whenRequestFormatIsAppOpen() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .appOpen
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = PubMaticAdapter()
    await confirmation("wait for the adpater collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          let error = error as? NSError
          #expect(error != nil)
          #expect(error!.code == 102)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
  }

  @Test("The adapter collects signals for a rewarded interstitial ad request unsuccessfully.")
  func signalCollection_fails_whenRequestFormatIsRewardedInterstitial() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .rewardedInterstitial
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = PubMaticAdapter()
    await confirmation("wait for the adpater collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          let error = error as? NSError
          #expect(error != nil)
          #expect(error!.code == 102)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
  }

}
