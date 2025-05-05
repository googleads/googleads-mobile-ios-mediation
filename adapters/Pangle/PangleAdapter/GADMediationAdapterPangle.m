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
#import <PAGAdSDK/PAGAdSDK.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"
#import "GADPangleAppOpenRenderer.h"
#import "GADPangleBannerRenderer.h"
#import "GADPangleInterstitialRenderer.h"
#import "GADPangleNativeRenderer.h"
#import "GADPangleNetworkExtras.h"
#import "GADPangleRewardedRenderer.h"

static NSInteger _GDPRConsent = -1;

@implementation GADMediationAdapterPangle {
  /// Pangle app open ad wrapper.
  GADPangleAppOpenRenderer *_appOpenAdRenderer;
  /// Pangle banner ad wrapper.
  GADPangleBannerRenderer *_bannerRenderer;
  /// Pangle interstitial ad wrapper.
  GADPangleInterstitialRenderer *_interstitialRenderer;
  /// Pangle rewarded ad wrapper.
  GADPangleRewardedRenderer *_rewardedRenderer;
  /// Pangle native ad wrapper.
  GADPangleNativeRenderer *_nativeRenderer;
}

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:
                             (nonnull GADRTBSignalCompletionHandler)completionHandler {
  if ([GADMAdapterPangleUtils isChildUser]) {
    completionHandler(nil, GADMAdapterPangleChildUserError());
    return;
  }
  GADPangleNetworkExtras *extras =
      [params.extras isKindOfClass:[GADPangleNetworkExtras class]] ? params.extras : nil;
  if (extras && extras.userDataString.length > 0) {
    // The user data needs to be set for it to be included in the signals.
    [PAGConfig shareConfig].userDataString = extras.userDataString;
  }

  PAGBiddingRequest *request = [PAGBiddingRequest new];
  request.adxID = GADMAdapterPangleAdxID;
  if (params.configuration.credentials.firstObject.format == GADAdFormatBanner) {
    request.bannerSize = [GADPangleBannerRenderer bannerSizeFromGADAdSize:params.adSize];
  }
  [PAGSdk getBiddingTokenWithRequest:request
                          completion:^(NSString *_Nonnull biddingToken) {
                            completionHandler(biddingToken, nil);
                          }];
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
  if ([GADMAdapterPangleUtils isChildUser]) {
    completionHandler(GADMAdapterPangleChildUserError());
    return;
  }
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
        @"Found the following App IDs: %@. Please remove any app IDs which you are not using.",
        appIds);
  }

  GADMPangleLog(@"Configuring Pangle SDK with the app ID: %@", appID);
  PAGConfig *config = [PAGConfig shareConfig];
  config.appID = appID;
  config.GDPRConsent = _GDPRConsent;
  config.adxID = GADMAdapterPangleAdxID;
  config.userDataString = [NSString stringWithFormat:@"[{\"name\":\"mediation\",\"value\":\"google\"},{\"name\":\"adapter_version\",\"value\":\"%@\"}]",GADMAdapterPangleVersion];
  [PAGSdk startWithConfig:config
        completionHandler:^(BOOL success, NSError *_Nonnull error) {
          completionHandler(error);
        }];
}

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = PAGSdk.SDKVersion;
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  // TODO(thanvir): Maybe, change the logic below to return the first four parts of the SDK
  // version even if it has more than four parts.
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
  if ([GADMAdapterPangleUtils isChildUser]) {
    completionHandler(nil, GADMAdapterPangleChildUserError());
    return;
  }
  _bannerRenderer = [[GADPangleBannerRenderer alloc] init];
  [_bannerRenderer renderBannerForAdConfiguration:adConfiguration
                                completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  if ([GADMAdapterPangleUtils isChildUser]) {
    completionHandler(nil, GADMAdapterPangleChildUserError());
    return;
  }
  _interstitialRenderer = [[GADPangleInterstitialRenderer alloc] init];
  [_interstitialRenderer renderInterstitialForAdConfiguration:adConfiguration
                                            completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  if ([GADMAdapterPangleUtils isChildUser]) {
    completionHandler(nil, GADMAdapterPangleChildUserError());
    return;
  }
  _rewardedRenderer = [[GADPangleRewardedRenderer alloc] init];
  [_rewardedRenderer renderRewardedAdForAdConfiguration:adConfiguration
                                      completionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:
                         (nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  if ([GADMAdapterPangleUtils isChildUser]) {
    completionHandler(nil, GADMAdapterPangleChildUserError());
    return;
  }
  _nativeRenderer = [[GADPangleNativeRenderer alloc] init];
  [_nativeRenderer renderNativeAdForAdConfiguration:adConfiguration
                                  completionHandler:completionHandler];
}

- (void)loadAppOpenAdForAdConfiguration:
            (nonnull GADMediationAppOpenAdConfiguration *)adConfiguration
                      completionHandler:
                          (nonnull GADMediationAppOpenLoadCompletionHandler)completionHandler {
  if ([GADMAdapterPangleUtils isChildUser]) {
    completionHandler(nil, GADMAdapterPangleChildUserError());
    return;
  }
  _appOpenAdRenderer = [[GADPangleAppOpenRenderer alloc] init];
  [_appOpenAdRenderer renderAppOpenAdForAdConfiguration:adConfiguration
                                      completionHandler:completionHandler];
}

+ (void)setGDPRConsent:(NSInteger)GDPRConsent {
  if (GDPRConsent != 0 && GDPRConsent != 1 && GDPRConsent != -1) {
    GADMPangleLog(@"Invalid GDPR value. Pangle SDK only accepts -1, 0 or 1.");
    return;
  }
  if (PAGSdk.initializationState == PAGSDKInitializationStateReady &&
      ![GADMAdapterPangleUtils isChildUser]) {
    PAGConfig.shareConfig.GDPRConsent = GDPRConsent;
  }
  _GDPRConsent = GDPRConsent;
}

+ (void)setPAConsent:(NSInteger)PAConsent {
  if (PAConsent != 0 && PAConsent != 1) {
    GADMPangleLog(@"Invalid PAConsent value. Pangle SDK only accepts 0 or 1.");
    return;
  }

  PAGConfig.shareConfig.PAConsent = PAConsent;
}

@end
