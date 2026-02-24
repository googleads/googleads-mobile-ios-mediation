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

import BigoADS
import GoogleMobileAds
import UIKit

@testable import BigoAdapter

final class FakeBigoClient: NSObject, BigoClient {

  var shouldAdLoadSucceed: Bool = true
  var shouldAdShowSucceed: Bool = true

  var bigoConsentOptionsCOPPA: Bool?

  var applicationId: String?
  var testMode: Bool?

  func initialize(
    with applicationId: String,
    testMode: Bool,
    completion: @escaping () -> Void
  ) {
    self.applicationId = applicationId
    self.testMode = testMode
    completion()
  }

  func getBidderToken() -> String? {
    return "token"
  }

  func loadRTBInterstitialAd(
    for slotId: String,
    bidPayLoad: String,
    watermark: Data,
    delegate: any BigoInterstitialAdLoaderDelegate
  ) {
    if shouldAdLoadSucceed {
      delegate.onInterstitialAdLoaded(BigoInterstitialAd())
    } else {
      delegate.onInterstitialAdLoadError?(
        BigoAdError(errorCode: 12345, subErrorCode: 67890, errorMsg: "Ad failed to load."))
    }
  }

  func presentInterstitialAd(
    _ ad: BigoInterstitialAd, viewController: UIViewController,
    interactionDelegate: BigoAdInteractionDelegate
  ) {
    if shouldAdShowSucceed {
      interactionDelegate.onAdOpened?(ad)
      interactionDelegate.onAdImpression?(ad)
      interactionDelegate.onAdClicked?(ad)
      interactionDelegate.onAdClosed?(ad)
    } else {
      interactionDelegate.onAd?(
        ad,
        error: BigoAdError(errorCode: 12345, subErrorCode: 67890, errorMsg: "Ad failed to show."))
    }
  }

  func loadRTBRewardVideoAd(
    for slotId: String,
    bidPayLoad: String,
    watermark: Data,
    delegate: any BigoRewardVideoAdLoaderDelegate
  ) {
    if shouldAdLoadSucceed {
      delegate.onRewardVideoAdLoaded(BigoRewardVideoAd())
    } else {
      delegate.onRewardVideoAdLoadError?(
        BigoAdError(errorCode: 12345, subErrorCode: 67890, errorMsg: "Ad failed to load."))
    }
  }

  func presentRewardVideoAd(
    _ ad: BigoRewardVideoAd,
    viewController: UIViewController,
    interactionDelegate: any BigoRewardVideoAdInteractionDelegate
  ) {
    if shouldAdShowSucceed {
      interactionDelegate.onAdOpened?(ad)
      interactionDelegate.onAdImpression?(ad)
      interactionDelegate.onAdClicked?(ad)
      interactionDelegate.onAdClosed?(ad)
      interactionDelegate.onAdRewarded?(ad)
    } else {
      interactionDelegate.onAd?(
        ad,
        error: BigoAdError(errorCode: 12345, subErrorCode: 67890, errorMsg: "Ad failed to show."))
    }
  }

  func loadRTBSplashAd(
    for slotId: String,
    bidPayLoad: String,
    watermark: Data,
    delegate: any BigoSplashAdLoaderDelegate
  ) {
    if shouldAdLoadSucceed {
      delegate.onSplashAdLoaded(BigoSplashAd())
    } else {
      delegate.onSplashAdLoadError?(
        BigoAdError(errorCode: 12345, subErrorCode: 67890, errorMsg: "Ad failed to load."))
    }
  }

  func presentSplashAd(
    _ ad: BigoSplashAd,
    viewController: UIViewController,
    interactionDelegate: any BigoSplashAdInteractionDelegate
  ) {
    if shouldAdShowSucceed {
      interactionDelegate.onAdOpened?(ad)
      interactionDelegate.onAdImpression?(ad)
      interactionDelegate.onAdClicked?(ad)
      interactionDelegate.onAdClosed?(ad)
    } else {
      interactionDelegate.onAd?(
        ad,
        error: BigoAdError(errorCode: 12345, subErrorCode: 67890, errorMsg: "Ad failed to show."))
    }
  }

  func loadRTBBannerAd(
    for slotId: String,
    bidPayLoad: String,
    adSize: BigoAdSize,
    watermark: Data,
    delegate: any BigoBannerAdLoaderDelegate
  ) {
    if shouldAdLoadSucceed {
      delegate.onBannerAdLoaded(BigoBannerAd())
    } else {
      delegate.onBannerAdLoadError?(
        BigoAdError(errorCode: 12345, subErrorCode: 67890, errorMsg: "Ad failed to load."))
    }
  }

  func loadRTBNativeAd(
    for slotId: String,
    bidPayLoad: String,
    watermark: Data,
    delegate: any BigoNativeAdLoaderDelegate
  ) {
    if shouldAdLoadSucceed {
      delegate.onNativeAdLoaded(BigoNativeAd())
    } else {
      delegate.onNativeAdLoadError?(
        BigoAdError(errorCode: 12345, subErrorCode: 67890, errorMsg: "Ad failed to load."))
    }
  }

  func setUserConsent(
    with tagForChildDirectedTreatment: NSNumber?, tagForUnderAgeOfConsent: NSNumber?
  ) {
    let isChild = tagForChildDirectedTreatment?.boolValue
    let isUnderAge = tagForUnderAgeOfConsent?.boolValue

    // https://www.bigossp.com/guide/sdk/ios/document#pass-mediation-sdk-info
    // A value of "YES" indicates that the user is not a child under 13 years
    // old, and a value of "NO" indicates that the user is a child under 13
    // years old.
    if isChild == true || isUnderAge == true {
      BigoAdSdk.setUserConsentWithOption(BigoConsentOptionsCOPPA, consent: false)
      bigoConsentOptionsCOPPA = false
    } else if isChild == false || isUnderAge == false {
      bigoConsentOptionsCOPPA = true
    }
  }
}
