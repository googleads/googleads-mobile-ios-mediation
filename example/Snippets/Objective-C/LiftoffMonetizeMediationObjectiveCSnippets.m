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
#import <LiftoffMonetizeAdapter/VungleAdapter.h>
#import <VungleAdsSDK/VungleAdsSDK.h>

@interface LiftoffMonetizeMediationObjectiveCSnippets : NSObject
@end

/**
 * Objective-C code snippets for
 * https://developers.google.com/admob/ios/mediation/liftoff-monetize and
 * https://developers.google.com/ad-manager/mobile-ads-sdk/ios/mediation/liftoff-monetize
 */
@implementation LiftoffMonetizeMediationObjectiveCSnippets

- (void)setCCPAStatus {
  // [START set_ccpa_status]
  [VunglePrivacySettings setCCPAStatus:YES];
  // [END set_ccpa_status]
}

- (void)setNetworkSpecificParams {
  // [START set_network_specific_params]
  GADRequest *adRequest = [GADRequest request];
  VungleAdNetworkExtras *extras = [[VungleAdNetworkExtras alloc] init];
  extras.userId = @"myUserID";
  extras.nativeAdOptionPosition = GADAdChoicesPositionTopRightCorner;
  // ...
  [adRequest registerAdNetworkExtras:extras];
  // [END set_network_specific_params]
}

@end