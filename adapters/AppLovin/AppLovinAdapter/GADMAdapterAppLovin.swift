// Copyright 2018 Google LLC
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
import UIKit

@MainActor
@objc(GADMAdapterAppLovin)
public final class GADMAdapterAppLovin: NSObject, @preconcurrency MediationAdNetworkAdapter {

  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  public weak var connector: (any MediationAdNetworkConnector)?

  /// An AppLovin interstitial ad.
  public var interstitialAd: ALAd?

  /// An AppLovin banner ad view.
  public private(set) var adView: ALAdView?

  /// The AppLovin zone identifier used to load an ad.
  public private(set) var zoneIdentifier: String?

  /// The AdMob UI settings.
  public private(set) var settings: [AnyHashable: Any] = [:]

  /// AppLovin interstitial object used to request an ad.
  private var interstitial: ALInterstitialAd?

  /// AppLovin interstitial delegate wrapper.
  private var interstitialDelegate: GADMAdapterAppLovinInterstitialDelegate?

  /// AppLovin banner delegate wrapper.
  private var bannerDelegate: GADMAdapterAppLovinBannerDelegate?

  @objc public init(gadmAdNetworkConnector connector: any MediationAdNetworkConnector) {
    self.connector = connector
    super.init()
  }

  @objc public static func adapterVersion() -> String {
    return GADMAdapterAppLovinConstant.adapterVersion
  }

  @objc public static func networkExtrasClass() -> any AdNetworkExtras.Type {
    return GADMAdapterAppLovinExtras.self
  }

  @objc public func stopBeingDelegate() {
    if interstitial != nil {
      GADMAdapterAppLovinMediationManager.sharedInstance.removeInterstitialZoneIdentifier(
        zoneIdentifier ?? ""
      )
    }

    if let interstitial {
      interstitial.adDisplayDelegate = nil
      interstitial.adVideoPlaybackDelegate = nil
    }
    interstitial = nil
    connector = nil
    interstitialDelegate = nil
    bannerDelegate = nil

    if let adView {
      adView.adLoadDelegate = nil
      adView.adDisplayDelegate = nil
      adView.adEventDelegate = nil
    }
    adView = nil
  }

