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

/// Constant for Sample Ad Network custom event error domain.
private let customEventErrorDomain: String = "com.google.CustomEvent"

class SampleCustomEventInterstitialSwift: NSObject, GADCustomEventInterstitial {
  /// The Sample Ad Network interstitial.
  var interstitial: SampleInterstitial?
  var delegate: GADCustomEventInterstitialDelegate?

  func requestAd(withParameter serverParameter: String?,
                 label serverLabel: String?,
                 request: GADCustomEventRequest) {
    interstitial = SampleInterstitial.init(adUnitID: serverParameter)
    interstitial?.delegate = self
    let adRequest = SampleAdRequest()
    adRequest.testMode = request.isTesting
    adRequest.keywords = request.userKeywords as? [String]
    interstitial?.fetchAd(adRequest)
  }

  /// Present the interstitial ad as a modal view using the provided view controller.
  func present(fromRootViewController rootViewController: UIViewController) {
    if let interstitial = interstitial, interstitial.isInterstitialLoaded {
      interstitial.show()
    }
  }
}

extension SampleCustomEventInterstitialSwift: SampleInterstitialAdDelegate {

  func interstitialDidLoad(_ interstitial: SampleInterstitial) {
    delegate?.customEventInterstitialDidReceiveAd(self)
  }

  func interstitial(_ interstitial: SampleInterstitial, didFailToLoadAdWith errorCode: SampleErrorCode) {
    let error = NSError(domain: customEventErrorDomain, code: errorCode.rawValue, userInfo: nil)
    delegate?.customEventInterstitial(self, didFailAd: error)
  }

  func interstitialWillPresentScreen(_ interstitial: SampleInterstitial) {
    delegate?.customEventInterstitialWillPresent(self)
  }

  func interstitialWillDismissScreen(_ interstitial: SampleInterstitial) {
    delegate?.customEventInterstitialWillDismiss(self)
  }

  func interstitialDidDismissScreen(_ interstitial: SampleInterstitial) {
    delegate?.customEventInterstitialDidDismiss(self)
  }

  func interstitialWillLeaveApplication(_ interstitial: SampleInterstitial) {
    delegate?.customEventInterstitialWasClicked(self)
    delegate?.customEventInterstitialWillLeaveApplication(self)
  }
}
