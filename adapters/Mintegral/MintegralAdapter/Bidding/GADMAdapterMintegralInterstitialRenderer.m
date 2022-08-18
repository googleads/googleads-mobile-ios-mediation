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

#import "GADMAdapterMintegralInterstitialRenderer.h"
#import "GADMAdapterMintegralUtils.h"
#import "GADMediationAdapterMintegralConstants.h"
#import "GADMAdapterMintegralExtras.h"
#include <stdatomic.h>
#import <MTGSDKNewInterstitial/MTGSDKNewInterstitial.h>
#import <MTGSDKNewInterstitial/MTGNewInterstitialBidAdManager.h>

@interface GADMAdapterMintegralInterstitialRenderer ()<GADMediationInterstitialAd,MTGNewInterstitialBidAdDelegate>

@end

@implementation GADMAdapterMintegralInterstitialRenderer
{
    // The completion handler to call when the ad loading succeeds or fails.
    GADMediationInterstitialLoadCompletionHandler _adLoadCompletionHandler;
    
    /// Data used to render an interstitial Ad.
    GADMediationInterstitialAdConfiguration *_adConfiguration;
    
    // The mintegral interstitial ad.
    MTGNewInterstitialBidAdManager *_interstitialAd;
    // An ad event delegate to invoke when ad rendering events occur.
    // Intentionally keeping a reference to the delegate because this delegate is returned from the
    // GMA SDK, not set on the GMA SDK.
    id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;
}

- (void)renderInterstitialForAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                                 completionHandler{
    _adConfiguration = adConfiguration;
    // Store the ad config and completion handler for later use.
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
    [completionHandler copy];
    _adLoadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
                                                                        _Nullable id<GADMediationInterstitialAd> ad, NSError *_Nullable error) {
        if (atomic_flag_test_and_set(&completionHandlerCalled)) {
            return nil;
        }
        id<GADMediationInterstitialAdEventDelegate> delegate = nil;
        if (originalCompletionHandler) {
            delegate = originalCompletionHandler(ad, error);
        }
        originalCompletionHandler = nil;
        return delegate;
    };
    
    NSString *unitId = adConfiguration.credentials.settings[GADMAdapterMintegralAdUnitID];
    NSString *placementId = adConfiguration.credentials.settings[GADMAdapterMintegralPlacementID];
    
    // if the unitId is nil.
    if ([GADMAdapterMintegralUtils isEmpty:unitId]) {
        NSError *error =
        GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorInvalidServerParameters, @"Unit ID cannot be nil.");
        _adLoadCompletionHandler(nil, error);
        return;
    }
    
    if ([GADMAdapterMintegralUtils isEmpty:adConfiguration.bidResponse]) {
        NSError *error =
        GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorInvalidServerParameters, @"bid token cannot be nil.");
        _adLoadCompletionHandler(nil, error);
        return;
    }
    
    _interstitialAd = [[MTGNewInterstitialBidAdManager alloc]initWithPlacementId:placementId unitId:unitId delegate:self];
    [_interstitialAd loadAdWithBidToken:adConfiguration.bidResponse];
}
- (void)newInterstitialBidAdLoadSuccess:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
}


- (void)newInterstitialBidAdResourceLoadSuccess:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    if (_adLoadCompletionHandler) {
        _adEventDelegate = _adLoadCompletionHandler(self, nil);
    }
}


- (void)newInterstitialBidAdLoadFail:(nonnull NSError *)error adManager:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    if (_adLoadCompletionHandler) {
        _adLoadCompletionHandler(nil, error);
    }
}

- (void)newInterstitialBidAdShowSuccess:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    [_adEventDelegate reportImpression];
    [_adEventDelegate willPresentFullScreenView];
}

- (void)newInterstitialBidAdShowSuccessWithBidToken:(nonnull NSString * )bidToken adManager:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
}

- (void)newInterstitialBidAdShowFail:(nonnull NSError *)error adManager:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    [_adEventDelegate didFailToPresentWithError:error];
}

- (void)newInterstitialBidAdPlayCompleted:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {

}

- (void)newInterstitialBidAdEndCardShowSuccess:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
}

- (void)newInterstitialBidAdClicked:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    [_adEventDelegate reportClick];
}

- (void)newInterstitialBidAdDismissedWithConverted:(BOOL)converted adManager:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    [_adEventDelegate willDismissFullScreenView];
}

- (void)newInterstitialBidAdDidClosed:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
    [_adEventDelegate didDismissFullScreenView];
}

- (void)newInterstitialBidAdRewarded:(BOOL)rewardedOrNot alertWindowStatus:(MTGNIAlertWindowStatus)alertWindowStatus adManager:(MTGNewInterstitialBidAdManager *_Nonnull)adManager {
}

#pragma mark GADMediationRewardedAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    
    GADMAdapterMintegralExtras *extras = _adConfiguration.extras;
    if (extras) {
        _interstitialAd.playVideoMute = extras.playVideoMute;
    }
    
    if ([_interstitialAd isAdReady]) {
        [_interstitialAd showFromViewController:viewController];
    }else{
        NSError *error =
        GADMAdapterMintegralErrorWithCodeAndDescription(GADMintegralErrorAdNotValid, @"Unable to display ad.");
        [_adEventDelegate didFailToPresentWithError:error];
    }
}
@end
