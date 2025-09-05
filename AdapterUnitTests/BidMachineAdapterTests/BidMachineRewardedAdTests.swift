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

@Suite("BidMachine adapter RTB rewarded")
final class BidMachineRTBRewardedAdTests {

  let client: FakeBidMachineClient

  init() {
    client = FakeBidMachineClient()
    BidMachineClientFactory.debugClient = client
  }

  @Test("RTB rewarded ad load succeeds")
  func load_succeeds() async {
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return AUTKMediationRewardedAdEventDelegate()
      }
    }
  }

  @Test("RTB rewarded ad load fails for failing to create a request config")
  func load_fails_whenBidMachineFailsToCreateRequestConfig() async {
    client.shouldBidMachineSucceedCreatingRequestConfig = false

    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationRewardedAdEventDelegate()
      }
    }
  }

  @Test("RTB rewarded ad load fails for failing to create an ad")
  func load_fails_whenBidMachineFailsToCreateAd() async {
    client.shouldBidMachineSucceedCreatingAd = false

    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationRewardedAdEventDelegate()
      }
    }
  }

  @Test("RTB rewarded ad load fails for failing to return an ad")
  func load_fails_whenBidMachineFailsToReturnAd() async {
    client.shouldBidMachineSucceedLoadingAd = false

    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationRewardedAdEventDelegate()
      }
    }
  }

  @Test("Presentation succeeds")
  func presentation_succeeds() async {
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    await (delegate as! MediationRewardedAd).present(from: UIViewController())

    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

  @Test("Presentation fails")
  func presentation_fails() async {
    client.shouldBidMachineSucceedPresenting = false

    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    await (delegate as! MediationRewardedAd).present(from: UIViewController())

    #expect(eventDelegate.didFailToPresentError != nil)
  }

  @Test("Impression count")
  func impreesion_count() async {
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    delegate?.didTrackImpression?(
      OCMockObject.mock(for: BidMachineRewarded.self) as! BidMachineRewarded)

    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Click count")
  func click_count() async {
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    delegate?.didTrackInteraction?(
      OCMockObject.mock(for: BidMachineRewarded.self) as! BidMachineRewarded)

    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("Reward count")
  func reward_count() async {
    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    adConfig.watermark = "test watermark".data(using: .utf8)
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    delegate?.didReceiveReward?(
      OCMockObject.mock(for: BidMachineRewarded.self) as! BidMachineRewarded)

    #expect(eventDelegate.didRewardUserInvokeCount == 1)
  }

}

@Suite("BidMachine adapter waterfall rewarded")
final class BidMachineWaterfallRewardedAdTests {

  let client: FakeBidMachineClient

  init() {
    client = FakeBidMachineClient()
    BidMachineClientFactory.debugClient = client
  }

  @Test("Waterfall rewarded ad load succeeds")
  func load_succeeds() async {
    let adConfig = AUTKMediationRewardedAdConfiguration()
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return AUTKMediationRewardedAdEventDelegate()
      }
    }
  }

  @Test("Waterfall rewarded ad load fails for failing to create a request config")
  func load_fails_whenBidMachineFailsToCreateRequestConfig() async {
    client.shouldBidMachineSucceedCreatingRequestConfig = false

    let adConfig = AUTKMediationRewardedAdConfiguration()
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationRewardedAdEventDelegate()
      }
    }
  }

  @Test("Waterfall rewarded ad load fails for failing to create an ad")
  func load_fails_whenBidMachineFailsToCreateAd() async {
    client.shouldBidMachineSucceedCreatingAd = false

    let adConfig = AUTKMediationRewardedAdConfiguration()
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationRewardedAdEventDelegate()
      }
    }
  }

  @Test("Waterfall rewarded ad load fails for failing to return an ad")
  func load_fails_whenBidMachineFailsToReturnAd() async {
    client.shouldBidMachineSucceedLoadingAd = false

    let adConfig = AUTKMediationRewardedAdConfiguration()
    adConfig.bidResponse = "test response"
    let adapter = BidMachineAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationRewardedAdEventDelegate()
      }
    }
  }

  @Test("Presentation succeeds")
  func presentation_succeeds() async {
    let adConfig = AUTKMediationRewardedAdConfiguration()
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    await (delegate as! MediationRewardedAd).present(from: UIViewController())

    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

  @Test("Presentation fails")
  func presentation_fails() async {
    client.shouldBidMachineSucceedPresenting = false

    let adConfig = AUTKMediationRewardedAdConfiguration()
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    await (delegate as! MediationRewardedAd).present(from: UIViewController())

    #expect(eventDelegate.didFailToPresentError != nil)
  }

  @Test("Impression count")
  func impreesion_count() async {
    let adConfig = AUTKMediationRewardedAdConfiguration()
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    delegate?.didTrackImpression?(
      OCMockObject.mock(for: BidMachineRewarded.self) as! BidMachineRewarded)

    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Click count")
  func click_count() async {
    let adConfig = AUTKMediationRewardedAdConfiguration()
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    delegate?.didTrackInteraction?(
      OCMockObject.mock(for: BidMachineRewarded.self) as! BidMachineRewarded)

    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("Reward count")
  func reward_count() async {
    let adConfig = AUTKMediationRewardedAdConfiguration()
    let adapter = BidMachineAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    var delegate: BidMachineAdDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadRewardedAd(for: adConfig) { ad, error in
        let error = error as NSError?
        #expect(error == nil)
        #expect(ad != nil)
        delegate = ad as? BidMachineAdDelegate
        continuation.resume()
        return eventDelegate
      }
    }
    delegate?.didReceiveReward?(
      OCMockObject.mock(for: BidMachineRewarded.self) as! BidMachineRewarded)

    #expect(eventDelegate.didRewardUserInvokeCount == 1)
  }

}
