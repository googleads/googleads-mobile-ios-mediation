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

#import "GADMediationAdapterFyber.h"

#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GADMAdapterFyberBannerAd.h"
#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberExtras.h"
#import "GADMAdapterFyberInterstitialAd.h"
#import "GADMAdapterFyberRewardedAd.h"
#import "GADMAdapterFyberUtils.h"

@interface GADMediationAdapterFyber () <GADMediationAdapter>
@end

@implementation GADMediationAdapterFyber {
  /// Fyber banner ad wrapper.
  GADMAdapterFyberBannerAd *_bannerAd;

  /// Fyber interstitial ad wrapper.
  GADMAdapterFyberInterstitialAd *_interstitialAd;

  /// Fyber rewarded ad wrapper.
  GADMAdapterFyberRewardedAd *_rewardedAd;
}

#pragma mark - GADMediationAdapter

+ (GADVersionNumber)adSDKVersion {
  return GADMAdapterFyberVersionFromString([[IASDKCore sharedInstance] version]);
}

+ (GADVersionNumber)adapterVersion {
  return GADMAdapterFyberVersionFromString(GADMAdapterFyberVersion);
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return GADMAdapterFyberExtras.class;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if (IASDKCore.sharedInstance.isInitialised) {
    completionHandler(nil);
    return;
  }

  NSMutableSet<NSString *> *applicationIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *credential in configuration.credentials) {
    NSString *appID = credential.settings[GADMAdapterFyberApplicationID];
    if (appID.length) {
      GADMAdapterFyberMutableSetAddObject(applicationIDs, appID);
    }
  }

  if (!applicationIDs.count) {
    NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
        GADMAdapterFyberErrorInvalidServerParameters, @"Missing or invalid Application ID.");
    GADMAdapterFyberLog(@"%@", error.localizedDescription);
    completionHandler(error);
    return;
  }

  NSString *applicationID = applicationIDs.allObjects.firstObject;
  if (applicationIDs.count > 1) {
    GADMAdapterFyberLog(
        @"Fyber supports a single application ID but multiple application IDs were provided. "
        @"Remove unneeded applications IDs from your mediation configurations. Application IDs: %@",
        applicationIDs);
    GADMAdapterFyberLog(@"Configuring Fyber Marketplace SDK with application ID: %@.",
                        applicationID);
  }

  GADMAdapterFyberInitializeWithAppId(applicationID, ^(NSError *_Nullable error) {
    completionHandler(error);
  });
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  _bannerAd = [[GADMAdapterFyberBannerAd alloc] initWithAdConfiguration:adConfiguration];
  [_bannerAd loadBannerAdWithCompletionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  _interstitialAd =
      [[GADMAdapterFyberInterstitialAd alloc] initWithAdConfiguration:adConfiguration];
  [_interstitialAd loadInterstitialAdWithCompletionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _rewardedAd = [[GADMAdapterFyberRewardedAd alloc] initWithAdConfiguration:adConfiguration];
  [_rewardedAd loadRewardedAdWithCompletionHandler:completionHandler];
}

@end
