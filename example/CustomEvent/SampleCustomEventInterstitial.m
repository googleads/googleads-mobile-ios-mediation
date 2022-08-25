//
// Copyright (C) 2015 Google, Inc.
//
// SampleCustomEventInterstitial.m
// Sample Ad Network Custom Event
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "SampleCustomEventInterstitial.h"
#include <stdatomic.h>
#import "SampleCustomEventConstants.h"
#import "SampleCustomEventUtils.h"

#import <Foundation/Foundation.h>
#import <SampleAdSDK/SampleAdSDK.h>

@interface SampleCustomEventInterstitial () <SampleInterstitialAdDelegate,
                                             GADMediationInterstitialAd> {
  /// The sample interstitial ad.
  SampleInterstitial *_interstitialAd;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;
}

@end

@implementation SampleCustomEventInterstitial

- (void)loadInterstitialForAdConfiguration:
            (GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];

  _loadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
      _Nullable id<GADMediationInterstitialAd> ad, NSError *_Nullable error) {
    // Only allow completion handler to be called once.
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }

    id<GADMediationInterstitialAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      // Call original handler and hold on to its return value.
      delegate = originalCompletionHandler(ad, error);
    }

    // Release reference to handler. Objects retained by the handler will also be released.
    originalCompletionHandler = nil;

    return delegate;
  };

  NSString *adUnit = adConfiguration.credentials.settings[@"parameter"];
  _interstitialAd = [[SampleInterstitial alloc] initWithAdUnitID:adUnit];
  _interstitialAd.delegate = self;
  SampleAdRequest *adRequest = [[SampleAdRequest alloc] init];
  adRequest.testMode = adConfiguration.isTestRequest;
  [_interstitialAd fetchAd:adRequest];
}

#pragma mark GADMediationInterstitialAd implementation

- (void)presentFromViewController:(UIViewController *)viewController {
  if ([_interstitialAd isInterstitialLoaded]) {
    [_interstitialAd show];
  } else {
    NSError *error = SampleCustomEventErrorWithCodeAndDescription(
        SampleCustomEventErrorAdNotLoaded,
        [NSString stringWithFormat:
                      @"The interstitial ad failed to present because the ad was not loaded."]);
    _adEventDelegate = _loadCompletionHandler(self, error);
  }
}

#pragma mark SampleInterstitialAdDelegate implementation

- (void)interstitialDidLoad:(SampleInterstitial *)interstitial {
  _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)interstitial:(SampleInterstitial *)interstitial
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *error = SampleCustomEventErrorWithCodeAndDescription(
      SampleCustomEventErrorAdLoadFailureCallback,
      [NSString
          stringWithFormat:@"Sample SDK returned an ad load failure callback with error code: %@",
                           errorCode]);
  _adEventDelegate = _loadCompletionHandler(nil, error);
}

- (void)interstitialWillPresentScreen:(SampleInterstitial *)interstitial {
  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate reportImpression];
}

- (void)interstitialWillDismissScreen:(SampleInterstitial *)interstitial {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)interstitialDidDismissScreen:(SampleInterstitial *)interstitial {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)interstitialWillLeaveApplication:(SampleInterstitial *)interstitial {
  [_adEventDelegate reportClick];
}

@end
