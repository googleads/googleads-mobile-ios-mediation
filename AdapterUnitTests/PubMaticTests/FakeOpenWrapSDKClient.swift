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

import OpenWrapSDK
import UIKit

@testable import PubMaticAdapter

final class FakeOpenWrapSDKClient: NSObject, OpenWrapSDKClient {

  // MARK: - Test flags
  var shouldSetUpSucceed = true
  var shouldAdLoadSucceed = true
  var shouldPresentFullScreenAdSucceed = true

  // MARK: - OpenWrapSDKClient

  var COPPAEnabled = false
  weak var bannerViewDelegate: POBBannerViewDelegate?
  weak var interstitialDelegate: POBInterstitialDelegate?
  weak var rewardedAdDelegate: POBRewardedAdDelegate?
  weak var nativeAdLoaderDelegate: POBNativeAdLoaderDelegate?

  func version() -> String {
    return "1.2.3"
  }

  func setUp(
    publisherId: String,
    profileIds: [NSNumber],
    completionHandler: @escaping ((any Error)?) -> Void
  ) {
    if self.shouldSetUpSucceed {
      completionHandler(nil)
    } else {
      completionHandler(NSError(domain: "com.test.domain", code: 12345, userInfo: [:]))
    }
  }

  func enableCOPPA(_ enable: Bool) {
    COPPAEnabled = enable
  }

  func collectSignals(for adFormat: POBAdFormat) -> String {
    return "test signals"
  }

  @MainActor func loadRtbBannerView(
    bidResponse: String, testMode: Bool, delegate: POBBannerViewDelegate, watermarkData: Data
  ) {
    bannerViewDelegate = delegate
    if shouldAdLoadSucceed {
      delegate.bannerViewDidReceiveAd?(POBBannerView())
    } else {
      delegate.bannerView?(
        POBBannerView(),
        didFailToReceiveAdWithError: NSError(domain: "test", code: 12345, userInfo: [:]))
    }
  }

  @MainActor func loadWaterfallBannerView(
    publisherId: String, profileId: NSNumber, adUnitId: String, adSize: POBAdSize, testMode: Bool,
    delegate: any POBBannerViewDelegate
  ) {
    bannerViewDelegate = delegate
    if shouldAdLoadSucceed {
      delegate.bannerViewDidReceiveAd?(POBBannerView())
    } else {
      delegate.bannerView?(
        POBBannerView(),
        didFailToReceiveAdWithError: NSError(domain: "test", code: 12345, userInfo: [:]))
    }
  }

  func loadRtbInterstitial(
    bidResponse: String, testMode: Bool, delegate: any POBInterstitialDelegate, watermarkData: Data
  ) {
    interstitialDelegate = delegate
    if shouldAdLoadSucceed {
      delegate.interstitialDidReceiveAd?(POBInterstitial())
    } else {
      delegate.interstitial?(
        POBInterstitial(),
        didFailToReceiveAdWithError: NSError(domain: "test", code: 12345, userInfo: [:]))
    }
  }

  func loadWaterfallInterstitial(
    publisherId: String, profileId: NSNumber, adUnitId: String, testMode: Bool,
    delegate: any POBInterstitialDelegate
  ) {
    interstitialDelegate = delegate
    if shouldAdLoadSucceed {
      delegate.interstitialDidReceiveAd?(POBInterstitial())
    } else {
      delegate.interstitial?(
        POBInterstitial(),
        didFailToReceiveAdWithError: NSError(domain: "test", code: 12345, userInfo: [:]))
    }
  }

  func loadRtbRewardedAd(
    bidResponse: String, testMode: Bool, delegate: any POBRewardedAdDelegate, watermarkData: Data
  ) {
    rewardedAdDelegate = delegate
    if shouldAdLoadSucceed {
      delegate.rewardedAdDidReceive?(POBRewardedAd())
    } else {
      delegate.rewardedAd?(
        POBRewardedAd(),
        didFailToReceiveAdWithError: NSError(domain: "test", code: 12345, userInfo: [:]))
    }
  }

  func loadWaterfallRewardedAd(
    publisherId: String, profileId: NSNumber, adUnitId: String, testMode: Bool,
    delegate: any POBRewardedAdDelegate
  ) {
    rewardedAdDelegate = delegate
    if shouldAdLoadSucceed {
      delegate.rewardedAdDidReceive?(POBRewardedAd())
    } else {
      delegate.rewardedAd?(
        POBRewardedAd(),
        didFailToReceiveAdWithError: NSError(domain: "test", code: 12345, userInfo: [:]))
    }
  }

  func loadRtbNativeAd(
    bidResponse: String,
    testMode: Bool,
    delegate: any POBNativeAdLoaderDelegate,
    watermarkData: Data
  ) {
    nativeAdLoaderDelegate = delegate
    if shouldAdLoadSucceed {
      delegate.nativeAdLoader?(POBNativeAdLoader(), didReceive: FakeNativeAd())
    } else {
      delegate.nativeAdLoader?(
        POBNativeAdLoader(),
        didFailToReceiveAdWithError: NSError(domain: "test", code: 12345, userInfo: [:]))
    }
  }

  func loadWaterfallNativeAd(
    publisherId: String, profileId: NSNumber, adUnitId: String, testMode: Bool,
    delegate: any POBNativeAdLoaderDelegate
  ) {
    nativeAdLoaderDelegate = delegate
    if shouldAdLoadSucceed {
      delegate.nativeAdLoader?(POBNativeAdLoader(), didReceive: FakeNativeAd())
    } else {
      delegate.nativeAdLoader?(
        POBNativeAdLoader(),
        didFailToReceiveAdWithError: NSError(domain: "test", code: 12345, userInfo: [:]))
    }
  }

  func presentInterstitial(from viewController: UIViewController) throws(PubMaticAdapterError) {
    if shouldPresentFullScreenAdSucceed {
      interstitialDelegate?.interstitialWillPresentAd?(POBInterstitial())
      interstitialDelegate?.interstitialDidRecordImpression?(POBInterstitial())
    } else {
      interstitialDelegate?.interstitial?(
        POBInterstitial(),
        didFailToShowAdWithError: NSError(domain: "test", code: 12345, userInfo: [:]))
    }
  }

  func presentRewardedAd(from viewController: UIViewController) throws(PubMaticAdapterError) {
    if shouldPresentFullScreenAdSucceed {
      rewardedAdDelegate?.rewardedAdWillPresent?(POBRewardedAd())
      rewardedAdDelegate?.rewardedAdDidRecordImpression?(POBRewardedAd())
    } else {
      rewardedAdDelegate?.rewardedAd?(
        POBRewardedAd(),
        didFailToShowAdWithError: NSError(domain: "test", code: 12345, userInfo: [:]))
    }
  }

}
