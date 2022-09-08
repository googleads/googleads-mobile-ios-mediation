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

#import "GADMAdapterMintegralBannerLoader.h"
#import "GADMAdapterMintegralUtils.h"
#import "GADMediationAdapterMintegralConstants.h"

#include <stdatomic.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKBanner/MTGBannerAdView.h>
#import <MTGSDKBanner/MTGBannerAdViewDelegate.h>

static CGSize const mintegralBannerAdSize320x50 = (CGSize){320, 50};
static CGSize const mintegralBannerAdSize320x100 = (CGSize){320, 100};
static CGSize const mintegralBannerAdSize300x250 = (CGSize){300, 250};
static CGSize const mintegralBannerAdSize728x90 = (CGSize){728, 90};

@interface GADMAdapterMintegralBannerLoader ()
<GADMediationBannerAd,
MTGBannerAdViewDelegate>

@end

@implementation GADMAdapterMintegralBannerLoader{
    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationBannerLoadCompletionHandler _adLoadCompletionHandler;
    
    /// An ad event delegate to invoke when ad rendering events occur.
    id<GADMediationBannerAdEventDelegate> _adEventDelegate;
    
    /// The Mintegral banner ad.
    MTGBannerAdView *_bannerAdView;
}

- (void)loadBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:
(nonnull GADMediationBannerLoadCompletionHandler)completionHandler{
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationBannerLoadCompletionHandler originalCompletionHandler =
    [completionHandler copy];
    _adLoadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
                                                                      _Nullable id<GADMediationBannerAd> ad, NSError *_Nullable error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationBannerAdEventDelegate> delegate = nil;
        if (originalCompletionHandler) {
            delegate = originalCompletionHandler(ad, error);
        }
        originalCompletionHandler = nil;
        return delegate;
    };
        
    UIViewController *rootViewController = adConfiguration.topViewController;
    NSString *adUnitId = adConfiguration.credentials.settings[GADMAdapterMintegralAdUnitID];
    NSString *placementId = adConfiguration.credentials.settings[GADMAdapterMintegralPlacementID];
    if ([GADMAdapterMintegralUtils isStringEmpty:adUnitId] ||
        [GADMAdapterMintegralUtils isStringEmpty:placementId]) {
        NSError *error =
        GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorInvalidServerParameters, @"Ad Unit ID or Placement ID cannot be nil.");
        _adLoadCompletionHandler(nil, error);
        return;
    }

    NSError *error = nil;
    CGSize bannerSize = [self bannerSizeFromGADAdSize:adConfiguration.adSize error:&error];
    if (error) {
      _adLoadCompletionHandler(nil, error);
      return;
    }

    _bannerAdView = [[MTGBannerAdView alloc]initBannerAdViewWithAdSize:bannerSize placementId:placementId unitId:adUnitId rootViewController:rootViewController];
    _bannerAdView.delegate = self;
    _bannerAdView.autoRefreshTime = 0;
    [_bannerAdView loadBannerAdWithBidToken:adConfiguration.bidResponse];
}

- (CGSize)bannerSizeFromGADAdSize:(GADAdSize)gadAdSize error:(NSError **)error {
    CGSize gadAdCGSize = CGSizeFromGADAdSize(gadAdSize);
    GADAdSize banner50 = GADAdSizeFromCGSize(
                                             CGSizeMake(gadAdCGSize.width, mintegralBannerAdSize320x50.height));  // 320*50
    GADAdSize banner100 = GADAdSizeFromCGSize(
                                              CGSizeMake(gadAdCGSize.width, mintegralBannerAdSize320x100.height));  // 320*100
    GADAdSize banner250 = GADAdSizeFromCGSize(
                                              CGSizeMake(gadAdCGSize.width, mintegralBannerAdSize300x250.height));  // 300*250
    GADAdSize banner90 = GADAdSizeFromCGSize(
                                             CGSizeMake(gadAdCGSize.width, mintegralBannerAdSize728x90.height));  // 728*90
    NSArray *potentials = @[
        NSValueFromGADAdSize(banner50),NSValueFromGADAdSize(banner100), NSValueFromGADAdSize(banner90), NSValueFromGADAdSize(banner250)
    ];
    GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentials);
    CGSize size = CGSizeFromGADAdSize(closestSize);
    if (size.height == mintegralBannerAdSize320x50.height) {
        return mintegralBannerAdSize320x50;
    }else if (size.height == mintegralBannerAdSize320x100.height) {
        return mintegralBannerAdSize320x100;
    }else if (size.height == mintegralBannerAdSize300x250.height) {
        return mintegralBannerAdSize300x250;
    }else if (size.height == mintegralBannerAdSize728x90.height) {
        return mintegralBannerAdSize728x90;
    }
    
    if (error) {
        *error = GADMAdapterMintegralErrorWithCodeAndDescription(
                                                                 GADMintegtalErrorBannerSizeMismatch,
                                                                 [NSString stringWithFormat:@"Invalid size for Mintegral mediation adapter. Size: %@",
                                                                  NSStringFromGADAdSize(gadAdSize)]);
    }
    return CGSizeZero;
}

#pragma mark MTGBannerAdViewDelegate
- (void)adViewLoadSuccess:(MTGBannerAdView *)adView {
    if (_adLoadCompletionHandler) {
        _adEventDelegate = _adLoadCompletionHandler(self, nil);
    }
}

- (void)adViewLoadFailedWithError:(NSError *)error adView:(MTGBannerAdView *)adView {
    if (_adLoadCompletionHandler) {
        _adLoadCompletionHandler(nil, error);
    }
}

- (void)adViewWillLogImpression:(MTGBannerAdView *)adView {
    [_adEventDelegate reportImpression];
}

- (void)adViewDidClicked:(MTGBannerAdView *)adView {
    [_adEventDelegate reportClick];
}

- (void)adViewWillOpenFullScreen:(MTGBannerAdView *)adView {
    [_adEventDelegate willPresentFullScreenView];
}

- (void)adViewCloseFullScreen:(MTGBannerAdView *)adView {
    [_adEventDelegate didDismissFullScreenView];
}

#pragma mark GADMediationBannerAd
// Rendered banner ad. Called after the adapter has successfully loaded and ad invoked
// the GADBannerRenderCompletionHandler.
- (UIView *)view {
    return _bannerAdView;
}

@end
