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
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"

static BOOL isAppInitialized;

@implementation GADMediationAdapterInMobi {

  /// InMobi rewarded ad wrapper.
  GADMAdapterInMobiRewardedAd *_rewardedAd;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet<NSString *> *accountIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *accountIDFromSettings = cred.settings[kGADMAdapterInMobiAccountID];
    if (accountIDFromSettings.length) {
      GADMAdapterInMobiMutableSetAddObject(accountIDs, accountIDFromSettings);
    }
  }

  if (!accountIDs.count) {
    NSError *error =
        [NSError errorWithDomain:kGADMAdapterInMobiErrorDomain
                            code:kGADErrorMediationDataError
                        userInfo:@{
                          NSLocalizedDescriptionKey :
                              @"InMobi mediation configurations did not contain a valid account ID."
                        }];
    completionHandler(error);
    return;
  }

  NSString *accountID = [accountIDs anyObject];
  if (accountIDs.count > 1) {
    NSLog(@"Found the following account IDs: %@. "
          @"Please remove any account IDs you are not using from the AdMob UI.",
          accountIDs);
    NSLog(@"Initializing InMobi SDK with the account ID: %@", accountID);
  }

  [IMSdk initWithAccountID:accountID consentDictionary:GADMInMobiConsent.consent];
  isAppInitialized = YES;
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [IMSdk getVersion];
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
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
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (BOOL)isAppInitialised {
  return isAppInitialized;
}

+ (void)setIsAppInitialised:(BOOL)status {
  isAppInitialized = status;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (!_rewardedAd) {
    NSString *placementIdentifierString =
        adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID];
    NSNumber *placementIdentifier =
        [NSNumber numberWithLongLong:placementIdentifierString.longLongValue];
    _rewardedAd =
        [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];
  }

  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

@end
