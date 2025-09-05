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

@Suite("BidMachine adapter RTB interstitial")
final class BidMachineRTBInterstitialAdTests {

  let client: FakeBidMachineClient

  init() {
    client = FakeBidMachineClient()
    BidMachineClientFactory.debugClient = client
  }

  @Test("RTB interstitial ad load succeeds")
  func loadInterstitial_succeeds() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
  }

  @Test("RTB interstitial ad load fails for failing to create a request config")
  func loadInterstiital_fails_whenBidMachineFailsToCreateRequestConfig() async {
    client.shouldBidMachineSucceedCreatingRequestConfig = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
  }

  @Test("RTB interstitial ad load fails for failing to create an ad")
  func loadInterstitial_fails_whenBidMachineFailsToCreateAd() async {
    client.shouldBidMachineSucceedCreatingAd = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
  }

  @Test("RTB interstitial ad load fails for failing to return an ad")
  func loadInterstitial_fails_whenBidMachineFailsToReturnAd() async {
    client.shouldBidMachineSucceedLoadingAd = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
  }

  @Test("Presentation fails")
  func presentation_fails() async {
    client.shouldBidMachineSucceedPresenting = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    await (delegate as! MediationInterstitialAd).present(from: UIViewController())

    #expect(eventDelegate.didFailToPresentError != nil)
  }

  @Test("Impression count")
  func impreesion_count() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    delegate?.didTrackImpression?(
      OCMockObject.mock(for: BidMachineInterstitial.self) as! BidMachineInterstitial)

    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Click count")
  func click_count() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    delegate?.didTrackInteraction?(
      OCMockObject.mock(for: BidMachineInterstitial.self) as! BidMachineInterstitial)

    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

}

@Suite("BidMachine adapter waterfall interstitial")
final class BidMachineWaterfallInterstitialAdTests {

  let client: FakeBidMachineClient

  init() {
    client = FakeBidMachineClient()
    BidMachineClientFactory.debugClient = client
  }

  @MainActor
  @Test("Waterfall interstitial ad load succeeds")
  func loadInterstitial_succeeds() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
  }

  @Test("Waterfall interstitial ad load fails for failing to create a request config")
  func loadnterstiital_fails_whenBidMachineFailsToCreateRequestConfig() async {
    client.shouldBidMachineSucceedCreatingRequestConfig = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
  }

  @Test("Waterfall interstitial ad load fails for failing to create an ad")
  func loadInterstitial_fails_whenBidMachineFailsToCreateAd() async {
    client.shouldBidMachineSucceedCreatingAd = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
  }

  @Test("Waterfall interstitial ad load fails for failing to return an ad")
  func loadInterstitial_fails_whenBidMachineFailsToReturnAd() async {
    client.shouldBidMachineSucceedLoadingAd = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
  }

  @Test("Presentation fails")
  func presentation_fails() async {
    client.shouldBidMachineSucceedPresenting = false

    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    await (delegate as! MediationInterstitialAd).present(from: UIViewController())

    #expect(eventDelegate.didFailToPresentError != nil)
  }

  @Test("Impression count")
  func impreesion_count() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    delegate?.didTrackImpression?(
      OCMockObject.mock(for: BidMachineInterstitial.self) as! BidMachineInterstitial)

    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Click count")
  func click_count() async {
    let adConfig = AUTKMediationInterstitialAdConfiguration()
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadInterstitial(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    delegate?.didTrackInteraction?(
      OCMockObject.mock(for: BidMachineInterstitial.self) as! BidMachineInterstitial)

    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

}
