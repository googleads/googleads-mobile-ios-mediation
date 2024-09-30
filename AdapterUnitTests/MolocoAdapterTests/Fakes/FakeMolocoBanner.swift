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

  var bannerDelegate: MolocoBannerDelegate?

  // MolocoSDK.MolocoAd properties.
  var isReady: Bool

  init(bannerDelegate: MolocoBannerDelegate) {
    isReady = true
    self.bannerDelegate = bannerDelegate
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
    // TODO: b/368608855 - Add Implementation.
  }

}
