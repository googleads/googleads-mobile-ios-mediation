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
import BidMachine
import Testing

@testable import GoogleBidMachineAdapter

@Suite("BidMachine adapter RTB native")
final class BidMachineRTBNativeAdTests {

  let client: FakeBidMachineClient
  let nativeAdProxy: FakeNativeAdProxy

  init() {
    client = FakeBidMachineClient()
    nativeAdProxy = FakeNativeAdProxy()
    BidMachineClientFactory.debugClient = client
    NativeAdProxyFactory.debugProxy = nativeAdProxy
  }

  @Test("RTB native ad load succeeds")
  func load_succeeds() async {
    let adConfig = AUTKMediationNativeAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return AUTKMediationNativeAdEventDelegate()
      }
    }
  }

  @Test("RTB native ad load fails when bid response is missing")
  func load_fails_whenBidResponseIsMissing() async {
    let adConfig = AUTKMediationNativeAdConfiguration()
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(error!.code == BidMachineAdapterError.ErrorCode.invalidAdConfiguration.rawValue)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationNativeAdEventDelegate()
      }
    }
  }

  @Test("RTB native ad load fails for failing to create a request config")
  func load_fails_whenBidMachineFailsToCreateRequestConfig() async {
    client.shouldBidMachineSucceedCreatingRequestConfig = false

    let adConfig = AUTKMediationNativeAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationNativeAdEventDelegate()
      }
    }
  }

  @Test("RTB native ad load fails for failing to create an ad")
  func load_fails_whenBidMachineFailsToCreateAd() async {
    client.shouldBidMachineSucceedCreatingAd = false

    let adConfig = AUTKMediationNativeAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationNativeAdEventDelegate()
      }
    }
  }

  @Test("RTB native ad load fails for failing to return an ad")
  func load_fails_whenBidMachineFailsToReturnAd() async {
    client.shouldBidMachineSucceedLoadingAd = false

    let adConfig = AUTKMediationNativeAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationNativeAdEventDelegate()
      }
    }
  }

  @Test("RTB native ad load fails for failing to download image assets")
  func load_fails_whenImageAssetDownloadFails() async {
    nativeAdProxy.shouldDownloadSucceed = false

    let adConfig = AUTKMediationNativeAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationNativeAdEventDelegate()
      }
    }
  }

}
