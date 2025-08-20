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

  @Test("RTB rewardedAd ad load succeeds")
  func loadRTBRewardedAd_succeeds() {
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

  @Test("RTB rewardedAd ad load fails for OpenWrapSDK error")
  func loadRTBRewardedAd_fails_whenOpenWrapSDKFailsToLoad() {
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

  @Test("Waterfall Interstitial ad load succeeds")
  func loadWaterfallRewarded_succeeds() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "publisher_id": "publisher_id",
      "profile_id": "12345",
      "ad_unit_id": "ad_unit_id",
    ]
    let config = AUTKMediationRewardedAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadRewardedAd(for: config) { ad, error in
      #expect(error == nil)
      #expect(ad != nil)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("Watefall interstitial ad load fails for OpenWrapSDK error")
  func loadWaterfallRewarded_fails_whenOpenWrapSDKFailsToLoad() {
    debugClient.shouldAdLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "publisher_id": "publisher_id",
      "profile_id": "12345",
      "ad_unit_id": "ad_unit_id",
    ]
    let config = AUTKMediationRewardedAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadRewardedAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(ad == nil)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("Watefall interstitial ad load fails for missing publisher ID")
  func loadWaterfallRewarded_fails_whenAdConfigurationMissingPublisherID() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "profile_id": "12345",
      "ad_unit_id": "ad_unit_id",
    ]
    let config = AUTKMediationRewardedAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadRewardedAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(
        error!.code == PubMaticAdapterError.ErrorCode.adConfigurationMissingPublisherId.rawValue)
      #expect(ad == nil)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("Watefall interstitial ad load fails for missing profile ID")
  func loadWaterfallRewarded_fails_whenAdConfigurationMissingProfileID() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "publisher_id": "publisher_id",
      "ad_unit_id": "ad_unit_id",
    ]
    let config = AUTKMediationRewardedAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadRewardedAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(
        error!.code == PubMaticAdapterError.ErrorCode.adConfigurationMissingProfileId.rawValue)
      #expect(ad == nil)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("Watefall interstitial ad load fails for containing non-number profile ID")
  func loadWaterfallRewarded_fails_whenAdConfigurationContainsNonNumberProfileID() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "publisher_id": "publisher_id",
      "profile_id": "a1234",
      "ad_unit_id": "ad_unit_id",
    ]
    let config = AUTKMediationRewardedAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadRewardedAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(error!.code == PubMaticAdapterError.ErrorCode.invalidProfileId.rawValue)
      #expect(ad == nil)
      return AUTKMediationRewardedAdEventDelegate()
    }
  }

  @Test("Watefall interstitial ad load fails for missing ad unit ID")
  func loadWaterfallRewarded_fails_whenAdConfigurationMissingAdUnitID() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "publisher_id": "publisher_id",
      "profile_id": "12345",
    ]
    let config = AUTKMediationRewardedAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadRewardedAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(error!.code == PubMaticAdapterError.ErrorCode.adConfigurationMissingAdUnitId.rawValue)
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
