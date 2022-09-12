// Copyright 2018 Google Inc.
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

#import "GADMediationAdapterIronSource.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceRewardedAd.h"
#import "GADMAdapterIronSourceUtils.h"
#import "ISMediationManager.h"

@interface GADMediationAdapterIronSource () {
  GADMAdapterIronSourceRewardedAd *_rewardedAd;
}

@end

@implementation GADMediationAdapterIronSource

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *appKeys = [[NSMutableSet alloc] init];
  NSMutableSet *ironSourceAdUnits = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    if (cred.format == GADAdFormatInterstitial) {
      GADMAdapterIronSourceMutableSetAddObject(ironSourceAdUnits, IS_INTERSTITIAL);
    } else if (cred.format == GADAdFormatRewarded) {
      GADMAdapterIronSourceMutableSetAddObject(ironSourceAdUnits, IS_REWARDED_VIDEO);
    }

    NSString *appKeyFromSetting = cred.settings[GADMAdapterIronSourceAppKey];
    GADMAdapterIronSourceMutableSetAddObject(appKeys, appKeyFromSetting);
  }

  if (!appKeys.count) {
    NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
        GADMAdapterIronSourceErrorInvalidServerParameters,
        @"IronSource mediation configurations did not contain a valid app key.");
    completionHandler(error);
    return;
  }

  NSString *appKey = [appKeys anyObject];
  if (appKeys.count > 1) {
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:
                            @"Found the following app keys: %@. "
                            @"Please remove any app keys you are not using from the AdMob UI.",
                            appKeys]];
    [GADMAdapterIronSourceUtils
        onLog:[NSString stringWithFormat:
                            @"Initializing IronSource SDK with the app key %@, for ad formats %@",
                            appKey, ironSourceAdUnits]];
  }

  [[ISMediationManager sharedManager] initIronSourceSDKWithAppKey:appKey
                                                       forAdUnits:ironSourceAdUnits];
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  GADVersionNumber version = {0};
  NSString *sdkVersion = [IronSource sdkVersion];
  NSArray<NSString *> *components = [sdkVersion componentsSeparatedByString:@"."];
  if (components.count > 2) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue;
  } else if (components.count == 2) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
  } else if (components.count == 1) {
    version.majorVersion = components[0].integerValue;
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

+ (GADVersionNumber)adapterVersion {
  GADVersionNumber version = {0};
  NSString *adapterVersion = GADMAdapterIronSourceAdapterVersion;
  NSArray<NSString *> *components = [adapterVersion componentsSeparatedByString:@"."];
  if (components.count >= 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedAd = [[GADMAdapterIronSourceRewardedAd alloc]
      initWithGADMediationRewardedAdConfiguration:adConfiguration
                                completionHandler:completionHandler];
  [_rewardedAd requestRewardedAd];
}

- (void)loadRewardedInterstitialAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                                   completionHandler:
                                       (nonnull GADMediationRewardedLoadCompletionHandler)
                                           completionHandler {
  // IronSource Rewarded Interstitial ads use the same Rewarded Video API.
  NSLog(@"IronSource adapter was asked to load a rewarded interstitial ad. Using the rewarded ad "
        @"request flow to load the ad to attempt to load a rewarded interstitial ad from "
        @"IronSource.");
  [self loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
