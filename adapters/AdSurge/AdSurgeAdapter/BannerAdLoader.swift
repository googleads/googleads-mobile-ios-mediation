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
  private let client: any AdSurgeClient
  var view: UIView

  @MainActor
  init(
    adConfiguration: MediationBannerAdConfiguration,
    loadCompletionHandler: @escaping GADMediationBannerLoadCompletionHandler,
    client: any AdSurgeClient = AdSurgeClientFactory.createClient()
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
      // Set the view before loading so that it is in place if the SDK reports the load result
      // synchronously.
      view = client.createBannerAdView(
        adUnitId: adUnitId,
        viewController: adConfiguration.topViewController,
        delegate: self
      )
      client.loadBannerAd(bidPayload: bidResponse)
    } catch {
      _ = adLoadCompletionHandler?(nil, error.toNSError())
      adLoadCompletionHandler = nil
    }
  }

  // MARK: - BannerAdClientDelegate

  func didLoad() {
    // The SDK may report more than one load result; only the first one completes the load.
    guard let adLoadCompletionHandler else { return }
    eventDelegate = adLoadCompletionHandler(self, nil)
    self.adLoadCompletionHandler = nil
  }

  func didFailToLoad(error: AdSurgeSDKError) {
    guard let adLoadCompletionHandler else { return }
    _ = adLoadCompletionHandler(nil, Util.sdkNSError(from: error))
    self.adLoadCompletionHandler = nil
  }

  func didClick() {
    eventDelegate?.reportClick()
  }

  func didHide() {
    eventDelegate?.willDismissFullScreenView()
    eventDelegate?.didDismissFullScreenView()
  }

  func didPayRevenue() {
    eventDelegate?.reportImpression()
  }

}
