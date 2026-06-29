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
@objc(GADMAdapterAppLovinBannerDelegate)
public class GADMAdapterAppLovinBannerDelegate: NSObject, @preconcurrency ALAdLoadDelegate,
  @preconcurrency ALAdDisplayDelegate, @preconcurrency ALAdViewEventDelegate
{

  private weak var parentAdapter: GADMAdapterAppLovin?

  @objc public init(parentAdapter: GADMAdapterAppLovin) {
    self.parentAdapter = parentAdapter
    super.init()
  }

  // MARK: - Ad Load Delegate
  public func adService(_ adService: ALAdService, didLoad ad: ALAd) {
    guard let parentAdapter else { return }
    GADMAdapterAppLovinUtils.log("Banner did load ad: \(ad)")
    parentAdapter.adView?.render(ad)
    parentAdapter.connector?.adapter(parentAdapter, didReceiveAdView: parentAdapter.adView)
  }

  public func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
    guard let parentAdapter else { return }
    let error = GADMAdapterAppLovinUtils.sdkError(withCode: Int(code))
    parentAdapter.connector?.adapter(parentAdapter, didFailAd: error)
  }

  // MARK: - Ad Display Delegate
  public func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Banner displayed")
  }

  public func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
    GADMAdapterAppLovinUtils.log("Banner dismissed")
  }

  public func ad(_ ad: ALAd, wasClickedIn view: UIView) {
    guard let parentAdapter else { return }
    GADMAdapterAppLovinUtils.log("Banner clicked")
    parentAdapter.connector?.adapterDidGetAdClick(parentAdapter)
  }

  // MARK: - Ad View Event Delegate
  public func ad(_ ad: ALAd, didPresentFullscreenFor adView: ALAdView) {
    guard let parentAdapter else { return }
    GADMAdapterAppLovinUtils.log("Banner presented fullscreen")
    parentAdapter.connector?.adapterWillPresentFullScreenModal(parentAdapter)
  }

  public func ad(_ ad: ALAd, willDismissFullscreenFor adView: ALAdView) {
    guard let parentAdapter else { return }
    GADMAdapterAppLovinUtils.log("Banner will dismiss fullscreen")
    parentAdapter.connector?.adapterWillDismissFullScreenModal(parentAdapter)
  }

  public func ad(_ ad: ALAd, didDismissFullscreenFor adView: ALAdView) {
    guard let parentAdapter else { return }
    GADMAdapterAppLovinUtils.log("Banner did dismiss fullscreen")
    parentAdapter.connector?.adapterDidDismissFullScreenModal(parentAdapter)
  }

  public func ad(_ ad: ALAd, willLeaveApplicationFor adView: ALAdView) {
    guard let parentAdapter else { return }
    GADMAdapterAppLovinUtils.log("Banner left application")
    parentAdapter.connector?.adapterWillLeaveApplication(parentAdapter)
  }

  public func ad(
    _ ad: ALAd, didFailToDisplayIn adView: ALAdView, withError code: ALAdViewDisplayErrorCode
  ) {
    GADMAdapterAppLovinUtils.log("Banner failed to display: \(code.rawValue)")
  }
}
