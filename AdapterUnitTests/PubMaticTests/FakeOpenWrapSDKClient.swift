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
  weak var interstitialDelegate: POBInterstitialDelegate?

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

  func loadRtbInterstitial(
    bidResponse: String, delegate: any POBInterstitialDelegate, watermarkData: Data
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

}
