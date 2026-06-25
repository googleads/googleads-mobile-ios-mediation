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

/// Protocol wrapping the AppLovin SDK operations to support unit testing with fakes.
@objc(GADMAdapterAppLovinClient)
public protocol AppLovinClient: NSObjectProtocol {
  /// Loads a banner ad using the AppLovin SDK and returns the constructed ALAdView.
  func loadBannerAd(
    forZoneIdentifier zoneIdentifier: String?,
    size: ALAdSize,
    sdk: ALSdk,
    delegate: ALAdLoadDelegate & ALAdDisplayDelegate & ALAdViewEventDelegate
  ) -> ALAdView?
}

/// Factory class for instantiating the AppLovin SDK client.
@objc(GADMAdapterAppLovinClientFactory)
public class GADMAdapterAppLovinClientFactory: NSObject {
  #if DEBUG
    /// Static debug client used to inject fakes/mocks during unit tests.
    @objc nonisolated(unsafe) public static var debugClient: AppLovinClient?
  #endif

  /// Creates and returns a client implementation.
  @objc public static func createClient() -> AppLovinClient {
    #if DEBUG
      return debugClient ?? GADMAdapterAppLovinClientImpl()
    #else
      return GADMAdapterAppLovinClientImpl()
    #endif
  }
}

/// Production implementation of the AppLovinClient wrapping the real AppLovin SDK.
class GADMAdapterAppLovinClientImpl: NSObject, AppLovinClient {
  func loadBannerAd(
    forZoneIdentifier zoneIdentifier: String?,
    size: ALAdSize,
    sdk: ALSdk,
    delegate: ALAdLoadDelegate & ALAdDisplayDelegate & ALAdViewEventDelegate
  ) -> ALAdView? {
    let adView = ALAdView(sdk: sdk, size: size)
    adView.adLoadDelegate = delegate
    adView.adDisplayDelegate = delegate
    adView.adEventDelegate = delegate

    if let zoneIdentifier = zoneIdentifier, !zoneIdentifier.isEmpty {
      sdk.adService.loadNextAd(forZoneIdentifier: zoneIdentifier, andNotify: delegate)
    } else {
      sdk.adService.loadNextAd(size, andNotify: delegate)
    }
    return adView
  }
}
