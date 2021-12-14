// Copyright 2021 Google LLC.
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

#import "GADMAdapterUnity.h"
#import <UnityAds/UnityAds.h>

#import "GADMAdapterUnityUtils.h"
#import "GADMediationAdapterUnity.h"
#import "GADMUnityInterstitialNetworkAdapterProxy.h"
#import "GADMUnityBannerNetworkAdapterProxy.h"
#import "NSError+Unity.h"

@interface GADMAdapterUnity ()
@property (nonatomic, weak) id<GADMAdNetworkConnector> connector;
@property (nonatomic, strong) UADSBannerView *bannerAd;
@property (nonatomic, strong) GADMUnityBannerNetworkAdapterProxy *bannerAdDelegateProxy;
@end

@implementation GADMAdapterUnity

-(NSString *)placementId {
    return [[self.connector credentials] objectForKey:kGADMAdapterUnityPlacementID] ? : @"";
}

- (GADMUnityInterstitialNetworkAdapterProxy*)interstitialDelegateProxy {
    return [[GADMUnityInterstitialNetworkAdapterProxy alloc] initWithGADMAdNetworkConnector:self.connector adapter:self];
}

#pragma mark GADMAdNetworkAdapter

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
    return [GADMediationAdapterUnity class];
}

+ (NSString *)adapterVersion {
    return kGADMAdapterUnityVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return nil;
}

- (void)stopBeingDelegate {
    self.bannerAd.delegate = nil;
    self.bannerAd = nil;
}

#pragma mark Interstitial Methods

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
    if (!connector) {
        return nil;
    }
    self = [super init];
    if (self) {
        _connector = connector;
    }
    return self;
}

- (void)getInterstitial {
    [UnityAds load:[self placementId] loadDelegate:[self interstitialDelegateProxy]];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    [UnityAds show:rootViewController placementId:[self placementId] showDelegate:[self interstitialDelegateProxy]];
}

#pragma mark Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
    GADAdSize supportedSize = supportedAdSizeFromRequestedSize(adSize);
    if (!IsGADAdSizeValid(supportedSize)) {
        [self.connector adapter:self didFailAd:[NSError unsupportedBannerGADAdSize:adSize]];
        return;
    }

    self.bannerAd = [[UADSBannerView alloc] initWithPlacementId:[self placementId] size:supportedSize.size];
    self.bannerAdDelegateProxy = [[GADMUnityBannerNetworkAdapterProxy alloc] initWithGADMAdNetworkConnector:self.connector adapter:self];
    self.bannerAd.delegate = self.bannerAdDelegateProxy;
    [self.bannerAd load];
}


@end
