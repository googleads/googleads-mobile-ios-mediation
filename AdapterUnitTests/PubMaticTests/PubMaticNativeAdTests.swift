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

@Suite("PubMatic native ad tests")
final class PubMaticNativeAdTests {

  private var debugClient: FakeOpenWrapSDKClient
  private var debugProxy: FakeNativeAdProxy
  private var fakeNativeAd: FakeNativeAd

  init() {
    fakeNativeAd = FakeNativeAd()
    debugProxy = FakeNativeAdProxy(nativeAd: fakeNativeAd)
    NativeAdProxyFactory.debugProxy = debugProxy
    debugClient = FakeOpenWrapSDKClient()
    OpenWrapSDKClientFactory.debugClient = debugClient
  }

  deinit {
    NativeAdProxyFactory.debugProxy = nil
    OpenWrapSDKClientFactory.debugClient = nil
  }

  @Test("RTB native ad load succeeds")
  func loadRTBNativeAd_succeeds() async {
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: config) { ad, error in
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return AUTKMediationNativeAdEventDelegate()
      }
    }

    #expect(debugProxy.eventDelegate != nil)
  }

  @Test("RTB native ad load fails for OpenWrapSDK error")
  func loadRTBNativeAd_fails_whenOpenWrapSDKFailsToLoad() {
    debugClient.shouldAdLoadSucceed = false

    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()

    adapter.loadNativeAd(for: config) { ad, error in
      #expect(error != nil)
      #expect(ad == nil)
      return AUTKMediationNativeAdEventDelegate()
    }
  }

  @Test("RTB native ad load fails for image download failure")
  func loadRTBNativeAd_fails_whenImageAssetsFailToDownload() {
    debugProxy.shouldDownloadSucceed = false

    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()

    adapter.loadNativeAd(for: config) { ad, error in
      #expect(error != nil)
      #expect(ad == nil)
      return AUTKMediationNativeAdEventDelegate()
    }
  }

  @Test("Watefall Native ad load fails for OpenWrapSDK error")
  func loadWaterfallNative_fails_whenOpenWrapSDKFailsToLoad() {
    debugClient.shouldAdLoadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "publisher_id": "publisher_id",
      "profile_id": "12345",
      "ad_unit_id": "ad_unit_id",
    ]
    let config = AUTKMediationNativeAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadNativeAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(ad == nil)
      return AUTKMediationNativeAdEventDelegate()
    }
  }

  @Test("Watefall Native ad load fails for missing publisher ID")
  func loadWaterfallNative_fails_whenAdConfigurationMissingPublisherID() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "profile_id": "12345",
      "ad_unit_id": "ad_unit_id",
    ]
    let config = AUTKMediationNativeAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadNativeAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(
        error!.code == PubMaticAdapterError.ErrorCode.adConfigurationMissingPublisherId.rawValue)
      #expect(ad == nil)
      return AUTKMediationNativeAdEventDelegate()
    }
  }

  @Test("Watefall Native ad load fails for missing profile ID")
  func loadWaterfallNative_fails_whenAdConfigurationMissingProfileID() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "publisher_id": "publisher_id",
      "ad_unit_id": "ad_unit_id",
    ]
    let config = AUTKMediationNativeAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadNativeAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(
        error!.code == PubMaticAdapterError.ErrorCode.adConfigurationMissingProfileId.rawValue)
      #expect(ad == nil)
      return AUTKMediationNativeAdEventDelegate()
    }
  }

  @Test("Watefall Native ad load fails for containing non-number profile ID")
  func loadWaterfallNative_fails_whenAdConfigurationContainsNonNumberProfileID() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "publisher_id": "publisher_id",
      "profile_id": "a1234",
      "ad_unit_id": "ad_unit_id",
    ]
    let config = AUTKMediationNativeAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadNativeAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(error!.code == PubMaticAdapterError.ErrorCode.invalidProfileId.rawValue)
      #expect(ad == nil)
      return AUTKMediationNativeAdEventDelegate()
    }
  }

  @Test("Watefall Native ad load fails for missing ad unit ID")
  func loadWaterfallNative_fails_whenAdConfigurationMissingAdUnitID() {
    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "publisher_id": "publisher_id",
      "profile_id": "12345",
    ]
    let config = AUTKMediationNativeAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()
    adapter.loadNativeAd(for: config) { ad, error in
      let error = error as NSError?
      #expect(error != nil)
      #expect(error!.code == PubMaticAdapterError.ErrorCode.adConfigurationMissingAdUnitId.rawValue)
      #expect(ad == nil)
      return AUTKMediationNativeAdEventDelegate()
    }
  }

  @Test("Waterfall native ad load fails for image download failure")
  func loadWaterfallNativeAd_fails_whenImageAssetsFailToDownload() {
    debugProxy.shouldDownloadSucceed = false

    let credentials = AUTKMediationCredentials()
    credentials.settings = [
      "publisher_id": "publisher_id",
      "profile_id": "a1234",
      "ad_unit_id": "ad_unit_id",
    ]
    let config = AUTKMediationNativeAdConfiguration()
    config.credentials = credentials
    let adapter = PubMaticAdapter()

    adapter.loadNativeAd(for: config) { ad, error in
      #expect(error != nil)
      #expect(ad == nil)
      return AUTKMediationNativeAdEventDelegate()
    }
  }

  @MainActor
  @Test("Native ad assets")
  func nativeAdAssets_validate() async {
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()

    var loadedAd: MediationNativeAd?
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: config) { ad, error in
        #expect(error == nil)
        loadedAd = try! #require(ad)
        continuation.resume()
        return AUTKMediationNativeAdEventDelegate()
      }
    }

    #expect(debugProxy.eventDelegate != nil)
    #expect(loadedAd?.images != nil)
    #expect(loadedAd?.icon != nil)
    #expect(loadedAd?.adChoicesView != nil)
    #expect(loadedAd?.headline == "title")
    #expect(loadedAd?.body == "description")
    #expect(loadedAd?.callToAction == "cta")
    #expect(loadedAd?.price == "price")
    #expect(loadedAd?.advertiser == "advertiser")
    #expect(loadedAd?.hasVideoContent == false)
    #expect(loadedAd?.handlesUserImpressions!() == true)
    #expect(loadedAd?.handlesUserClicks!() == true)
    #expect(loadedAd?.starRating == NSDecimalNumber(string: "123"))
    #expect(loadedAd?.extraAssets == nil)
    #expect(loadedAd?.store == nil)
  }

  @MainActor
  @Test("Resgister rendered views")
  func renderedViews_register() async {
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: config) { ad, error in
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return AUTKMediationNativeAdEventDelegate()
      }
    }

    let expectedView = UIView()
    let expectedClickableViews = [GADNativeAssetIdentifier.adChoicesViewAsset: UIView()]
    let expectedViewController = UIViewController()
    debugProxy.didRender(
      in: expectedView, clickableAssetViews: expectedClickableViews, nonclickableAssetViews: [:],
      viewController: expectedViewController)
    #expect(fakeNativeAd.registeredInteractionView === expectedView)
    #expect(
      fakeNativeAd.registeredClickableViews?[0] === Array(expectedClickableViews.values).first)
    #expect(
      debugClient.nativeAdLoaderDelegate!.viewControllerForPresentingModal()
        === expectedViewController)
  }

  @Test("Impression")
  func verifyImpression() async {
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationNativeAdEventDelegate()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: config) { ad, error in
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return eventDelegate
      }
    }

    debugProxy.nativeAdDidRecordImpression(fakeNativeAd)
    #expect(eventDelegate.reportImpressionInvokeCount == 1)
  }

  @Test("Click")
  func verifyClick() async {
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationNativeAdEventDelegate()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: config) { ad, error in
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return eventDelegate
      }
    }

    debugProxy.nativeAdDidRecordClick(fakeNativeAd)
    #expect(eventDelegate.reportClickInvokeCount == 1)
  }

  @Test("Present modal")
  func verifyPresentModal() async {
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationNativeAdEventDelegate()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: config) { ad, error in
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return eventDelegate
      }
    }

    debugProxy.nativeAdWillPresentModal(fakeNativeAd)
    #expect(eventDelegate.willPresentFullScreenViewInvokeCount == 1)
  }

  @Test("Dismiss modal")
  func verifyDismissModal() async {
    let config = AUTKMediationNativeAdConfiguration()
    config.bidResponse = "Test response"
    config.watermark = Data()
    let adapter = PubMaticAdapter()
    let eventDelegate = AUTKMediationNativeAdEventDelegate()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      adapter.loadNativeAd(for: config) { ad, error in
        #expect(error == nil)
        #expect(ad != nil)
        continuation.resume()
        return eventDelegate
      }
    }

    debugProxy.nativeAdDidDismissModal(fakeNativeAd)
    #expect(eventDelegate.didDismissFullScreenViewInvokeCount == 1)
  }

}
