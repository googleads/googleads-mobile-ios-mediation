// Copyright 2018 Google Inc.
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

#import "GADMAdapterAdColonyRtbInterstitialRenderer.h"

#import <AdColony/AdColony.h>
#include <stdatomic.h>

#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMediationAdapterAdColony.h"

@interface GADMAdapterAdColonyRtbInterstitialRenderer () <GADMediationInterstitialAd>
@end

@implementation GADMAdapterAdColonyRtbInterstitialRenderer {
  /// Completion handler to call when the ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _renderCompletionHandler;

  /// AdColony interstitial ad.
  AdColonyInterstitial *_interstitialAd;

  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;
}

/// Asks the receiver to render the ad configuration.
- (void)renderInterstitialForAdConfig:(nonnull GADMediationInterstitialAdConfiguration *)adConfig
                    completionHandler:
                        (nonnull GADMediationInterstitialLoadCompletionHandler)handler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler = [handler copy];
  _renderCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
      id<GADMediationInterstitialAd> interstitialAd, NSError *error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationInterstitialAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(interstitialAd, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  GADMAdapterAdColonyRtbInterstitialRenderer *__weak weakSelf = self;
  [GADMAdapterAdColonyHelper
      setupZoneFromAdConfig:adConfig
                   callback:^(NSString *zone, NSError *error) {
                     GADMAdapterAdColonyRtbInterstitialRenderer *strongSelf = weakSelf;

                     if (!strongSelf) {
                       return;
                     }

                     if (error) {
                       strongSelf->_renderCompletionHandler(nil, error);
                       return;
                     }

                     [strongSelf getInterstitialFromZoneID:zone adConfig:adConfig];
                   }];
}

- (void)getInterstitialFromZoneID:(NSString *)zone
                         adConfig:(GADMediationInterstitialAdConfiguration *)adConfiguration {
  _interstitialAd = nil;

  GADMAdapterAdColonyRtbInterstitialRenderer *__weak weakSelf = self;

  GADMAdapterAdColonyLog(@"Requesting interstatial ad for zone: %@", zone);

  [AdColony requestInterstitialInZone:zone
      options:nil
      success:^(AdColonyInterstitial *_Nonnull ad) {
        GADMAdapterAdColonyLog(@"Retrieved interstitial ad for zone: %@", zone);
        [weakSelf handleAdReceived:ad forAdConfig:adConfiguration zone:zone];
      }
      failure:^(AdColonyAdRequestError *_Nonnull err) {
        NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(kGADErrorInvalidRequest,
                                                                        err.localizedDescription);
        GADMAdapterAdColonyRtbInterstitialRenderer *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        strongSelf->_renderCompletionHandler(nil, error);
        GADMAdapterAdColonyLog(@"Failed to retrieve ad: %@", error.localizedDescription);
      }];
}

- (void)handleAdReceived:(AdColonyInterstitial *_Nonnull)ad
             forAdConfig:(GADMediationInterstitialAdConfiguration *)adConfiguration
                    zone:(NSString *)zone {
  _interstitialAd = ad;
  _adEventDelegate = _renderCompletionHandler(self, nil);

  // Re-request intersitial when expires, this avoids the situation:
  // 1. Admob interstitial request from zone A. Causes ADC configure to occur with zone A,
  // then ADC ad request from zone A. Both succeed.
  // 2. Admob rewarded video request from zone B. Causes ADC configure to occur with zones A,
  // B, then ADC ad request from zone B. Both succeed.
  // 3. Try to present ad loaded from zone A. It doesn’t show because of error: `No session
  // with id: xyz has been registered. Cannot show interstitial`.
  [ad setExpire:^{
    GADMAdapterAdColonyLog(
        @"Interstitial Ad expired from zone: %@ because of configuring "
        @"another Ad. To avoid this situation, use startWithCompletionHandler: to initialize "
        @"Google Mobile Ads SDK and wait for the completion handler to be called before "
        @"requesting an dd.",
        zone);
  }];
}

#pragma mark GADMediationInterstitialAd

- (void)presentFromViewController:(UIViewController *)viewController {
  GADMAdapterAdColonyRtbInterstitialRenderer *__weak weakSelf = self;

  [_interstitialAd setOpen:^{
    GADMAdapterAdColonyRtbInterstitialRenderer *strongSelf = weakSelf;
    if (strongSelf) {
      id<GADMediationInterstitialAdEventDelegate> adEventDelegate = strongSelf->_adEventDelegate;
      [adEventDelegate willPresentFullScreenView];
      [adEventDelegate reportImpression];
    }
  }];

  [_interstitialAd setClick:^{
    GADMAdapterAdColonyRtbInterstitialRenderer *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf->_adEventDelegate reportClick];
    }
  }];

  [_interstitialAd setClose:^{
    GADMAdapterAdColonyRtbInterstitialRenderer *strongSelf = weakSelf;
    if (strongSelf) {
      id<GADMediationInterstitialAdEventDelegate> adEventDelegate = strongSelf->_adEventDelegate;
      [adEventDelegate willDismissFullScreenView];
      [adEventDelegate didDismissFullScreenView];
    }
  }];

  [_interstitialAd setLeftApplication:^{
    GADMAdapterAdColonyRtbInterstitialRenderer *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf->_adEventDelegate willBackgroundApplication];
    }
  }];

  if (![_interstitialAd showWithPresentingViewController:viewController]) {
    NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(kGADErrorMediationAdapterError,
                                                                    @"Failed to show ad for zone.");
    GADMAdapterAdColonyRtbInterstitialRenderer *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf->_adEventDelegate didFailToPresentWithError:error];
    }
  }
}

@end
