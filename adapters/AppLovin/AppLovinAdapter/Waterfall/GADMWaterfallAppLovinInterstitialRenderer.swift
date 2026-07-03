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
/// Renderer for AppLovin waterfall interstitial ad. Loads an interstitial ad and handles ad lifecycle events.
@objc(GADMWaterfallAppLovinInterstitialRenderer)
public class GADMWaterfallAppLovinInterstitialRenderer: NSObject, MediationInterstitialAd {

  private let adConfiguration: MediationInterstitialAdConfiguration
  private var adLoadCompletionHandler: GADMediationInterstitialLoadCompletionHandler?
  // These properties are accessed inside the non-isolated present(from:) method.
  // Although marked nonisolated(unsafe), they are safe because they are only set
  // during initialization/loading and read during presentation.
  nonisolated(unsafe) private var zoneIdentifier: String?
  nonisolated(unsafe) private var interstitialAd: ALAd?
  private weak var delegate: MediationInterstitialAdEventDelegate?
  nonisolated(unsafe) private var interstitial: ALInterstitialAd?
  private var loadAlreadyStarted = false

  @objc public init(adConfiguration: MediationInterstitialAdConfiguration) {
    self.adConfiguration = adConfiguration
    super.init()
  }

  @objc public func loadAd(
    withCompletion completion: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    #if DEBUG
      assert(!loadAlreadyStarted, "Trying to load a new ad while already loading/loaded one")
      loadAlreadyStarted = true
    #endif

    var completionHandlerCalled = false
    adLoadCompletionHandler = { [weak self] ad, error in
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
    guard let zoneIdentifier else {
      let errorString = "Invalid custom zone entered. Please double-check your credentials."
      let error = GADMAdapterAppLovinUtils.error(
        withCode: GADMAdapterAppLovinErrorCode.invalidServerParameters,
        description: errorString
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    GADMAdapterAppLovinUtils.log("Requesting interstitial for zone: \(zoneIdentifier)")

    let adAlreadyLoaded = GADMAdapterAppLovinMediationManager.sharedInstance
      .containsAndAddInterstitialZoneIdentifier(zoneIdentifier)
    if adAlreadyLoaded {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: GADMAdapterAppLovinErrorCode.adAlreadyLoaded,
        description:
          "Can't request a second ad for the same zone identifier without showing the first ad."
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    // Set muted state.
    sharedALSdk.settings.isMuted = MobileAds.shared.isApplicationMuted
    interstitial = GADMediationAdapterAppLovin.createInterstitialAd(with: sharedALSdk)

    let interstitialDelegate = GADMWaterfallAppLovinInterstitialDelegate(parentRenderer: self)
    interstitial?.adDisplayDelegate = interstitialDelegate
    interstitial?.adVideoPlaybackDelegate = interstitialDelegate

    if zoneIdentifier.isEmpty {
      sharedALSdk.adService.loadNextAd(ALAdSize.interstitial, andNotify: interstitialDelegate)
    } else {
      sharedALSdk.adService.loadNextAd(
        forZoneIdentifier: zoneIdentifier, andNotify: interstitialDelegate)
    }
  }

  // MARK: - GADMediationInterstitialAd
  // Satisfies the non-isolated requirement from GADMediationInterstitialAd protocol.
  nonisolated public func present(from viewController: UIViewController) {
    GADMAdapterAppLovinUtils.log("Showing interstitial ad for zone: \(zoneIdentifier ?? "").")
    guard let interstitialAd else {
      GADMAdapterAppLovinUtils.log("No ad to show.")
      return
    }
    interstitial?.show(interstitialAd)
  }

  // MARK: - Ad Lifecycle Events
  fileprivate func loadedAd(_ ad: ALAd) {
    let isMultipleAdsEnabled = GADMAdapterAppLovinUtils.isMultipleAdsLoadingEnabled()
    if isMultipleAdsEnabled {
      GADMAdapterAppLovinMediationManager.sharedInstance.removeInterstitialZoneIdentifier(
        zoneIdentifier ?? "")
    }
    GADMAdapterAppLovinUtils.log("Interstitial did load ad: \(ad)")
    interstitialAd = ad
    delegate = adLoadCompletionHandler?(self, nil)
  }

  fileprivate func failedToLoadAdWithError(_ code: Int32) {
    GADMAdapterAppLovinMediationManager.sharedInstance.removeInterstitialZoneIdentifier(
      zoneIdentifier ?? "")
    let error = GADMAdapterAppLovinUtils.sdkError(withCode: Int(code))
    _ = adLoadCompletionHandler?(nil, error)
  }

  fileprivate func displayedAd(_ ad: ALAd) {
    #if DEBUG
      assert(
        ad == interstitialAd, "AppLovinAdapter: Received ad displayed callback for an unexpected ad"
      )
    #endif
    GADMAdapterAppLovinUtils.log("Interstitial ad displayed")
    delegate?.reportImpression()
    delegate?.willPresentFullScreenView()
  }

  fileprivate func hidAd(_ ad: ALAd) {
    #if DEBUG
      assert(
        ad == interstitialAd, "AppLovinAdapter: Received ad hidden callback for an unexpected ad")
    #endif
    GADMAdapterAppLovinUtils.log("Interstitial ad hidden")
    GADMAdapterAppLovinMediationManager.sharedInstance.removeInterstitialZoneIdentifier(
      zoneIdentifier ?? "")
    delegate?.willDismissFullScreenView()
    delegate?.didDismissFullScreenView()
  }

  fileprivate func reportClickOnAd(_ ad: ALAd) {
    #if DEBUG
      assert(
        ad == interstitialAd, "AppLovinAdapter: Received ad clicked callback for an unexpected ad")
    #endif
    GADMAdapterAppLovinUtils.log("Interstitial ad clicked")
    delegate?.reportClick()
  }
}

// MARK: - Private Delegate Wrapper
/// Delegate for handling AppLovin interstitial ad events. AppLovin's delegate protocols are
/// implemented in a separate class to avoid a retain cycle, as the AppLovin SDK keeps a strong
/// reference to its delegate.
@MainActor
private class GADMWaterfallAppLovinInterstitialDelegate: NSObject, @preconcurrency ALAdLoadDelegate,
  @preconcurrency ALAdDisplayDelegate, @preconcurrency ALAdVideoPlaybackDelegate
{

  private weak var parentRenderer: GADMWaterfallAppLovinInterstitialRenderer?

  init(parentRenderer: GADMWaterfallAppLovinInterstitialRenderer) {
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
    parentRenderer?.displayedAd(ad)
  }

  func ad(_ ad: ALAd, wasHiddenIn view: UIView) {
    parentRenderer?.hidAd(ad)
  }

  func ad(_ ad: ALAd, wasClickedIn view: UIView) {
    parentRenderer?.reportClickOnAd(ad)
  }

  // MARK: - Video Playback Delegate
  func videoPlaybackBegan(in ad: ALAd) {
    GADMAdapterAppLovinUtils.log("Interstitial video playback began")
  }

  func videoPlaybackEnded(
    in ad: ALAd, atPlaybackPercent percentPlayed: NSNumber, fullyWatched wasFullyWatched: Bool
  ) {
    GADMAdapterAppLovinUtils.log(
      "Interstitial video playback ended at playback percent: \(percentPlayed.uintValue)%")
  }
}
