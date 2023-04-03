// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMediationAdapterYahoo.h"
#import "GADMAdapterYahooConstants.h"
#import "GADMAdapterYahooRewardedAd.h"
#import "GADMAdapterYahooUtils.h"

@implementation GADMediationAdapterYahoo {
  GADMAdapterYahooRewardedAd *_rewardedAd;
}

#pragma mark - GADMediationAdapter

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if (YASAds.sharedInstance.isInitialized) {
    completionHandler(nil);
  }

  NSMutableSet *siteIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *siteID = cred.settings[GADMAdapterYahooDCN];
    GADMAdapterYahooMutableSetAddObject(siteIDs, siteID);
  }

  if (!siteIDs.count) {
    NSError *error = GADMAdapterYahooErrorWithCodeAndDescription(
        GADMAdapterYahooErrorInvalidServerParameters,
        @"Yahoo mediation configurations did not contain a valid Site ID.");
    completionHandler(error);
    return;
  }

  NSString *siteID = [siteIDs anyObject];
  if (siteIDs.count != 1) {
    NSLog(@"Found the following site IDs: %@. Please remove any site IDs you are not using from "
          @"the AdMob/Ad Manager UI.",
          siteIDs);
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    bool isInitialized = GADMAdapterYahooInitializeYASAdsWithSiteID(siteID);
    if (!isInitialized) {
      NSError *initializeError = GADMAdapterYahooErrorWithCodeAndDescription(
          GADMAdapterYahooErrorInitialization, @"Yahoo Mobile SDK failed to initialize.");
      completionHandler(initializeError);
    }
  });

  completionHandler(nil);
}

+ (GADVersionNumber)adapterVersion {
  NSArray<NSString *> *versionComponents =
      [GADMAdapterYahooVersion componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = YASAds.sdkInfo.version;
  NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedAd = [[GADMAdapterYahooRewardedAd alloc] init];
  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

@end
