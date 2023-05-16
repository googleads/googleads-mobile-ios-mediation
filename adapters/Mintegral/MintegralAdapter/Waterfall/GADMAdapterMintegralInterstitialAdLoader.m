// Copyright 2023 Google LLC
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

#import "GADMAdapterMintegralInterstitialAdLoader.h"
#import "GADMAdapterMintegralExtras.h"
#import "GADMAdapterMintegralUtils.h"
#import "GADMediationAdapterMintegralConstants.h"

#import <MTGSDKNewInterstitial/MTGNewInterstitialAdManager.h>
#import <MTGSDKNewInterstitial/MTGSDKNewInterstitial.h>
#include <stdatomic.h>

@interface GADMAdapterMintegralInterstitialAdLoader () <MTGNewInterstitialAdDelegate>

@end

@implementation GADMAdapterMintegralInterstitialAdLoader {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _adLoadCompletionHandler;

  /// Ad configuration for the ad to be loaded.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// The Mintegral interstitial ad.
  MTGNewInterstitialAdManager *_interstitialAd;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;
}

- (void)loadInterstitialAdForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                                 completionHandler {
  _adConfiguration = adConfiguration;
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

  NSString *adUnitId = adConfiguration.credentials.settings[GADMAdapterMintegralAdUnitID];
  NSString *placementId = adConfiguration.credentials.settings[GADMAdapterMintegralPlacementID];
  if (!adUnitId.length || !placementId.length) {
    NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(
        GADMintegralErrorInvalidServerParameters, @"Ad Unit ID or Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _interstitialAd = [[MTGNewInterstitialAdManager alloc] initWithPlacementId:placementId
                                                                      unitId:adUnitId
                                                                    delegate:self];
  [_interstitialAd loadAd];
}

#pragma mark - MTGNewInterstitialAdDelegate
- (void)newInterstitialAdResourceLoadSuccess:(MTGNewInterstitialAdManager *_Nonnull)adManager {
  if (_adLoadCompletionHandler) {
    _adEventDelegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)newInterstitialAdLoadFail:(nonnull NSError *)error
                        adManager:(MTGNewInterstitialAdManager *_Nonnull)adManager {
  if (_adLoadCompletionHandler) {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)newInterstitialAdShowSuccess:(MTGNewInterstitialAdManager *_Nonnull)adManager {
  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate reportImpression];
}

- (void)newInterstitialAdShowFail:(nonnull NSError *)error
                        adManager:(MTGNewInterstitialAdManager *_Nonnull)adManager {
  [_adEventDelegate didFailToPresentWithError:error];
}

- (void)newInterstitialAdClicked:(MTGNewInterstitialAdManager *_Nonnull)adManager {
  [_adEventDelegate reportClick];
}

- (void)newInterstitialAdDismissedWithConverted:(BOOL)converted
                                      adManager:(MTGNewInterstitialAdManager *_Nonnull)adManager {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)newInterstitialAdDidClosed:(MTGNewInterstitialAdManager *_Nonnull)adManager {
  [_adEventDelegate didDismissFullScreenView];
}

#pragma mark - GADMediationInterstitialAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  GADMAdapterMintegralExtras *extras = _adConfiguration.extras;
  _interstitialAd.playVideoMute = extras.muteVideoAudio;
  if ([_interstitialAd isAdReady]) {
    [_interstitialAd showFromViewController:viewController];
  } else {
    NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(
        GADMintegralErrorAdFailedToShow,
        @"Mintegral SDK failed to present a waterfall interstitial ad.");
    [_adEventDelegate didFailToPresentWithError:error];
  }
}

@end
