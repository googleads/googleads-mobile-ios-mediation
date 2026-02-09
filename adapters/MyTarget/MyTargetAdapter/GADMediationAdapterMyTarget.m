// Copyright 2023 Google LLC
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

#import "GADMAdapterMyTargetBannerAd.h"
#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetInterstitialAd.h"
#import "GADMAdapterMyTargetNativeAd.h"
#import "GADMAdapterMyTargetRewardedAd.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMediationAdapterMyTarget ()

@end

@implementation GADMediationAdapterMyTarget {
  /// myTarget banner ad wrapper.
  GADMAdapterMyTargetBannerAd *_bannerAd;

  /// myTarget rewarded ad wrapper.
  GADMAdapterMyTargetRewardedAd *_rewardedAd;

  /// myTarget interstitial ad wrapper.
  GADMAdapterMyTargetInterstitialAd *_interstitialAd;

  /// myTarget native ad wrapper.
  GADMAdapterMyTargetNativeAd *_nativeAd;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // INFO: MyTarget SDK doesn't have any initialization API.
  GADMAdapterMyTargetSetUserConsentIfNeeded();
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [MTRGVersion currentVersion];
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [versionString componentsSeparatedByString:@"."];
  if (components.count >= 3) {
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

+ (GADVersionNumber)adapterVersion {
  NSString *versionString = GADMAdapterMyTargetVersion;
  NSArray<NSString *> *components = [versionString componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (components.count >= 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }
  return version;
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  GADMAdapterMyTargetSetUserConsentIfNeeded();

  _bannerAd = [[GADMAdapterMyTargetBannerAd alloc] initWithAdConfiguration:adConfiguration
                                                         completionHandler:completionHandler];
  [_bannerAd loadBannerAd];
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  GADMAdapterMyTargetSetUserConsentIfNeeded();

  _rewardedAd = [[GADMAdapterMyTargetRewardedAd alloc] initWithAdConfiguration:adConfiguration
                                                             completionHandler:completionHandler];
  [_rewardedAd loadRewardedAd];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  GADMAdapterMyTargetSetUserConsentIfNeeded();

  _interstitialAd =
      [[GADMAdapterMyTargetInterstitialAd alloc] initWithAdConfiguration:adConfiguration
                                                       completionHandler:completionHandler];
  [_interstitialAd loadInterstitialAd];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
  GADMAdapterMyTargetSetUserConsentIfNeeded();

  _nativeAd = [[GADMAdapterMyTargetNativeAd alloc] initWithAdConfiguration:adConfiguration
                                                         completionHandler:completionHandler];
  [_nativeAd loadNativeAd];
}

@end
