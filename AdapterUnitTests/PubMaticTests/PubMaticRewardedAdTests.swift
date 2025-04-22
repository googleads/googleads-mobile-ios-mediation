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

@Suite("PubMatic rewardedAd tests")
final class PubMaticRewardedAdTests {

  private var debugClient: FakeOpenWrapSDKClient

  init() {
    debugClient = FakeOpenWrapSDKClient()
    OpenWrapSDKClientFactory.debugClient = debugClient
  }

  deinit {
    OpenWrapSDKClientFactory.debugClient = nil
  }

  @Test("RewardedAd ad load succeeds")
  func loadRewardedAd_succeeds() {
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    adapter.loadRewardedAd(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("RewardedAd ad load fails for missing a bid response")
  func loadRewardedAd_fails_whenMissingBidResponse() {
    let config = AUTKMediationRewardedAdConfiguration()
    let adapter = PubMaticAdapter()
    adapter.loadRewardedAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(error!.code == PubMaticAdapterError.ErrorCode.invalidAdConfiguration.rawValue)
      #expect(ad == nil)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("RewardedAd ad load fails for OpenWrapSDK error")
  func loadRewardedAd_fails_whenOpenWrapSDKFailsToLoad() {
    debugClient.shouldAdLoadSucceed = false

    let config = AUTKMediationRewardedAdConfiguration()
    let adapter = PubMaticAdapter()
    config.bidResponse = "Test response"
    adapter.loadRewardedAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(ad == nil)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("RewardedAd ad presentation succeeds")
  @MainActor func presentRewardedAd_succeeds() {
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    var rewardedAdAd: MediationRewardedAd?
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    adapter.loadRewardedAd(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      rewardedAdAd = ad
      return eventDelegate
    }
    rewardedAdAd?.present(from: UIViewController())

    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("RewardedAd ad presentation fails")
  @MainActor func presentRewardedAd_fails() {
    debugClient.shouldPresentFullScreenAdSucceed = false

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    var rewardedAdAd: MediationRewardedAd?
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    adapter.loadRewardedAd(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      rewardedAdAd = ad
      return eventDelegate
    }
    rewardedAdAd?.present(from: UIViewController())

    #expect(eventDelegate.didFailToPresentError != nil)
  }

  @Test("RewardedAd ad click")
  @MainActor func verifyRewardedAdImpression() {
    debugClient.shouldPresentFullScreenAdSucceed = false

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    adapter.loadRewardedAd(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      return eventDelegate
    }
    (debugClient as FakeOpenWrapSDKClient).rewardedAdDelegate?.rewardedAdDidClick?(
      POBRewardedAd())

    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("RewardedAd ad dismiss")
  @MainActor func verifyRewardedAdDismiss() {
    debugClient.shouldPresentFullScreenAdSucceed = false

    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    adapter.loadRewardedAd(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      return eventDelegate
    }
    (debugClient as FakeOpenWrapSDKClient).rewardedAdDelegate?.rewardedAdDidDismiss?(
      POBRewardedAd())

    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

  @Test("Rewarded ad reward")
  @MainActor func verifyRewardGrandEvent() {
    let config = AUTKMediationRewardedAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    adapter.loadRewardedAd(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      return eventDelegate
    }
    (debugClient as FakeOpenWrapSDKClient).rewardedAdDelegate?.rewardedAd?(
      POBRewardedAd(), shouldReward: POBReward())

    #expect(eventDelegate.didRewardUserInvokeCount == 1)
  }

}
