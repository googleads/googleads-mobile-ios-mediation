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

#import <Maio/Maio.h>

#import "GADMAdapterMaioAdsManager.h"
#import "GADMAdapterMaioRewardedAd.h"
#import "GADMAdapterMaioUtils.h"
#import "GADMMaioConstants.h"
#import "GADMediationAdapterMaio.h"
#import "GADRTBAdapterMaioEntryPoint.h"

@import MaioOB;

@interface GADMediationAdapterMaio () <MaioDelegate>

@property(nonatomic) GADMAdapterMaioRewardedAd *rewardedAd;

@property(nonatomic) GADRTBAdapterMaioEntryPoint *rtbAdapter;

@end

@implementation GADMediationAdapterMaio

- (instancetype)init
{
    self = [super init];
    if (self) {
        _rtbAdapter = [GADRTBAdapterMaioEntryPoint new];
    }
    return self;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {

  NSMutableSet *publisherIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *publisherID = cred.settings[kGADMMaioAdapterPublisherID];
    GADMAdapterMaioMutableSetAddObject(publisherIDs, publisherID);
  }

  NSMutableSet *mediaIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *mediaID = cred.settings[kGADMMaioAdapterMediaId];
    GADMAdapterMaioMutableSetAddObject(mediaIDs, mediaID);
  }

  BOOL existsMediaID = mediaIDs.count > 0;
  BOOL existsPublisherID = publisherIDs.count > 0;
  if (!existsMediaID && !existsPublisherID) {
    [self setUpCaseNotExistsAnyWithCompletionHandler:completionHandler];
  } else if (!existsMediaID && existsPublisherID) {
    [self setupCaseExistsPublisherIDs:publisherIDs completionHandler:completionHandler];
  } else if (existsMediaID && !existsPublisherID) {
    [self setupCaseExistsMediaIDs:mediaIDs completionHandler:completionHandler];
  } else if (existsMediaID && existsPublisherID) {
    [self setUpCaseExistsMediaIDs:mediaIDs publisherIDs:publisherIDs completionHandler:completionHandler];
  }
}

+ (void)setupCaseExistsMediaIDs: (nonnull NSSet *)mediaIDs completionHandler: (nonnull GADMediationAdapterSetUpCompletionBlock) completionHandler {
  NSString *mediaID = [mediaIDs anyObject];
  if (mediaIDs.count > 1) {
    NSLog(@"Found the following media IDs: %@. "
          @"Please remove any media IDs you are not using from the AdMob UI.",
          mediaIDs);
    NSLog(@"Initializing maio SDK with the media ID %@", mediaID);
  }

  GADMAdapterMaioAdsManager *manager =
      [GADMAdapterMaioAdsManager getMaioAdsManagerByMediaId:mediaID];
  [manager initializeMaioSDKWithCompletionHandler:^(NSError *error) {
    completionHandler(error);
  }];
}

+ (void)setUpCaseNotExistsAnyWithCompletionHandler: (nonnull GADMediationAdapterSetUpCompletionBlock) completionHandler {
  NSError *error = [GADMMaioError errorWithDescription:@"Maio mediation configuration did not contain a valid identifier"];
  NSError *error = GADMAdapterMaioErrorWithCodeAndDescription(
          GADMAdapterMaioErrorInvalidServerParameters,
          @"maio mediation configurations did not contain a valid media ID.");
  completionHandler(error);
}

+ (void)setupCaseExistsPublisherIDs: (nonnull NSSet *)publisherIDs completionHandler: (nonnull GADMediationAdapterSetUpCompletionBlock) completionHandler {
  completionHandler(nil);
}

+ (void)setUpCaseExistsMediaIDs: (nonnull NSSet *)mediaIDs publisherIDs: (nonnull NSSet *)publisherIDs completionHandler: (nonnull GADMediationAdapterSetUpCompletionBlock) completionHandler {
  [self setupCaseExistsMediaIDs:mediaIDs completionHandler:completionHandler];
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
  NSArray *versionComponents = [kGADMMaioAdapterVersion componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params completionHandler:(nonnull GADRTBSignalCompletionHandler)completionHandler {
  [self.rtbAdapter collectSignalsForRequestParameters:params completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (adConfiguration.bidResponse) {
    [self.rtbAdapter loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
    return;
  }

  self.rewardedAd = [[GADMAdapterMaioRewardedAd alloc] init];
  [self.rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                                  completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler {
  if (adConfiguration.bidResponse) {
    [self.rtbAdapter loadInterstitialForAdConfiguration:adConfiguration completionHandler:completionHandler];
    return;
  }

  // Nevar use? Interstitial(Mediation) use GADMMaioInterstitialAdapter.
  NSError *error = [GADMMaioError errorWithDescription:@"Incompatible call for the interstitial. This logic need bidResponse."];
  completionHandler(nil, error);
}

@end
