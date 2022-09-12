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
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiRewardedAd.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"

@implementation GADMediationAdapterInMobi {
  /// InMobi rewarded ad wrapper.
  GADMAdapterInMobiRewardedAd *_rewardedAd;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if (GADMAdapterInMobiInitializer.sharedInstance.initializationState ==
      GADMAdapterInMobiInitStateInitialized) {
    completionHandler(nil);
    return;
  }

  NSMutableSet<NSString *> *accountIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *accountIDFromSettings = cred.settings[GADMAdapterInMobiAccountID];
    if (accountIDFromSettings.length) {
      GADMAdapterInMobiMutableSetAddObject(accountIDs, accountIDFromSettings);
    }
  }

  if (!accountIDs.count) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorInvalidServerParameters,
        @"InMobi mediation configurations did not contain a valid account ID.");
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

  [GADMAdapterInMobiInitializer.sharedInstance initializeWithAccountID:accountID
                                                     completionHandler:^(NSError *_Nullable error) {
                                                       completionHandler(error);
                                                     }];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [IMSdk getVersion];
  NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = versionComponents[0].integerValue;
    version.minorVersion = versionComponents[1].integerValue;
    version.patchVersion = versionComponents[2].integerValue;
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADInMobiExtras class];
}

+ (GADVersionNumber)adapterVersion {
  NSArray<NSString *> *versionComponents =
      [GADMAdapterInMobiVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = versionComponents[0].integerValue;
    version.minorVersion = versionComponents[1].integerValue;
    version.patchVersion =
        versionComponents[2].integerValue * 100 + versionComponents[3].integerValue;
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (!_rewardedAd) {
    NSString *placementIdentifierString =
        adConfiguration.credentials.settings[GADMAdapterInMobiPlacementID];
    NSNumber *placementIdentifier =
        [NSNumber numberWithLongLong:placementIdentifierString.longLongValue];
    _rewardedAd =
        [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];
  }

  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

@end
