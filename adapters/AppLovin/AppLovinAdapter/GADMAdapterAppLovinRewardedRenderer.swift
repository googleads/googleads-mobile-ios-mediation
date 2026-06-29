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
/// Renderer for AppLovin waterfall rewarded ad. Loads a rewarded ad and handles ad lifecycle events.
@objc(GADMAdapterAppLovinRewardedRenderer)
public class GADMAdapterAppLovinRewardedRenderer: NSObject, @preconcurrency MediationRewardedAd {

  /// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
  @objc public var adLoadCompletionHandler: GADMediationRewardedLoadCompletionHandler?

  /// Delegate to notify the Google Mobile Ads SDK of rewarded presentation events.
  // These properties are accessed inside the non-isolated present(from:) method.
  // Although marked nonisolated(unsafe), they are safe because they are only set/mutated
  // during initialization/loading and read during presentation.
  @objc nonisolated(unsafe) public weak var delegate: MediationRewardedAdEventDelegate?
  @objc nonisolated(unsafe) public var ad: ALAd?

  /// The AppLovin zone identifier used to load an ad.
  @objc public let zoneIdentifier: String?

  /// The AdMob UI settings.
  @objc public let settings: [String: Any]

  /// Data used to render a rewarded ad.
  private let adConfiguration: MediationRewardedAdConfiguration

  /// Delegate to get notified by the AppLovin SDK of rewarded presentation events.
  nonisolated(unsafe) private var appLovinDelegate: GADMAppLovinRewardedDelegate?

  /// AppLovin incentivized interstitial ad object used to load an ad.
  nonisolated(unsafe) private var incent: ALIncentivizedInterstitialAd?

  @objc public init(
    adConfiguration: MediationRewardedAdConfiguration,
    completionHandler: @escaping GADMediationRewardedLoadCompletionHandler
  ) {
    self.adConfiguration = adConfiguration
    self.settings = (adConfiguration.credentials.settings as? [String: Any]) ?? [:]
    self.zoneIdentifier = GADMAdapterAppLovinUtils.zoneIdentifier(
      forAdConfiguration: adConfiguration)
    super.init()

    var completionHandlerCalled = false
    adLoadCompletionHandler = { [weak self] ad, error in
      if completionHandlerCalled { return nil }
      completionHandlerCalled = true
      return completionHandler(ad, error)
    }
  }

  /// Request a rewarded ad from AppLovin SDK.
  @objc public func requestRewardedAd() {
    guard let sharedALSdk = ALSdk.shared() as ALSdk? else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: .appLovinSDKNotInitialized,
        description: "AppLovin SDK not initialized."
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }
    sharedALSdk.settings.isMuted = MobileAds.shared.isApplicationMuted

    appLovinDelegate = GADMAppLovinRewardedDelegate(parentRenderer: self)

    // Create rewarded video object.
    incent = GADMediationAdapterAppLovin.createIncentivizedInterstitialAd(with: sharedALSdk)
    incent?.setExtraInfoForKey("google_watermark", value: adConfiguration.watermark)

    incent?.adDisplayDelegate = appLovinDelegate
    incent?.adVideoPlaybackDelegate = appLovinDelegate

    if let bidResponse = adConfiguration.bidResponse {
      sharedALSdk.adService.loadNextAd(forAdToken: bidResponse, andNotify: appLovinDelegate!)
      return
    }

    guard let zoneIdentifier else {
      let errorString = "Invalid custom zone entered. Please double-check your credentials."
      let error = GADMAdapterAppLovinUtils.error(
        withCode: GADMAdapterAppLovinErrorCode.invalidServerParameters,
        description: errorString
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    let sharedManager = GADMAdapterAppLovinMediationManager.sharedInstance
    if sharedManager.containsAndAddRewardedZoneIdentifier(zoneIdentifier) {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: GADMAdapterAppLovinErrorCode.adAlreadyLoaded,
        description:
          "Can't request a second ad for the same zone identifier without showing the first ad."
      )
      _ = adLoadCompletionHandler?(nil, error)
      return
    }

    GADMAdapterAppLovinUtils.log("Requesting rewarded ad for zone: \(zoneIdentifier)")

    if zoneIdentifier == GADMAdapterAppLovinDefaultZoneIdentifier {
      incent?.preloadAndNotify(appLovinDelegate!)
    } else {
      sharedALSdk.adService.loadNextAd(
        forZoneIdentifier: zoneIdentifier, andNotify: appLovinDelegate!)
    }
  }

  // MARK: - MediationRewardedAd
  // Satisfies the non-isolated requirement from MediationRewardedAd protocol.
  // The caller (Google Mobile Ads SDK) is guaranteed to execute this method on the Main Thread.
  nonisolated public func present(from viewController: UIViewController) {
    if let ad {
      GADMAdapterAppLovinUtils.log("Showing rewarded video for zone: \(zoneIdentifier ?? "")")
      incent?.show(ad, andNotify: appLovinDelegate!)
    } else {
      let error = GADMAdapterAppLovinUtils.error(
        withCode: GADMAdapterAppLovinErrorCode.show,
        description: "Attempting to show rewarded video before one was loaded"
      )
      delegate?.didFailToPresentWithError(error)
    }
  }

  deinit {
    GADMAdapterAppLovinMediationManager.sharedInstance.removeRewardedZoneIdentifier(
      zoneIdentifier ?? "")
  }
}
