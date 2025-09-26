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

}
