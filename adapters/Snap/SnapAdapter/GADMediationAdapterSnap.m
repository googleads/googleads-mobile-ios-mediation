// Copyright 2021 Google LLC
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

#import "GADMediationAdapterSnap.h"

#import "GADMediationAdapterSnapConstants.h"
#import "GADMediationSnapBanner.h"
#import "GADMediationSnapInterstitial.h"
#import "GADMediationSnapRewarded.h"
#import "GADMediatonAdapterSnapUtils.h"

#import <SAKSDK/SAKSDK.h>

@implementation GADMediationAdapterSnap {
  /// Snap Audience Network banner ad wrapper.
  GADMediationSnapBanner *_banner;
  /// Snap Audience Network interstitial ad wrapper.
  GADMediationSnapInterstitial *_interstitial;
  /// Snap Audience Network rewarded ad wrapper.
  GADMediationSnapRewarded *_rewarded;
}

+ (GADVersionNumber)adapterVersion {
  NSArray *versionComponents = [GADMAdapterSnapVersion componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    // Adapter versions have 2 patch versions. Multiply the first patch by 100.
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (GADVersionNumber)adSDKVersion {
  NSString *sdkVersion = SAKMobileAd.shared.sdkVersion;
  NSArray<NSString *> *versionComponents = [sdkVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count == 3) {
    version.majorVersion = versionComponents[0].integerValue;
    version.minorVersion = versionComponents[1].integerValue;
    version.patchVersion = versionComponents[2].integerValue;
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet<NSString *> *snapAppIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *credentials in configuration.credentials) {
    NSString *snapAppID = credentials.settings[GADMAdapterSnapAppID];
    if (snapAppID.length) {
      GADMediationAdapterSnapMutableSetAddObject(snapAppIDs, snapAppID);
    }
  }
  if (!snapAppIDs.count) {
    NSString *desc = @"Snap Audience Network requires a single snapAppId. "
                      "No snapAppId were provided.";
    return completionHandler([NSError errorWithDomain:GADErrorDomain
                                                 code:GADErrorInvalidRequest
                                             userInfo:@{NSLocalizedDescriptionKey : desc}]);
  }
  NSString *snapAppID = [snapAppIDs anyObject];
  if (snapAppIDs.count > 1) {
    NSLog(@"Found the following Snap Application IDs: %@\n"
          @"Please remove any Snap Application IDs you are not using from the AdMob UI",
          snapAppIDs);
    NSLog(@"Configuring Snap Audience Network SDK with the Snap Application ID %@", snapAppID);
  }
  [self startWithSnapAppID:snapAppID completionHandler:completionHandler];
}

+ (void)startWithSnapAppID:(nonnull NSString *)snapAppID
         completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  SAKRegisterRequestConfigurationBuilder *builder =
      [[SAKRegisterRequestConfigurationBuilder alloc] init];
  [builder withSnapKitAppId:snapAppID];
  [SAKMobileAd.shared startWithConfiguration:[builder build]
                                  completion:^(BOOL success, NSError *error) {
                                    if (success) {
                                      completionHandler(nil);
                                    } else {
                                      completionHandler(error);
                                    }
                                  }];
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  _banner = [[GADMediationSnapBanner alloc] init];
  [_banner renderBannerForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitial = [[GADMediationSnapInterstitial alloc] init];
  [_interstitial renderInterstitialForAdConfiguration:adConfiguration
                                    completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewarded = [[GADMediationSnapRewarded alloc] init];
  [_rewarded renderRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params
                         completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
  completionHandler(SAKMobileAd.shared.biddingToken, nil);
}

@end
