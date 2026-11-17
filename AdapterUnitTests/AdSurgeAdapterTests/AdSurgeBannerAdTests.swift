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
@Suite("AdSurge banner ad tests", .serialized)
final class AdSurgeBannerAdTests {

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

  private func createBannerConfig(
    adUnitId: String? = "test_ad_unit_123",
    bidResponse: String? = "test_bid_response",
    adSize: AdSize = AdSizeBanner
  ) -> AUTKMediationBannerAdConfiguration {
    let config = AUTKMediationBannerAdConfiguration()
    let credentials = AUTKMediationCredentials()
    var settings = [String: Any]()
    if let adUnitId {
      settings["ad_unit_id"] = adUnitId
    }
    credentials.settings = settings
    config.credentials = credentials
    config.bidResponse = bidResponse
    config.adSize = adSize
    return config
  }

  @Test("Banner load succeeds when configuration is valid")
  func loadBanner_succeeds_whenConfigurationIsValid() async {
    let config = createBannerConfig()
    let viewController = UIViewController()
    config.topViewController = viewController
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner != nil)
        #expect(banner?.view != nil)
        #expect(error == nil)
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
    #expect(fakeClient.createdBannerAdUnitId == "test_ad_unit_123")
    #expect(fakeClient.loadedBannerBidPayload == "test_bid_response")
    #expect(fakeClient.bannerViewController === viewController)
  }

  @Test("Banner load reports the AdSurge banner view")
  func loadBanner_reportsAdSurgeBannerView() async {
    let config = createBannerConfig()
    var loadedView: UIView?
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, _ in
        loadedView = banner?.view
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
    #expect(loadedView != nil)
    #expect(loadedView === fakeClient.bannerView)
  }

  @Test("Banner view is set before the banner ad is loaded")
  func loadBanner_setsViewBeforeLoading() {
    let loader = BannerAdLoader(
      adConfiguration: createBannerConfig(),
      loadCompletionHandler: { _, _ in nil },
      client: fakeClient)
    var viewWhenLoading: UIView?
    fakeClient.onBannerLoad = { [weak loader] in
      viewWhenLoading = loader?.view
    }

    loader.loadAd()

    #expect(fakeClient.loadedBannerBidPayload == "test_bid_response")
    #expect(viewWhenLoading != nil)
    #expect(viewWhenLoading === fakeClient.bannerView)
  }

  @Test("Banner load fails when ad unit ID is missing")
  func loadBanner_fails_whenAdUnitIdMissing() async {
    let config = createBannerConfig(adUnitId: nil)
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner == nil)
        let nsError = error as? NSError
        #expect(nsError != nil)
        #expect(nsError?.domain == AdSurgeAdapterError.domain)
        #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.invalidAdConfiguration.rawValue)
        continuation.resume()
        return nil
      }
    }
  }

  @Test("Banner load fails when bid response is missing")
  func loadBanner_fails_whenBidResponseMissing() async {
    let config = createBannerConfig(bidResponse: nil)
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner == nil)
        let nsError = error as? NSError
        #expect(nsError != nil)
        #expect(nsError?.domain == AdSurgeAdapterError.domain)
        #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.invalidAdConfiguration.rawValue)
        continuation.resume()
        return nil
      }
    }
  }

  @Test("Banner load fails when AdSurge client fails to load")
  func loadBanner_fails_whenClientFailsToLoad() async {
    fakeClient.bannerLoadError = AdSurgeSDKError(code: 1, message: "No fill.")
    let config = createBannerConfig()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner == nil)
        let nsError = error as? NSError
        #expect(nsError?.domain == "com.adsurge.adn")
        #expect(nsError?.code == 1)
        #expect(nsError?.localizedDescription == "No fill.")
        continuation.resume()
        return nil
      }
    }
  }

  @Test("Banner ad reports click")
  func bannerAd_reportsClick() async {
    let config = createBannerConfig()
    let eventDelegate = AUTKMediationBannerAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner != nil)
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateBannerClick()
    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("Banner ad reports impression on revenue event")
  func bannerAd_reportsImpression() async {
    let config = createBannerConfig()
    let eventDelegate = AUTKMediationBannerAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner != nil)
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateBannerPayRevenue()
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Banner ad dismisses full screen view on hide event")
  func bannerAd_dismissesFullScreenView() async {
    let config = createBannerConfig()
    let eventDelegate = AUTKMediationBannerAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner != nil)
        continuation.resume()
        return eventDelegate
      }
    }
    fakeClient.simulateBannerHide()
    #expect(eventDelegate.willDismissFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

  @Test("Banner load succeeds with medium rectangle size")
  func loadBanner_succeeds_withMediumRectangleSize() async {
    let config = createBannerConfig(adSize: AdSizeMediumRectangle)
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner != nil)
        #expect(error == nil)
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
  }

  @Test("Banner load succeeds with adaptive banner size")
  func loadBanner_succeeds_withAdaptiveBannerSize() async {
    let adaptiveSize = currentOrientationAnchoredAdaptiveBanner(width: 320)
    let config = createBannerConfig(adSize: adaptiveSize)
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner != nil)
        #expect(error == nil)
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
  }

  @Test("Banner load reports only the first result when a failure follows a load")
  func loadBanner_ignoresLoadFailure_afterLoadSuccess() async {
    let recorder = LoadCompletionRecorder()
    await recorder.waitForFirstCompletion {
      adapter.loadBanner(for: createBannerConfig()) { _, error in
        recorder.record(error)
        return AUTKMediationBannerAdEventDelegate()
      }
    }

    fakeClient.simulateBannerLoadFailure(AdSurgeSDKError(code: 1, message: "No fill."))

    #expect(recorder.errors == [nil])
  }

  @Test("Banner load reports only the first result when a load follows a failure")
  func loadBanner_ignoresLoadSuccess_afterLoadFailure() async {
    fakeClient.bannerLoadError = AdSurgeSDKError(code: 1, message: "No fill.")
    let recorder = LoadCompletionRecorder()
    await recorder.waitForFirstCompletion {
      adapter.loadBanner(for: createBannerConfig()) { _, error in
        recorder.record(error)
        return nil
      }
    }

    fakeClient.simulateBannerLoadSuccess()

    #expect(recorder.errors.count == 1)
    #expect(recorder.errors.first??.domain == "com.adsurge.adn")
    #expect(recorder.errors.first??.code == 1)
  }

  @Test("Banner ad ignores events after the loader is released")
  func bannerAd_ignoresEvents_afterLoaderIsReleased() async {
    var adapter: AdSurgeAdapter? = AdSurgeAdapter()
    let eventDelegate = AUTKMediationBannerAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter?.loadBanner(for: createBannerConfig()) { _, _ in
        continuation.resume()
        return eventDelegate
      }
    }

    adapter = nil
    #expect(fakeClient.bannerDelegate == nil)
    fakeClient.simulateBannerClick()
    fakeClient.simulateBannerHide()
    fakeClient.simulateBannerPayRevenue()

    #expect(eventDelegate.reportClickInvokeCount == 0)
    #expect(eventDelegate.willDismissFullScreenViewInvokeCount == 0)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 0)
    #expect(eventDelegate.reportImpressionInvokeCount == 0)
  }

  @Test("Banner ad keeps reporting events after a second load callback")
  func bannerAd_reportsEvents_afterSecondLoadCallback() async {
    let eventDelegate = AUTKMediationBannerAdEventDelegate()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: createBannerConfig()) { _, _ in
        continuation.resume()
        return eventDelegate
      }
    }

    fakeClient.simulateBannerLoadSuccess()
    fakeClient.simulateBannerClick()
    fakeClient.simulateBannerHide()
    fakeClient.simulateBannerPayRevenue()

    #expect(eventDelegate.reportClickInvokeCount == 1)
    #expect(eventDelegate.willDismissFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

}
