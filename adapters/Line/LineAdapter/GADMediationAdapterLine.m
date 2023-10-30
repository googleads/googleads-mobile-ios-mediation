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

#import "GADMediationAdapterLine.h"

#import <FiveAd/FiveAd.h>

#import "GADMediationAdapterLineBannerAdLoader.h"
#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineExtras.h"
#import "GADMediationAdapterLineInterstitialAdLoader.h"
#import "GADMediationAdapterLineNativeAdLoader.h"
#import "GADMediationAdapterLineRewardedAdLoader.h"
#import "GADMediationAdapterLineUtils.h"

@implementation GADMediationAdapterLine {
  /// The banner ad loader.
  GADMediationAdapterLineBannerAdLoader *_bannerAdLoader;

  /// The interstitial ad loader.
  GADMediationAdapterLineInterstitialAdLoader *_interstitialAdLoader;

  /// The rewarded ad loader.
  GADMediationAdapterLineRewardedAdLoader *_rewardedAdLoader;

  /// The native ad loader.
  GADMediationAdapterLineNativeAdLoader *_nativeAdLoader;
}

+ (GADVersionNumber)adapterVersion {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components =
      [GADMediationAdapterLineVersion componentsSeparatedByString:@"."];
  if (components.count == 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }
  return version;
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [FADSettings semanticVersion];
  NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = versionComponents[0].integerValue;
    version.minorVersion = versionComponents[1].integerValue;
    version.patchVersion = versionComponents[2].integerValue;
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMediationAdapterLineExtras class];
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSCAssert(completionHandler, @"Completion handler must not be nil.");
  NSError *error = GADMediationAdapterLineRegisterFiveAd(configuration.credentials);
  completionHandler(error);
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  _bannerAdLoader =
      [[GADMediationAdapterLineBannerAdLoader alloc] initWithAdConfiguration:adConfiguration
                                                       loadCompletionHandler:completionHandler];
  [_bannerAdLoader loadAd];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitialAdLoader = [[GADMediationAdapterLineInterstitialAdLoader alloc]
      initWithAdConfiguration:adConfiguration
        loadCompletionHandler:completionHandler];
  [_interstitialAdLoader loadAd];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedAdLoader =
      [[GADMediationAdapterLineRewardedAdLoader alloc] initWithAdConfiguration:adConfiguration
                                                         loadCompletionHandler:completionHandler];
  [_rewardedAdLoader loadAd];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
  _nativeAdLoader =
      [[GADMediationAdapterLineNativeAdLoader alloc] initWithAdConfiguration:adConfiguration
                                                       loadCompletionHandler:completionHandler];
  [_nativeAdLoader loadAd];
}

@end
