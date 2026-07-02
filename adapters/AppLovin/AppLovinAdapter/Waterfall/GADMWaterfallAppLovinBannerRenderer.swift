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
@objc(GADMWaterfallAppLovinBannerRenderer)
/// Renderer for AppLovin waterfall banner ad. Loads a banner ad and handles ad lifecycle events.
public class GADMWaterfallAppLovinBannerRenderer: NSObject, MediationBannerAd {

  private let adConfiguration: MediationBannerAdConfiguration
  private var adLoadCompletionHandler: GADMediationBannerLoadCompletionHandler?
  private var zoneIdentifier: String?
  /// The loaded AppLovin banner ad view. This backing property is marked `nonisolated(unsafe)`
  /// so that it can be safely returned from the SDK's non-isolated `view` computed property.
  /// It is only mutated on the Main Actor during ad loading.
  nonisolated(unsafe) private var adView: ALAdView?

  /// A placeholder view returned if `view` is queried before the ad loads. Since UIKit initializers
  /// are isolated to MainActor, this is pre-allocated on init and returned as an immutable reference.
  /// The Google Mobile Ads SDK should never call `view` before the ad is loaded, but this is kept
  /// as a defensive measure.
  nonisolated(unsafe) private let dummyView: UIView
  private weak var delegate: MediationBannerAdEventDelegate?
  private var loadAlreadyStarted = false

  @objc public init(adConfiguration: MediationBannerAdConfiguration) {
    self.adConfiguration = adConfiguration
    self.dummyView = UIView()
    super.init()
  }

