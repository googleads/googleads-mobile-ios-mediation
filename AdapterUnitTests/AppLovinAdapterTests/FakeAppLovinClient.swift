// Copyright 2026 Google LLC.
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
import UIKit

/// Fake implementation of AppLovinClient for unit testing.
@objc(OAUTFakeAppLovinClient)
public class FakeAppLovinClient: NSObject {
  /// Test flag to control whether ad loading should succeed.
  @objc public var fetchShouldSucceed = true

  /// Mock ad to trigger in success callback.
  @objc public var mockAdToLoad: ALAd?

  /// Test flag to control whether load success callback should be triggered synchronously.
  @objc public var shouldTriggerLoadSuccess = false

  /// Test flag to control whether load failure callback should be triggered synchronously.
  @objc public var shouldTriggerLoadFailure = false

  /// Error code to pass in load failure callback.
  @objc public var errorCodeToTrigger: Int = 0

  /// Mock ad view instance returned by loadBannerAd.
  @objc public var mockAdView: ALAdView?

  /// Captured delegate passed during banner load.
  @objc public var delegate: (ALAdLoadDelegate & ALAdDisplayDelegate & ALAdViewEventDelegate)?

  @objc public func loadBannerAd(
    forZoneIdentifier zoneIdentifier: String?,
    size: ALAdSize,
    sdk: ALSdk,
    delegate: ALAdLoadDelegate & ALAdDisplayDelegate & ALAdViewEventDelegate
  ) -> ALAdView? {
    self.delegate = delegate
    if shouldTriggerLoadSuccess {
      if let ad = mockAdToLoad {
        delegate.adService(sdk.adService, didLoad: ad)
      }
    } else if shouldTriggerLoadFailure {
      delegate.adService(sdk.adService, didFailToLoadAdWithError: Int32(errorCodeToTrigger))
    }
    return mockAdView
  }
}

extension FakeAppLovinClient: GADMAdapterAppLovinClient {}
