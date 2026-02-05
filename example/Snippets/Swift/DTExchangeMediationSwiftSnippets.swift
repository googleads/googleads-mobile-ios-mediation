//
//  Copyright (C) 2026 Google LLC
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import DTExchangeAdapter
import GoogleMobileAds
import IASDKCore

/// Swift code snippets for
/// https://developers.google.com/admob/ios/mediation/dt-exchange and
/// https://developers.google.com/ad-manager/mobile-ads-sdk/ios/mediation/dt-exchange
private final class DTExchangeMediationSwiftSnippets {

  /// Placeholder value for a user's US privacy string.
  private let usPrivacyString = "TODO: Obtain US_PRIVACY_STRING from your CMP"

  private func setCCPAString() {
    // [START set_ccpa_string]
    IASDKCore.sharedInstance().ccpaString = usPrivacyString
    // [END set_ccpa_string]
  }

  private func setNetworkSpecificParameters() {
    // [START set_network_specific_parameters]
    let userData = IAUserData.build { builder in
      builder.age = 23
      builder.gender = IAUserGenderType.male
      builder.zipCode = "1234"
    }

    let request = Request()
    let extras = GADMAdapterFyberExtras()
    extras.userData = userData
    extras.muteAudio = true
    request.register(extras)
    // [END set_network_specific_parameters]
  }

}
