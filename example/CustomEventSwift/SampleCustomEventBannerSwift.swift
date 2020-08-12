//
// Copyright (C) 2017 Google, Inc.
//
// SampleCustomEventBannerSwift.swift
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

@objc class SampleCustomEventBannerSwift: NSObject, GADCustomEventBanner {

  /// The Sample Ad Network banner.
  var bannerAd: SampleBanner?
  var delegate: GADCustomEventBannerDelegate?

  required override init() {
    super.init()
  }

  func requestAd(
    _ adSize: GADAdSize,
    parameter serverParameter: String?,
    label serverLabel: String?,
    request: GADCustomEventRequest
  ) {

    // Create the bannerView with the appropriate size.
    bannerAd = SampleBanner(
      frame: CGRect(x: 0, y: 0, width: adSize.size.width, height: adSize.size.height))
    bannerAd?.delegate = self
    bannerAd?.adUnit = serverParameter
    let adRequest = SampleAdRequest()
    adRequest.testMode = request.isTesting
    adRequest.keywords = request.userKeywords as? [String]
    bannerAd?.fetchAd(adRequest)
  }
}

extension SampleCustomEventBannerSwift: SampleBannerAdDelegate {

  func bannerDidLoad(_ banner: SampleBanner) {
    delegate?.customEventBanner(self, didReceiveAd: banner)
  }

  func banner(_ banner: SampleBanner, didFailToLoadAdWith errorCode: SampleErrorCode) {
    let error = NSError(domain: customEventErrorDomain, code: errorCode.rawValue, userInfo: nil)
    delegate?.customEventBanner(self, didFailAd: error)
  }

  func bannerWillLeaveApplication(_ banner: SampleBanner) {
    delegate?.customEventBannerWasClicked(self)
    delegate?.customEventBannerWillLeaveApplication(self)
  }
}
