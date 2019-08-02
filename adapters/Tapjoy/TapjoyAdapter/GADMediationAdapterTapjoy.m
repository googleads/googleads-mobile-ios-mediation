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

#import "GADMediationAdapterTapjoy.h"
#import <Tapjoy/Tapjoy.h>
#import "GADMAdapterTapjoy.h"
#import "GADMAdapterTapjoyConstants.h"
#import "GADMAdapterTapjoySingleton.h"
#import "GADMAdapterTapjoyUtils.h"
#import "GADMRTBInterstitialRendererTapjoy.h"
#import "GADMRewardedAdTapjoy.h"
#import "GADMTapjoyExtras.h"

@interface GADMediationAdapterTapjoy ()

@property(nonatomic, strong) GADMRTBInterstitialRendererTapjoy *interstitialRenderer;
@property(nonatomic, strong) GADMRewardedAdTapjoy *rewardedAd;

@end

@implementation GADMediationAdapterTapjoy

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // Pass additional info through to SDK for upcoming request, etc.
  NSMutableSet *sdkKeys = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *sdkKeyFromSettings = cred.settings[kGADMAdapterTapjoySdkKey];
    GADMAdapterTapjoyMutableSetAddObject(sdkKeys, sdkKeyFromSettings);
  }

  if (!sdkKeys.count) {
    NSError *error =
        [NSError errorWithDomain:kGADMAdapterTapjoyErrorDomain
                            code:kGADErrorMediationDataError
                        userInfo:@{
                          NSLocalizedDescriptionKey :
                              @"Tapjoy mediation configurations did not contain a valid SDK Key."
                        }];
    completionHandler(error);
    return;
  }

  NSString *sdkKey = [sdkKeys anyObject];
  if (sdkKeys.count > 1) {
    NSLog(@"Found the following sdk keys: %@. "
          @"Please remove any sdk keys you are not using from the AdMob UI.",
          sdkKeys);
    NSLog(@"Initializing Tapjoy SDK with the sdk key: %@", sdkKey);
  }

  NSMutableDictionary *connectOptions = [[NSMutableDictionary alloc] init];
  [[GADMAdapterTapjoySingleton sharedInstance] initializeTapjoySDKWithSDKKey:sdkKey
                                                                     options:connectOptions
                                                           completionHandler:^(NSError *error) {
                                                             completionHandler(error);
                                                           }];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [Tapjoy getVersion];
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
  return [GADMTapjoyExtras class];
}

+ (GADVersionNumber)version {
  NSArray *versionComponents = [kGADMAdapterTapjoyVersion componentsSeparatedByString:@"."];

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
  NSString *signals = [Tapjoy getUserToken];
  completionHandler(signals, nil);
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitialRenderer = [[GADMRTBInterstitialRendererTapjoy alloc] init];
  [_interstitialRenderer renderInterstitialForAdConfig:adConfiguration
                                     completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedAd = [[GADMRewardedAdTapjoy alloc] init];

  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

@end
