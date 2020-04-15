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

@implementation GADMediationAdapterInMobi {
  /// InMobi rewarded ad wrapper.
  GADMAdapterInMobiRewardedAd *_rewardedAd;
}

static BOOL _isInitialized;

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if (_isInitialized) {
    completionHandler(nil);
    return;
  }

  NSMutableSet<NSString *> *accountIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *accountIDFromSettings = cred.settings[kGADMAdapterInMobiAccountID];
    if (accountIDFromSettings.length) {
      GADMAdapterInMobiMutableSetAddObject(accountIDs, accountIDFromSettings);
    }
  }

  if (!accountIDs.count) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        kGADErrorMediationDataError,
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

  NSError *error = [GADMediationAdapterInMobi initializeWithAccountID:accountID];
  completionHandler(error);
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

+ (GADVersionNumber)version {
  NSArray<NSString *> *versionComponents =
      [kGADMAdapterInMobiVersion componentsSeparatedByString:@"."];
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
        adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID];
    NSNumber *placementIdentifier =
        [NSNumber numberWithLongLong:placementIdentifierString.longLongValue];
    _rewardedAd =
        [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];
  }

  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

+ (nullable NSError *)initializeWithAccountID:(nonnull NSString *)accountID {
  if (_isInitialized) {
    return nil;
  }

  NSError *error = nil;
  if (!accountID.length) {
    error = GADMAdapterInMobiErrorWithCodeAndDescription(
        kGADErrorMediationDataError, @"[InMobi] Error - Account ID not specified.");
    return error;
  }

  [IMSdk initWithAccountID:accountID consentDictionary:GADMInMobiConsent.consent andError:&error];
  if (error) {
    return error;
  }

  _isInitialized = YES;
  NSLog(@"[InMobi] Initialized successfully.");
  return nil;
}

+ (BOOL)isInitialized {
  return _isInitialized;
}

@end
