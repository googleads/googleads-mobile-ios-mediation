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

#import "GADMediationAdapterInMobi.h"
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobi.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiRewardedAd.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"
#import "InMobiBannerAd.h"
#import "InMobiInterstitialAd.h"

@interface GADMediationAdapterInMobi () {
  InMobiBannerAd *_bannerAd;
  InMobiInterstitialAd *_interstitialAd;
  GADMAdapterInMobiRewardedAd *_rewardedAd;
}

@end

@implementation GADMediationAdapterInMobi

BOOL isAppInitialised;

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *accountIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *accountIDFromSettings = cred.settings[kGADMAdapterInMobiAccountID];
    GADMAdapterInMobiMutableSetAddObject(accountIDs, accountIDFromSettings);
  }

  if (!accountIDs.count) {
    NSError *error =
        [NSError errorWithDomain:kGADMAdapterInMobiErrorDomain
                            code:kGADErrorMediationDataError
                        userInfo:@{
                          NSLocalizedDescriptionKey :
                              @"InMobi mediation configurations did not contain a valid account ID."
                        }];
    completionHandler(error);
    return;
  }

  NSString *accountID = [accountIDs anyObject];
  if (accountIDs.count > 1) {
    NSLog(@"Found the following account IDs: %@. "
          @"Please remove any account IDs you are not using from the AdMob UI.",
          accountIDs);
    NSLog(@"Initializing InMobi SDK with the account ID: %@", accountID);
  }

  [IMSdk initWithAccountID:accountID consentDictionary:[GADMInMobiConsent getConsent]];
  isAppInitialised = YES;
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [IMSdk getVersion];
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count == 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADInMobiExtras class];
}

+ (GADVersionNumber)version {
  NSArray *versionComponents = [kGADMAdapterInMobiVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

+ (BOOL)isAppInitialised {
  return isAppInitialised;
}

+ (void)setIsAppInitialised:(BOOL)status {
  isAppInitialised = status;
}

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params
                         completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
  if (params.configuration.credentials.count == 0) {
    completionHandler(
        nil,
        [NSError errorWithDomain:kGADMAdapterInMobiErrorDomain
                            code:101
                        userInfo:@{NSLocalizedDescriptionKey : @"Inmobi credentials unavailable"}]);
  }

  GADMediationCredentials *credentials = params.configuration.credentials.firstObject;
  NSDictionary *settings = credentials.settings;
  NSString *accId = settings[kGADMAdapterInMobiAccountID];
  NSString *placementId = settings[kGADMAdapterInMobiPlacementID];

  if (!isAppInitialised) {
    [IMSdk initWithAccountID:accId];
  }

  GADAdSize adSize = params.adSize;
  switch (credentials.format) {
    case GADAdFormatBanner: {
      // This avoids a crash where UI methods are invoked on a non-main thread.
      dispatch_async(dispatch_get_main_queue(), ^{
        self->_bannerAd = [[InMobiBannerAd alloc] initWithPlacementId:[placementId longLongValue]
                                                               adSize:adSize];
        [self->_bannerAd collectIMSignalsWithGMACompletionHandler:completionHandler];
      });
    } break;
    case GADAdFormatInterstitial:
      _interstitialAd =
          [[InMobiInterstitialAd alloc] initWithPlacementId:[placementId longLongValue]];
      [_interstitialAd collectIMSignalsWithGACompletionHandler:completionHandler];
      break;
    case GADAdFormatRewarded:
      _rewardedAd =
          [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementId:[placementId longLongValue]];
      [_rewardedAd collectIMSignalsWithGACompletionHandler:completionHandler];
      break;
    case GADAdFormatNative:
      completionHandler(
          nil,
          [NSError errorWithDomain:kGADMAdapterInMobiErrorDomain
                              code:102
                          userInfo:@{
                            NSLocalizedDescriptionKey :
                                @"The InMobi adapter currently does not support Native ads in Open "
                                @"Bidding. Please contact the InMobi team to request this feature."
                          }]);
      break;
  }
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  if (!_bannerAd) {
    NSString *placementID = adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID];
    GADAdSize adSize = adConfiguration.adSize;
    _bannerAd = [[InMobiBannerAd alloc] initWithPlacementId:[placementID longLongValue]
                                                     adSize:adSize];
  }

  [_bannerAd loadIMBannerResponseWithGMAAdConfig:adConfiguration
                               completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  if (!_interstitialAd) {
    NSString *placementID = adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID];
    _interstitialAd =
        [[InMobiInterstitialAd alloc] initWithPlacementId:[placementID longLongValue]];
  }

  [_interstitialAd loadIMInterstitialResponseWithGMAdConfig:adConfiguration
                                          completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (!_rewardedAd) {
    NSString *placementID = adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID];
    _rewardedAd =
        [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementId:[placementID longLongValue]];
  }

  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

@end
