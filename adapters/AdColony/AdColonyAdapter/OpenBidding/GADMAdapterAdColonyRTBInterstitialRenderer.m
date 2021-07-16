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

  /// Ad configuration for the ad to be loaded.
  GADMediationInterstitialAdConfiguration *_adConfiguration;
}

/// Asks the receiver to render the ad configuration.
- (void)renderInterstitialForAdConfig:(nonnull GADMediationInterstitialAdConfiguration *)adConfig
                    completionHandler:
                        (nonnull GADMediationInterstitialLoadCompletionHandler)handler {
  _adConfiguration = adConfig;
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

  [self loadAd];
}

- (void)loadAd {
  GADMAdapterAdColonyRTBInterstitialRenderer *__weak weakSelf = self;
  [GADMAdapterAdColonyHelper
      setupZoneFromAdConfig:_adConfiguration
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
                     AdColonyAdOptions *options = [GADMAdapterAdColonyHelper
                         getAdOptionsFromAdConfig:strongSelf->_adConfiguration];
                     [AdColony requestInterstitialInZone:zone
                                                 options:options
                                             andDelegate:strongSelf];
                   }];
}

#pragma mark GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (![_interstitialAd showWithPresentingViewController:viewController]) {
    NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(GADMAdapterAdColonyErrorShow,
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
  GADMAdapterAdColonyLog("Failed to load interstitial ad with error: %@",
                         error.localizedDescription);
  _renderCompletionHandler(nil, error);
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
  // Only reload an ad on bidding, where AdColony would otherwise be charged for an impression
  // it couldn't show. Don't reload ads for regular mediation, as it has side effects on reporting.
  if (_adConfiguration.bidResponse) {
    // Re-requesting interstitial ad to avoid the following situation:
    // 1. Request a interstitial ad from AdColony.
    // 2. AdColony ad loads. Adapter sends a callback saying the ad has been loaded.
    // 3. AdColony ad expires due to timeout.
    // 4. Publisher will not be able to present the ad as it has expired.
    [self loadAd];
  }
}

- (void)adColonyInterstitialWillLeaveApplication:(nonnull AdColonyInterstitial *)interstitial {
  [_adEventDelegate willBackgroundApplication];
}

- (void)adColonyInterstitialDidReceiveClick:(nonnull AdColonyInterstitial *)interstitial {
  [_adEventDelegate reportClick];
}

@end
