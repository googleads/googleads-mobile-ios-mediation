//
//  Copyright (C) 2025 Google, Inc.
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

import FBAudienceNetwork
import GoogleMobileAds
import MetaAdapter

/*
 * Swift code snippets for
 * https://developers.google.com/admob/ios/mediation/meta and
 * https://developers.google.com/ad-manager/mobile-ads-sdk/ios/mediation/meta
 */
private class MetaMediationSwiftSnippets {

  private func setAdvertiserTracking() {
    // [START set_advertiser_tracking]
    // Set the flag as true.
    FBAdSettings.setAdvertiserTrackingEnabled(true)
    // [END set_advertiser_tracking]
  }

  private func socialContext(from nativeAd: NativeAd) -> String? {
    // [START get_social_context]
    let socialContext = nativeAd.extraAssets?[GADFBSocialContext] as? String
    // [END get_social_context]
    return socialContext
  }

}
