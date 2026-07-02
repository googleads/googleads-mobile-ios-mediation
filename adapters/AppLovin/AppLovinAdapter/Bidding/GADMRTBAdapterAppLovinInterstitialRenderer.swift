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
import Foundation
import GoogleMobileAds

/// Renderer for AppLovin RTB interstitial ads.
@MainActor
@objc(GADMRTBAdapterAppLovinInterstitialRenderer)
public final class GADMRTBAdapterAppLovinInterstitialRenderer: NSObject,
  @preconcurrency MediationInterstitialAd
{

  /// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
  @objc public var adLoadCompletionHandler: GADMediationInterstitialLoadCompletionHandler?

  /// Delegate to notify the Google Mobile Ads SDK of interstitial presentation events.
  @objc public weak var delegate: MediationInterstitialAdEventDelegate?

  /// An AppLovin interstitial ad.
  @objc public var ad: ALAd?

  /// Data used to render an interstitial ad.
  private let adConfiguration: MediationInterstitialAdConfiguration

  /// AppLovin interstitial object used to load an ad.
  nonisolated(unsafe) private var interstitialAd: ALInterstitialAd?

  @objc public init(
    adConfiguration: MediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    super.init()

    // Store the completion handler for later use.
    var completionHandlerCalled = false
    var originalCompletionHandler: GADMediationInterstitialLoadCompletionHandler? =
      completionHandler

    self.adLoadCompletionHandler = { ad, error in
      if completionHandlerCalled {
        return nil
      }
      completionHandlerCalled = true
      var delegate: MediationInterstitialAdEventDelegate?
      if let handler = originalCompletionHandler {
        delegate = handler(ad, error)
      }
      originalCompletionHandler = nil
      return delegate
    }
  }

  /// Loads an AppLovin interstitial ad.
  @objc public func loadAd() {
    guard let sdk = ALSdk.shared() as ALSdk? else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .appLovinSDKNotInitialized,
        description: "Failed to retrieve ALSdk shared instance."
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    sdk.settings.isMuted = MobileAds.shared.isApplicationMuted

    // Create interstitial object.
    let interstitialAd = GADMediationAdapterAppLovin.createInterstitialAd(with: sdk)
    self.interstitialAd = interstitialAd
    interstitialAd.setExtraInfoForKey("google_watermark", value: adConfiguration.watermark)

    let delegate = GADMAppLovinRTBInterstitialDelegate(parentRenderer: self)
    interstitialAd.adDisplayDelegate = delegate
    interstitialAd.adVideoPlaybackDelegate = delegate

    guard let bidResponse = adConfiguration.bidResponse else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .invalidServerParameters,
        description: "Bid response is missing for RTB ad."
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    // Load ad.
    sdk.adService.loadNextAd(forAdToken: bidResponse, andNotify: delegate)
  }

  // MARK: - GADMediationInterstitialAd

  nonisolated public func present(from viewController: UIViewController) {
    MainActor.assumeIsolated {
      if let ad = self.ad {
        self.interstitialAd?.show(ad)
      }
    }
  }

  deinit {
    interstitialAd?.adDisplayDelegate = nil
    interstitialAd?.adVideoPlaybackDelegate = nil
  }
}
