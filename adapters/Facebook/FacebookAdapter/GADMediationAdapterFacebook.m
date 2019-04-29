// Copyright 2018 Google Inc.
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

#import "GADMediationAdapterFacebook.h"
#import "GADFBBannerRenderer.h"
#import "GADFBError.h"
#import "GADFBInterstitialRenderer.h"
#import "GADFBNativeRenderer.h"
#import "GADFBNetworkExtras.h"
#import "GADFBRewardedRenderer.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMAdapterFacebook.h"
@import FBAudienceNetwork;

@interface GADMediationAdapterFacebook () {
  /// Facebook Audience Network rewarded ad wrapper.
  GADFBRewardedRenderer *_rewardedAd;
  /// Facebook Audience Network native ad wrapper.
  GADFBNativeRenderer *_native;
  /// Facebook Audience Network interstitial ad wrapper.
  GADFBInterstitialRenderer *_interstitial;
  /// Facebook Audience Network banner ad wrapper.
  GADFBBannerRenderer *_banner;
}

@end

@implementation GADMediationAdapterFacebook

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
  NSMutableSet *placementIds = [[NSMutableSet alloc] init];
  for (GADMediationCredentials *cred in configuration.credentials) {
    NSString *placementId = [cred.settings objectForKey:kGADMAdapterFacebookPubID];
    if (placementId) {
      [placementIds addObject:placementId];
    }
  }
  FBAdInitSettings *fbSettings = [[FBAdInitSettings alloc]
      initWithPlacementIDs:[placementIds allObjects]
                 mediationService:[NSString stringWithFormat:@"GOOGLE_%@", [GADRequest sdkVersion]]];

  [FBAudienceNetworkAds
      initializeWithSettings:fbSettings
           completionHandler:^(FBAdInitResults *results) {
             if (results.success) {
               completionHandler(nil);
             } else {
               NSError *error =
                   [NSError errorWithDomain:@"GADMediationAdapterFacebook"
                                       code:0
                                   userInfo:@{NSLocalizedDescriptionKey : results.message}];
               completionHandler(error);
             }
           }];
}

+ (GADVersionNumber)version {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [kGADMAdapterFacebookVersion componentsSeparatedByString:@"."];
  if (components.count == 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADFBNetworkExtras class];
}

+ (GADVersionNumber)adSDKVersion {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [FB_AD_SDK_VERSION componentsSeparatedByString:@"."];
  if (components.count == 3) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue;
  } else {
    NSLog(@"Unexpected Facebook version string: %@. Returning 0 for adSDKVersion.",
          FB_AD_SDK_VERSION);
  }
  return version;
}

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:
                             (nonnull GADRTBSignalCompletionHandler)completionHandler {
  completionHandler([FBAdSettings bidderToken], nil);
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
  if ([adConfiguration respondsToSelector:@selector(childDirectedTreatment)] &&
      adConfiguration.childDirectedTreatment) {
    [FBAdSettings setIsChildDirected:[adConfiguration.childDirectedTreatment boolValue]];
  }

  _banner = [[GADFBBannerRenderer alloc] init];
  [_banner renderBannerForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  if ([adConfiguration respondsToSelector:@selector(childDirectedTreatment)] &&
      adConfiguration.childDirectedTreatment) {
    [FBAdSettings setIsChildDirected:[adConfiguration.childDirectedTreatment boolValue]];
  }

  _interstitial = [[GADFBInterstitialRenderer alloc] init];
  [_interstitial renderInterstitialForAdConfiguration:adConfiguration
                                    completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  if ([adConfiguration respondsToSelector:@selector(childDirectedTreatment)] &&
      adConfiguration.childDirectedTreatment) {
    [FBAdSettings setIsChildDirected:[adConfiguration.childDirectedTreatment boolValue]];
  }
  _rewardedAd = [[GADFBRewardedRenderer alloc] init];
  [_rewardedAd loadRewardedAdForAdConfiguration:adConfiguration
                              completionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
  if ([adConfiguration respondsToSelector:@selector(childDirectedTreatment)] &&
      adConfiguration.childDirectedTreatment) {
    [FBAdSettings setIsChildDirected:[adConfiguration.childDirectedTreatment boolValue]];
  }
  _native = [[GADFBNativeRenderer alloc] init];
  [_native renderNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
