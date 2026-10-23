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

  @Test("Banner load fails when banner size is unsupported")
  func loadBanner_fails_whenBannerSizeUnsupported() async {
    let unsupportedSize = AdSize(size: CGSize(width: 100, height: 100), flags: 0)
    let config = createBannerConfig(adSize: unsupportedSize)
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner == nil)
        let nsError = error as? NSError
        #expect(nsError != nil)
        #expect(nsError?.domain == AdSurgeAdapterError.domain)
        #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.unsupportedBannerSize.rawValue)
        continuation.resume()
        return nil
      }
    }
  }

  @Test("Banner load fails when partner client fails to load")
  func loadBanner_fails_whenClientFailsToLoad() async {
    fakeClient.loadBannerShouldSucceed = false
    let config = createBannerConfig()
    await withCheckedContinuation { continuation in
      adapter.loadBanner(for: config) { banner, error in
        #expect(banner == nil)
        let nsError = error as? NSError
        #expect(nsError != nil)
        #expect(nsError?.code == AdSurgeAdapterError.ErrorCode.internalError.rawValue)
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

}
