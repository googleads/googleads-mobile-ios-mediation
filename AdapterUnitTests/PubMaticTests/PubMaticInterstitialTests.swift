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
import OpenWrapSDK
import Testing

@testable import PubMaticAdapter

@Suite("PubMatic interstitial tests")
final class PubMaticInterstitialTests {

  private var debugClient: FakeOpenWrapSDKClient

  init() {
    debugClient = FakeOpenWrapSDKClient()
    OpenWrapSDKClientFactory.debugClient = debugClient
  }

  deinit {
    OpenWrapSDKClientFactory.debugClient = nil
  }

  @Test("Interstitial ad load succeeds")
  func loadInterstitial_succeeds() {
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    adapter.loadInterstitial(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      return AUTKMediationInterstitialAdEventDelegate()
    }
  }

  @Test("Interstitial ad load fails for missing a bid response")
  func loadInterstitial_fails_whenMissingBidResponse() {
    let config = AUTKMediationInterstitialAdConfiguration()
    let adapter = PubMaticAdapter()
    adapter.loadInterstitial(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(error!.code == PubMaticAdapterError.ErrorCode.invalidAdConfiguration.rawValue)
      #expect(ad == nil)
      return AUTKMediationInterstitialAdEventDelegate()
    }
  }

  @Test("Interstitial ad load fails for OpenWrapSDK error")
  func loadInterstitial_fails_whenOpenWrapSDKFailsToLoad() {
    debugClient.shouldAdLoadSucceed = false

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "Test response"
    let adapter = PubMaticAdapter()
    adapter.loadInterstitial(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(ad == nil)
      return AUTKMediationInterstitialAdEventDelegate()
    }
  }

  @Test("Interstitial ad presentation succeeds")
  @MainActor func presentInterstitial_succeeds() {
    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    var interstitialAd: MediationInterstitialAd?
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    adapter.loadInterstitial(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      interstitialAd = ad
      return eventDelegate
    }
    interstitialAd?.present(from: UIViewController())

    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Interstitial ad presentation fails")
  @MainActor func presentInterstitial_fails() {
    debugClient.shouldPresentFullScreenAdSucceed = false

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    var interstitialAd: MediationInterstitialAd?
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    adapter.loadInterstitial(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      interstitialAd = ad
      return eventDelegate
    }
    interstitialAd?.present(from: UIViewController())

    #expect(eventDelegate.didFailToPresentError != nil)
  }

  @Test("Interstitial ad click")
  @MainActor func verifyInterstitialImpression() {
    debugClient.shouldPresentFullScreenAdSucceed = false

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    adapter.loadInterstitial(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      return eventDelegate
    }
    (debugClient as FakeOpenWrapSDKClient).interstitialDelegate?.interstitialDidClickAd?(
      POBInterstitial())

    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("Interstitial ad dismiss")
  @MainActor func verifyInterstitialDismiss() {
    debugClient.shouldPresentFullScreenAdSucceed = false

    let config = AUTKMediationInterstitialAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    adapter.loadInterstitial(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      return eventDelegate
    }
    (debugClient as FakeOpenWrapSDKClient).interstitialDelegate?.interstitialDidDismissAd?(
      POBInterstitial())

    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

}
