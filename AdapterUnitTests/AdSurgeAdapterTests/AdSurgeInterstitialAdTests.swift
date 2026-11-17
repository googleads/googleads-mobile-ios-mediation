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

  private let fakeClient = FakeAdSurgeClient()
  private let adapter = AdSurgeAdapter()

  init() {
    fakeClient.reset()
    AdSurgeClientFactory.debugClient = fakeClient
  }

  deinit {
    fakeClient.reset()
    AdSurgeClientFactory.debugClient = nil
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

  @Test("Interstitial load fails when AdSurge client fails to load")
  func loadInterstitial_fails_whenClientFailsToLoad() async {
    fakeClient.interstitialLoadError = AdSurgeSDKError(code: 1, message: "No fill.")
    let config = createInterstitialConfig()
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, error in
        #expect(interstitial == nil)
        let nsError = error as? NSError
        #expect(nsError?.domain == "com.adsurge.adn")
        #expect(nsError?.code == 1)
        #expect(nsError?.localizedDescription == "No fill.")
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

  @Test("Interstitial ad fails to present when the ad is not ready")
  func interstitialAd_failsToPresent_whenAdNotReady() async throws {
    fakeClient.interstitialAdReady = false
    let config = createInterstitialConfig()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    var loadedInterstitial: MediationInterstitialAd?
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { interstitial, _ in
        loadedInterstitial = interstitial
        continuation.resume()
        return eventDelegate
      }
    }
    let interstitial = try #require(loadedInterstitial)
    interstitial.present(from: UIViewController())
    let nsError = eventDelegate.didFailToPresentError as NSError?
    #expect(nsError?.domain == AdSurgeAdapterError.domain)
    #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.adNotReadyForPresentation.rawValue)
    #expect(
      nsError?.localizedDescription == "AdSurge interstitial ad is not ready to be presented.")
    #expect(fakeClient.showInterstitialCount == 0)
    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 0)
  }

  @Test("Interstitial ad reports presentation without impression on display")
  func interstitialAd_reportsPresentationWithoutImpressionOnDisplay() async {
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
    #expect(eventDelegate.reportImpressionInvokeCount == 0)
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
    fakeClient.simulateInterstitialDisplay(
      error: AdSurgeSDKError(code: 6, message: "Consent declined."))
    let presentError = eventDelegate.didFailToPresentError as NSError?
    #expect(presentError?.domain == "com.adsurge.adn")
    #expect(presentError?.code == 6)
    #expect(presentError?.localizedDescription == "Consent declined.")
    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 0)
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

  @Test("Interstitial ad reports one impression when display is followed by a revenue event")
  func interstitialAd_reportsSingleImpression_whenDisplayFollowedByRevenue() async {
    let config = createInterstitialConfig()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: config) { _, _ in
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateInterstitialDisplay()
    fakeClient.simulateInterstitialPayRevenue()
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Interstitial load reports only the first result when a failure follows a load")
  func loadInterstitial_ignoresLoadFailure_afterLoadSuccess() async {
    let recorder = LoadCompletionRecorder()
    await recorder.waitForFirstCompletion {
      adapter.loadInterstitial(for: createInterstitialConfig()) { _, error in
        recorder.record(error)
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }

    fakeClient.simulateInterstitialLoadFailure(AdSurgeSDKError(code: 1, message: "No fill."))

    #expect(recorder.errors == [nil])
  }

  @Test("Interstitial load reports only the first result when a load follows a failure")
  func loadInterstitial_ignoresLoadSuccess_afterLoadFailure() async {
    fakeClient.interstitialLoadError = AdSurgeSDKError(code: 1, message: "No fill.")
    let recorder = LoadCompletionRecorder()
    await recorder.waitForFirstCompletion {
      adapter.loadInterstitial(for: createInterstitialConfig()) { _, error in
        recorder.record(error)
        return nil
      }
    }

    fakeClient.simulateInterstitialLoadSuccess()

    #expect(recorder.errors.count == 1)
    #expect(recorder.errors.first??.domain == "com.adsurge.adn")
    #expect(recorder.errors.first??.code == 1)
  }

  @Test("Interstitial ad ignores events after the loader is released")
  func interstitialAd_ignoresEvents_afterLoaderIsReleased() async {
    var adapter: AdSurgeAdapter? = AdSurgeAdapter()
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter?.loadInterstitial(for: createInterstitialConfig()) { _, _ in
        continuation.resume()
        return eventDelegate
      }
    }

    adapter = nil
    #expect(fakeClient.interstitialDelegate == nil)
    fakeClient.simulateInterstitialDisplay()
    fakeClient.simulateInterstitialDisplay(
      error: AdSurgeSDKError(code: 6, message: "Consent declined."))
    fakeClient.simulateInterstitialClick()
    fakeClient.simulateInterstitialHide()
    fakeClient.simulateInterstitialPayRevenue()

    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 0)
    #expect(eventDelegate.didFailToPresentError == nil)
    #expect(eventDelegate.reportClickInvokeCount == 0)
    #expect(eventDelegate.willDismissFullScreenViewInvokeCount == 0)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 0)
    #expect(eventDelegate.reportImpressionInvokeCount == 0)
  }

  @Test("Interstitial ad forwards every presentation to the AdSurge client")
  func interstitialAd_forwardsEveryPresentation() async throws {
    var loadedInterstitial: MediationInterstitialAd?
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: createInterstitialConfig()) { interstitial, _ in
        loadedInterstitial = interstitial
        continuation.resume()
        return AUTKMediationInterstitialAdEventDelegate()
      }
    }
    let interstitial = try #require(loadedInterstitial)
    let viewController = UIViewController()

    interstitial.present(from: viewController)
    interstitial.present(from: viewController)

    #expect(fakeClient.showInterstitialCount == 2)
    #expect(fakeClient.lastPresentedViewController === viewController)
  }

  @Test("Interstitial ad keeps reporting events after a second load callback")
  func interstitialAd_reportsEvents_afterSecondLoadCallback() async throws {
    let eventDelegate = AUTKMediationInterstitialAdEventDelegate()
    var loadedInterstitial: MediationInterstitialAd?
    await withCheckedContinuation { continuation in
      adapter.loadInterstitial(for: createInterstitialConfig()) { interstitial, _ in
        loadedInterstitial = interstitial
        continuation.resume()
        return eventDelegate
      }
    }
    let interstitial = try #require(loadedInterstitial)

    fakeClient.simulateInterstitialLoadSuccess()
    interstitial.present(from: UIViewController())
    fakeClient.simulateInterstitialDisplay()
    fakeClient.simulateInterstitialClick()
    fakeClient.simulateInterstitialPayRevenue()

    #expect(fakeClient.showInterstitialCount == 1)
    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.reportClickInvokeCount == 1)
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

}
