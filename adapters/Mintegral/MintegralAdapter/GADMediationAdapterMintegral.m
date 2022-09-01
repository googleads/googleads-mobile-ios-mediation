// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMediationAdapterMintegral.h"
#import "GADMediationAdapterMintegralConstants.h"
#import "GADMAdapterMintegralExtras.h"
#import "GADMAdapterMintegralRewardedAdRenderer.h"
#import "GADMAdapterMintegralBannerRenderer.h"
#import "GADMAdapterMintegralInterstitialRenderer.h"
#import "GADMAdapterMintegralNativeRenderer.h"
#import "GADMAdapterMintegralUtils.h"
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKBidding/MTGBiddingSDK.h>


@implementation GADMediationAdapterMintegral {
    /// Mintegral rewarded ad.
    GADMAdapterMintegralRewardedAdRenderer * _rewardedAd;
    
    /// Mintegral banner ad.
    GADMAdapterMintegralBannerRenderer *_bannerAd;
    
    /// Mintegral interstitial ad.
    GADMAdapterMintegralInterstitialRenderer *_interstitialAd;
    
    /// Mintegral native ad.
    GADMAdapterMintegralNativeRenderer *_nativeAd;
}


#pragma mark GADRTBAdapter

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
    return [GADMAdapterMintegralExtras class];
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
    
    NSMutableSet *appIds = [[NSMutableSet alloc] init];
    NSMutableSet *appKeys = [[NSMutableSet alloc] init];
    
    for (GADMediationCredentials *credential in configuration.credentials) {
        NSString *appId = credential.settings[GADMAdapterMintegralAppID];
        GADMAdapterMintegralMutableSetAddObject(appIds, appId);
        
        NSString *appKey =credential.settings[GADMAdapterMintegralAppKey];
        GADMAdapterMintegralMutableSetAddObject(appKeys, appKey);
    }
    
    if (appIds.count < 1) {
        NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorInvalidServerParameters, @"Mintegral mediation configurations did not contain a valid app ID.");
        completionHandler(error);
        return;
    }
    
    if (appKeys.count < 1) {
        NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorInvalidServerParameters, @"Mintegral mediation configurations did not contain a valid app key.");
        completionHandler(error);
        return;
    }
    
    NSString *appId = [appIds anyObject];
    if (appIds.count > 1) {
        GADMediationAdapterMintegralLog(
          @"Found the following App IDs:%@. Please remove any app IDs which you are not using",
          appIds);
        GADMediationAdapterMintegralLog(@"Configuring Mintegral SDK with the app ID:%@", appId);
    }
    
    NSString *appKey = [appKeys anyObject];
    if (appKeys.count > 1) {
        GADMediationAdapterMintegralLog(
          @"Found the following Api keys:%@. Please remove any api keys which you are not using",
                                        appKeys);
        GADMediationAdapterMintegralLog(@"Configuring Mintegral SDK with the app key:%@", appKey);
    }
    
    // Initialize the Mintergral SDK.
    [GADMediationAdapterMintegral setAdmobChannel];
    [[MTGSDK sharedInstance] setAppID:appId ApiKey:appKey];
    if (completionHandler) {
        completionHandler(nil);
    }
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [MTGSDK sdkVersion];
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [versionString componentsSeparatedByString:@"."];
  if (components.count == 3) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue;
  } else {
    NSLog(@"Unexpected ad SDK version string: %@. Returning 0 for adSDKVersion.", versionString);
  }
  return version;
}

+ (GADVersionNumber)adapterVersion {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [GADMAdapterMintegralVersion componentsSeparatedByString:@"."];
  if (components.count >= 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }
  return version;
}

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params
                         completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
    if (completionHandler) {
        completionHandler([MTGBiddingSDK buyerUID],nil);
    }
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
(GADMediationRewardedLoadCompletionHandler)completionHandler {
    _rewardedAd = [[GADMAdapterMintegralRewardedAdRenderer alloc]init];
    [_rewardedAd renderRewardedAdForAdConfiguration:adConfiguration
                                completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                               completionHandler; {
    _interstitialAd = [[GADMAdapterMintegralInterstitialRenderer alloc]init];
    [_interstitialAd renderInterstitialForAdConfiguration:adConfiguration
                                                          completionHandler:completionHandler];
}

- (void)loadBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:
(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
    _bannerAd = [[GADMAdapterMintegralBannerRenderer alloc]init];
    [_bannerAd renderBannerForAdConfiguration:adConfiguration
                        completionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
    _nativeAd = [[GADMAdapterMintegralNativeRenderer alloc]init];
    [_nativeAd renderNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

+ (void)setAdmobChannel {
    //This is to call the mintegral ad sdk private method, which is only used to mark the official aggregation channel from admob
    Class _class = NSClassFromString(@"MTGSDK");
    SEL selector = NSSelectorFromString(@"setChannelFlag:");
    NSString *pluginNumber = @"Y+H6DFttYrPQYcIBiQKwJQKQYrN=";
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([_class respondsToSelector:selector]) {
        [_class performSelector:selector withObject:pluginNumber];
    }
    #pragma clang diagnostic pop
}

@end
