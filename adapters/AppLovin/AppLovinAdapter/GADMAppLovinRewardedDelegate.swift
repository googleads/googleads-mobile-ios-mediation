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
/// Delegate for handling AppLovin rewarded ad events. AppLovin's delegate protocols are
/// implemented in a separate class to avoid a retain cycle, as the AppLovin SDK keeps a strong
/// reference to its delegate.
@objc(GADMAppLovinRewardedDelegate)
public class GADMAppLovinRewardedDelegate: NSObject, @preconcurrency ALAdLoadDelegate,
  @preconcurrency ALAdDisplayDelegate, @preconcurrency ALAdVideoPlaybackDelegate,
  @preconcurrency ALAdRewardDelegate
{

  private weak var parentRenderer: GADMAdapterAppLovinRewardedRenderer?

  @objc public init(parentRenderer: GADMAdapterAppLovinRewardedRenderer) {
    self.parentRenderer = parentRenderer
    super.init()
  }

  // MARK: - Ad Load Delegate
  public func adService(_ adService: ALAdService, didLoad ad: ALAd) {
    GADMAdapterAppLovinUtils.log("Rewarded ad did load ad: \(ad)")
    guard let parentRenderer else { return }
    parentRenderer.ad = ad

    let isMultipleAdsEnabled = GADMAdapterAppLovinUtils.isMultipleAdsLoadingEnabled()
    if isMultipleAdsEnabled {
      GADMAdapterAppLovinMediationManager.sharedInstance.removeRewardedZoneIdentifier(
        parentRenderer.zoneIdentifier ?? "")
    }

    parentRenderer.delegate = parentRenderer.adLoadCompletionHandler?(parentRenderer, nil)
  }

  public func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
    guard let parentRenderer else { return }
    GADMAdapterAppLovinMediationManager.sharedInstance.removeRewardedZoneIdentifier(
      parentRenderer.zoneIdentifier ?? "")
    if let adLoadCompletionHandler = parentRenderer.adLoadCompletionHandler {
      let error = GADMAdapterAppLovinUtils.sdkError(withCode: Int(code))
      _ = adLoadCompletionHandler(nil, error)
    }
  }

  // MARK: - Ad Display Delegate
  public func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Rewarded ad displayed")
    guard let parentRenderer else { return }
    let delegate = parentRenderer.delegate
    delegate?.willPresentFullScreenView()
    delegate?.reportImpression()
  }

  public func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Rewarded ad dismissed")
    guard let parentRenderer else { return }
    let delegate = parentRenderer.delegate
    GADMAdapterAppLovinMediationManager.sharedInstance.removeRewardedZoneIdentifier(
      parentRenderer.zoneIdentifier ?? "")
    delegate?.willDismissFullScreenView()
    delegate?.didDismissFullScreenView()
  }

  public func ad(_ ad: ALAd, wasClickedIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Rewarded ad clicked")
    parentRenderer?.delegate?.reportClick()
  }

  // MARK: - Video Playback Delegate
  public func videoPlaybackBegan(in ad: ALAd) {
    GADMAdapterAppLovinUtils.log("Rewarded ad playback began")
    parentRenderer?.delegate?.didStartVideo()
  }

  public func videoPlaybackEnded(
    in ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool
  ) {
    GADMAdapterAppLovinUtils.log(
      "Rewarded ad playback ended at playback percent: \(percentPlayed.uintValue)%")
    guard let delegate = parentRenderer?.delegate else { return }
    if wasFullyWatched {
      delegate.didRewardUser()
      delegate.didEndVideo()
    }
  }

  // MARK: - Reward Delegate
  public func rewardValidationRequest(
    for ad: ALAd, didExceedQuotaWithResponse response: [AnyHashable: Any]
  ) {
    GADMAdapterAppLovinUtils.log(
      "Rewarded ad validation request for ad did exceed quota with response: \(response)")
  }

  public func rewardValidationRequest(for ad: ALAd, didFailWithError responseCode: Int) {
    GADMAdapterAppLovinUtils.log(
      "Rewarded ad validation request for ad failed with error code: \(responseCode)")
  }

  public func rewardValidationRequest(
    for ad: ALAd, wasRejectedWithResponse response: [AnyHashable: Any]
  ) {
    GADMAdapterAppLovinUtils.log(
      "Rewarded ad validation request was rejected with response: \(response)")
  }

  public func rewardValidationRequest(
    for ad: ALAd, didSucceedWithResponse response: [AnyHashable: Any]
  ) {
    guard let amountString = response["amount"] as? String,
      let amount = NSDecimalNumber(string: amountString) as NSDecimalNumber?,
      let currency = response["currency"] as? String
    else {
      return
    }
    GADMAdapterAppLovinUtils.log("Rewarded \(amount) \(currency)")
  }
}
