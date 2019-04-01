// Copyright 2019 Google Inc.
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

#import "GADMediationAdapterMyTarget.h"
#import <MyTargetSDK/MyTargetSDK.h>
#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMRewardedAdMyTarget.h"

@interface GADMediationAdapterMyTarget ()

@property(nonatomic, strong) GADMRewardedAdMyTarget *rewardedAd;

@end

@implementation GADMediationAdapterMyTarget

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // INFO: MyTarget SDK doesn't have any initialization API.
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [MTRGVersion currentVersion];
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [versionString componentsSeparatedByString:@"."];
  if (components.count == 3) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue;
  } else {
    NSLog(@"Unexpected MyTarget version string: %@. Returning 0 for adSDKVersion.", versionString);
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterMyTargetExtras class];
}

+ (GADVersionNumber)version {
  NSString *versionString = kGADMAdapterMyTargetVersion;
  NSArray<NSString *> *components = [versionString componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (components.count == 3) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.rewardedAd = [[GADMRewardedAdMyTarget alloc] init];
  [self.rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                                  completionHandler:completionHandler];
}

@end
