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

import HyBid

/*
 * Swift code snippets for
 * https://developers.google.com/admob/ios/mediation/verve and
 * https://developers.google.com/ad-manager/mobile-ads-sdk/ios/mediation/verve
 */
private final class VerveMediationSwiftSnippets {

  /// Placeholder value for a user's US privacy string.
  private let usPrivacyString = "TODO: Obtain US_PRIVACY_STRING from your CMP"

  private func setIABUSPrivacyString() {
    // [START set_iab_us_privacy_string]
    HyBidUserDataManager.sharedInstance().setIABUSPrivacyString(usPrivacyString)
    // [END set_iab_us_privacy_string]
  }

}
