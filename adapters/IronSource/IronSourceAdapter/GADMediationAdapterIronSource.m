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

#import "GADMediationAdapterIronSource.h"
#import "GADMAdapterIronSourceBannerAd.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceInterstitialAd.h"
#import "GADMAdapterIronSourceRewardedAd.h"
#import "GADMAdapterIronSourceUtils.h"

@interface GADMediationAdapterIronSource () {
    GADMAdapterIronSourceRewardedAd *_rewardedAd;
    GADMAdapterIronSourceInterstitialAd *_interstitialAd;
    GADMAdapterIronSourceBannerAd *_bannerAd;
}

@end

@implementation GADMediationAdapterIronSource

#pragma mark GADMediation Adapter implementation

+ (void)setUpWithConfiguration:(nonnull GADMediationServerConfiguration *)configuration
             completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
    NSMutableSet *appKeys = [[NSMutableSet alloc] init];
    NSMutableSet *ironSourceAdUnits = [[NSMutableSet alloc] init];
    
    // Check which ad units are expected to be served in the current session.
    for (GADMediationCredentials *cred in configuration.credentials) {
        if (cred.format == GADAdFormatInterstitial) {
            GADMAdapterIronSourceMutableSetAddObject(ironSourceAdUnits, IS_INTERSTITIAL);
        } else if (cred.format == GADAdFormatRewarded) {
            GADMAdapterIronSourceMutableSetAddObject(ironSourceAdUnits, IS_REWARDED_VIDEO);
        } else if (cred.format == GADAdFormatBanner) {
            GADMAdapterIronSourceMutableSetAddObject(ironSourceAdUnits, IS_BANNER);
        }
        
        NSString *appKeyFromSetting = cred.settings[GADMAdapterIronSourceAppKey];
        GADMAdapterIronSourceMutableSetAddObject(appKeys, appKeyFromSetting);
    }
    
    if (!appKeys.count) {
        NSError *error = GADMAdapterIronSourceErrorWithCodeAndDescription(
                                                                          GADMAdapterIronSourceErrorInvalidServerParameters,
                                                                          @"IronSource mediation configurations did not contain a valid app key.");
        completionHandler(error);
        return;
    }
    
    NSString *appKey = [appKeys anyObject];
    if (appKeys.count > 1) {
        // Multiple app keys are ignored and only one of them is used
        [GADMAdapterIronSourceUtils
         onLog:[NSString stringWithFormat:
                @"Found the following app keys: %@. "
                @"Please remove any app keys you are not using from the AdMob UI.",
                appKeys]];
        [GADMAdapterIronSourceUtils
         onLog:[NSString stringWithFormat:
                @"Initializing IronSource SDK with the app key %@, for ad formats %@",
                appKey, ironSourceAdUnits]];
    }
    
    // Report the mediation type to IronSource
    [IronSource
     setMediationType:[NSString stringWithFormat:@"%@%@SDK%@", GADMAdapterIronSourceMediationName,
                       GADMAdapterIronSourceInternalVersion,
                       [GADMAdapterIronSourceUtils getAdMobSDKVersion]]];
    
    // Initiailize the IronSource SDK
    [[GADMediationAdapterIronSource alloc] initIronSourceSDKWithAppKey:appKey
                                                            forAdUnits:ironSourceAdUnits
                                                     completionHandler:completionHandler];
}

+ (GADVersionNumber)adSDKVersion {
    GADVersionNumber version = {0};
    NSString *sdkVersion = [IronSource sdkVersion];
    NSArray<NSString *> *components = [sdkVersion componentsSeparatedByString:@"."];
    if (components.count > 2) {
        version.majorVersion = components[0].integerValue;
        version.minorVersion = components[1].integerValue;
        version.patchVersion = components[2].integerValue;
    } else if (components.count == 2) {
        version.majorVersion = components[0].integerValue;
        version.minorVersion = components[1].integerValue;
    } else if (components.count == 1) {
        version.majorVersion = components[0].integerValue;
    }
    
    return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
    return nil;
}

