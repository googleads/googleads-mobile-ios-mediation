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

#import "GADMAdapterAdColonyRTBInterstitialRenderer.h"

#import <AdColony/AdColony.h>
#include <stdatomic.h>

#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMediationAdapterAdColony.h"

@interface GADMAdapterAdColonyRTBInterstitialRenderer () <GADMediationInterstitialAd,
                                                          AdColonyInterstitialDelegate>
@end

@implementation GADMAdapterAdColonyRTBInterstitialRenderer {
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
      _Nullable id<GADMediationInterstitialAd> interstitialAd, NSError *_Nullable error) {
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

  GADMAdapterAdColonyRTBInterstitialRenderer *__weak weakSelf = self;
  [GADMAdapterAdColonyHelper
      setupZoneFromAdConfig:adConfig
                   callback:^(NSString *zone, NSError *error) {
                     GADMAdapterAdColonyRTBInterstitialRenderer *strongSelf = weakSelf;

                     if (!strongSelf) {
                       return;
                     }

                     if (error) {
                       if (strongSelf->_renderCompletionHandler) {
                         strongSelf->_renderCompletionHandler(nil, error);
                       }

                       return;
                     }

                     GADMAdapterAdColonyLog(@"Requesting interstitial ad for zone: %@", zone);
                     AdColonyAdOptions *options =
                         [GADMAdapterAdColonyHelper getAdOptionsFromAdConfig:adConfig];
                     [AdColony requestInterstitialInZone:zone
                                                 options:options
                                             andDelegate:strongSelf];
                   }];
}

#pragma mark GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (![_interstitialAd showWithPresentingViewController:viewController]) {
    NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(kGADErrorMediationAdapterError,
                                                                    @"Failed to show ad for zone.");
    [_adEventDelegate didFailToPresentWithError:error];
  }
}

#pragma mark - AdColonyInterstitialDelegate Delegate

- (void)adColonyInterstitialDidLoad:(nonnull AdColonyInterstitial *)interstitial {
  GADMAdapterAdColonyLog(@"Loaded interstitial ad for zone: %@", interstitial.zoneID);
  _interstitialAd = interstitial;
  _adEventDelegate = _renderCompletionHandler(self, nil);
}

- (void)adColonyInterstitialDidFailToLoad:(nonnull AdColonyAdRequestError *)error {
  GADMAdapterAdColonyLog(@"Failed to load interstitial ad with error: %@",
                         error.localizedDescription);
  NSError *requestError =
      GADMAdapterAdColonyErrorWithCodeAndDescription(kGADErrorNoFill, error.localizedDescription);
  _renderCompletionHandler(nil, requestError);
}

- (void)adColonyInterstitialWillOpen:(nonnull AdColonyInterstitial *)interstitial {
  id<GADMediationInterstitialAdEventDelegate> strongAdEventDelegate = _adEventDelegate;
  [strongAdEventDelegate willPresentFullScreenView];
  [strongAdEventDelegate reportImpression];
}

- (void)adColonyInterstitialDidClose:(nonnull AdColonyInterstitial *)interstitial {
  id<GADMediationInterstitialAdEventDelegate> strongAdEventDelegate = _adEventDelegate;
  [strongAdEventDelegate willDismissFullScreenView];
  [strongAdEventDelegate didDismissFullScreenView];
}

- (void)adColonyInterstitialExpired:(nonnull AdColonyInterstitial *)interstitial {
  // Each time AdColony's SDK is configured, it discards previously loaded ads. Publishers should
  // initialize the GMA SDK and wait for initialization to complete to ensure that AdColony's SDK
  // gets initialized with all known zones.
  GADMAdapterAdColonyLog(
      @"Interstitial ad expired due to configuring another ad. Use -[GADMobileAds "
      @"startWithCompletionHandler:] to initialize the Google Mobile Ads SDK and wait for the "
      @"completion handler to be called before requesting an ad. Zone: %@",
      interstitial.zoneID);
}

- (void)adColonyInterstitialWillLeaveApplication:(nonnull AdColonyInterstitial *)interstitial {
  [_adEventDelegate willBackgroundApplication];
}

- (void)adColonyInterstitialDidReceiveClick:(nonnull AdColonyInterstitial *)interstitial {
  [_adEventDelegate reportClick];
}

@end
