// Copyright 2019 Google LLC
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

#import "GADMediationAdapterMaio.h"

#import <Maio/Maio-Swift.h>

#import "GADMAdapterMaioBannerAd.h"
#import "GADMAdapterMaioInterstitialAd.h"
#import "GADMAdapterMaioRewardedAd.h"
#import "GADMAdapterMaioUtils.h"
#import "GADMMaioConstants.h"

@interface GADMediationAdapterMaio ()
@end

@implementation GADMediationAdapterMaio {
  // maio waterfall interstitial ad wrapper.
  GADMAdapterMaioInterstitialAd *_interstitialAd;

  // maio waterfall rewarded ad wrapper.
  GADMAdapterMaioRewardedAd *_rewardedAd;

  // maio waterfall banner ad wrapper.
  GADMAdapterMaioBannerAd *_bannerAd;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if (GADMAdapterMaioIsChildUser()) {
    completionHandler(GADMAdapterMaioErrorWithCodeAndDescription(
        GADMAdapterMaioErrorChildUser,
        @"The adapter cannot be setup, because the session has age-restricted treatment and "
        @"maio SDK cannot receive age-restricted signals."));
    return;
  }
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [MaioVersion.shared description];
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
  return nil;
}

+ (GADVersionNumber)adapterVersion {
  NSArray *versionComponents = [GADMMaioAdapterVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  if (GADMAdapterMaioIsChildUser()) {
    completionHandler(nil, GADMAdapterMaioErrorWithCodeAndDescription(
                               GADMAdapterMaioErrorChildUser,
                               @"The request had age-restricted treatment, but maio SDK "
                               @"cannot receive age-restricted signals."));
    return;
  }
  _bannerAd = [[GADMAdapterMaioBannerAd alloc] init];
  [_bannerAd loadBannerAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (GADMAdapterMaioIsChildUser()) {
    completionHandler(nil, GADMAdapterMaioErrorWithCodeAndDescription(
                               GADMAdapterMaioErrorChildUser,
                               @"The request had age-restricted treatment, but maio SDK "
                               @"cannot receive age-restricted signals."));
    return;
  }
  _rewardedAd = [[GADMAdapterMaioRewardedAd alloc] init];
  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                               completionHandler {
  if (GADMAdapterMaioIsChildUser()) {
    completionHandler(nil, GADMAdapterMaioErrorWithCodeAndDescription(
                               GADMAdapterMaioErrorChildUser,
                               @"The request had age-restricted treatment, but maio SDK "
                               @"cannot receive age-restricted signals."));
    return;
  }
  _interstitialAd =
      [[GADMAdapterMaioInterstitialAd alloc] initWithAdConfiguration:adConfiguration
                                                   completionHandler:completionHandler];
  [_interstitialAd loadInterstitialAd];
}

@end
