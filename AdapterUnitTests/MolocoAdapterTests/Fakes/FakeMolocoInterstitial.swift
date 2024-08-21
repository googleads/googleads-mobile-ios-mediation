// Copyright 2024 Google LLC.
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

import Foundation
import GoogleMobileAds
import MolocoSDK

/// A fake implementation of MolocoInterstitial.
final class FakeMolocoInterstitial: MolocoSDK.MolocoInterstitial {

  let loadError: NSError?

  let showShallSucceed: Bool

  let showError: NSError?

  /// Var to capture the bid response that was used to load the ad on Moloco SDK. Used for
  /// assertion. It is initlialized to a value that is never asserted for.
  var bidResponseUsedToLoadMolocoAd: String = "nil"

  /// If loadError is nil, this fake mimics load success. If loadError is not nil, this fake mimics
  /// load failure.
  init(
    interstitialDelegate: any MolocoSDK.MolocoInterstitialDelegate, loadError: NSError?,
    isReadyToBeShown: Bool, showShallSucceed: Bool, showError: NSError?
  ) {
    self.interstitialDelegate = interstitialDelegate
    self.fullscreenViewController = nil
    self.loadError = loadError
    self.isReady = isReadyToBeShown
    self.showShallSucceed = showShallSucceed
    self.showError = showError
  }

  var interstitialDelegate: (any MolocoSDK.MolocoInterstitialDelegate)?

  func show(from viewController: UIViewController) {
    guard let interstitialDelegate else { return }
    if showShallSucceed {
      // Fake that show and the subsequent ad lifecycle events happen.
      interstitialDelegate.didShow(ad: self)
      interstitialDelegate.didClick(on: self)
      interstitialDelegate.didHide(ad: self)
    } else {
      if showError != nil {
        interstitialDelegate.failToShow(ad: self, with: showError)
      } else {
        interstitialDelegate.failToShow(ad: self, with: nil)
      }
    }

  }

  func show(from viewController: UIViewController, muted: Bool) {
  }

  var fullscreenViewController: UIViewController?

  func load(bidResponse: String) {
    bidResponseUsedToLoadMolocoAd = bidResponse
    loadError == nil
      ? interstitialDelegate?.didLoad(ad: self)
      : interstitialDelegate?.failToLoad(ad: self, with: loadError)
  }

  func destroy() {
  }

  var isReady: Bool

}
