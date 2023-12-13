// Copyright 2023 Google LLC
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

#import "SampleAdapterInterstitialAd.h"
#include <stdatomic.h>
#import "SampleAdapter.h"
#import "SampleAdapterConstants.h"

@implementation SampleAdapterInterstitialAd {
  /// The completion handler to call ad loading events.
  GADMediationInterstitialLoadCompletionHandler _adLoadCompletionHandler;

  /// An ad event delegate to forward ad rendering events.
  __weak id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;

  /// The interstitial ad configuration.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// Interstitial ad object from Sample SDK.
  SampleInterstitial *_interstitialAd;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)renderInterstitialAdWithCompletionHandler:
    (nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _adLoadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
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

  NSString *adUnit = _adConfiguration.credentials.settings[SampleSDKAdUnitIDKey];
  if (!adUnit.length) {
    NSError *parameterError =
        [NSError errorWithDomain:kAdapterErrorDomain
                            code:SampleAdapterErrorCodeInvalidServerParameters
                        userInfo:@{NSLocalizedDescriptionKey : @"Missing or invalid ad unit."}];
    _adLoadCompletionHandler(nil, parameterError);
    return;
  }

  _interstitialAd = [[SampleInterstitial alloc] initWithAdUnitID:adUnit];
  _interstitialAd.delegate = self;

  SampleAdRequest *request = [[SampleAdRequest alloc] init];
  // Set up request parameters.
  request.testMode = _adConfiguration.isTestRequest;

  NSLog(@"Requesting an interstitial ad from Sample Ad Network.");
  [_interstitialAd fetchAd:request];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (!_interstitialAd.isInterstitialLoaded) {
    NSError *showError = [NSError errorWithDomain:kAdapterErrorDomain
                                             code:SampleAdapterErrorCodeAdNotReady
                                         userInfo:@{NSLocalizedDescriptionKey : @"Ad not ready."}];
    [_adEventDelegate didFailToPresentWithError:showError];
    return;
  }

  [_interstitialAd show];
}

#pragma mark - SampleInterstitialAdDelegate methods

- (void)interstitialDidLoad:(SampleInterstitial *)interstitial {
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)interstitial:(SampleInterstitial *)interstitial
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *loadError = [NSError
      errorWithDomain:kAdapterErrorDomain
                 code:errorCode
             userInfo:@{NSLocalizedDescriptionKey : @"Sample SDK returned an error callback."}];
  _adLoadCompletionHandler(nil, loadError);
}

- (void)interstitialWillPresentScreen:(SampleInterstitial *)interstitial {
  [_adEventDelegate willPresentFullScreenView];
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
