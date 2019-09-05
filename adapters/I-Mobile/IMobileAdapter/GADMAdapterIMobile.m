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

#import "GADMAdapterIMobile.h"
#import "GADMAdapterIMobileConstants.h"
#import "GADMAdapterIMobileHelper.h"

/// Ad type.
typedef NS_ENUM(NSUInteger, kImobileAdType) {
    kImobileAdTypeBanner,
    kImobileAdTypeInterstitial
};

/// Adapter for banner and interstitial ads.
@interface IMobileAdapter ()

/// Connector for AdMob.
@property (nonatomic, weak) id<GADMAdNetworkConnector> connector;

/// View to display ads.
@property (nonatomic, strong) UIView *imobileAdView;

/// Ad type.
@property (atomic) kImobileAdType adType;

@end

@implementation IMobileAdapter

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

        // Get parameters for i-mobile SDK.
        NSDictionary *params = [connector credentials];
        NSString *publisherId = params[kGADMAdapterIMobilePublisherIdKey];
        NSString *mediaId = params[kGADMAdapterIMobileMediaIdKey];
        NSString *spotId = params[kGADMAdapterIMobileSpotIdKey];

        // Call i-mobile SDK.
        [ImobileSdkAds registerWithPublisherID:publisherId MediaID:mediaId SpotID:spotId];
        [ImobileSdkAds setSpotDelegate:spotId delegate:self];
        [ImobileSdkAds startBySpotID:spotId];
    }
    return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
    // Ad type is banner.
    self.adType = kImobileAdTypeBanner;

    // Validate adSize.
    if (!(GADAdSizeEqualToSize(adSize, kGADAdSizeBanner)
        || GADAdSizeEqualToSize(adSize, kGADAdSizeLargeBanner)
        || GADAdSizeEqualToSize(adSize, kGADAdSizeMediumRectangle)
        || GADAdSizeEqualToSize(adSize, kGADAdSizeSmartBannerPortrait))) {

        if (self.connector) {
            NSError *error = [GADMAdapterIMobileHelper errorWithDescritption:[NSString stringWithFormat:@"%@ is not supported.", NSStringFromGADAdSize(adSize)] code:kGADErrorMediationInvalidAdSize];
            [self.connector adapter:self didFailAd:error];
        }
        return;
    }

    // Create view to display ads.
    if (GADAdSizeEqualToSize(adSize, kGADAdSizeSmartBannerPortrait)) {
        CGFloat adWidth = [[UIScreen mainScreen] bounds].size.width < [[UIScreen mainScreen] bounds].size.height ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height;
        self.imobileAdView = [[UIView alloc] initWithFrame:CGRectMake((adWidth - 320) / 2, 0, adWidth, 50)];
    } else {
        self.imobileAdView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, adSize.size.width, adSize.size.height)];
    }

    // Call i-mobile SDK.
    if (self.connector) {
        [ImobileSdkAds showBySpotIDForAdMobMediation:[self.connector credentials][kGADMAdapterIMobileSpotIdKey] View:self.imobileAdView];
    }
}

- (void)getInterstitial {
    // Ad type is interstitial.
    self.adType = kImobileAdTypeInterstitial;

    // Call i-mobile SDK.
    if (self.connector && [ImobileSdkAds getStatusBySpotID:[self.connector credentials][kGADMAdapterIMobileSpotIdKey]] == IMOBILESDKADS_STATUS_READY) {
        [self.connector adapterDidReceiveInterstitial:self];
    }
}

- (void)stopBeingDelegate {
    self.imobileAdView = nil;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    if (self.connector) {
        [self.connector adapterWillPresentInterstitial:self];
        [ImobileSdkAds showBySpotID:[self.connector credentials][kGADMAdapterIMobileSpotIdKey]];
    }
}

#pragma mark - IMobileSdkAdsDelegate

- (void)imobileSdkAdsSpot:(NSString *)spotId
        didReadyWithValue:(ImobileSdkAdsReadyResult)value {

    if (self.connector) {
        switch (self.adType) {
            case kImobileAdTypeBanner:
                [self.connector adapter:self didReceiveAdView:self.imobileAdView];
                break;
            case kImobileAdTypeInterstitial:
                [self.connector adapterDidReceiveInterstitial:self];
                break;
            default:
                break;
        }
    }
}

- (void)imobileSdkAdsSpot:(NSString *)spotId
         didFailWithValue:(ImobileSdkAdsFailResult)value {

    [self stopBeingDelegate];
    if (self.connector) {
        NSError *error = [GADMAdapterIMobileHelper errorWithDescritption:[NSString stringWithFormat:@"Error. Reason is %@", value] code:[GADMAdapterIMobileHelper getAdMobErrorWithIMobileResult:value]];
        [self.connector adapter:self didFailAd:error];
    }
}

- (void)imobileSdkAdsSpotDidClick:(NSString *)spotId {
    if (self.connector) {
        [self.connector adapterDidGetAdClick:self];
        [self.connector adapterWillLeaveApplication:self];
    }
}

- (void)imobileSdkAdsSpotDidClose:(NSString *)spotId {
    if (self.connector) {
        [self.connector adapterDidDismissInterstitial:self];
    }
}

@end
