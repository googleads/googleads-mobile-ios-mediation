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
import Testing

@testable import GoogleBidMachineAdapter

@Suite("BidMachine adapter information")
final class BidMachineAdapterTests {

  init() {
    BidMachineClientFactory.debugClient = FakeBidMachineClient()
  }

  @Test("Adapter version validation")
  func adapterVersion_validates() {
    let adapterVersion = BidMachineAdapter.adapterVersion()
    #expect(adapterVersion.majorVersion > 0)
    #expect(adapterVersion.minorVersion >= 0)
    #expect(adapterVersion.patchVersion >= 0)
  }

  @Test("Ad SDK version validation")
  func adSdkVersion_validates() {
    let adSdkVersion = BidMachineAdapter.adSDKVersion()
    #expect(adSdkVersion.majorVersion > 0)
    #expect(adSdkVersion.minorVersion >= 0)
    #expect(adSdkVersion.patchVersion >= 0)
  }

  @Test("Adapter extra validation")
  func adapterExtra_validates() {
    #expect(BidMachineAdapter.networkExtrasClass() == BidMachineAdapterExtras.self)
  }

}

@Suite("BidMachine adapter set up")
final class BidMachineAdapterInitTests {

  let client: FakeBidMachineClient

  init() {
    client = FakeBidMachineClient()
    BidMachineClientFactory.debugClient = client
  }

  deinit {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = nil
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = nil
  }

  @Test("Set up succeeds with coppa undefined")
  func setUp_succeeds() async {
    let credentials = AUTKMediationCredentials()
    credentials.settings = ["source_id": "source_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      BidMachineAdapter.setUp(with: serverConfiguration) { error in
        #expect(error == nil)
        setUpCompletion()
      }
    }
    #expect(client.sourceId == "source_id")
    #expect(client.isCOPPA == nil)
  }

  @Test("Set up succeeds with coppa is set to false when tag for child is false")
  func setUp_succeedsWithTagForChildFalse() async {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["source_id": "source_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      BidMachineAdapter.setUp(with: serverConfiguration) { error in
        #expect(error == nil)
        setUpCompletion()
      }
    }
    #expect(client.sourceId == "source_id")
    #expect(client.isCOPPA == false)
  }

  @Test("Set up succeeds with coppa is set to true when tag for child is true")
  func setUp_succeedsWithTagForChildTrue() async {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["source_id": "source_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      BidMachineAdapter.setUp(with: serverConfiguration) { error in
        #expect(error == nil)
        setUpCompletion()
      }
    }
    #expect(client.sourceId == "source_id")
    #expect(client.isCOPPA == true)
  }

  @Test("Set up succeeds with coppa is set to false when tag for under age is false")
  func setUp_succeedsWithTagForUnderAgeFalse() async {
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["source_id": "source_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      BidMachineAdapter.setUp(with: serverConfiguration) { error in
        #expect(error == nil)
        setUpCompletion()
      }
    }
    #expect(client.sourceId == "source_id")
    #expect(client.isCOPPA == false)
  }

  @Test("Set up succeeds with coppa is set to true when tag for under age is true")
  func setUp_succeedsWithTagForUnderAgeTrue() async {
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["source_id": "source_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      BidMachineAdapter.setUp(with: serverConfiguration) { error in
        #expect(error == nil)
        setUpCompletion()
      }
    }
    #expect(client.sourceId == "source_id")
    #expect(client.isCOPPA == true)
  }

  @Test("Set up succeeds with coppa true when tag for child is true and under age is false")
  func setUp_succeedsWithChildTrueAndUnderAgeFalse() async {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["source_id": "source_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      BidMachineAdapter.setUp(with: serverConfiguration) { error in
        #expect(error == nil)
        setUpCompletion()
      }
    }
    #expect(client.sourceId == "source_id")
    #expect(client.isCOPPA == true)
  }

  @Test("Set up succeeds with coppa true when tag for child is false and under age is true")
  func setUp_succeedsWithChildFalseAndUnderAgeTrue() async {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["source_id": "source_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      BidMachineAdapter.setUp(with: serverConfiguration) { error in
        #expect(error == nil)
        setUpCompletion()
      }
    }
    #expect(client.sourceId == "source_id")
    #expect(client.isCOPPA == true)
  }

  @Test("Set up succeeds with coppa false when both tags are false")
  func setUp_succeedsWithBothTagsFalse() async {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = false
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["source_id": "source_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      BidMachineAdapter.setUp(with: serverConfiguration) { error in
        #expect(error == nil)
        setUpCompletion()
      }
    }
    #expect(client.sourceId == "source_id")
    #expect(client.isCOPPA == false)
  }

  @Test("Set up succeeds with coppa true when both tags are true")
  func setUp_succeedsWithBothTagsTrue() async {
    MobileAds.shared.requestConfiguration.tagForChildDirectedTreatment = true
    MobileAds.shared.requestConfiguration.tagForUnderAgeOfConsent = true

    let credentials = AUTKMediationCredentials()
    credentials.settings = ["source_id": "source_id"]
    let serverConfiguration = AUTKMediationServerConfiguration()
    serverConfiguration.credentials = [credentials]

    await confirmation("wait for the adapter set up") { setUpCompletion in
      BidMachineAdapter.setUp(with: serverConfiguration) { error in
        #expect(error == nil)
        setUpCompletion()
      }
    }
    #expect(client.sourceId == "source_id")
    #expect(client.isCOPPA == true)
  }
}

@Suite("BidMachine adapter signals collection")
final class BidMachineAdapterSignalsCollectionTests {

  init() {
    BidMachineClientFactory.debugClient = FakeBidMachineClient()
  }

  @Test("The adapter collects signals for a banner ad request successfully.")
  func signalCollection_succeeds_whenRequestFormatIsBanner() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .banner
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = BidMachineAdapter()
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

    let adapter = BidMachineAdapter()
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

    let adapter = BidMachineAdapter()
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

    let adapter = BidMachineAdapter()
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

  @Test("The adapter fails to collect signals for an app open ad request.")
  func signalCollection_fails_whenRequestFormatIsAppOpen() async {
    let credentials = AUTKMediationCredentials()
    credentials.format = .appOpen
    let configurations = AUTKRTBMediationSignalsConfiguration()
    configurations.credentials = [credentials]
    let requestParams = AUTKRTBRequestParameters()
    requestParams.configuration = configurations

    let adapter = BidMachineAdapter()
    await confirmation("wait for the adpater collect signals") { signalsCollectionCompleted in
      await withCheckedContinuation { continuation in
        adapter.collectSignals(for: requestParams) { signals, error in
          #expect(error != nil)
          #expect(signals == nil)
          continuation.resume()
        }
      }
      signalsCollectionCompleted()
    }
  }

}
