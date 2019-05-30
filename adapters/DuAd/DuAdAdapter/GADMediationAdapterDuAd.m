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

#import "GADMediationAdapterDuAd.h"
#import "GADDuAdInitializer.h"
#import "GADDuAdNetworkExtras.h"
#import "GADMAdapterDuAdConstants.h"
#import "GADDuAdError.h"
@import DUModuleSDK;

@implementation GADMediationAdapterDuAd

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *placementIDs = [[NSMutableSet alloc] init];
  NSMutableSet *appIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    [appIDs addObject:cred.settings[kGADMAdapterDuAdAppID]];
    [placementIDs addObject:cred.settings[kGADMAdapterDuAdPlacementID]];
  }

  NSString *appID = [appIDs anyObject];

  if (appID && placementIDs.count > 0) {
    if (appIDs.count != 1) {
      NSLog(@"Found the following app IDs: %@. Please remove any app IDs you are not using from the "
            @"AdMob/Ad Manager UI.",
            appIDs);
      NSLog(@"Initializing DuAd SDK with the app ID %@", appID);
    }

    [[GADDuAdInitializer sharedInstance] initializeWithAppID:appID placmentIDs:placementIDs];
    completionHandler(nil);
  } else {
    NSError *error = GADDUErrorWithDescription(@"App ID or Placement ID cannot be nil.");
    completionHandler(error);
  }
}

+ (GADVersionNumber)adSDKVersion {
  NSArray *versionComponents = [DUSV componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count == 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADDuAdNetworkExtras class];
}

+ (GADVersionNumber)version {
  NSArray *versionComponents = [kGADMAdapterDuAdVersion componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count == 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

@end
