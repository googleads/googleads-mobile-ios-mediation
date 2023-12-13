// Copyright 2015 Google LLC
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

#import "SampleAdapter.h"
#import <SampleAdSDK/SampleAdSDK.h>
#import "SampleAdapterBannerAd.h"
#import "SampleAdapterConstants.h"
#import "SampleAdapterInterstitialAd.h"
#import "SampleAdapterNativeAd.h"
#import "SampleAdapterRewardedAd.h"
#import "SampleExtras.h"

@interface SampleAdapter () {
  /// Banner ad wrapper for the Sample SDK.
  SampleAdapterBannerAd *_bannerAd;

  /// Interstitial ad wrapper for the Sample SDK.
  SampleAdapterInterstitialAd *_interstitialAd;

  /// Rewarded ad wrapper for the Sample SDK.
  SampleAdapterRewardedAd *_rewardedAd;

  /// Native ad wrapper for the Sample SDK.
  SampleAdapterNativeAd *_nativeAd;
}

@end

@implementation SampleAdapter

#pragma mark GADMediationAdapter implementation

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [SampleExtras class];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = SampleSDKVersion;
  NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = versionComponents[0].integerValue;
    version.minorVersion = versionComponents[1].integerValue;
    version.patchVersion = versionComponents[2].integerValue;
  }
  return version;
}

+ (GADVersionNumber)adapterVersion {
  NSString *versionString = SampleAdapterVersion;
  NSArray<NSString *> *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = versionComponents[0].integerValue;
    version.minorVersion = versionComponents[1].integerValue;
    // Adapter versions have 2 patch versions. Multiply the first patch by 100.
    version.patchVersion =
        versionComponents[2].integerValue * 100 + versionComponents[3].integerValue;
  }
  return version;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // Since the Sample SDK doesn't need to initialize, the completion handler is called directly
  // here.
  completionHandler(nil);
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  _bannerAd = [[SampleAdapterBannerAd alloc] initWithAdConfiguration:adConfiguration];
  [_bannerAd renderBannerAdWithCompletionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitialAd = [[SampleAdapterInterstitialAd alloc] initWithAdConfiguration:adConfiguration];
  [_interstitialAd renderInterstitialAdWithCompletionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedAd = [[SampleAdapterRewardedAd alloc] initWithAdConfiguration:adConfiguration];
  [_rewardedAd renderRewardedAdWithCompletionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
  _nativeAd = [[SampleAdapterNativeAd alloc] initWithAdConfiguration:adConfiguration];
  [_nativeAd renderNativeAdWithCompletionHandler:completionHandler];
}

@end
