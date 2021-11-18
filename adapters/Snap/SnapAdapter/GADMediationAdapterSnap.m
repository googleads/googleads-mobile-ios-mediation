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

#import "GADMediationSnapBanner.h"
#import "GADMediationSnapRewarded.h"
#import "GADMediationSnapInterstitial.h"
#import "GADMediationAdapterSnapConstants.h"

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
    NSArray<NSString *> *components = [GADMAdapterSnapVersion componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (components.count == 3) {
      version.majorVersion = components[0].integerValue;
      version.minorVersion = components[1].integerValue;
      version.patchVersion = components[2].integerValue;
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
    NSMutableSet<NSString *> *snapAppIds = [[NSMutableSet alloc] init];
    for (GADMediationCredentials *credentials in configuration.credentials) {
        NSString *snapAppId = credentials.settings[GADMAdapterSnapAppID];
        if (snapAppId.length) {
            [snapAppIds addObject:snapAppId];
        }
    }
    
    if (!snapAppIds.count) {
        NSString *desc = @"Snap Audience Network requires a single snapAppId. "
                         "No snapAppId were provided.";
        return completionHandler([NSError errorWithDomain:GADErrorDomain
                                                     code:GADErrorInvalidRequest
                                                 userInfo:@{ NSLocalizedDescriptionKey : desc }]);
    }
    
    NSString *snapAppId = [snapAppIds anyObject];
    if (snapAppIds.count > 1) {
        NSLog(@"Found the following Snap Application IDs: %@\n"
              @"Please remove any Snap Application IDs you are not using from the AdMob UI",
              snapAppIds);
        NSLog(@"Configuring Snap Audience Network SDK with the Snap Application ID %@", snapAppId);
    }
    [self startWithSnapAppId:snapAppId completionHandler:completionHandler];
}

+ (void)startWithSnapAppId:(nonnull NSString *)snapAppId
          completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
    SAKRegisterRequestConfigurationBuilder *builder = [[SAKRegisterRequestConfigurationBuilder alloc] init];
    [builder withSnapKitAppId:snapAppId];
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

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler {
    _interstitial = [[GADMediationSnapInterstitial alloc] init];
    [_interstitial renderInterstitialForAdConfiguration:adConfiguration
                                      completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    _rewarded = [[GADMediationSnapRewarded alloc] init];
    [_rewarded renderRewardedAdForAdConfiguration:adConfiguration
                                completionHandler:completionHandler];
}

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params
                         completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
    completionHandler(SAKMobileAd.shared.biddingToken, nil);
}

@end
