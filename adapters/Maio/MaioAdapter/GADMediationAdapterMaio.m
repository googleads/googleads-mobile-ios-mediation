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

#import "GADMAdapterMaioInterstitialAd.h"
#import "GADMAdapterMaioRewardedAd.h"
#import "GADMAdapterMaioUtils.h"
#import "GADMMaioConstants.h"
#import "GADRTBMaioInterstitialAd.h"
#import "GADRTBMaioRewardedAd.h"

@interface GADMediationAdapterMaio ()
@end

@implementation GADMediationAdapterMaio {
  // maio bidding interstitial ad wrapper.
  GADRTBMaioInterstitialAd *_interstitialRTBAd;

  // maio waterfall interstitial ad wrapper.
  GADMAdapterMaioInterstitialAd *_interstitialAd;

  // maio bidding rewarded ad wrapper.
  GADRTBMaioRewardedAd *_rewardedRTBAd;

  // maio waterfall rewarded ad wrapper.
  GADMAdapterMaioRewardedAd *_rewardedAd;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // maio SDK does not have any initialization process.
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

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:
                             (nonnull GADRTBSignalCompletionHandler)completionHandler {
  // Maio does not send any kind of signal, so we send an empty NSString instead.
  completionHandler(@"", nil);
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (adConfiguration.bidResponse) {
    _rewardedRTBAd = [[GADRTBMaioRewardedAd alloc] initWithAdConfiguration:adConfiguration];
    [_rewardedRTBAd loadRewardedAdWithCompletionHandler:completionHandler];
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
  if (adConfiguration.bidResponse) {
    _interstitialRTBAd = [[GADRTBMaioInterstitialAd alloc] initWithAdConfiguration:adConfiguration];
    [_interstitialRTBAd loadInterstitialWithCompletionHandler:completionHandler];
    return;
  }

  _interstitialAd =
      [[GADMAdapterMaioInterstitialAd alloc] initWithAdConfiguration:adConfiguration
                                                   completionHandler:completionHandler];
  [_interstitialAd loadInterstitialAd];
}

@end
