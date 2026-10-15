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
import UIKit

@testable import AdSurgeAdapter

@MainActor
@Suite("AdSurge rewarded ad tests", .serialized)
final class AdSurgeRewardedAdTests {

  private let fakeClient = FakeClient()
  private let adapter = AdSurgeAdapter()

  init() {
    fakeClient.reset()
    ClientFactory.debugClient = fakeClient
  }

  deinit {
    fakeClient.reset()
    ClientFactory.debugClient = nil
  }

  private func createRewardedConfig(
    adUnitId: String? = "test_ad_unit_rewarded",
    bidResponse: String? = "test_bid_response"
  ) -> AUTKMediationRewardedAdConfiguration {
    let config = AUTKMediationRewardedAdConfiguration()
    let credentials = AUTKMediationCredentials()
    var settings = [String: Any]()
    if let adUnitId {
      settings["ad_unit_id"] = adUnitId
    }
    credentials.settings = settings
    config.credentials = credentials
    config.bidResponse = bidResponse
    return config
  }

  @Test("Rewarded load succeeds when configuration is valid")
  func loadRewarded_succeeds_whenConfigurationIsValid() async {
    let config = createRewardedConfig()
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        #expect(rewarded != nil)
        #expect(error == nil)
        continuation.resume()
        return AUTKMediationRewardedAdEventDelegate()
      }
    }
    #expect(fakeClient.loadedRewardedAdUnitId == "test_ad_unit_rewarded")
    #expect(fakeClient.loadedRewardedBidPayload == "test_bid_response")
  }

  @Test("Rewarded load fails when ad unit ID is missing")
  func loadRewarded_fails_whenAdUnitIdMissing() async {
    let config = createRewardedConfig(adUnitId: nil)
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        #expect(rewarded == nil)
        let nsError = error as? NSError
        #expect(nsError != nil)
        #expect(nsError?.domain == AdSurgeAdapterError.domain)
        #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.invalidAdConfiguration.rawValue)
        continuation.resume()
        return nil
      }
    }
  }

  @Test("Rewarded load fails when bid response is missing")
  func loadRewarded_fails_whenBidResponseMissing() async {
    let config = createRewardedConfig(bidResponse: nil)
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        #expect(rewarded == nil)
        let nsError = error as? NSError
        #expect(nsError != nil)
        #expect(nsError?.domain == AdSurgeAdapterError.domain)
        #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.invalidAdConfiguration.rawValue)
        continuation.resume()
        return nil
      }
    }
  }

  @Test("Rewarded load fails when partner client fails to load")
  func loadRewarded_fails_whenClientFailsToLoad() async {
    fakeClient.loadRewardedShouldSucceed = false
    let config = createRewardedConfig()
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        #expect(rewarded == nil)
        let nsError = error as? NSError
        #expect(nsError != nil)
        #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.internalError.rawValue)
        continuation.resume()
        return nil
      }
    }
  }

  @Test("Rewarded ad presents from root view controller")
  func rewardedAd_presentsFromRootViewController() async {
    let config = createRewardedConfig()
    var loadedRewarded: MediationRewardedAd?
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        loadedRewarded = rewarded
        continuation.resume()
        return AUTKMediationRewardedAdEventDelegate()
      }
    }
    let viewController = UIViewController()
    loadedRewarded?.present(from: viewController)
    #expect(fakeClient.showRewardedCount == 1)
    #expect(fakeClient.lastPresentedRewardedViewController == viewController)
  }

  @Test("Rewarded ad reports presentation and impression on display")
  func rewardedAd_reportsImpressionOnDisplay() async {
    let config = createRewardedConfig()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateRewardedDisplay()
    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Rewarded ad reports error when display fails")
  func rewardedAd_reportsDisplayFailure() async {
    let config = createRewardedConfig()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        continuation.resume()
        return eventDelegate
      }
    }
    let displayError = AdSurgeAdapterError(
      errorCode: .internalError,
      description: "Display failed."
    ).toNSError()
    fakeClient.simulateRewardedDisplay(error: displayError)
    #expect(eventDelegate.didFailToPresentError != nil)
  }

  @Test("Rewarded ad reports click")
  func rewardedAd_reportsClick() async {
    let config = createRewardedConfig()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateRewardedClick()
    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("Rewarded ad dismisses full screen view on hide")
  func rewardedAd_dismissesFullScreenViewOnHide() async {
    let config = createRewardedConfig()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateRewardedHide()
    #expect(eventDelegate.willDismissFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

  @Test("Rewarded ad rewards user on reward event")
  func rewardedAd_rewardsUserOnRewardEvent() async {
    let config = createRewardedConfig()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateRewardedRewardUser()
    #expect(eventDelegate.didRewardUserInvokeCount == 1)
  }

  @Test("Rewarded ad reports impression on revenue event")
  func rewardedAd_reportsImpressionOnRevenue() async {
    let config = createRewardedConfig()
    let eventDelegate = AUTKMediationRewardedAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadRewardedAd(for: config) { rewarded, error in
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateRewardedPayRevenue()
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

}
