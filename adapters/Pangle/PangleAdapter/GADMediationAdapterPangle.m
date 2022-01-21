// Copyright 2021 Google LLC
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

#import "GADMediationAdapterPangle.h"
#import "GADMediationAdapterPangleConstants.h"
#import <BUAdSDK/BUAdSDK.h>
#import "GADPangleRTBBannerRenderer.h"
#import "GADPangleRTBInterstitialRenderer.h"
#import "GADPangleRTBRewardedlRenderer.h"
#import "GADPangleRTBNativeRenderer.h"
#import "GADMediationAdapterPangleConstants.h"
#import "GADMAdapterPangleUtils.h"

@interface GADMediationAdapterPangle ()

@property (nonatomic, strong) GADPangleRTBBannerRenderer *bannerRenderer;
@property (nonatomic, strong) GADPangleRTBInterstitialRenderer *interstitialRenderer;
@property (nonatomic, strong) GADPangleRTBRewardedlRenderer *rewardedlRenderer;
@property (nonatomic, strong) GADPangleRTBNativeRenderer *navtiveRenderer;

@end

@implementation GADMediationAdapterPangle

- (void)collectSignalsForRequestParameters:(nonnull GADRTBRequestParameters *)params
                         completionHandler:(nonnull GADRTBSignalCompletionHandler)completionHandler {
    NSString *signals = [BUAdSDKManager mopubBiddingToken];
    if (completionHandler) {
        completionHandler(signals,nil);
    }
}

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
    NSMutableSet *appIds = [NSMutableSet new];
    for (GADMediationCredentials *cred in configuration.credentials) {
        NSString *appId = cred.settings[GADMAdapterPangleAppID];
        if (appId && [appId isKindOfClass:[NSString class]] && appId.length) {
            [appIds addObject:appId];
        }
    }
    
    if (appIds.count < 1) {
        NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorMissingServerParameters, @"pangle mediation configuration did not contain a valid app id");
        completionHandler(error);
        return;
    }
    
    NSString *appID = [appIds anyObject];
    if (appIds.count > 1) {
        PangleLog(@"found the following app ids:%@. Please remove any app IDs which you are not using", appIds);
        PangleLog(@"configuring pangle sdk with the app id:%@", appID);
    }
    
    BUAdSDKConfiguration *cog = [BUAdSDKConfiguration configuration];
    cog.territory = BUAdSDKTerritory_NO_CN;
    cog.appID = appID;
    [BUAdSDKManager startWithAsyncCompletionHandler:^(BOOL success, NSError *error) {
        completionHandler(error);
    }];
}

+ (GADVersionNumber)adSDKVersion {
    NSString *versionString = BUAdSDKManager.SDKVersion;
    NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (versionComponents.count == 4) {
        NSInteger four = [versionComponents[3] integerValue];
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion = [versionComponents[2] integerValue]*100+four;
        
    }else {
        PangleLog(@"Unexpected version string: %@. Returning 0 for adSDKVersion.", versionString);
    }
    return version;
}

+ (GADVersionNumber)adapterVersion {
  GADVersionNumber version = {0};
  NSArray<NSString *> *components = [GADMAdapterPangleVersion componentsSeparatedByString:@"."];
  if (components.count == 4) {
    version.majorVersion = components[0].integerValue;
    version.minorVersion = components[1].integerValue;
    version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  // TODO: Return the class for passng in mediation extras (if any). Else, return `Nil`.
  return Nil;
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    [BUAdSDKManager setCoppa:adConfiguration.childDirectedTreatment.integerValue];
    self.bannerRenderer = [GADPangleRTBBannerRenderer new];
    [self.bannerRenderer renderBannerForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler {
    [BUAdSDKManager setCoppa:adConfiguration.childDirectedTreatment.integerValue];
    self.interstitialRenderer = [GADPangleRTBInterstitialRenderer new];
    [self.interstitialRenderer renderInterstitialForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler {
    [BUAdSDKManager setCoppa:adConfiguration.childDirectedTreatment.integerValue];
    self.navtiveRenderer = [GADPangleRTBNativeRenderer new];
    [self.navtiveRenderer renderNativeAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
    [BUAdSDKManager setCoppa:adConfiguration.childDirectedTreatment.integerValue];
    self.rewardedlRenderer = [GADPangleRTBRewardedlRenderer new];
    [self.rewardedlRenderer renderRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

@end
