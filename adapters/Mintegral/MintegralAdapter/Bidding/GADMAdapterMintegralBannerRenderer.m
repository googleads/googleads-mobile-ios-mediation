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

#import "GADMAdapterMintegralBannerRenderer.h"
#import "GADMAdapterMintegralUtils.h"
#import "GADMediationAdapterMintegralConstants.h"
#include <stdatomic.h>
#import <MTGSDK/MTGSDK.h>
#import <MTGSDKBanner/MTGBannerAdView.h>
#import <MTGSDKBanner/MTGBannerAdViewDelegate.h>

@interface GADMAdapterMintegralBannerRenderer ()
<GADMediationBannerAd,
MTGBannerAdViewDelegate>

@end

@implementation GADMAdapterMintegralBannerRenderer{
    /// Ad configuration for the ad to be loaded.
    GADMediationBannerAdConfiguration *_adConfiguration;
    
    /// The completion handler to call when the ad loading succeeds or fails.
    GADMediationBannerLoadCompletionHandler _adLoadCompletionHandler;
    
    /// An ad event delegate to invoke when ad rendering events occur.
    id<GADMediationBannerAdEventDelegate> _adEventDelegate;
    
    /// The Mintegral banner ad.
    MTGBannerAdView *_bannerAdView;
}

- (void)renderBannerForAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:
(nonnull GADMediationBannerLoadCompletionHandler)completionHandler{
    _adConfiguration = adConfiguration;
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
        
    NSString *adUnitId = adConfiguration.credentials.settings[GADMAdapterMintegralAdUnitID];
    NSString *placementId = adConfiguration.credentials.settings[GADMAdapterMintegralPlacementID];
    UIViewController *rootViewController = adConfiguration.topViewController;

    if ([GADMAdapterMintegralUtils isStringEmpty:adUnitId]) {
        NSError *error =
        GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorInvalidServerParameters, @"Ad Unit ID cannot be nil.");
        _adLoadCompletionHandler(nil, error);
        return;
    }
    
    _bannerAdView = [[MTGBannerAdView alloc]initBannerAdViewWithAdSize:adConfiguration.adSize.size placementId:placementId unitId:adUnitId rootViewController:rootViewController];
    _bannerAdView.delegate = self;
    _bannerAdView.autoRefreshTime = 0;
    [_bannerAdView loadBannerAdWithBidToken:adConfiguration.bidResponse];
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
