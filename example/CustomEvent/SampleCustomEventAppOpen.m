// Copyright 2025 Google LLC
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

#import "SampleCustomEventAppOpen.h"

#include <stdatomic.h>

#import <SampleAdSDK/SampleAdSDK.h>

#import "SampleCustomEventUtils.h"

@interface SampleCustomEventAppOpen () <SampleAppOpenAdDelegate, GADMediationAppOpenAd> {
  /// The sample app open ad.
  SampleAppOpenAd *_appOpenAd;

  /// Completion handler to call when sample app open ad finishes loading.
  GADMediationAppOpenLoadCompletionHandler _loadCompletionHandler;

  /// Delegate for receiving app open ad notifications.
  id<GADMediationAppOpenAdEventDelegate> _adEventDelegate;
}

@end

@implementation SampleCustomEventAppOpen

- (void)loadAppOpenAdForAdConfiguration:(GADMediationAppOpenAdConfiguration *)adConfiguration
                      completionHandler:
                          (GADMediationAppOpenLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationAppOpenLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];

  _loadCompletionHandler = ^id<GADMediationAppOpenAdEventDelegate>(
      _Nullable id<GADMediationAppOpenAd> ad, NSError *_Nullable error) {
    // Only allow completion handler to be called once.
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }

    id<GADMediationAppOpenAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      // Call original handler and hold on to its return value.
      delegate = originalCompletionHandler(ad, error);
    }

    // Release reference to handler. Objects retained by the handler will also be released.
    originalCompletionHandler = nil;

    return delegate;
  };

  NSString *adUnit = adConfiguration.credentials.settings[@"parameter"];
  _appOpenAd = [[SampleAppOpenAd alloc] initWithAdUnitID:adUnit];
  _appOpenAd.delegate = self;
  SampleAdRequest *adRequest = [[SampleAdRequest alloc] init];
  adRequest.testMode = adConfiguration.isTestRequest;
  [_appOpenAd fetchAd:adRequest];
}

#pragma mark GADMediationAppOpenAd implementation

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if ([_appOpenAd isReady]) {
    [_appOpenAd presentFromRootViewController:viewController];
  } else {
    NSError *error = SampleCustomEventErrorWithCodeAndDescription(
        SampleCustomEventErrorAdNotLoaded,
        [NSString
            stringWithFormat:@"The app open ad failed to present because the ad was not loaded."]);
    [_adEventDelegate didFailToPresentWithError:error];
  }
}

#pragma mark SampleAppOpenAdDelegate implementation

- (void)appOpenAdDidReceiveAd:(SampleAppOpenAd *)appOpenAd {
  _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)appOpenAdDidFailToLoadWithError:(SampleErrorCode)errorCode {
  NSError *error = SampleCustomEventErrorWithCodeAndDescription(
      SampleCustomEventErrorAdLoadFailureCallback,
      [NSString
          stringWithFormat:@"Sample SDK returned an ad load failure callback with error code: %ld",
                           errorCode]);
  _adEventDelegate = _loadCompletionHandler(nil, error);
}

- (void)appOpenAdWillPresent:(nonnull SampleAppOpenAd *)appOpenAd {
  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate reportImpression];
}

- (void)appOpenAdDidPresent:(nonnull SampleAppOpenAd *)appOpenAd {
}

- (void)appOpenAdDidDismiss:(nonnull SampleAppOpenAd *)appOpenAd {
  [_adEventDelegate willDismissFullScreenView];
  [_adEventDelegate didDismissFullScreenView];
}

- (void)appOpenWillLeaveApplication:(nonnull SampleAppOpenAd *)appOpenAd {
  [_adEventDelegate reportClick];
}

@end
