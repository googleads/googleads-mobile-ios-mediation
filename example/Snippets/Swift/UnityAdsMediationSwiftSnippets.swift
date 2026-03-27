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

import GoogleMobileAds
import UnityAds

/// Swift code snippets for
/// https://developers.google.com/admob/ios/mediation/unity and
/// https://developers.google.com/ad-manager/mobile-ads-sdk/ios/mediation/unity
private class UnityAdsMediationSwiftSnippets {

  private func setGDPRConsent() {
    // [START set_gdpr_meta_data]
    let gdprMetaData = UADSMetaData()
    gdprMetaData.set("gdpr.consent", value: true)
    gdprMetaData.commit()
    // [END set_gdpr_meta_data]
  }

  private func setPrivacyConsent() {
    // [START set_ccpa_meta_data]
    let ccpaMetaData = UADSMetaData()
    ccpaMetaData.set("privacy.consent", value: true)
    ccpaMetaData.commit()
    // [END set_ccpa_meta_data]
  }

}
