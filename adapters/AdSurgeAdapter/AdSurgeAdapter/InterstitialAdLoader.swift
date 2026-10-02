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

final class InterstitialAdLoader: NSObject, MediationInterstitialAd, InterstitialAdClientDelegate,
  @unchecked Sendable
{

  private let adConfiguration: MediationInterstitialAdConfiguration
  private var adLoadCompletionHandler: GADMediationInterstitialLoadCompletionHandler?
  private weak var eventDelegate: MediationInterstitialAdEventDelegate?
  private let client: any Client

  init(
    adConfiguration: MediationInterstitialAdConfiguration,
    loadCompletionHandler: @escaping GADMediationInterstitialLoadCompletionHandler,
    client: any Client = ClientFactory.createClient()
  ) {
    self.adConfiguration = adConfiguration
    self.adLoadCompletionHandler = loadCompletionHandler
    self.client = client
    super.init()
  }

  func loadAd() {
    do {
      let adUnitId = try Util.adUnitID(from: adConfiguration)
      let bidResponse = try Util.bidResponse(from: adConfiguration)
      client.loadInterstitialAd(
        for: adUnitId,
        bidPayload: bidResponse,
        delegate: self
      )
    } catch {
      _ = adLoadCompletionHandler?(nil, error.toNSError())
      adLoadCompletionHandler = nil
    }
  }

  func present(from viewController: UIViewController) {
    client.showInterstitialAd(from: viewController)
  }

  // MARK: - InterstitialAdClientDelegate

  func interstitialDidLoad() {
    eventDelegate = adLoadCompletionHandler?(self, nil)
    adLoadCompletionHandler = nil
  }

  func interstitialDidFailToLoad(with error: any Error) {
    _ = adLoadCompletionHandler?(nil, error.toNSError())
    adLoadCompletionHandler = nil
  }

  func interstitialDidDisplay() {
    eventDelegate?.willPresentFullScreenView()
    eventDelegate?.reportImpression()
  }

  func interstitialDidFailToDisplay(with error: any Error) {
    eventDelegate?.didFailToPresentWithError(error.toNSError())
  }

  func interstitialDidClick() {
    eventDelegate?.reportClick()
  }

  func interstitialDidHide() {
    eventDelegate?.willDismissFullScreenView()
    eventDelegate?.didDismissFullScreenView()
  }

  func interstitialDidPayRevenue() {
    eventDelegate?.reportImpression()
  }

}
