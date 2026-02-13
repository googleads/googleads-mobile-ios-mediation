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

#import "GADMediationAdapterIMobile.h"

#import <ImobileSdkAds.h>

#import "GADMAdapterIMobileBannerAd.h"
#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileInterstitialAd.h"
#import "GADMAdapterIMobileUnifiedNativeAd.h"
#import "GADMAdapterIMobileUtils.h"

@implementation GADMediationAdapterIMobile {
  /// i-mobile banner ad wrapper.
  GADMAdapterIMobileBannerAd *_bannerAd;

  /// i-mobile interstitial ad wrapper.
  GADMAdapterIMobileInterstitialAd *_interstitialAd;

  /// i-mobile native ad wrapper.
  GADMAdapterIMobileUnifiedNativeAd *_unifiedNativeAd;
}

#pragma mark - GADMediationAdapter

+ (GADVersionNumber)adSDKVersion {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components =
      [[ImobileSdkAds getSdkVersion] componentsSeparatedByString:@"."];

  if (components.count >= 3) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue;
  }

  return version;
}

+ (GADVersionNumber)adapterVersion {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [GADMAdapterIMobileVersion componentsSeparatedByString:@"."];

  if (components.count >= 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }

  return version;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if (GADMAdapterIMobileIsChildUser()) {
    completionHandler(GADMAdapterIMobileErrorWithCodeAndDescription(
        GADMAdapterIMobileErrorChildUser, @"The request had age-restricted treatment, but i-mobile "
                                          @"SDK cannot receive age-restricted signals."));
    return;
  }
  completionHandler(nil);
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  if (GADMAdapterIMobileIsChildUser()) {
    completionHandler(nil, GADMAdapterIMobileErrorWithCodeAndDescription(
                               GADMAdapterIMobileErrorChildUser,
                               @"The request had age-restricted treatment, but i-mobile SDK "
                               @"cannot receive age-restricted signals."));
    return;
  }
  _bannerAd = [[GADMAdapterIMobileBannerAd alloc] initWithAdConfiguration:adConfiguration];
  [_bannerAd loadBannerAdWithCompletionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  if (GADMAdapterIMobileIsChildUser()) {
    completionHandler(nil, GADMAdapterIMobileErrorWithCodeAndDescription(
                               GADMAdapterIMobileErrorChildUser,
                               @"The request had age-restricted treatment, but i-mobile SDK "
                               @"cannot receive age-restricted signals."));
    return;
  }
  _interstitialAd =
      [[GADMAdapterIMobileInterstitialAd alloc] initWithAdConfiguration:adConfiguration];
  [_interstitialAd loadInterstitialAdWithCompletionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
  if (GADMAdapterIMobileIsChildUser()) {
    completionHandler(nil, GADMAdapterIMobileErrorWithCodeAndDescription(
                               GADMAdapterIMobileErrorChildUser,
                               @"The request had age-restricted treatment, but i-mobile SDK "
                               @"cannot receive age-restricted signals."));
    return;
  }
  _unifiedNativeAd =
      [[GADMAdapterIMobileUnifiedNativeAd alloc] initWithAdConfiguration:adConfiguration];
  [_unifiedNativeAd loadNativeAdWithCompletionHandler:completionHandler];
}

@end
