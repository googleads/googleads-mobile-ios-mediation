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

import Foundation
import GoogleMobileAds
import UIKit

final class BannerAdLoader: NSObject, MediationBannerAd, BannerAdClientDelegate,
  @unchecked Sendable
{

  private let adConfiguration: MediationBannerAdConfiguration
  private var adLoadCompletionHandler: GADMediationBannerLoadCompletionHandler?
  private weak var eventDelegate: MediationBannerAdEventDelegate?
  private let client: any Client
  var view: UIView

  @MainActor
  init(
    adConfiguration: MediationBannerAdConfiguration,
    loadCompletionHandler: @escaping GADMediationBannerLoadCompletionHandler,
    client: any Client = ClientFactory.createClient()
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.client = client
    self.view = UIView()
    super.init()
  }

  @MainActor
  func loadAd() {
    do {
      let adUnitId = try Util.adUnitID(from: adConfiguration)
      let bidResponse = try Util.bidResponse(from: adConfiguration)
      _ = try Util.bannerSize(for: adConfiguration.adSize)
      let bannerView = client.createBannerAdView(for: adUnitId)
      self.view = bannerView
      client.loadBannerAd(
        bannerView,
        bidPayload: bidResponse,
        viewController: adConfiguration.topViewController,
        delegate: self
      )
    } catch {
      _ = adLoadCompletionHandler?(nil, error.toNSError())
      adLoadCompletionHandler = nil
    }
  }

  // MARK: - BannerAdClientDelegate

  func bannerDidLoad() {
    eventDelegate = adLoadCompletionHandler?(self, nil)
    adLoadCompletionHandler = nil
  }

  func bannerDidFailToLoad(with error: any Error) {
    _ = adLoadCompletionHandler?(nil, error.toNSError())
    adLoadCompletionHandler = nil
  }

  func bannerDidClick() {
    eventDelegate?.reportClick()
  }

  func bannerDidHide() {
    eventDelegate?.willDismissFullScreenView()
    eventDelegate?.didDismissFullScreenView()
  }

  func bannerDidPayRevenue() {
    eventDelegate?.reportImpression()
  }

}
