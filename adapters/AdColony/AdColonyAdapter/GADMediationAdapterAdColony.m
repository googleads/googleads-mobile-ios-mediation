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
//

#import "GADMediationAdapterAdColony.h"

#import <AdColony/AdColony.h>
#include <stdatomic.h>

#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMAdapterAdColonyInitializer.h"
#import "GADMAdapterAdColonyRTBBannerRenderer.h"
#import "GADMAdapterAdColonyRTBInterstitialRenderer.h"
#import "GADMAdapterAdColonyRewardedRenderer.h"

static AdColonyAppOptions *GADMAdapterAdColonyAppOptions;

@implementation GADMediationAdapterAdColony {
  /// AdColony banner ad renderer.
  GADMAdapterAdColonyRTBBannerRenderer *_bannerRenderer;

  /// AdColony interstitial ad renderer.
  GADMAdapterAdColonyRTBInterstitialRenderer *_interstitialRenderer;

  /// AdColony rewarded ad renderer.
  GADMAdapterAdColonyRewardedRenderer *_rewardedRenderer;
}

+ (void)load {
  GADMAdapterAdColonyAppOptions = [[AdColonyAppOptions alloc] init];
}

+ (AdColonyAppOptions *)appOptions {
  return GADMAdapterAdColonyAppOptions;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *zoneIDs = [[NSMutableSet alloc] init];
  NSMutableSet *appIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *zoneID = GADMAdapterAdColonyZoneIDForSettings(cred.settings);
    GADMAdapterAdColonyMutableSetAddObject(zoneIDs, zoneID);

    NSString *appID = cred.settings[GADMAdapterAdColonyAppIDkey];
    GADMAdapterAdColonyMutableSetAddObject(appIDs, appID);
  }

  if (appIDs.count < 1 || zoneIDs.count < 1) {
    NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(
        GADMAdapterAdColonyErrorMissingServerParameters,
        @"AdColony mediation configurations did not contain a valid app ID or zone ID.");
    completionHandler(error);
    return;
  }

  NSString *appID = [appIDs anyObject];

  if (appIDs.count != 1) {
    GADMAdapterAdColonyLog(@"Found the following app IDs: %@. Please remove any app IDs you are "
                           @"not using from the AdMob/Ad Manager UI.",
                           appIDs);
    GADMAdapterAdColonyLog(@"Configuring AdColony SDK with the app ID %@", appID);
  }

  [[GADMAdapterAdColonyInitializer sharedInstance]
      initializeAdColonyWithAppId:appID
                            zones:[zoneIDs allObjects]
                          options:GADMAdapterAdColonyAppOptions
                         callback:^(NSError *error) {
                           // Tell the Google Mobile Ads SDK that AdColony is initialized and
                           // is ready to service requests.
                           completionHandler(error);
                         }];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [AdColony getSDKVersion];
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
  return [GADMAdapterAdColonyExtras class];
}

+ (GADVersionNumber)adapterVersion {
  NSString *versionString = GADMAdapterAdColonyVersionString;
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

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params
                         completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
  [AdColony collectSignals:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedRenderer = [[GADMAdapterAdColonyRewardedRenderer alloc] init];
  [_rewardedRenderer loadRewardedAdForAdConfiguration:adConfiguration
                                    completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitialRenderer = [[GADMAdapterAdColonyRTBInterstitialRenderer alloc] init];
  [_interstitialRenderer renderInterstitialForAdConfig:adConfiguration
                                     completionHandler:completionHandler];
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  _bannerRenderer = [[GADMAdapterAdColonyRTBBannerRenderer alloc] init];
  [_bannerRenderer renderBannerForAdConfig:adConfiguration completionHandler:completionHandler];
}
@end
