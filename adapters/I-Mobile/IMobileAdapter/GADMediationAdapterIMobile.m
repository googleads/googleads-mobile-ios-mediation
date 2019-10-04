// Copyright 2019 Google Inc.
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

#import "GADMediationAdapterIMobile.h"
#import "GADIMobileMediatedUnifiedNativeAd.h"
#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileHelper.h"

/// Adapter for Native ads.
@interface GADMediationAdapterIMobile ()

/// Connector for AdMob.
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;

/// View for i-mobile SDK.
@property(nonatomic, strong) UIView *sdkView;

@end

@implementation GADMediationAdapterIMobile

#pragma mark - GADMAdNetworkAdapter

+ (NSString *)adapterVersion {
    return kGADMAdapterIMobileVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return Nil;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
    self = [super init];
    if (self) {
        // Initialize.
        self.connector = connector;
        self.sdkView = [[UIView alloc] init];

        // Get parameters for i-mobile SDK.
        NSDictionary *params = [connector credentials];
        NSString *publisherId = params[kGADMAdapterIMobilePublisherIdKey];
        NSString *mediaId = params[kGADMAdapterIMobileMediaIdKey];
        NSString *spotId = params[kGADMAdapterIMobileSpotIdKey];

        // Call i-mobile SDK.
        [ImobileSdkAds registerWithPublisherID:publisherId MediaID:mediaId SpotID:spotId];
        [ImobileSdkAds startBySpotID:spotId];
    }
    return self;
}

/// Not supported.
- (void)getBannerWithSize:(GADAdSize)adSize {
    if (self.connector) {
        NSError *error = [GADMAdapterIMobileHelper errorWithDescritption:@"GADMediationAdapterIMobile doesn't support banner ads. Please use GADMAdapterIMobile." code:kGADErrorInvalidRequest];
        [self.connector adapter:self didFailAd:error];
    }
}

/// Not supported.
- (void)getInterstitial {
    if (self.connector) {
        NSError *error = [GADMAdapterIMobileHelper errorWithDescritption:@"GADMediationAdapterIMobile doesn't support interstitial ads. Please use GADMAdapterIMobile." code:kGADErrorInvalidRequest];
        [self.connector adapter:self didFailAd:error];
    }
}

- (void)stopBeingDelegate {
    self.sdkView = nil;
}

/// Not supported.
- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    if (self.connector) {
        NSError *error = [GADMAdapterIMobileHelper errorWithDescritption:@"GADMediationAdapterIMobile doesn't support interstitial ads. Please use GADMAdapterIMobile." code:kGADErrorInvalidRequest];
        [self.connector adapter:self didFailAd:error];
    }
}

- (void)getNativeAdWithAdTypes:(NSArray<GADAdLoaderAdType> *)adTypes
                       options:(NSArray<GADAdLoaderOptions *> *)options {

    // Validate adTypes.
    if (![adTypes containsObject:kGADAdLoaderAdTypeUnifiedNative]) {
        if (self.connector) {
            NSError *error = [GADMAdapterIMobileHelper errorWithDescritption:@"GADMediationAdapterIMobile only supports UnifiedNative." code:kGADErrorInvalidRequest];
            [self.connector adapter:self didFailAd:error];
        }
        return;
    }

    // Call i-mobile SDK.
    [ImobileSdkAds getNativeAdData:[self.connector credentials][kGADMAdapterIMobileSpotIdKey] View:self.sdkView Params:[[ImobileSdkAdsNativeParams alloc] init] Delegate:self];
}

#pragma mark - IMobileSdkAdsDelegate

- (void)imobileSdkAdsSpot:(NSString *)spotId
         didFailWithValue:(ImobileSdkAdsFailResult)value {
    
    [self stopBeingDelegate];
    if (self.connector) {
        NSError *error = [GADMAdapterIMobileHelper errorWithDescritption:[NSString stringWithFormat:@"Error. Reason is %@", value] code:[GADMAdapterIMobileHelper getAdMobErrorWithIMobileResult:value]];
        [self.connector adapter:self didFailAd:error];
    }
}

- (void)onNativeAdDataReciveCompleted:(NSString *)spotId
                          nativeArray:(NSArray *)nativeArray {

    // Check ad data.
    if ([nativeArray count] == 0) {
        if (self.connector) {
            NSError *error = [GADMAdapterIMobileHelper errorWithDescritption:@"No ads to show." code:kGADErrorNoFill];
            [self.connector adapter:self didFailAd:error];
        }
        return;
    }

    // Get ad image.
    ImobileSdkAdsNativeObject* iMobileNativeAd = nativeArray[0];
    [iMobileNativeAd getAdImageCompleteHandler:^(UIImage *image) {
        if (self.connector) {
            GADIMobileMediatedUnifiedNativeAd *unifiedAd = [[GADIMobileMediatedUnifiedNativeAd alloc] initWithIMobileNativeAd:iMobileNativeAd image:image];
            [self.connector adapter:self didReceiveMediatedUnifiedNativeAd:unifiedAd];
        }
    }];
}

@end
