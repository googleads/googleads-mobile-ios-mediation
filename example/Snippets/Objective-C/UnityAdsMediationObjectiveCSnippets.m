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

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <UnityAds/UnityAds.h>

@interface UnityAdsMediationObjectiveCSnippets : NSObject
@end

/**
 * Objective-C code snippets for
 * https://developers.google.com/admob/ios/mediation/unity and
 * https://developers.google.com/ad-manager/mobile-ads-sdk/ios/mediation/unity
 */
@implementation UnityAdsMediationObjectiveCSnippets

- (void)setGDPRConsent {
  // [START set_gdpr_meta_data]
  UADSMetaData *gdprMetaData = [[UADSMetaData alloc] init];
  [gdprMetaData set:@"gdpr.consent" value:@YES];
  [gdprMetaData commit];
  // [END set_gdpr_meta_data]
}

- (void)setPrivacyConsent {
  // [START set_ccpa_meta_data]
  UADSMetaData *ccpaMetaData = [[UADSMetaData alloc] init];
  [ccpaMetaData set:@"privacy.consent" value:@YES];
  [ccpaMetaData commit];
  // [END set_ccpa_meta_data]
}

@end
