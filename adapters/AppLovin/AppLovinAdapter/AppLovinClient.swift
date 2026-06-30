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
import UIKit

typealias AppLovinBannerDelegate = ALAdLoadDelegate & ALAdDisplayDelegate & ALAdViewEventDelegate

@MainActor
@objc protocol AppLovinClient: NSObjectProtocol {
  /// Returns the banner ad view.
  var bannerAdView: UIView? { get }

  /// Instantiates and loads the banner ad.
  func loadBannerAd(
    for sdk: ALSdk,
    size: ALAdSize,
    zoneIdentifier: String?,
    delegate: AppLovinBannerDelegate
  )

  /// Renders the loaded banner ad view.
  func renderAd(_ ad: ALAd)
}

@MainActor
@objc class AppLovinClientImpl: NSObject, AppLovinClient {
  private var adView: ALAdView?

  var bannerAdView: UIView? { adView }

  func loadBannerAd(
    for sdk: ALSdk,
    size: ALAdSize,
    zoneIdentifier: String?,
    delegate: AppLovinBannerDelegate
  ) {
    let view = ALAdView(sdk: sdk, size: size)
    adView = view
    view.adLoadDelegate = delegate
    view.adDisplayDelegate = delegate
    view.adEventDelegate = delegate

    if let zoneId = zoneIdentifier {
      sdk.adService.loadNextAd(forZoneIdentifier: zoneId, andNotify: delegate)
    } else {
      sdk.adService.loadNextAd(size, andNotify: delegate)
    }
  }

  func renderAd(_ ad: ALAd) {
    adView?.render(ad)
  }
}

@MainActor
@objc class AppLovinClientFactory: NSObject {
  private override init() {}

  @objc static var debugClient: AppLovinClient?

  @objc static func createClient() -> AppLovinClient {
    debugClient ?? AppLovinClientImpl()
  }
}
