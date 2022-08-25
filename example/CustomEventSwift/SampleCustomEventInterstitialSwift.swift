//
// Copyright (C) 2017 Google, Inc.
//
// SampleCustomEventInterstitialSwift.swift
// Mediation Example
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import GoogleMobileAds
import SampleAdSDK

class SampleCustomEventInterstitialSwift: NSObject, GADMediationInterstitialAd {

  /// The Sample Ad Network interstitial.
  var interstitial: SampleInterstitial?

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  var delegate: GADMediationInterstitialAdEventDelegate?

  var completionHandler: GADMediationInterstitialLoadCompletionHandler?

  required override init() {
    super.init()
  }

  func loadInterstitial(
    for adConfiguration: GADMediationInterstitialAdConfiguration,
    completionHandler: @escaping GADMediationInterstitialLoadCompletionHandler
  ) {
    interstitial = SampleInterstitial.init(
      adUnitID: adConfiguration.credentials.settings["parameter"] as? String)
    interstitial?.delegate = self
    let adRequest = SampleAdRequest()
    adRequest.testMode = adConfiguration.isTestRequest
    self.completionHandler = completionHandler
    interstitial?.fetchAd(adRequest)
  }

  func present(from viewController: UIViewController) {
    if let interstitial = interstitial, interstitial.isInterstitialLoaded {
      interstitial.show()
    }
  }
}

extension SampleCustomEventInterstitialSwift: SampleInterstitialAdDelegate {

  func interstitialDidLoad(_ interstitial: SampleInterstitial) {
    if let handler = completionHandler {
      delegate = handler(self, nil)
    }
  }

  func interstitial(
    _ interstitial: SampleInterstitial, didFailToLoadAdWith errorCode: SampleErrorCode
  ) {
    let error = SampleCustomEventUtilsSwift.SampleCustomEventErrorWithCodeAndDescription(
      code: SampleCustomEventErrorCodeSwift.SampleCustomEventErrorAdLoadFailureCallback,
      description: "Sample SDK returned an ad load failure callback with error code: \(errorCode)")
    if let handler = completionHandler {
      delegate = handler(nil, error)
    }
  }

  func interstitialWillPresentScreen(_ interstitial: SampleInterstitial) {
    delegate?.willPresentFullScreenView()
    delegate?.reportImpression()
  }

  func interstitialWillDismissScreen(_ interstitial: SampleInterstitial) {
    delegate?.willDismissFullScreenView()
  }

  func interstitialDidDismissScreen(_ interstitial: SampleInterstitial) {
    delegate?.didDismissFullScreenView()
  }

  func interstitialWillLeaveApplication(_ interstitial: SampleInterstitial) {
    delegate?.reportClick()
  }
}
