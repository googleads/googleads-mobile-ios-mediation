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
#import "GADMAdapterUnityConstants.h"
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
@property(nonatomic, strong, nullable) NSData *watermarkForFullScreenAd;
@end

@implementation GADMediationAdapterUnity

static BOOL _isTestMode = NO;

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

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params
                         completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
  GADAdFormat adFormat = params.configuration.credentials.firstObject.format;
  if (adFormat == GADAdFormatBanner || adFormat == GADAdFormatInterstitial ||
      adFormat == GADAdFormatRewarded || adFormat == GADAdFormatRewardedInterstitial) {
    UnityAdsAdFormat format = UnityAdsAdFormatInterstitial;
    if (adFormat == GADAdFormatBanner) {
      format = UnityAdsAdFormatBanner;
    } else if (adFormat == GADAdFormatRewarded || adFormat == GADAdFormatRewardedInterstitial) {
      format = UnityAdsAdFormatRewarded;
    }
    UnityAdsTokenConfiguration *config = [UnityAdsTokenConfiguration newWithAdFormat:format];
    [UnityAds getTokenWith:config
                completion:^(NSString *_Nullable token) {
                  NSString *unityToken = token ?: @"";
                  completionHandler(unityToken, nil);
                }];
  } else {
    completionHandler(
        nil, GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorAdUnsupportedAdFormat,
                                                         @"Unsupported ad format."));
  }
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  [GADMediationAdapterUnity
      setCOPPA:(GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment
                    ? GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment
                          .integerValue
                    : -1)];
  self.adapterProxy = [[GADMUnityRewardedMediationAdapterProxy alloc] initWithAd:self
                                                               completionHandler:completionHandler];

  [self loadAdWithConfiguration:adConfiguration];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  [GADMediationAdapterUnity
      setCOPPA:(GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment
                    ? GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment
                          .integerValue
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
  self.watermarkForFullScreenAd = adConfiguration.watermark;
  UADSLoadOptions *loadOptions = [UADSLoadOptions new];
  loadOptions.objectId = self.objectId;
  if (adConfiguration.bidResponse) {
    loadOptions.adMarkup = adConfiguration.bidResponse;
  }

  [UnityAds load:self.placementId options:loadOptions loadDelegate:self.adapterProxy];
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  [GADMediationAdapterUnity
      setCOPPA:(GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment
                    ? GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment
                          .integerValue
                    : -1)];
  [self initializeWithConfiguration:adConfiguration];

  self.placementId = adConfiguration.placementId;
  self.adapterProxy =
      [[GADMUnityBannerMediationAdapterProxy alloc] initWithAd:self
                                               requestedAdSize:adConfiguration.adSize
                                                    forBidding:adConfiguration.bidResponse != nil
                                             completionHandler:completionHandler];
  self.bannerView = [[UADSBannerView alloc] initWithPlacementId:self.placementId
                                                           size:adConfiguration.adSize.size];
  self.bannerView.delegate = self.adapterProxy;
  UADSLoadOptions *loadOptions = [UADSLoadOptions new];
  NSData *watermark = adConfiguration.watermark;
  if (watermark != nil) {
    NSString *watermarkString = [watermark base64EncodedStringWithOptions:0];
    [loadOptions.dictionary setValue:watermarkString forKey:GADMAdapterUnityWatermarkKey];
  }
  if (adConfiguration.bidResponse) {
    loadOptions.adMarkup = adConfiguration.bidResponse;
  }

  [self.bannerView loadWithOptions:loadOptions];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  UADSShowOptions *showOptions = [UADSShowOptions new];
  showOptions.objectId = self.objectId;
  if (self.watermarkForFullScreenAd != nil) {
    NSString *watermarkString = [self.watermarkForFullScreenAd base64EncodedStringWithOptions:0];
    [showOptions.dictionary setValue:watermarkString forKey:GADMAdapterUnityWatermarkKey];
  }

  [self.adapterProxy.eventDelegate willPresentFullScreenView];
  [UnityAds show:viewController
       placementId:self.placementId
           options:showOptions
      showDelegate:self.adapterProxy];
}

- (void)initializeWithConfiguration:(GADMediationAdConfiguration *)adConfiguration {
  [[GADUnityRouter sharedRouter] sdkInitializeWithGameId:adConfiguration.gameId
                                   withCompletionHandler:nil];
}

#pragma mark Utility Methods

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

+ (BOOL)testMode {
  return _isTestMode;
}

+ (void)setTestMode:(BOOL)testMode {
  GADMUnityLog(@"Updating test mode flag to `%@`", (testMode ? @"YES" : @"NO"));
  _isTestMode = testMode;
}

#pragma mark GADMediationBannerAd

- (UIView *)view {
  return self.bannerView;
}

@end
