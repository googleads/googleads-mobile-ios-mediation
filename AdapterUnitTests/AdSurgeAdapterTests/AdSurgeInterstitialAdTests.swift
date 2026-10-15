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
@Suite("AdSurge interstitial ad tests", .serialized)
final class AdSurgeInterstitialAdTests {

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

  private func createInterstitialConfig(
    adUnitId: String? = "test_ad_unit_interstitial",
    bidResponse: String? = "test_bid_response"
  ) -> AUTKMediationInterstitialAdConfiguration {
    let config = AUTKMediationInterstitialAdConfiguration()
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

  @Test("Interstitial load succeeds when configuration is valid")
  func loadInterstitial_succeeds_whenConfigurationIsValid() async {
    let config = createInterstitialConfig()
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        #expect(interstitial != nil)
        #expect(error == nil)
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
    #expect(fakeClient.loadedInterstitialAdUnitId == "test_ad_unit_interstitial")
    #expect(fakeClient.loadedInterstitialBidPayload == "test_bid_response")
  }

  @Test("Interstitial load fails when ad unit ID is missing")
  func loadInterstitial_fails_whenAdUnitIdMissing() async {
    let config = createInterstitialConfig(adUnitId: nil)
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        #expect(interstitial == nil)
        let nsError = error as? NSError
        #expect(nsError != nil)
        #expect(nsError?.domain == AdSurgeAdapterError.domain)
        #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.invalidAdConfiguration.rawValue)
        continuation.resume()
        return nil
      }
    }
  }

  @Test("Interstitial load fails when bid response is missing")
  func loadInterstitial_fails_whenBidResponseMissing() async {
    let config = createInterstitialConfig(bidResponse: nil)
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        #expect(interstitial == nil)
        let nsError = error as? NSError
        #expect(nsError != nil)
        #expect(nsError?.domain == AdSurgeAdapterError.domain)
        #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.invalidAdConfiguration.rawValue)
        continuation.resume()
        return nil
      }
    }
  }

  @Test("Interstitial load fails when partner client fails to load")
  func loadInterstitial_fails_whenClientFailsToLoad() async {
    fakeClient.loadInterstitialShouldSucceed = false
    let config = createInterstitialConfig()
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        #expect(interstitial == nil)
        let nsError = error as? NSError
        #expect(nsError != nil)
        #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.internalError.rawValue)
        continuation.resume()
        return nil
      }
    }
  }

  @Test("Interstitial ad presents from root view controller")
  func interstitialAd_presentsFromRootViewController() async {
    let config = createInterstitialConfig()
    var loadedInterstitial: MediationInterstitialAd?
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        loadedInterstitial = interstitial
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
    let viewController = UIViewController()
    loadedInterstitial?.present(from: viewController)
    #expect(fakeClient.showInterstitialCount == 1)
    #expect(fakeClient.lastPresentedViewController == viewController)
  }

  @Test("Interstitial ad reports presentation and impression on display")
  func interstitialAd_reportsImpressionOnDisplay() async {
    let config = createInterstitialConfig()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateInterstitialDisplay()
    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Interstitial ad reports error when display fails")
  func interstitialAd_reportsDisplayFailure() async {
    let config = createInterstitialConfig()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        continuation.resume()
        return eventDelegate
      }
    }
    let displayError = AdSurgeAdapterError(
      errorCode: .internalError,
      description: "Display failed."
    ).toNSError()
    fakeClient.simulateInterstitialDisplay(error: displayError)
    #expect(eventDelegate.didFailToPresentError != nil)
  }

  @Test("Interstitial ad reports click")
  func interstitialAd_reportsClick() async {
    let config = createInterstitialConfig()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateInterstitialClick()
    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("Interstitial ad dismisses full screen view on hide")
  func interstitialAd_dismissesFullScreenViewOnHide() async {
    let config = createInterstitialConfig()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateInterstitialHide()
    #expect(eventDelegate.willDismissFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

  @Test("Interstitial ad reports impression on revenue event")
  func interstitialAd_reportsImpressionOnRevenue() async {
    let config = createInterstitialConfig()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateInterstitialPayRevenue()
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

}
