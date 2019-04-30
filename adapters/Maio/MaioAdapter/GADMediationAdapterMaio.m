// Copyright 2019 Google LLC.
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

#import "GADMediationAdapterMaio.h"
#import "GADMAdapterMaioAdsManager.h"
#import "GADMAdapterMaioRewardedAd.h"
#import "GADMMaioConstants.h"
@import Maio;

@interface GADMediationAdapterMaio () <MaioDelegate>

@property(nonatomic) GADMAdapterMaioRewardedAd *rewardedAd;

@end

@implementation GADMediationAdapterMaio

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *mediaIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    [mediaIDs addObject:[cred.settings valueForKey:kGADMMaioAdapterMediaId]];
  }

  NSString *mediaID = [mediaIDs anyObject];

  if (mediaIDs.count > 1) {
    NSLog(@"Found the following media IDs: %@. Please remove any media IDs you are not using from "
          @"the AdMob UI.",
          mediaIDs);
    NSLog(@"Initializing Maio SDK with the media ID %@", mediaID);
  }

  GADMAdapterMaioAdsManager *manager =
      [GADMAdapterMaioAdsManager getMaioAdsManagerByMediaId:mediaID];
  [manager initializeMaioSDKWithCompletionHandler:^(NSError *error) {
    completionHandler(error);
  }];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [Maio sdkVersion];
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count == 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

+ (GADVersionNumber)version {
  NSArray *versionComponents = [kGADMMaioAdapterVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count == 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.rewardedAd = [[GADMAdapterMaioRewardedAd alloc] init];
  [self.rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                                  completionHandler:completionHandler];
}

@end
