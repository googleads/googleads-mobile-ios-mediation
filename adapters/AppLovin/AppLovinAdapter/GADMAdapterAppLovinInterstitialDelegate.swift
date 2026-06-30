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

@MainActor
@objc(GADMAdapterAppLovinInterstitialDelegate)
public class GADMAdapterAppLovinInterstitialDelegate: NSObject, @preconcurrency ALAdLoadDelegate,
  @preconcurrency ALAdDisplayDelegate, @preconcurrency ALAdVideoPlaybackDelegate
{

  private weak var parentRenderer: GADMAdapterAppLovin?

  @objc public init(parentRenderer: GADMAdapterAppLovin) {
    self.parentRenderer = parentRenderer
    super.init()
  }

  // MARK: - Ad Load Delegate
  public func adService(_ adService: ALAdService, didLoad ad: ALAd) {
    guard let parentRenderer else { return }
    let isMultipleAdsEnabled = GADMAdapterAppLovinUtils.isMultipleAdsLoadingEnabled()
    if isMultipleAdsEnabled {
      GADMAdapterAppLovinMediationManager.sharedInstance.removeInterstitialZoneIdentifier(
        parentRenderer.zoneIdentifier ?? "")
    }
    GADMAdapterAppLovinUtils.log("Interstitial did load ad: \(ad)")
    parentRenderer.interstitialAd = ad
    parentRenderer.connector?.adapterDidReceiveInterstitial(parentRenderer)
  }

  public func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
    guard let parentRenderer else { return }
    GADMAdapterAppLovinMediationManager.sharedInstance.removeInterstitialZoneIdentifier(
      parentRenderer.zoneIdentifier ?? "")
    let error = GADMAdapterAppLovinUtils.sdkError(withCode: Int(code))
    parentRenderer.connector?.adapter(parentRenderer, didFailAd: error)
  }

  // MARK: - Ad Display Delegate
  public func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Interstitial displayed")
    guard let parentRenderer else { return }
    parentRenderer.connector?.adapterWillPresentInterstitial(parentRenderer)
  }

  public func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Interstitial hidden")
    guard let parentRenderer else { return }
    GADMAdapterAppLovinMediationManager.sharedInstance.removeInterstitialZoneIdentifier(
      parentRenderer.zoneIdentifier ?? "")
    let connector = parentRenderer.connector
    connector?.adapterWillDismissInterstitial(parentRenderer)
    connector?.adapterDidDismissInterstitial(parentRenderer)
  }

  public func ad(_ ad: ALAd, wasClickedIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Interstitial clicked")
    guard let parentRenderer else { return }
    let connector = parentRenderer.connector
    connector?.adapterDidGetAdClick(parentRenderer)
    connector?.adapterWillLeaveApplication(parentRenderer)
  }

  // MARK: - Video Playback Delegate
  public func videoPlaybackBegan(in ad: ALAd) {
    GADMAdapterAppLovinUtils.log("Interstitial video playback began")
  }

  public func videoPlaybackEnded(
    in ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool
  ) {
    GADMAdapterAppLovinUtils.log(
      "Interstitial video playback ended at playback percent: \(percentPlayed.uintValue)%")
  }
}
