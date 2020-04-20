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

#import "GADMediationAdapterVungle.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRewardedAd.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"
#import "VungleAdNetworkExtras.h"

@implementation GADMediationAdapterVungle {
  /// Vungle rewarded ad wrapper.
  GADMAdapterVungleRewardedAd *_rewardedAd;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *applicationIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *appID = cred.settings[kGADMAdapterVungleApplicationID];
    GADMAdapterVungleMutableSetAddObject(applicationIDs, appID);
  }

  if (!applicationIDs.count) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationDataError,
        @"Vungle mediation configurations did not contain a valid application ID.");
    completionHandler(error);
    return;
  }

  NSString *applicationID = [applicationIDs anyObject];
  if (applicationIDs.count > 1) {
    NSLog(@"Found the following application IDs: %@. "
          @"Please remove any application IDs you are not using from the AdMob UI.",
          applicationIDs);
    NSLog(@"Configuring Vungle SDK with the application ID %@.", applicationID);
  }

  [[GADMAdapterVungleRouter sharedInstance] initWithAppId:applicationID delegate:nil];
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = VungleSDKVersion;
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
  return [VungleAdNetworkExtras class];
}

+ (GADVersionNumber)version {
  NSString *versionString = kGADMAdapterVungleVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    // Adapter versions have 2 patch versions. Multiply the first patch by 100.
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedAd = [[GADMAdapterVungleRewardedAd alloc] initWithAdConfiguration:adConfiguration
                                                           completionHandler:completionHandler];
  [_rewardedAd requestRewardedAd];
}

@end
