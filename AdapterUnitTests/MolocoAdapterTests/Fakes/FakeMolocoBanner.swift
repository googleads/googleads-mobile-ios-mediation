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

/// A fake implementation of MolocoBanner.
final class FakeMolocoBanner: UIView {

  /// The Moloco banner delegate.
  var bannerDelegate: MolocoBannerDelegate?

  /// The error that should occur during banner ad loading.
  let loadError: Error?

  /// Whether the banner ad fails to show.
  let shouldFailToShow: Bool

  /// The specified error that occurs during banner ad presentation.
  let showError: Error?

  /// Var to capture the bid response that was used to load the ad on Moloco SDK. Used for
  /// assertion. It is initlialized to a value that is never asserted for.
  var bidResponseUsedToLoadMolocoAd: String = ""

  // MolocoSDK.MolocoAd properties.
  var isReady: Bool

  init(
    bannerDelegate: MolocoBannerDelegate, loadError: Error?, shouldFailToShow: Bool,
    showError: Error?
  ) {
    isReady = true
    self.bannerDelegate = bannerDelegate
    self.loadError = loadError
    self.shouldFailToShow = shouldFailToShow || showError != nil
    self.showError = showError
    super.init(frame: CGRect.zero)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}

// MARK: - MolocoSDK.MolocoAd

extension FakeMolocoBanner: MolocoAd {

  func destroy() {
    // No-op.
  }

  @MainActor
  @objc
  func load(bidResponse: String) {
    bidResponseUsedToLoadMolocoAd = bidResponse

    if let loadError {
      bannerDelegate?.failToLoad(ad: self, with: loadError)
      return
    }

    if shouldFailToShow {
      bannerDelegate?.didLoad(ad: self)
      bannerDelegate?.failToShow(ad: self, with: showError)
      return
    }

    // Simulate load and the subsequent ad lifecycle events.
    bannerDelegate?.didLoad(ad: self)
    bannerDelegate?.didShow(ad: self)
    bannerDelegate?.didClick(on: self)
  }

}