+ (GADVersionNumber)adapterVersion {
    GADVersionNumber version = {0};
    NSString *adapterVersion = GADMAdapterIronSourceAdapterVersion;
    NSArray<NSString *> *components = [adapterVersion componentsSeparatedByString:@"."];
    if (components.count >= 4) {
        version.majorVersion = components[0].integerValue;
        version.minorVersion = components[1].integerValue;
        version.patchVersion = components[2].integerValue * 100 + components[3].integerValue;
    }
    
    return version;
}

- (void)collectSignalsForRequestParameters:(GADRTBRequestParameters *)params
                         completionHandler:(GADRTBSignalCompletionHandler)completionHandler {
    completionHandler([IronSource getISDemandOnlyBiddingData], nil);
}

- (void)loadRewardedAdForAdConfiguration:
(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
    if (adConfiguration.bidResponse){
        _rtbRvAd = [GADMAdapterIronSourceRtbRewardedAd alloc];
        [_rtbRvAd loadRewardedAdForConfiguration:adConfiguration completionHandler:completionHandler ];
    } else {
        _rewardedAd = [GADMAdapterIronSourceRewardedAd alloc];
        [_rewardedAd loadRewardedAdForConfiguration:adConfiguration completionHandler:completionHandler];
    }
}

- (void)loadRewardedInterstitialAdForAdConfiguration:
(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                                   completionHandler:
(nonnull GADMediationRewardedLoadCompletionHandler)
completionHandler {
    // IronSource Rewarded Interstitial ads use the same Rewarded Video API.
    NSLog(@"IronSource adapter was asked to load a rewarded interstitial ad. Using the rewarded ad "
          @"request flow to load the ad to attempt to load a rewarded interstitial ad from "
          @"IronSource.");
    [self loadRewardedAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

- (void)loadInterstitialForAdConfiguration:
(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
completionHandler {
    if (adConfiguration.bidResponse){
        self.rtbIsAd = [GADMAdapterIronSourceRtbInterstitialAd alloc];
        [self.rtbIsAd loadInterstitialForAdConfiguration:adConfiguration completionHandler:completionHandler ];
        
    } else {
        _interstitialAd = [GADMAdapterIronSourceInterstitialAd alloc];
        [_interstitialAd loadInterstitialForAdConfiguration:adConfiguration
                                          completionHandler:completionHandler];
    }
}

- (void)loadBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:
(nonnull GADMediationBannerLoadCompletionHandler)completionHandler {
    _bannerAd = [GADMAdapterIronSourceBannerAd alloc];
    [_bannerAd loadBannerAdForAdConfiguration:adConfiguration completionHandler:completionHandler];
}

#pragma mark - Initialize IronSource SDK



- (void)initIronSourceSDKWithAppKey:(nonnull NSString *)appKey forAdUnits:(nonnull NSSet *)adUnits completionHandler:(nonnull GADMediationAdapterSetUpCompletionBlock)completionHandler {
    
    NSArray<ISAAdFormat *> *adunitToInit = [GADMAdapterIronSourceUtils adFormatsToInitializeForAdUnits:adUnits];
    ISAInitRequestBuilder *requestBuilder = [[[ISAInitRequestBuilder alloc] initWithAppKey: appKey] withLegacyAdFormats: adunitToInit];
    ISAInitRequest *request = [requestBuilder build];
    
    [IronSourceAds initWithRequest: request completion:^(BOOL success, NSError *_Nullable error) {
        if ( !success || error )
        {
            [GADMAdapterIronSourceUtils
                onLog:[NSString stringWithFormat:@"iAds init failed with error reason: %@",
                       error.localizedDescription]];
            completionHandler(error);
            return;
        }
        [GADMAdapterIronSourceUtils
            onLog:[NSString stringWithFormat:@"iAds SDK initialized"]];
        completionHandler(nil);
    }];
}




@end
