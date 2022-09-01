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
import UIKit

@objc class SampleCustomEventBannerSwift: NSObject, GADMediationBannerAd {

  /// The Sample Ad Network banner.
  var bannerAd: SampleBanner?

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  var delegate: GADMediationBannerAdEventDelegate?

  /// Completion handler called after ad load
  var completionHandler: GADMediationBannerLoadCompletionHandler?

  var view: UIView {
    return
      bannerAd ?? UIView()
  }

  required override init() {
    super.init()
  }

  func loadBanner(
    for adConfiguration: GADMediationBannerAdConfiguration,
    completionHandler: @escaping GADMediationBannerLoadCompletionHandler
  ) {
    // Create the bannerView with the appropriate size.
    let adSize = adConfiguration.adSize
    bannerAd = SampleBanner(
      frame: CGRect(x: 0, y: 0, width: adSize.size.width, height: adSize.size.height))
    bannerAd?.delegate = self
    bannerAd?.adUnit = adConfiguration.credentials.settings["parameter"] as? String
    let adRequest = SampleAdRequest()
    adRequest.testMode = adConfiguration.isTestRequest
    self.completionHandler = completionHandler
    bannerAd?.fetchAd(adRequest)
  }
}

extension SampleCustomEventBannerSwift: SampleBannerAdDelegate {

  func bannerDidLoad(_ banner: SampleBanner) {
    if let handler = completionHandler {
      delegate = handler(self, nil)
    }
  }

  func banner(_ banner: SampleBanner, didFailToLoadAdWith errorCode: SampleErrorCode) {
    let error = SampleCustomEventUtilsSwift.SampleCustomEventErrorWithCodeAndDescription(
      code: SampleCustomEventErrorCodeSwift.SampleCustomEventErrorAdLoadFailureCallback,
      description: "Sample SDK returned an ad load failure callback with error code: \(errorCode)")
    if let handler = completionHandler {
      delegate = handler(nil, error)
    }
  }

  func bannerWillLeaveApplication(_ banner: SampleBanner) {
    delegate?.reportClick()
  }
}
