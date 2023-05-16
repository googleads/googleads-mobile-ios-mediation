// Copyright 2020 Google LLC.
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

#import "GADMediationAdapterUnity.h"
#import <UnityAds/UnityAds.h>
#import "GADMAdapterUnityUtils.h"
#import "GADMUnityBannerMediationAdapterProxy.h"
#import "GADMUnityInterstitialMediationAdapterProxy.h"
#import "GADMUnityRewardedMediationAdapterProxy.h"
#import "GADMediationConfigurationSettings.h"
#import "GADUnityRouter.h"
#import "NSErrorUnity.h"

@interface GADMediationAdapterUnity () <GADMediationRewardedAd,
                                        GADMediationInterstitialAd,
                                        GADMediationBannerAd>
@property(nonatomic, strong) NSString *placementId;
@property(nonatomic, strong) GADUnityBaseMediationAdapterProxy *adapterProxy;
@property(nonatomic, strong) UADSBannerView *bannerView;
@property(nonatomic, strong) NSString *objectId;  // Object ID used to track loaded/shown ads.
@end

@implementation GADMediationAdapterUnity

// Called on Admob->init
+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSSet *gameIDs = configuration.gameIds;
  if (!gameIDs.count) {
    completionHandler([NSError noValidGameId]);
    return;
  }

  NSString *gameID = [gameIDs anyObject];
  if (gameIDs.count > 1) {
    NSLog(@"Found the following game IDs: %@. "
          @"Please remove any game IDs you are not using from the AdMob UI.",
          gameIDs);
    NSLog(@"Initializing Unity Ads SDK with the game ID %@.", gameID);
  }

  [[GADUnityRouter sharedRouter] sdkInitializeWithGameId:gameID
                                   withCompletionHandler:completionHandler];
}

+ (GADVersionNumber)adSDKVersion {
  return extractVersionFromString([UnityAds getVersion]);
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

+ (GADVersionNumber)adapterVersion {
  return extractVersionFromString(GADMAdapterUnityVersion);
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  [GADMediationAdapterUnity setCOPPA:(adConfiguration.childDirectedTreatment
                                          ? adConfiguration.childDirectedTreatment.integerValue
                                          : -1)];
  self.adapterProxy = [[GADMUnityRewardedMediationAdapterProxy alloc] initWithAd:self
                                                               completionHandler:completionHandler];

  [self loadAdWithConfiguration:adConfiguration];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  [GADMediationAdapterUnity setCOPPA:(adConfiguration.childDirectedTreatment
                                          ? adConfiguration.childDirectedTreatment.integerValue
                                          : -1)];
  self.adapterProxy =
      [[GADMUnityInterstitialMediationAdapterProxy alloc] initWithAd:self
                                                   completionHandler:completionHandler];

  [self loadAdWithConfiguration:adConfiguration];
}

- (void)loadAdWithConfiguration:(GADMediationAdConfiguration *)adConfiguration {
  [self initializeWithConfiguration:adConfiguration];

  self.placementId = adConfiguration.placementId;
  self.objectId = [NSUUID UUID].UUIDString;
  UADSLoadOptions *loadOptions = [UADSLoadOptions new];
  loadOptions.objectId = self.objectId;

  [UnityAds load:self.placementId options:loadOptions loadDelegate:self.adapterProxy];
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  [GADMediationAdapterUnity setCOPPA:(adConfiguration.childDirectedTreatment
                                          ? adConfiguration.childDirectedTreatment.integerValue
                                          : -1)];
  [self initializeWithConfiguration:adConfiguration];

  self.placementId = adConfiguration.placementId;

  GADAdSize supportedSize = supportedAdSizeFromRequestedSize(adConfiguration.adSize);
  if (!IsGADAdSizeValid(supportedSize)) {
    completionHandler(self, [NSError unsupportedBannerGADAdSize:adConfiguration.adSize]);
    return;
  }
  self.adapterProxy = [[GADMUnityBannerMediationAdapterProxy alloc] initWithAd:self
                                                             completionHandler:completionHandler];

  self.bannerView = [[UADSBannerView alloc] initWithPlacementId:self.placementId
                                                           size:supportedSize.size];
  self.bannerView.delegate = self.adapterProxy;
  [self.bannerView load];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  UADSShowOptions *showOptions = [UADSShowOptions new];
  showOptions.objectId = self.objectId;
  [UnityAds show:viewController
       placementId:self.placementId
           options:showOptions
      showDelegate:self.adapterProxy];
}

- (void)initializeWithConfiguration:(GADMediationAdConfiguration *)adConfiguration {
  [[GADUnityRouter sharedRouter] sdkInitializeWithGameId:adConfiguration.gameId
                                   withCompletionHandler:nil];
}

/// Set the COPPA setting in Unity Ads SDK.
///
/// @param COPPA An integer value that indicates whether the app should be treated as
/// child-directed for purposes of the COPPA.  0 means false. 1 means true. -1 means
/// unspecified.
+ (void)setCOPPA:(NSInteger)COPPA {
  UADSMetaData *userMetaData = [[UADSMetaData alloc] init];
  if (COPPA == 1 || COPPA == -1) {
    /// Unity Ads will default to treating users as children when a user-level COPPA designation is
    /// absent.
    [userMetaData set:@"user.nonbehavioral" value:@YES];
    [userMetaData commit];
    return;
  } else if (COPPA == 0) {
    [userMetaData set:@"user.nonbehavioral" value:@NO];
    [userMetaData commit];
    return;
  } else {
    GADMUnityLog(@"Invalid COPPA value.");
    return;
  }
}

#pragma mark GADMediationBannerAd

- (UIView *)view {
  return self.bannerView;
}

@end
