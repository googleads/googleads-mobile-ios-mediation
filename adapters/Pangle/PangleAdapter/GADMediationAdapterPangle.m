// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMediationAdapterPangle.h"
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"
#import "GADPangleRTBBannerRenderer.h"
#import "GADPangleRTBInterstitialRenderer.h"
#import "GADPangleRTBRewardedRenderer.h"
#import "GADPangleRTBNativeRenderer.h"
#import "GADPangleNetworkExtras.h"
#import <PAGAdSDK/PAGAdSDK.h>

static NSInteger _GDPRConsent = -1, _doNotSell = -1;

@implementation GADMediationAdapterPangle {
    /// Pangle banner ad wrapper.
    GADPangleRTBBannerRenderer *_bannerRenderer;
    /// Pangle interstitial ad wrapper.
    GADPangleRTBInterstitialRenderer *_interstitialRenderer;
    /// Pangle rewarded ad wrapper.
    GADPangleRTBRewardedRenderer *_rewardedRenderer;
    /// Pangle native ad wrapper.
    GADPangleRTBNativeRenderer *_nativeRenderer;
}

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:
(nonnull GADRTBSignalCompletionHandler)completionHandler {
    GADPangleNetworkExtras *extras = [params.extras isKindOfClass:[GADPangleNetworkExtras class]] ? params.extras : nil;
    if (extras && extras.userDataString.length > 0) {
        [PAGConfig shareConfig].userDataString = extras.userDataString;
    }
    NSString *signals = [PAGSdk getBiddingToken:nil];
    completionHandler(signals, nil);
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *appIds = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *appId = cred.settings[GADMAdapterPangleAppID];
    GADMAdapterPangleMutableSetAddObject(appIds, appId);
  }

  if (appIds.count < 1) {
    NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(
        GADPangleErrorInvalidServerParameters,
        @"Pangle mediation configurations did not contain a valid App ID.");
    completionHandler(error);
    return;
  }

  NSString *appID = [appIds anyObject];
  if (appIds.count > 1) {
    GADMPangleLog(
        @"Found the following App IDs:%@. Please remove any app IDs which you are not using",
        appIds);
    GADMPangleLog(@"Configuring Pangle SDK with the app ID:%@", appID);
  }
  PAGConfig *config = [PAGConfig shareConfig];
  config.appID = appID;
  config.GDPRConsent = _GDPRConsent;
  config.doNotSell = _doNotSell;
  [PAGSdk startWithConfig:config completionHandler:^(BOOL success, NSError * _Nonnull error) {
    completionHandler(error);
  }];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = PAGSdk.SDKVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count == 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  } else {
    GADMPangleLog(@"Unexpected version string: %@. Returning 0 for adSDKVersion.", versionString);
  }
  return version;
}

+ (GADVersionNumber)adapterVersion {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [GADMAdapterPangleVersion componentsSeparatedByString:@"."];
  if (components.count >= 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
    if (components.count >= 5) {
      version.patchVersion = version.patchVersion * 100 + components[4].integerValue;
    }
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADPangleNetworkExtras class];
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  [GADMediationAdapterPangle setChildDirected:(adConfiguration.childDirectedTreatment
                                           ? adConfiguration.childDirectedTreatment.integerValue
                                           : -1)];
  _bannerRenderer = [[GADPangleRTBBannerRenderer alloc] init];
  [_bannerRenderer renderBannerForAdConfiguration:adConfiguration
                                completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  [GADMediationAdapterPangle setChildDirected:(adConfiguration.childDirectedTreatment
                                           ? adConfiguration.childDirectedTreatment.integerValue
                                           : -1)];
  _interstitialRenderer = [[GADPangleRTBInterstitialRenderer alloc] init];
  [_interstitialRenderer renderInterstitialForAdConfiguration:adConfiguration
                                            completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  [GADMediationAdapterPangle setChildDirected:(adConfiguration.childDirectedTreatment
                                           ? adConfiguration.childDirectedTreatment.integerValue
                                           : -1)];
  _rewardedRenderer = [[GADPangleRTBRewardedRenderer alloc] init];
  [_rewardedRenderer renderRewardedAdForAdConfiguration:adConfiguration
                                      completionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
    [GADMediationAdapterPangle setChildDirected:(adConfiguration.childDirectedTreatment
                                             ? adConfiguration.childDirectedTreatment.integerValue
                                             : -1)];
    _nativeRenderer = [[GADPangleRTBNativeRenderer alloc] init];
    [_nativeRenderer renderNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

/// Set the COPPA setting in Pangle SDK.
///
/// @param childDirected An integer value that indicates whether the app should be treated as
/// child-directed for purposes of the COPPA.  0 means user is not a child.
/// 1 means user is a child. -1 means unspecified.
/// Any value outside of -1, 0, or 1 will result in this method being a no-op.
+ (void)setChildDirected:(NSInteger)childDirected {
  if (childDirected != 0 && childDirected != 1 && childDirected != -1) {
    GADMPangleLog(@"Invalid COPPA value. Pangle SDK only accepts -1, 0 or 1.");
    return;
  }
  if (PAGSdk.initializationState == PAGSDKInitializationStateReady) {
      PAGConfig.shareConfig.childDirected = childDirected;
  }
}
+ (void)GDPRConsent:(NSInteger)GDPRConsent {
  if (GDPRConsent != 0 && GDPRConsent != 1 && GDPRConsent != -1) {
    GADMPangleLog(@"Invalid GDPR value. Pangle SDK only accepts -1, 0 or 1.");
    return;
  }
  if (PAGSdk.initializationState == PAGSDKInitializationStateReady) {
      PAGConfig.shareConfig.GDPRConsent = GDPRConsent;
  }
  _GDPRConsent = GDPRConsent;
}

+ (void)doNotSell:(NSInteger)doNotSell {
  if (doNotSell != 0 && doNotSell != 1 && doNotSell != -1) {
    GADMPangleLog(@"Invalid CCPA value. Pangle SDK only accepts -1, 0 or 1.");
    return;
  }
  if (PAGSdk.initializationState == PAGSDKInitializationStateReady) {
      PAGConfig.shareConfig.doNotSell = doNotSell;
  }
  _doNotSell = doNotSell;
}

@end
