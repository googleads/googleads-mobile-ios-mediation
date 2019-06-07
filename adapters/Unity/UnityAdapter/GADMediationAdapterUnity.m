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

#import "GADMediationAdapterUnity.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityRewardedAd.h"
#import "GADMAdapterUnitySingleton.h"
@import UnityAds;

@interface GADMediationAdapterUnity ()

@property(nonatomic, strong) GADMAdapterUnityRewardedAd *rewardedAd;

@end

@implementation GADMediationAdapterUnity

// Called on Admob->init
+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *gameIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    [gameIDs addObject:[cred.settings objectForKey:kGADMAdapterUnityGameID]];
  }

  NSString *gameID = [gameIDs anyObject];

  if (gameIDs.count != 1) {
    NSLog(@"Found the following game IDs: %@. Please remove any game IDs you are not using from "
          @"the AdMob UI.",
          gameIDs);
    NSLog(@"Initializing Unity Ads SDK with the game ID %@.", gameID);
  }

  [[GADMAdapterUnitySingleton sharedInstance] initializeWithGameID:gameID];

  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  GADVersionNumber version = {0};
  NSString *sdkVersion = [UnityAds getVersion];
  NSArray<NSString *> *components = [sdkVersion componentsSeparatedByString:@"."];
  if (components.count == 3) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue;
  } else {
    NSLog(@"Unexpected Unity Ads version string: %@. Returning 0 for adSDKVersion.", sdkVersion);
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

+ (GADVersionNumber)version {
  GADVersionNumber version = {0};
  NSString *adapterVersion = kGADMAdapterUnityVersion;
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
  self.rewardedAd = [[GADMAdapterUnityRewardedAd alloc] initWithAdConfiguration:adConfiguration
                                                              completionHandler:completionHandler];
  [self.rewardedAd requestRewardedAd];
}

@end
