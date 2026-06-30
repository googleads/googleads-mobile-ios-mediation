// Copyright 2026 Google LLC
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

import AppLovinSDK
import OCMock
import ObjectiveC
import UIKit

@testable import AppLovinAdapter

@MainActor
@objc class FakeAppLovinClient: NSObject, AppLovinClient {
  let dummyView = ALAdView(size: ALAdSize.banner)

  var bannerAdView: UIView? { dummyView }

  var loadBannerAdCalled = false
  var capturedDelegate: AppLovinBannerDelegate?
  var shouldAdLoadSucceed = true
  var errorCodeToFailWith: Int32 = 1001

  func loadBannerAd(
    for sdk: ALSdk,
    size: ALAdSize,
    zoneIdentifier: String?,
    delegate: AppLovinBannerDelegate
  ) {
    loadBannerAdCalled = true
    capturedDelegate = delegate

    let serviceMock = OCMockObject.mock(for: ALAdService.self) as! ALAdService
    if shouldAdLoadSucceed {
      let adMock = OCMockObject.mock(for: ALAd.self) as! ALAd
      delegate.adService(serviceMock, didLoad: adMock)
    } else {
      delegate.adService(serviceMock, didFailToLoadAdWithError: errorCodeToFailWith)
    }
  }

  func renderAd(_ ad: ALAd) {
    // Fake implementation does nothing
  }
}
