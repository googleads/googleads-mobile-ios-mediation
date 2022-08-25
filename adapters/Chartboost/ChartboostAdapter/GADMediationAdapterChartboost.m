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

#import "GADMediationAdapterChartboost.h"
#if __has_include(<Chartboost/Chartboost.h>)
#import <Chartboost/Chartboost.h>
#else
#import "Chartboost.h"
#endif
#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostRewardedAd.h"
#import "GADMAdapterChartboostUtils.h"
#import "GADMChartboostError.h"
#import "GADMChartboostExtras.h"
#import "GADMediationAdapterChartboost.h"

@implementation GADMediationAdapterChartboost {
  /// Chartboost rewarded ad wrapper.
  GADMAdapterChartboostRewardedAd *_rewardedAd;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if (SYSTEM_VERSION_LESS_THAN(GADMAdapterChartboostMinimumOSVersion)) {
    NSString *logMessage = [NSString
        stringWithFormat:
            @"Chartboost minimum supported OS version is iOS %@. Requested action is a no-op.",
            GADMAdapterChartboostMinimumOSVersion];
    NSError *error = GADMAdapterChartboostErrorWithCodeAndDescription(
        GADMAdapterChartboostErrorMinimumOSVersion, logMessage);
    completionHandler(error);
    return;
  }

  NSMutableDictionary *credentials = [[NSMutableDictionary alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *appID = cred.settings[GADMAdapterChartboostAppID];
    NSString *appSignature = cred.settings[GADMAdapterChartboostAppSignature];

    if (appID.length && appSignature.length) {
      GADMAdapterChartboostMutableDictionarySetObjectForKey(credentials, appID, appSignature);
    }
  }

  if (!credentials.count) {
    NSError *error = GADMAdapterChartboostErrorWithCodeAndDescription(
        GADMAdapterChartboostErrorInvalidServerParameters,
        @"Chartboost mediation configurations did not contain a valid appID and app signature.");
    completionHandler(error);
    return;
  }

  NSString *appID = credentials.allKeys.firstObject;
  NSString *appSignature = credentials[appID];
  if (credentials.count > 1) {
    NSLog(@"Found multiple app IDs: %@. "
          @"Please remove any app IDs you are not using from the AdMob UI.",
          credentials.allKeys);
    NSLog(@"Initializing Chartboost SDK with the app ID: %@ and app signature: %@", appID,
          appSignature);
  }
  [Chartboost startWithAppId:appID
                appSignature:appSignature
                  completion:^(BOOL success) {
                    NSError *error = nil;
                    if (!success) {
                      error = GADMAdapterChartboostErrorWithCodeAndDescription(
                          GADMAdapterChartboostErrorInitializationFailure,
                          @"Chartboost SDK initialization failed.");
                    }
                    completionHandler(error);
                  }];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [Chartboost getSDKVersion];
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
  return [GADMChartboostExtras class];
}

+ (GADVersionNumber)adapterVersion {
  NSString *versionString = GADMAdapterChartboostVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
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
  _rewardedAd = [[GADMAdapterChartboostRewardedAd alloc] initWithAdConfiguration:adConfiguration
                                                               completionHandler:completionHandler];
  [_rewardedAd loadRewardedAd];
}

@end
