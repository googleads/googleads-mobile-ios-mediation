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

import AppLovinAdapter
import AppLovinSDK
import Foundation
import UIKit

// Dummy class to fake ALAd
private final class FakeALAd: NSObject {
  let zoneIdentifier: String?
  init(zoneIdentifier: String?) {
    self.zoneIdentifier = zoneIdentifier
    super.init()
  }
}

public func makeFakeALAd(zoneIdentifier: String? = nil) -> ALAd {
  let fake = FakeALAd(zoneIdentifier: zoneIdentifier)
  return unsafeBitCast(fake, to: ALAd.self)
}

@MainActor
public final class FakeAppLovinAdView: AppLovinAdView {
  public let fakeALAdView: ALAdView

  public init() {
    let dummyView = UIView()
    self.fakeALAdView = unsafeBitCast(dummyView, to: ALAdView.self)
  }

  public var view: UIView {
    return fakeALAdView
  }

  public func render(_ ad: ALAd) {}

  public var adLoadDelegate: (any ALAdLoadDelegate)?
  public var adDisplayDelegate: (any ALAdDisplayDelegate)?
  public var adEventDelegate: (any ALAdViewEventDelegate)?
  public var frame: CGRect = .zero
}

@MainActor
public final class FakeAppLovinClient: AppLovinClient {
  public var isSDKInitialized: Bool = true
  public var createdAdViews: [FakeAppLovinAdView] = []
  public var lastLoadedSize: ALAdSize?
  public var lastLoadedZoneIdentifier: String?
  public var lastDelegate: (any ALAdLoadDelegate)?
  public var adToReturn: ALAd?
  public var errorToReturn: Int32?

  public init() {}

  public func createAdView(size: ALAdSize) -> any AppLovinAdView {
    let fakeAdView = FakeAppLovinAdView()
    createdAdViews.append(fakeAdView)
    return fakeAdView
  }

  public func loadNextAd(
    size: ALAdSize,
    zoneIdentifier: String?,
    andNotify delegate: any ALAdLoadDelegate
  ) {
    lastLoadedSize = size
    lastLoadedZoneIdentifier = zoneIdentifier
    lastDelegate = delegate

    let adService = unsafeBitCast(self, to: ALAdService.self)
    if let error = errorToReturn {
      delegate.adService(adService, didFailToLoadAdWithError: error)
    } else {
      let ad = adToReturn ?? makeFakeALAd(zoneIdentifier: zoneIdentifier)
      delegate.adService(adService, didLoad: ad)
    }
  }

  public func initialize(
    withSDKKey sdkKey: String,
    completionHandler: @escaping @Sendable @MainActor () -> Void
  ) {
    completionHandler()
  }
}
