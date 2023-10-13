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

#import "GADMAdapterMintegralRTBAppOpenAdLoader.h"
#import "GADMAdapterMintegralExtras.h"
#import "GADMAdapterMintegralUtils.h"
#import "GADMediationAdapterMintegralConstants.h"

#import <MTGSDK/MTGSDK.h>
#import <MTGSDKSplash/MTGSplashAD.h>

#include <stdatomic.h>

@interface GADMAdapterMintegralRTBAppOpenAdLoader () <MTGSplashADDelegate>
@end

@implementation GADMAdapterMintegralRTBAppOpenAdLoader {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationAppOpenLoadCompletionHandler _adLoadCompletionHandler;

  /// Ad configuration for the ad to be loaded.
  GADMediationAppOpenAdConfiguration *_adConfiguration;

  /// The Mintegral splash ad.
  MTGSplashAD *_splashAd;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationAppOpenAdEventDelegate> _adEventDelegate;
}

- (void)loadRTBAppOpenAdForAdConfiguration:
            (nonnull GADMediationAppOpenAdConfiguration *)adConfiguration
                         completionHandler:
                             (nonnull GADMediationAppOpenLoadCompletionHandler)completionHandler {
  _adConfiguration = adConfiguration;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationAppOpenLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _adLoadCompletionHandler = ^id<GADMediationAppOpenAdEventDelegate>(
      _Nullable id<GADMediationAppOpenAd> ad, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationAppOpenAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(ad, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  NSString *placementId = adConfiguration.credentials.settings[GADMAdapterMintegralPlacementID];
  NSString *adUnitId = adConfiguration.credentials.settings[GADMAdapterMintegralAdUnitID];
  if (!adUnitId.length || !placementId.length) {
    NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(
        GADMintegralErrorInvalidServerParameters, @"Ad Unit ID or Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }
  NSString *bidResponse = _adConfiguration.bidResponse;

  _splashAd =
      [[MTGSplashAD alloc] initWithPlacementID:placementId
                                        unitID:adUnitId
                                     countdown:GADMAdapterMintegralAppOpenSkipCountDownInSeconds
                                     allowSkip:YES];
  _splashAd.delegate = self;
  [_splashAd preloadWithBidToken:bidResponse];
}

#pragma mark - GADMediationAppOpenAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (_splashAd.isBiddingADReadyToShow) {
    // TODO(thanvir): keyWindow is deprecated. Use an alternative.
    UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
    [_adEventDelegate willPresentFullScreenView];
    [_splashAd showBiddingADInKeyWindow:keyWindow customView:nil];
  } else {
    NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(
        GADMintegralErrorAdFailedToShow,
        @"Mintegral SDK failed to present a bidding splash ad. It is not ready.");
    [_adEventDelegate didFailToPresentWithError:error];
  }
}

#pragma mark - MTGSplashADDelegate

- (void)splashADPreloadSuccess:(nonnull MTGSplashAD *)splashAD {
  if (_adLoadCompletionHandler) {
    _adEventDelegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)splashADPreloadFail:(nonnull MTGSplashAD *)splashAD error:(nonnull NSError *)error {
  if (_adLoadCompletionHandler) {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)splashADShowSuccess:(nonnull MTGSplashAD *)splashAD {
  [_adEventDelegate reportImpression];
}

- (void)splashADShowFail:(nonnull MTGSplashAD *)splashAD error:(nonnull NSError *)error {
  [_adEventDelegate didFailToPresentWithError:error];
}

- (void)splashADDidClick:(nonnull MTGSplashAD *)splashAD {
  [_adEventDelegate reportClick];
}

- (void)splashADWillClose:(nonnull MTGSplashAD *)splashAD {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)splashADDidClose:(nonnull MTGSplashAD *)splashAD {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)splashADLoadSuccess:(nonnull MTGSplashAD *)splashAD {
  // Not used.
}

- (void)splashADLoadFail:(nonnull MTGSplashAD *)splashAD error:(nonnull NSError *)error {
  // Not used.
}

- (void)splashAD:(nonnull MTGSplashAD *)splashAD timeLeft:(NSUInteger)time {
  // Not used.
}

#pragma mark - MTGSplashADDelegate (Splash Floating Ball - not used)

- (CGPoint)pointForSplashZoomOutADViewToAddOn:(nonnull MTGSplashAD *)splashAD {
  // Not used.
  return CGPointZero;
}

- (void)splashADDidLeaveApplication:(nonnull MTGSplashAD *)splashAD {
  // Not used.
}

- (void)splashZoomOutADViewClosed:(nonnull MTGSplashAD *)splashAD {
  // Not used.
}

- (void)splashZoomOutADViewDidShow:(nonnull MTGSplashAD *)splashAD {
  // Not used.
}

- (nonnull UIView *)superViewForSplashZoomOutADViewToAddOn:(nonnull MTGSplashAD *)splashAD {
  // Not used.
  return [[UIView alloc] initWithFrame:CGRectZero];
}

@end
