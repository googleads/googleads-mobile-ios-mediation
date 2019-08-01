// Copyright 2019 Google LLC.
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

#import "InMobiInterstitialAd.h"
#include <stdatomic.h>
#import "GADMAdapterInMobiUtils.h"

@interface InMobiInterstitialAd () <GADMediationInterstitialAd, IMInterstitialDelegate>

@property(nonatomic, strong) IMInterstitial *interstitial;
@property(nonatomic, copy) GADRTBSignalCompletionHandler signalCompletionHandler;
@property(nonatomic, copy) GADMediationInterstitialLoadCompletionHandler renderCompletionHandler;
@property(nonatomic, weak) id<GADMediationInterstitialAdEventDelegate> adEventDelegate;

@end

@implementation InMobiInterstitialAd

- (instancetype)initWithPlacementId:(long long)placementId {
  _interstitial = [[IMInterstitial alloc] initWithPlacementId:placementId];
  [_interstitial setExtras:@{@"tp" : @"c_admob"}];
  _interstitial.delegate = self;
  return self;
}

- (void)collectIMSignalsWithGACompletionHandler:
    (nonnull GADRTBSignalCompletionHandler)completionHandler {
  _signalCompletionHandler = completionHandler;
  GADMAdapterInMobiMutableSetSafeGADRTBSignalCompletionHandler(_signalCompletionHandler,
                                                               completionHandler);
  [_interstitial getSignals];
}

- (void)loadIMInterstitialResponseWithGMAdConfig:(GADMediationInterstitialAdConfiguration *)adConfig
                               completionHandler:
                                   (GADMediationInterstitialLoadCompletionHandler)handler {
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
  [_interstitial load:[adConfig.bidResponse dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_interstitial showFromViewController:viewController];
}

#pragma mark IMInterstitialDelegate

- (void)interstitial:(IMInterstitial *)interstitial gotSignals:(NSData *)signals {
  NSString *signalsString = [[NSString alloc] initWithData:signals encoding:NSUTF8StringEncoding];
  _signalCompletionHandler(signalsString, nil);
}

- (void)interstitial:(IMInterstitial *)interstitial
    failedToGetSignalsWithError:(IMRequestStatus *)status {
  _signalCompletionHandler(nil, status);
}

- (void)interstitialDidFinishLoading:(IMInterstitial *)interstitial {
  _adEventDelegate = _renderCompletionHandler(self, nil);
}

- (void)interstitial:(IMInterstitial *)interstitial
    didFailToLoadWithError:(IMRequestStatus *)error {
  _renderCompletionHandler(nil, error);
}

- (void)interstitialDidPresent:(IMInterstitial *)interstitial {
  // Report the impression when interstitial ad didPresent on screen.
  [_adEventDelegate reportImpression];
}

- (void)interstitialDidDismiss:(IMInterstitial *)interstitial {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)interstitial:(IMInterstitial *)interstitial didInteractWithParams:(NSDictionary *)params {
  [_adEventDelegate reportClick];
}

- (void)interstitialWillPresent:(IMInterstitial *)interstitial {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)interstitialWillDismiss:(IMInterstitial *)interstitial {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)userWillLeaveApplicationFromInterstitial:(IMInterstitial *)interstitial {
  [_adEventDelegate willBackgroundApplication];
}

@end