  @objc public func getInterstitial() {
    let credentials = connector?.credentials() ?? [:]
    guard let sdkKey = GADMAdapterAppLovinUtils.retrieveSDKKey(fromCredentials: credentials) else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .missingSDKKey,
        description: "AppLovin SDK Key is missing."
      )
      connector?.adapter(self, didFailAd: error)
      return
    }
    GADMAdapterAppLovinInitializer.initialize(withSDKKey: sdkKey) { [weak self] in
      guard let self else { return }
      self.loadInterstitial()
    }
  }

  private func loadInterstitial() {
    guard let connector else { return }

    if GADMAdapterAppLovinUtils.isChildUser() {
      connector.adapter(self, didFailAd: GADMAdapterAppLovinUtils.childUserError())
      return
    }

    let sharedSdk = ALSdk.shared()

    zoneIdentifier = GADMAdapterAppLovinUtils.zoneIdentifier(forConnector: connector)
    // Unable to resolve a valid zone - error out
    guard let zoneIdentifier else {
      let errorString = "Invalid custom zone entered. Please double-check your credentials."
      let zoneIdentifierError = GADMAdapterAppLovinUtils.error(
        withCode: .invalidServerParameters,
        description: errorString
      )
      connector.adapter(self, didFailAd: zoneIdentifierError)
      return
    }

    GADMAdapterAppLovinUtils.log("Requesting interstitial for zone: \(zoneIdentifier)")

    let sharedManager = GADMAdapterAppLovinMediationManager.sharedInstance
    if sharedManager.containsAndAddInterstitialZoneIdentifier(zoneIdentifier) {
      let adAlreadyLoadedError = GADMAdapterAppLovinUtils.error(
        withCode: .adAlreadyLoaded,
        description: "Can't request a second ad for the same zone identifier without showing "
          + "the first ad."
      )
      connector.adapter(self, didFailAd: adAlreadyLoadedError)
      return
    }

    let delegate = GADMAdapterAppLovinInterstitialDelegate(parentRenderer: self)
    interstitialDelegate = delegate
    sharedSdk.settings.isMuted = MobileAds.shared.isApplicationMuted
    interstitial = ALInterstitialAd(sdk: sharedSdk)
    interstitial?.adDisplayDelegate = delegate
    interstitial?.adVideoPlaybackDelegate = delegate
    settings = connector.credentials() ?? [:]

    if !zoneIdentifier.isEmpty {
      sharedSdk.adService.loadNextAd(
        forZoneIdentifier: zoneIdentifier,
        andNotify: delegate
      )
    } else {
      sharedSdk.adService.loadNextAd(ALAdSize.interstitial, andNotify: delegate)
    }
  }

  @objc public func presentInterstitial(from rootViewController: UIViewController) {
    GADMAdapterAppLovinUtils.log("Showing interstitial ad for zone: \(zoneIdentifier ?? "").")
    guard let interstitialAd else {
      GADMAdapterAppLovinUtils.log("No ad to show.")
      return
    }
    interstitial?.show(interstitialAd)
  }

  @objc public func getBanner(with adSize: AdSize) {
    let credentials = connector?.credentials() ?? [:]
    guard let sdkKey = GADMAdapterAppLovinUtils.retrieveSDKKey(fromCredentials: credentials) else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .missingSDKKey,
        description: "AppLovin SDK Key is missing."
      )
      connector?.adapter(self, didFailAd: error)
      return
    }
    GADMAdapterAppLovinInitializer.initialize(withSDKKey: sdkKey) { [weak self] in
      guard let self else { return }
      self.loadBanner(with: adSize)
    }
  }

  private func loadBanner(with adSize: AdSize) {
    guard let connector else { return }

    if GADMAdapterAppLovinUtils.isChildUser() {
      connector.adapter(self, didFailAd: GADMAdapterAppLovinUtils.childUserError())
      return
    }

    let sharedSdk = ALSdk.shared()

    zoneIdentifier = GADMAdapterAppLovinUtils.zoneIdentifier(forConnector: connector)
    // Unable to resolve a valid zone - error out.
    guard let zoneIdentifier else {
      let errorString = "Invalid custom zone entered. Please double-check your credentials."
      let zoneIdentifierError = GADMAdapterAppLovinUtils.error(
        withCode: .invalidServerParameters,
        description: errorString
      )
      connector.adapter(self, didFailAd: zoneIdentifierError)
      return
    }

    GADMAdapterAppLovinUtils.log(
      "Requesting banner of size \(string(for: adSize)) for zone: \(zoneIdentifier)."
    )

    // Convert requested size to AppLovin Ad Size.
    let appLovinAdSize = GADMAdapterAppLovinUtils.appLovinAdSize(fromRequestedSize: adSize)

    guard let appLovinAdSize else {
      let errorMessage = "Adapter requested to display a banner ad of unsupported size: \(adSize)"
      let adSizeError = GADMAdapterAppLovinUtils.error(
        withCode: .bannerSizeMismatch,
        description: errorMessage
      )
      connector.adapter(self, didFailAd: adSizeError)
      return
    }

    adView = ALAdView(sdk: sharedSdk, size: appLovinAdSize)

    let size = cgSize(for: adSize)
    adView?.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)

    let delegate = GADMAdapterAppLovinBannerDelegate(parentAdapter: self)
    bannerDelegate = delegate
    adView?.adLoadDelegate = delegate
    adView?.adDisplayDelegate = delegate
    adView?.adEventDelegate = delegate

    if !zoneIdentifier.isEmpty {
      sharedSdk.adService.loadNextAd(
        forZoneIdentifier: zoneIdentifier,
        andNotify: delegate
      )
    } else {
      sharedSdk.adService.loadNextAd(appLovinAdSize, andNotify: delegate)
    }
  }

  @objc public func isBannerAnimationOK(_ animationType: MediationBannerAnimationType) -> Bool {
    return true
  }
}
