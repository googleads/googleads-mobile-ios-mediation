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
#include <stdatomic.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"
#import "GADPangleNetworkExtras.h"
#import <PAGAdSDK/PAGAdSDK.h>

@interface GADPangleRTBInterstitialRenderer () <PAGLInterstitialAdDelegate>

/// The completion handler to call when the ad loading succeeds or fails.
@property (nonatomic, copy) GADMediationInterstitialLoadCompletionHandler loadCompletionHandler;
/// The Pangle interstitial ad.
@property (nonatomic, strong) PAGLInterstitialAd *interstitialAd;
/// An ad event delegate to invoke when ad rendering events occur.
@property (nonatomic, weak) id<GADMediationInterstitialAdEventDelegate> delegate;

@end

@implementation GADPangleRTBInterstitialRenderer

- (void)renderInterstitialForAdConfiguration:
            (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
                           completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)
                                                 completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  self.loadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
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
    self.loadCompletionHandler(nil, error);
    return;
  }
  PAGInterstitialRequest *request = [PAGInterstitialRequest request];
  request.adString = adConfiguration.bidResponse;
  __weak typeof(self) weakSelf = self;
  [PAGLInterstitialAd loadAdWithSlotID:placementId request:request completionHandler:^(PAGLInterstitialAd * _Nullable interstitialAd, NSError * _Nullable error) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) {
       return;
      }
    if (error) {
      if (strongSelf.loadCompletionHandler) {
        strongSelf.loadCompletionHandler(nil, error);
      }
      return;
    }
    
    strongSelf.interstitialAd = interstitialAd;
    strongSelf.interstitialAd.delegate = strongSelf;
    
    if (strongSelf.loadCompletionHandler) {
      strongSelf.delegate = strongSelf.loadCompletionHandler(strongSelf, nil);
    }
  }];
}

#pragma mark - GADMediationInterstitialAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [self.interstitialAd presentFromRootViewController:viewController];
}

#pragma mark - PAGLInterstitialAdDelegate
- (void)adDidShow:(PAGLInterstitialAd *)ad {
  id<GADMediationInterstitialAdEventDelegate> delegate = self.delegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)adDidClick:(PAGLInterstitialAd *)ad {
  id<GADMediationInterstitialAdEventDelegate> delegate = self.delegate;
  [delegate reportClick];
}

- (void)adDidDismiss:(PAGLInterstitialAd *)ad {
  id<GADMediationInterstitialAdEventDelegate> delegate = self.delegate;
  [delegate willDismissFullScreenView];
  [delegate didDismissFullScreenView];
}

@end
