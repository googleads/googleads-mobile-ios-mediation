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

static BOOL isAppInitialized;

@implementation GADMediationAdapterInMobi {
  /// InMobi banner ad wrapper.
  InMobiBannerAd *_bannerAd;

  /// InMobi interstitial ad wrapper.
  InMobiInterstitialAd *_interstitialAd;

  /// InMobi rewarded ad wrapper.
  GADMAdapterInMobiRewardedAd *_rewardedAd;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet<NSString *> *accountIDs = [[NSMutableSet alloc] init];

  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *accountIDFromSettings = cred.settings[kGADMAdapterInMobiAccountID];
    if (accountIDFromSettings.length) {
      GADMAdapterInMobiMutableSetAddObject(accountIDs, accountIDFromSettings);
    }
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

  [IMSdk initWithAccountID:accountID consentDictionary:GADMInMobiConsent.consent];
  isAppInitialized = YES;
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = [IMSdk getVersion];
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
  return isAppInitialized;
}

+ (void)setIsAppInitialised:(BOOL)status {
  isAppInitialized = status;
}

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:
                             (nonnull GADRTBSignalCompletionHandler)completionHandler {
  if (params.configuration.credentials.count == 0) {
    completionHandler(
        nil,
        [NSError errorWithDomain:kGADMAdapterInMobiErrorDomain
                            code:kGADErrorMediationDataError
                        userInfo:@{NSLocalizedDescriptionKey : @"Inmobi credentials unavailable"}]);
  }

  GADMediationCredentials *credentials = params.configuration.credentials.firstObject;
  NSDictionary<NSString *, id> *settings = credentials.settings;
  NSString *accountIdentifier = settings[kGADMAdapterInMobiAccountID];
  NSString *placementIdentifierString = settings[kGADMAdapterInMobiPlacementID];
  NSNumber *placementIdentifier =
      [NSNumber numberWithLongLong:placementIdentifierString.longLongValue];

  NSError *error = GADMAdapterInMobiValidatePlacementIdentifier(placementIdentifier);
  if (error) {
    completionHandler(nil, error);
    return;
  }

  if (!isAppInitialized) {
    [IMSdk initWithAccountID:accountIdentifier];
  }

  GADAdSize adSize = params.adSize;
  switch (credentials.format) {
    case GADAdFormatBanner: {
      // This avoids a crash where UI methods are invoked on a non-main thread.
      dispatch_async(dispatch_get_main_queue(), ^{
        self->_bannerAd = [[InMobiBannerAd alloc] initWithPlacementIdentifier:placementIdentifier
                                                                       adSize:adSize];
        [self->_bannerAd collectIMSignalsWithGMACompletionHandler:completionHandler];
      });
    } break;
    case GADAdFormatInterstitial:
      _interstitialAd =
          [[InMobiInterstitialAd alloc] initWithPlacementIdentifier:placementIdentifier];
      [_interstitialAd collectIMSignalsWithGACompletionHandler:completionHandler];
      break;
    case GADAdFormatRewarded:
      _rewardedAd =
          [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];
      [_rewardedAd collectIMSignalsWithGACompletionHandler:completionHandler];
      break;
    case GADAdFormatNative:
      completionHandler(
          nil,
          [NSError errorWithDomain:kGADMAdapterInMobiErrorDomain
                              code:kGADErrorInvalidRequest
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
    NSString *placementIdentifierString =
        adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID];
    NSNumber *placementIdentifier =
        [NSNumber numberWithLongLong:placementIdentifierString.longLongValue];

    GADAdSize adSize = adConfiguration.adSize;
    _bannerAd = [[InMobiBannerAd alloc] initWithPlacementIdentifier:placementIdentifier
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
    NSString *placementIdentifierString =
        adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID];
    NSNumber *placementIdentifier =
        [NSNumber numberWithLongLong:placementIdentifierString.longLongValue];
    _interstitialAd =
        [[InMobiInterstitialAd alloc] initWithPlacementIdentifier:placementIdentifier];
  }

  [_interstitialAd loadIMInterstitialResponseWithGMAdConfig:adConfiguration
                                          completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (!_rewardedAd) {
    NSString *placementIdentifierString =
        adConfiguration.credentials.settings[kGADMAdapterInMobiPlacementID];
    NSNumber *placementIdentifier =
        [NSNumber numberWithLongLong:placementIdentifierString.longLongValue];
    _rewardedAd =
        [[GADMAdapterInMobiRewardedAd alloc] initWithPlacementIdentifier:placementIdentifier];
  }

  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

@end