  @objc public func loadAd(
    withCompletion completion: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    #if DEBUG
      assert(!loadAlreadyStarted, "Trying to load a new ad while already loading/loaded one")
      loadAlreadyStarted = true
    #endif

    var completionHandlerCalled = false
    adLoadCompletionHandler = { ad, error in
      if completionHandlerCalled { return nil }
      completionHandlerCalled = true
      return completion(ad, error)
    }

    guard let sharedALSdk = ALSdk.shared() as ALSdk? else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .appLovinSDKNotInitialized,
        description: "AppLovin SDK not initialized."
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    zoneIdentifier = GADMAdapterAppLovinUtils.zoneIdentifier(forAdConfiguration: adConfiguration)
    guard let zoneIdentifier = zoneIdentifier else {
      let errorString = "Invalid custom zone entered. Please double-check your credentials."
      let error = GADMAdapterAppLovinUtils.error(
        withCode: GADMAdapterAppLovinErrorCode.invalidServerParameters,
        description: errorString
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    let adSize = adConfiguration.adSize
    GADMAdapterAppLovinUtils.log(
      "NEW API: Requesting banner of size \(string(for: adSize)) for zone: \(zoneIdentifier)."
    )

    guard let appLovinAdSize = GADMAdapterAppLovinUtils.appLovinAdSize(fromRequestedSize: adSize)
    else {
      let errorMessage =
        "Adapter requested to display a banner ad of unsupported size: \(string(for: adSize))"
      let error = GADMAdapterAppLovinUtils.error(
        withCode: GADMAdapterAppLovinErrorCode.bannerSizeMismatch,
        description: errorMessage
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    let adView = GADMediationAdapterAppLovin.createAdView(with: sharedALSdk, size: appLovinAdSize)
    let size = cgSize(for: adSize)
    adView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

    let appLovinDelegate = GADMWaterfallAppLovinBannerDelegate(parentRenderer: self)
    adView.adLoadDelegate = appLovinDelegate
    adView.adDisplayDelegate = appLovinDelegate
    adView.adEventDelegate = appLovinDelegate
    self.adView = adView

    if zoneIdentifier.isEmpty {
      sharedALSdk.adService.loadNextAd(appLovinAdSize, andNotify: appLovinDelegate)
    } else {
      sharedALSdk.adService.loadNextAd(
        forZoneIdentifier: zoneIdentifier, andNotify: appLovinDelegate)
    }
  }

  // MARK: - MediationBannerAd
  /// Conforms to GADMediationBannerAd. The view property is accessed non-isolatedly by the
  /// Google Mobile Ads SDK.
  nonisolated public var view: UIView {
    return (adView as UIView?) ?? dummyView
  }

  // MARK: - Ad Lifecycle Events
  /// These events are expected to be invoked by AppLovin's delegate (i.e.
  /// GADMWaterfallAppLovinBannerDelegate).
  fileprivate func loadedAd(_ ad: ALAd) {
    GADMAdapterAppLovinUtils.log("Banner did load ad: \(ad)")
    adView?.render(ad)
    delegate = adLoadCompletionHandler?(self, nil)
  }

  fileprivate func failedToLoadAdWithError(_ code: Int32) {
    let error = GADMAdapterAppLovinUtils.sdkError(withCode: Int(code))
    _ = adLoadCompletionHandler?(nil, error)
  }

  fileprivate func displayedAdInView(_ view: UIView) {
    #if DEBUG
      assert(
        view === adView as UIView?,
        "AppLovinAdapter: Received ad displayed callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner displayed")
    delegate?.reportImpression()
  }

  fileprivate func hidAdInView(_ view: UIView) {
    #if DEBUG
      assert(
        view === adView as UIView?,
        "AppLovinAdapter: Received ad hidden callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner dismissed")
    // There is no callback on GMA SDK for banner ad dismissal.
  }

  fileprivate func reportClickOnAdInView(_ view: UIView) {
    #if DEBUG
      assert(
        view === adView as UIView?,
        "AppLovinAdapter: Received ad click callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner clicked")
    delegate?.reportClick()
  }

  fileprivate func didPresentFullscreenForAdView(_ adView: ALAdView) {
    #if DEBUG
      assert(
        adView === self.adView,
        "AppLovinAdapter: Received fullscreen present callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner presented fullscreen")
    // Call willPresentFullScreenView. We don't get an earlier callback from AppLovin on banner view
    // presenting fullscreen and so this is the earliest we can call willPresentFullScreenView. There
    // is no corresponding callback on GMA SDK for didPresentFullscreenForAdView.
    delegate?.willPresentFullScreenView()
  }

  fileprivate func willDismissFullscreenForAdView(_ adView: ALAdView) {
    #if DEBUG
      assert(
        adView === self.adView,
        "AppLovinAdapter: Received will-dismiss-fullscreen callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner will dismiss fullscreen")
    delegate?.willDismissFullScreenView()
  }

  fileprivate func didDismissFullscreenForAdView(_ adView: ALAdView) {
    #if DEBUG
      assert(
        adView === self.adView,
        "AppLovinAdapter: Received did-dismiss-fullscreen callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner did dismiss fullscreen")
    delegate?.didDismissFullScreenView()
  }

  fileprivate func willLeaveApplicationForAdView(_ adView: ALAdView) {
    #if DEBUG
      assert(
        adView === self.adView,
        "AppLovinAdapter: Received will-leave-application callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner left application")
    // There is no corresponding callback on GMA SDK for willLeaveApplicationForAdView.
  }

  fileprivate func didFailToDisplayInAdView(
    _ adView: ALAdView, withError code: ALAdViewDisplayErrorCode
  ) {
    #if DEBUG
      assert(
        adView === self.adView,
        "AppLovinAdapter: Received display failure callback for an unexpected view")
    #endif
    GADMAdapterAppLovinUtils.log("Banner failed to display: \(code.rawValue)")
    let error = GADMAdapterAppLovinUtils.sdkError(withCode: Int(code.rawValue))
    delegate?.didFailToPresentWithError(error)
  }
}

// MARK: - Private Delegate Wrapper
/// Delegate for handling AppLovin banner ad events. AppLovin's delegate protocols are
/// implemented in a separate class to avoid a retain cycle, as the AppLovin SDK keeps a strong
/// reference to its delegate.
@MainActor
private class GADMWaterfallAppLovinBannerDelegate: NSObject, @preconcurrency ALAdLoadDelegate,
  @preconcurrency ALAdDisplayDelegate, @preconcurrency ALAdViewEventDelegate
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
