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

#import "GADMediationAdapterInMobi.h"
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobi.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiRewardedAd.h"
#import "GADMInMobiConsent.h"

@interface GADMediationAdapterInMobi ()

@property(nonatomic) GADMAdapterInMobiRewardedAd *rewardedAd;

@end

@implementation GADMediationAdapterInMobi

BOOL isAppInitialised;

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *accountIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    [accountIDs addObject:cred.settings[kGADMAdapterInMobiAccountID]];
  }

  NSString *accountID = [accountIDs anyObject];

  if (accountIDs.count > 1) {
    NSLog(@"Found the following account ID's: %@. Please remove any account IDs you are not using "
          @"from the AdMob UI.",
          accountIDs);
    NSLog(@"Initializing InMobi SDK with the account ID %@", accountID);
  }

  [IMSdk initWithAccountID:accountID consentDictionary:[GADMInMobiConsent getConsent]];
  isAppInitialised = YES;
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [IMSdk getVersion];
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
  return [GADInMobiExtras class];
}

+ (GADVersionNumber)version {
  NSArray *versionComponents = [kGADMAdapterInMobiVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count == 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (BOOL)isAppInitialised {
  return isAppInitialised;
}

+ (void)setIsAppInitialised:(BOOL)status {
  isAppInitialised = status;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (!isAppInitialised) {
    NSString *accountID = adConfiguration.credentials.settings[kGADMAdapterInMobiAccountID];
    [IMSdk initWithAccountID:accountID consentDictionary:[GADMInMobiConsent getConsent]];
    isAppInitialised = YES;
  }

  self.rewardedAd = [[GADMAdapterInMobiRewardedAd alloc] init];
  [self.rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                                  completionHandler:completionHandler];
}

@end
