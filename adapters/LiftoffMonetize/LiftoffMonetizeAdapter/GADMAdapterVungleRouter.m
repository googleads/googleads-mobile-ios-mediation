// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterVungleRouter.h"
#import <VungleAdsSDK/VungleAdsSDK.h>
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleUtils.h"

@implementation GADMAdapterVungleRouter {
}

+ (nonnull GADMAdapterVungleRouter *)sharedInstance {
  static GADMAdapterVungleRouter *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[GADMAdapterVungleRouter alloc] init];
  });
  return instance;
}

- (void)initWithAppId:(nonnull NSString *)appId
             delegate:(nullable id<GADMAdapterVungleDelegate>)delegate {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSString *version = [GADMAdapterVungleVersion stringByReplacingOccurrencesOfString:@"."
                                                                            withString:@"_"];
    [VungleAds setIntegrationName:@"admob" version:version];
  });
  if ([VungleAds isInitialized]) {
    [delegate initialized:YES error:nil];
    return;
  }

  // Liftoff Monetize requires COPPA status to be set before initializing the SDK.
  // https://support.vungle.com/hc/en-us/articles/360048572411-Advanced-Settings#h_01JV5D5KQRJR1C6EJ59X4914E6
  [self updateVungleCOPPAStatusIfNeeded];
  [VungleAds initWithAppId:appId
                completion:^(NSError *_Nullable error) {
                  [delegate initialized:error == nil error:error];
                }];
}

/// Updates |VunglePrivacySettings| using Google Mobile Ads tag for child treatment and tag for
/// under age consent.
- (void)updateVungleCOPPAStatusIfNeeded {
  NSNumber *tagForChildDirectedTreatment =
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment;
  NSNumber *tagForUnderAgeOfConsent =
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent;
  if ([tagForChildDirectedTreatment isEqual:@YES] || [tagForUnderAgeOfConsent isEqual:@YES]) {
    [VunglePrivacySettings setCOPPAStatus:YES];
  } else if ([tagForChildDirectedTreatment isEqual:@NO] || [tagForUnderAgeOfConsent isEqual:@NO]) {
    [VunglePrivacySettings setCOPPAStatus:NO];
  }
}

@end
