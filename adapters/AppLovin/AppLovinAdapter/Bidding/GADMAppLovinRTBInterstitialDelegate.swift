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

/// AppLovin Interstitial Delegate wrapper. AppLovin interstitial protocols are implemented in a
/// separate class to avoid a retain cycle, as the AppLovin SDK keep a strong reference to its
/// delegate.
@MainActor
@objc(GADMAppLovinRTBInterstitialDelegate)
public final class GADMAppLovinRTBInterstitialDelegate: NSObject, @preconcurrency ALAdLoadDelegate,
  @preconcurrency ALAdDisplayDelegate, @preconcurrency ALAdVideoPlaybackDelegate
{

  /// AppLovin interstitial ad renderer to which the events are delegated.
  private weak var parentRenderer: GADMRTBAdapterAppLovinInterstitialRenderer?

  @objc public init(parentRenderer: GADMRTBAdapterAppLovinInterstitialRenderer) {
    self.parentRenderer = parentRenderer
    super.init()
  }

  // MARK: - Ad Load Delegate

  @objc public func adService(_ adService: ALAdService, didLoad ad: ALAd) {
    GADMAdapterAppLovinUtils.log("Interstitial did load ad: \(ad)")

    guard let parentRenderer = parentRenderer else { return }
    parentRenderer.ad = ad
    if let adLoadCompletionHandler = parentRenderer.adLoadCompletionHandler {
      parentRenderer.delegate = adLoadCompletionHandler(parentRenderer, nil)
    }
  }

  @objc public func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
    guard let parentRenderer = parentRenderer else { return }
    if let adLoadCompletionHandler = parentRenderer.adLoadCompletionHandler {
      let error = GADMAdapterAppLovinUtils.sdkError(withCode: Int(code))
      _ = adLoadCompletionHandler(nil, error)
    }
  }

  // MARK: - Ad Display Delegate

  @objc public func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Interstitial displayed")
    let strongDelegate = parentRenderer?.delegate
    strongDelegate?.willPresentFullScreenView()
    strongDelegate?.reportImpression()
  }

  @objc public func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Interstitial hidden")
    let strongDelegate = parentRenderer?.delegate
    strongDelegate?.willDismissFullScreenView()
    strongDelegate?.didDismissFullScreenView()
  }

  @objc public func ad(_ ad: ALAd, wasClickedIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Interstitial clicked")
    let strongDelegate = parentRenderer?.delegate
    strongDelegate?.reportClick()
  }

  // MARK: - Video Playback Delegate

  @objc public func videoPlaybackBegan(in ad: ALAd) {
    GADMAdapterAppLovinUtils.log("Interstitial video playback began")
  }

  @objc public func videoPlaybackEnded(
    in ad: ALAd,
    atPlaybackPercent percentPlayed: NSNumber,
    fullyWatched wasFullyWatched: Bool
  ) {
    GADMAdapterAppLovinUtils.log(
      "Interstitial video playback ended at playback percent: \(percentPlayed.uintValue)%"
    )
  }
}
