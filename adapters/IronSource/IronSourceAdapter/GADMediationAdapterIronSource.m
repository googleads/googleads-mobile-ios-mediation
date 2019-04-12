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
#import "ISMediationManager.h"

@interface GADMediationAdapterIronSource () {
  /// Ironsource rewarded ad wrapper.
  GADMAdapterIronSourceRewardedAd *_rewardedAd;
}

@end

@implementation GADMediationAdapterIronSource

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *appKeys = [[NSMutableSet alloc] init];
  NSMutableSet *ironSourceAdUnits = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    if (cred.format == GADAdFormatInterstitial) {
      [ironSourceAdUnits addObject:IS_INTERSTITIAL];
    } else if (cred.format == GADAdFormatRewarded) {
      [ironSourceAdUnits addObject:IS_REWARDED_VIDEO];
    }
    [appKeys addObject:[cred.settings valueForKey:kGADMAdapterIronSourceAppKey]];
  }

  NSString *appKey = [appKeys anyObject];

  if (appKeys.count != 1) {
    NSLog(
        @"Found the following app keys: %@. Please remove any app keys you are not using from the "
        @"AdMob UI.",
        appKeys);
    NSLog(@"Initializing IronSource SDK with the app key %@, for ad formats %@", appKey,
          ironSourceAdUnits);
  }

  [[ISMediationManager sharedManager] initIronSourceSDKWithAppKey:appKey
                                                       forAdUnits:ironSourceAdUnits];

  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  GADVersionNumber version = {0};
  NSString *sdkVersion = [IronSource sdkVersion];
  NSArray<NSString *> *components = [sdkVersion componentsSeparatedByString:@"."];
  if (components.count == 3) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue;
  } else {
    NSLog(@"Unexpected IronSource version string: %@. Returning 0 for adSDKVersion.", sdkVersion);
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

+ (GADVersionNumber)version {
  GADVersionNumber version = {0};
  NSString *adapterVersion = kGADMAdapterIronSourceAdapterVersion;
  NSArray<NSString *> *components = [adapterVersion componentsSeparatedByString:@"."];
  if (components.count == 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedAd = [[GADMAdapterIronSourceRewardedAd alloc]
      initWithGADMediationRewardedAdConfiguration:adConfiguration
                                completionHandler:completionHandler];
  [_rewardedAd requestRewardedAd];
}

@end
