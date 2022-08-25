// Copyright 2019 Google LLC.
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

#import <Maio/Maio.h>
#import <MaioOB/MaioOB-Swift.h>

#import "GADMAdapterMaioAdsManager.h"
#import "GADMAdapterMaioRewardedAd.h"
#import "GADMAdapterMaioUtils.h"
#import "GADMMaioConstants.h"
#import "GADRTBMaioInterstitialAd.h"
#import "GADRTBMaioRewardedAd.h"

@interface GADMediationAdapterMaio () <MaioDelegate>
@end

@implementation GADMediationAdapterMaio {
  // maio bidding interstitial ad wrapper.
  GADRTBMaioInterstitialAd *_interstitialRTBAd;

  // maio bidding rewarded ad wrapper.
  GADRTBMaioRewardedAd *_rewardedRTBAd;

  // maio waterfall rewarded ad wrapper.
  GADMAdapterMaioRewardedAd *_rewardedAd;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *publisherIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *credential in configuration.credentials) {
    NSString *publisherID = credential.settings[GADMMaioAdapterPublisherIDKey];
    GADMAdapterMaioMutableSetAddObject(publisherIDs, publisherID);
  }

  NSMutableSet *mediaIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *credential in configuration.credentials) {
    NSString *mediaID = credential.settings[GADMMaioAdapterMediaIdKey];
    GADMAdapterMaioMutableSetAddObject(mediaIDs, mediaID);
  }

  BOOL existsMediaID = mediaIDs.count > 0;
  BOOL existsPublisherID = publisherIDs.count > 0;

  if (existsMediaID) {
    NSString *mediaID = [mediaIDs anyObject];
    if (mediaIDs.count > 1) {
      NSLog(@"Found the following media IDs: %@. "
            @"Please remove any media IDs you are not using from the AdMob UI.",
            mediaIDs);
      NSLog(@"Initializing maio SDK with the media ID: %@", mediaID);
    }

    GADMAdapterMaioAdsManager *manager =
        [GADMAdapterMaioAdsManager getMaioAdsManagerByMediaId:mediaID];
    [manager initializeMaioSDKWithCompletionHandler:^(NSError *error) {
      completionHandler(error);
    }];
  } else if (existsPublisherID) {
    // For bidding integrations, maio SDK does not need to be initialized.
    completionHandler(nil);
  } else {
    NSError *error = GADMAdapterMaioErrorWithCodeAndDescription(
        GADMAdapterMaioErrorInvalidServerParameters,
        @"maio mediation configurations did not contain a valid media ID.");
    completionHandler(error);
  }
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

  // Interstitial waterfall mediation runs through GADMMaioInterstitialAdapter.
  NSError *error = GADMAdapterMaioErrorWithCodeAndDescription(
      GADMAdapterMaioErrorAdFormatNotSupported,
      @"Incompatible call for the interstitial. This logic need bidResponse.");
  completionHandler(nil, error);
}

@end
