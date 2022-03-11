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

#import "GADPangleRTBInterstitialRenderer.h"
#import <BUAdSDK/BUAdSDK.h>
#include <stdatomic.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"

@interface GADPangleRTBInterstitialRenderer () <BUFullscreenVideoAdDelegate>

@end

@implementation GADPangleRTBInterstitialRenderer {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _loadCompletionHandler;
  /// The Pangle interstitial ad.
  BUFullscreenVideoAd *_fullScreenAdVideo;
  /// An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationInterstitialAdEventDelegate> _delegate;
}

- (void)renderInterstitialForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                                 completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _loadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
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

  NSString *placementId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID];
  if (!placementId.length) {
    NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(
        GADPangleErrorInvalidServerParameters,
        [NSString stringWithFormat:@"%@ cannot be nil.", GADMAdapterPanglePlacementID]);
    _loadCompletionHandler(nil, error);
    return;
  }
  _fullScreenAdVideo = [[BUFullscreenVideoAd alloc] initWithSlotID:placementId];
  _fullScreenAdVideo.delegate = self;
  [_fullScreenAdVideo setAdMarkup:adConfiguration.bidResponse];
}

#pragma mark - GADMediationInterstitialAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_fullScreenAdVideo showAdFromRootViewController:viewController];
}

#pragma mark -  BUFullscreenVideoAdDelegate
- (void)fullscreenVideoMaterialMetaAdDidLoad:(BUFullscreenVideoAd *)fullscreenVideoAd {
  if (_loadCompletionHandler) {
    _delegate = _loadCompletionHandler(self, nil);
  }
}

- (void)fullscreenVideoAd:(BUFullscreenVideoAd *)fullscreenVideoAd
         didFailWithError:(NSError *_Nullable)error {
  if (_loadCompletionHandler) {
    _loadCompletionHandler(nil, error);
  }
}

- (void)fullscreenVideoAdWillVisible:(BUFullscreenVideoAd *)fullscreenVideoAd {
  id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)fullscreenVideoAdDidClick:(BUFullscreenVideoAd *)fullscreenVideoAd {
  id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
  [delegate reportClick];
}

- (void)fullscreenVideoAdWillClose:(BUFullscreenVideoAd *)fullscreenVideoAd {
  id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
  [delegate willDismissFullScreenView];
}

- (void)fullscreenVideoAdDidClose:(BUFullscreenVideoAd *)fullscreenVideoAd {
  id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
  [delegate didDismissFullScreenView];
}

- (void)fullscreenVideoAdDidPlayFinish:(BUFullscreenVideoAd *)fullscreenVideoAd
                      didFailWithError:(NSError *_Nullable)error {
  if (error) {
    id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
    [delegate didFailToPresentWithError:error];
  }
}

@end
