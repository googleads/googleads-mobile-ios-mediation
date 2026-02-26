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

#import <DTExchangeAdapter/DTExchangeAdapter.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IASDKCore/IASDKCore.h>

@interface DTExchangeMediationObjectiveCSnippets : NSObject
@end

/**
 * Objective-C code snippets for
 * https://developers.google.com/admob/ios/mediation/dt-exchange and
 * https://developers.google.com/ad-manager/mobile-ads-sdk/ios/mediation/dt-exchange
 */
@implementation DTExchangeMediationObjectiveCSnippets

/// Placeholder value for a user's US privacy string.
static NSString *const kUSPrivacyString = @"TODO: Obtain US_PRIVACY_STRING from your CMP";

- (void)setCCPAString {
  // [START set_ccpa_string]
  [[IASDKCore sharedInstance] setCCPAString:kUSPrivacyString];
  // [END set_ccpa_string]
}

- (void)setNetworkSpecificParameters {
  // [START set_network_specific_parameters]
  IAUserData *userData = [IAUserData build:^(id<IAUserDataBuilder> _Nonnull builder) {
    builder.age = 23;
    builder.gender = IAUserGenderTypeMale;
    builder.zipCode = @"1234";
  }];

  GADRequest *request = [GADRequest request];
  GADMAdapterFyberExtras *extras = [[GADMAdapterFyberExtras alloc] init];
  extras.userData = userData;
  extras.muteAudio = YES;
  [request registerAdNetworkExtras:extras];
  // [END set_network_specific_parameters]
}

@end
