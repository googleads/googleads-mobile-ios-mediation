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
#import <PAGAdSDK/PAGAdSDK.h>
#include <stdatomic.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"
#import "GADPangleNetworkExtras.h"

@interface GADPangleRTBInterstitialRenderer () <PAGLInterstitialAdDelegate>

@end

@implementation GADPangleRTBInterstitialRenderer {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _loadCompletionHandler;
  /// The Pangle interstitial ad.
  PAGLInterstitialAd *_interstitialAd;
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
  PAGInterstitialRequest *request = [PAGInterstitialRequest request];
  request.adString = adConfiguration.bidResponse;
  __weak typeof(self) weakSelf = self;
  [PAGLInterstitialAd
       loadAdWithSlotID:placementId
                request:request
      completionHandler:^(PAGLInterstitialAd *_Nullable interstitialAd, NSError *_Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        if (error) {
          if (strongSelf->_loadCompletionHandler) {
            strongSelf->_loadCompletionHandler(nil, error);
          }
          return;
        }

        strongSelf->_interstitialAd = interstitialAd;
        strongSelf->_interstitialAd.delegate = strongSelf;

        if (strongSelf->_loadCompletionHandler) {
          strongSelf->_delegate = strongSelf->_loadCompletionHandler(strongSelf, nil);
        }
      }];
}

#pragma mark - GADMediationInterstitialAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_interstitialAd presentFromRootViewController:viewController];
}

#pragma mark - PAGLInterstitialAdDelegate
- (void)adDidShow:(PAGLInterstitialAd *)ad {
  id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)adDidClick:(PAGLInterstitialAd *)ad {
  id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
  [delegate reportClick];
}

- (void)adDidDismiss:(PAGLInterstitialAd *)ad {
  id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
  [delegate willDismissFullScreenView];
  [delegate didDismissFullScreenView];
}

@end
