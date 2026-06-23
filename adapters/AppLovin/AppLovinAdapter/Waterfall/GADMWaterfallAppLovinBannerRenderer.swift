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

@objc(GADMWaterfallAppLovinBannerRenderer)
public class GADMWaterfallAppLovinBannerRenderer: NSObject, MediationBannerAd {

  /// Block to notify the Google Mobile Ads SDK if ad loading succeeded or failed.
  private var adLoadCompletionHandler: GADMediationBannerLoadCompletionHandler?

  /// Identifier to identify AppLovin's ad zone.
  private var zoneIdentifier: String?

  /// An AppLovin banner ad view.
  private var adView: ALAdView?

  /// Delegate to notify the Google Mobile Ads SDK of presentation events.
  private weak var delegate: MediationBannerAdEventDelegate?

  private let adConfiguration: MediationBannerAdConfiguration
  private var loadAlreadyStarted = false

  @objc public init(adConfiguration: MediationBannerAdConfiguration) {
    self.adConfiguration = adConfiguration
    super.init()
  }

  @objc public func loadAdWithCompletion(
    _ completion: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    #if DEBUG
      assert(!loadAlreadyStarted, "Trying to load a new ad while already loading/loaded one")
      loadAlreadyStarted = true
    #endif

    // Store the completion handler for later use.
    var completionCalled = false
    adLoadCompletionHandler = { [weak self] ad, error in
      guard let self = self else { return nil }
      objc_sync_enter(self)
      defer { objc_sync_exit(self) }
      if completionCalled {
        return nil
      }
      completionCalled = true
      return completion(ad, error)
    }

    let sharedALSdk = ALSdk.shared()

    zoneIdentifier = GADMAdapterAppLovinUtils.zoneIdentifier(forAdConfiguration: adConfiguration)
    guard let zoneIdentifier = zoneIdentifier else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .invalidServerParameters,
        description: "Invalid custom zone entered. Please double-check your credentials."
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    let adSize = adConfiguration.adSize

    GADMAdapterAppLovinUtils.log(
      [
        "NEW API: Requesting banner of size",
        string(for: adSize),
        "for zone:",
        zoneIdentifier,
      ].joined(separator: " ")
    )

    // Convert requested size to AppLovin Ad Size.
    guard let appLovinAdSize = GADMAdapterAppLovinUtils.appLovinAdSize(fromRequestedSize: adSize)
    else {
      let errorMessage =
        "Adapter requested to display a banner ad of unsupported size: \(string(for: adSize))"
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .bannerSizeMismatch,
        description: errorMessage
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    adView = GADMediationAdapterAppLovin.createAdView(with: sharedALSdk, size: appLovinAdSize)

    let size = cgSize(for: adSize)
    adView?.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

    let appLovinDelegate = GADMWaterfallAppLovinBannerDelegate(parentRenderer: self)
    adView?.adLoadDelegate = appLovinDelegate
    adView?.adDisplayDelegate = appLovinDelegate
    adView?.adEventDelegate = appLovinDelegate

    if zoneIdentifier.count > 0 {
      sharedALSdk.adService.loadNextAd(
        forZoneIdentifier: zoneIdentifier,
        andNotify: appLovinDelegate
      )
    } else {
      sharedALSdk.adService.loadNextAd(appLovinAdSize, andNotify: appLovinDelegate)
    }
  }

  // MARK: - GADMediationBannerAd

  public var view: UIView {
    return adView ?? UIView()
  }

  // MARK: - Handle ad lifecycle events

  fileprivate func loadedAd(_ ad: ALAd) {
    GADMAdapterAppLovinUtils.log("Banner did load ad: \(ad)")
    adView?.render(ad)
    if let handler = adLoadCompletionHandler {
      delegate = handler(self, nil)
    }
  }

  fileprivate func failedToLoadAdWithError(_ code: Int32) {
    let error = GADMAdapterAppLovinUtils.sdkError(withCode: Int(code))
    _ = adLoadCompletionHandler?(nil, error)
  }

  fileprivate func displayedAdInView(_ view: UIView) {
    #if DEBUG
      assert(
        view == adView, "AppLovinAdapter: Received ad displayed callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner displayed")
    delegate?.reportImpression()
  }

  fileprivate func hidAdInView(_ view: UIView) {
    #if DEBUG
      assert(view == adView, "AppLovinAdapter: Received ad hidden callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner dismissed")
  }

  fileprivate func reportClickOnAdInView(_ view: UIView) {
    #if DEBUG
      assert(view == adView, "AppLovinAdapter: Received ad click callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner clicked")
    delegate?.reportClick()
  }

  fileprivate func didPresentFullscreenForAdView(_ adView: ALAdView) {
    #if DEBUG
      assert(
        adView == self.adView,
        "AppLovinAdapter: Received fullscreen present callback for an unexpected view"
      )
    #endif
    GADMAdapterAppLovinUtils.log("Banner presented fullscreen")
    delegate?.willPresentFullScreenView()
  }

  fileprivate func willDismissFullscreenForAdView(_ adView: ALAdView) {
    #if DEBUG
      assert(
        adView == self.adView,
        "AppLovinAdapter: Received will-dismiss-fullscreen callback for an unexpected view"
      )
    #endif
    GADMAdapterAppLovinUtils.log("Banner will dismiss fullscreen")
    delegate?.willDismissFullScreenView()
  }

  fileprivate func didDismissFullscreenForAdView(_ adView: ALAdView) {
    #if DEBUG
      assert(
        adView == self.adView,
        "AppLovinAdapter: Received did-dismiss-fullscreen callback for an unexpected view"
      )
    #endif
    GADMAdapterAppLovinUtils.log("Banner did dismiss fullscreen")
    delegate?.didDismissFullScreenView()
  }

  fileprivate func willLeaveApplicationForAdView(_ adView: ALAdView) {
    #if DEBUG
      assert(
        adView == self.adView,
        "AppLovinAdapter: Received will-leave-application callback for an unexpected view"
      )
    #endif
    GADMAdapterAppLovinUtils.log("Banner left application")
  }

  fileprivate func didFailToDisplayInAdView(
    _ adView: ALAdView,
    withError code: ALAdViewDisplayErrorCode
  ) {
    #if DEBUG
      assert(
        adView == self.adView,
        "AppLovinAdapter: Received display failure callback for an unexpected view"
      )
    #endif
    GADMAdapterAppLovinUtils.log("Banner failed to display: \(code.rawValue)")
    delegate?.didFailToPresentWithError(GADMAdapterAppLovinUtils.sdkError(withCode: code.rawValue))
  }
}

// MARK: - Private Delegate Class

private class GADMWaterfallAppLovinBannerDelegate:
  NSObject, ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate
{
  private weak var parentRenderer: GADMWaterfallAppLovinBannerRenderer?

  init(parentRenderer: GADMWaterfallAppLovinBannerRenderer) {
    self.parentRenderer = parentRenderer
    super.init()
  }

  // MARK: - Ad Load Delegate

  func adService(_ adService: ALAdService, didLoad ad: ALAd) {
    parentRenderer?.loadedAd(ad)
  }

  func adService(_ adService: ALAdService, didFailToLoadAdWithError code: Int32) {
    parentRenderer?.failedToLoadAdWithError(code)
  }

  // MARK: - Ad Display Delegate

  func ad(_ ad: ALAd, wasDisplayedIn view: UIView) {
    parentRenderer?.displayedAdInView(view)
  }

  func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
    parentRenderer?.hidAdInView(view)
  }

  func ad(_ ad: ALAd, wasClickedIn view: UIView) {
    parentRenderer?.reportClickOnAdInView(view)
  }

  // MARK: - Ad View Event Delegate

  func ad(_ ad: ALAd, didPresentFullscreenFor adView: ALAdView) {
    parentRenderer?.didPresentFullscreenForAdView(adView)
  }

  func ad(_ ad: ALAd, willDismissFullscreenFor adView: ALAdView) {
    parentRenderer?.willDismissFullscreenForAdView(adView)
  }

  func ad(_ ad: ALAd, didDismissFullscreenFor adView: ALAdView) {
    parentRenderer?.didDismissFullscreenForAdView(adView)
  }

  func ad(_ ad: ALAd, willLeaveApplicationFor adView: ALAdView) {
    parentRenderer?.willLeaveApplicationForAdView(adView)
  }

  func ad(
    _ ad: ALAd,
    didFailToDisplayIn adView: ALAdView,
    withError code: ALAdViewDisplayErrorCode
  ) {
    parentRenderer?.didFailToDisplayInAdView(adView, withError: code)
  }
}
