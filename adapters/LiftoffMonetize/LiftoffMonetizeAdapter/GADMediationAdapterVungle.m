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

#import "GADMediationAdapterVungle.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRewardBasedVideoAd.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"
#import "GADMediationVungleAppOpenAd.h"
#import "GADMediationVungleBanner.h"
#import "GADMediationVungleInterstitial.h"
#import "GADMediationVungleNativeAd.h"
#import "GADMediationVungleRewardedAd.h"
#import "VungleAdNetworkExtras.h"

@implementation GADMediationAdapterVungle {
  /// Liftoff Monetize rewarded ad wrapper.
  GADMediationVungleRewardedAd *_rewardedAd;

  /// Liftoff Monetize waterfall mediation rewarded ad wrapper.
  GADMAdapterVungleRewardBasedVideoAd *_waterfallRewardedAd;

  /// Liftoff Monetize interstitial ad wrapper.
  GADMediationVungleInterstitial *_interstitialAd;

  /// Liftoff Monetize native ad wrapper.
  GADMediationVungleNativeAd *_nativeAd;

  /// Liftoff Monetize banner ad wrapper.
  GADMediationVungleBanner *_bannerAd;

  /// Liftoff Monetize app open ad wrapper.
  GADMediationVungleAppOpenAd *_appOpenAd;
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  // Gather all app ids supplied by the server configuration
  NSMutableSet *applicationIDs = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *appID = cred.settings[GADMAdapterVungleApplicationID];
    if (appID.length) {
      GADMAdapterVungleMutableSetAddObject(applicationIDs, appID);
    }
  }

  if (!applicationIDs.count) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorInvalidServerParameters,
        @"Liftoff Monetize mediation configurations did not contain a valid application ID.");
    completionHandler(error);
    return;
  }

  NSString *applicationID = [applicationIDs anyObject];
  if (applicationIDs.count > 1) {
    NSLog(@"Found the following application IDs: %@. "
          @"Please remove any application IDs you are not using from the AdMob UI.",
          applicationIDs);
    NSLog(@"Configuring Vungle SDK with the application ID %@.", applicationID);
  }

  [GADMAdapterVungleRouter.sharedInstance initWithAppId:applicationID delegate:nil];
  completionHandler(nil);
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = VungleAds.sdkVersion;
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
  return [VungleAdNetworkExtras class];
}

+ (GADVersionNumber)adapterVersion {
  NSString *versionString = GADMAdapterVungleVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];

  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    // Adapter versions have 2 patch versions. Multiply the first patch by 100.
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  NSNumber *childDirectedTreatment =
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment;
  if (childDirectedTreatment) {
    [VunglePrivacySettings setCOPPAStatus:[childDirectedTreatment boolValue]];
  }
  if (!adConfiguration.bidResponse) {
    _waterfallRewardedAd =
        [[GADMAdapterVungleRewardBasedVideoAd alloc] initWithAdConfiguration:adConfiguration
                                                           completionHandler:completionHandler];
    [_waterfallRewardedAd requestRewardedAd];
    return;
  }
  _rewardedAd = [[GADMediationVungleRewardedAd alloc] initWithAdConfiguration:adConfiguration
                                                            completionHandler:completionHandler];
  [_rewardedAd requestRewardedAd];
}

- (void)loadInterstitialForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                               completionHandler {
  NSNumber *childDirectedTreatment =
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment;
  if (childDirectedTreatment) {
    [VunglePrivacySettings setCOPPAStatus:[childDirectedTreatment boolValue]];
  }
  _interstitialAd =
      [[GADMediationVungleInterstitial alloc] initWithAdConfiguration:adConfiguration
                                                    completionHandler:completionHandler];
  [_interstitialAd requestInterstitialAd];
}

- (void)loadNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:
                         (nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  NSNumber *childDirectedTreatment =
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment;
  if (childDirectedTreatment) {
    [VunglePrivacySettings setCOPPAStatus:[childDirectedTreatment boolValue]];
  }
  _nativeAd = [[GADMediationVungleNativeAd alloc] initNativeAdForAdConfiguration:adConfiguration
                                                               completionHandler:completionHandler];
  [_nativeAd requestNativeAd];
}

- (void)loadRewardedInterstitialAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                                   completionHandler:
                                       (nonnull GADMediationRewardedLoadCompletionHandler)
                                           completionHandler {
  // Liftoff Monetize Rewarded Interstitial ads use the same Rewarded Video API.
  NSLog(@"Liftoff Monetize adapter was asked to load a rewarded interstitial ad. Using the "
        @"rewarded ad request flow to load the ad to attempt to load a rewarded interstitial "
        @"ad from Liftoff Monetize.");
  [self loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:
                       (nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
  NSNumber *tagForChildDirectedTreatment =
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment;
  if (tagForChildDirectedTreatment) {
    [VunglePrivacySettings setCOPPAStatus:[tagForChildDirectedTreatment boolValue]];
  }
  _bannerAd = [[GADMediationVungleBanner alloc] initWithAdConfiguration:adConfiguration
                                                      completionHandler:completionHandler];
  [_bannerAd requestBannerAd];
}

- (void)loadAppOpenAdForAdConfiguration:
            (nonnull GADMediationAppOpenAdConfiguration *)adConfiguration
                      completionHandler:
                          (nonnull GADMediationAppOpenLoadCompletionHandler)loadCompletionHandler {
  NSNumber *tagForChildDirectedTreatment =
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment;
  if (tagForChildDirectedTreatment) {
    [VunglePrivacySettings setCOPPAStatus:tagForChildDirectedTreatment.boolValue];
  }
  _appOpenAd = [[GADMediationVungleAppOpenAd alloc] initWithAdConfiguration:adConfiguration
                                                      loadCompletionHandler:loadCompletionHandler];
  [_appOpenAd requestAppOpenAd];
}

#pragma mark GADRTBAdapter implementation

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:
                             (nonnull GADRTBSignalCompletionHandler)completionHandler {
  completionHandler([VungleAds getBiddingToken], nil);
}

@end
