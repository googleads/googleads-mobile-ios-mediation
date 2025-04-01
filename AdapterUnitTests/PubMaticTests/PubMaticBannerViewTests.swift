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

@Suite("PubMatic banner view tests")
final class PubMaticBannerViewTests {

  private var debugClient: FakeOpenWrapSDKClient

  init() {
    debugClient = FakeOpenWrapSDKClient()
    OpenWrapSDKClientFactory.debugClient = debugClient
  }

  deinit {
    OpenWrapSDKClientFactory.debugClient = nil
  }

  @Test("Banner view load succeeds")
  func loadBannerView_succeeds() async {
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadBanner(for: config) { ad, error in
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
  }

  @Test("Banner view load fails for missing a bid response")
  func loadBannerView_fails_whenMissingBidResponse() async {
    let config = AUTKMediationBannerAdConfiguration()
    let adapter = PubMaticAdapter()
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadBanner(for: config) { ad, error in
        let error = error as NSError?
        #expect(error != nil)
        #expect(error!.code == PubMaticAdapterError.ErrorCode.invalidAdConfiguration.rawValue)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
  }

  @Test("Banner view load fails for OpenWrapSDK error")
  func loadBannerView_fails_whenOpenWrapSDKFailsToLoad() async {
    debugClient.shouldAdLoadSucceed = false

    let config = AUTKMediationBannerAdConfiguration()
    let adapter = PubMaticAdapter()
    config.bidResponse = "Test response"
    config.watermark = Data()
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadBanner(for: config) { ad, error in
        #expect(error != nil)
        #expect(ad == nil)
        continuation.resume()
        return AUTKMediationBannerAdEventDelegate()
      }
    }
  }

  @Test("Banner view impression")
  func verifyBannerViewImpression() async {
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationBannerAdEventDelegate()
    var viewDelegate: POBBannerViewDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadBanner(for: config) { ad, error in
        #expect(error == nil)
        #expect(ad != nil)
        viewDelegate = (ad as? POBBannerViewDelegate)
        continuation.resume()
        return eventDelegate
      }
    }
    await viewDelegate?.bannerViewDidRecordImpression?(POBBannerView())

    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Banner view click")
  func verifyBannerViewClick() async {
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationBannerAdEventDelegate()
    var viewDelegate: POBBannerViewDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadBanner(for: config) { ad, error in
        #expect(error == nil)
        #expect(ad != nil)
        viewDelegate = (ad as? POBBannerViewDelegate)
        continuation.resume()
        return eventDelegate
      }
    }
    await viewDelegate?.bannerViewDidClickAd?(POBBannerView())

    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("Banner view's view controller")
  @MainActor
  func verifyBannerViewViewController() async {
    let config = AUTKMediationBannerAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let expectedViewController = UIViewController()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationBannerAdEventDelegate()
    var viewDelegate: POBBannerViewDelegate?

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadBanner(for: config) { ad, error in
        #expect(error == nil)
        #expect(ad != nil)
        viewDelegate = (ad as? POBBannerViewDelegate)
        let view = ad!.view
        expectedViewController.view.addSubview(view)
        continuation.resume()
        return eventDelegate
      }
    }

    #expect(expectedViewController === viewDelegate?.bannerViewPresentationController())
  }
}
