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

#import "SampleAdapterRewardedAd.h"
#include <stdatomic.h>
#import "SampleAdapter.h"
#import "SampleAdapterConstants.h"
#import "SampleExtras.h"

@implementation SampleAdapterRewardedAd {
  /// The completion handler to call ad loading events.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;

  /// An ad event delegate to forward ad rendering events.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// The rewarded ad configuration.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// Rewarded ad object from Sample SDK.
  SampleRewardedAd *_rewardedAd;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationRewardedAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)renderRewardedAdWithCompletionHandler:
    (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _adLoadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
      id<GADMediationRewardedAd> rewardedAd, NSError *error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationRewardedAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(rewardedAd, error);
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

  _rewardedAd = [[SampleRewardedAd alloc] initWithAdUnitID:adUnit];
  _rewardedAd.delegate = self;

  SampleExtras *extras = _adConfiguration.extras;
  _rewardedAd.enableDebugLogging = extras.enableDebugLogging;

  SampleAdRequest *request = [[SampleAdRequest alloc] init];
  // Set up request parameters.
  request.mute = extras.muteAudio;

  NSLog(@"Requesting a rewarded ad from Sample Ad Network.");
  [_rewardedAd fetchAd:request];
}

#pragma mark - GADMediationRewardedAd methods

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (!_rewardedAd.isReady) {
    NSError *showError = [NSError errorWithDomain:kAdapterErrorDomain
                                             code:SampleAdapterErrorCodeAdNotReady
                                         userInfo:@{NSLocalizedDescriptionKey : @"Ad not ready."}];
    [_adEventDelegate didFailToPresentWithError:showError];
    return;
  }

  [_rewardedAd presentFromRootViewController:viewController];
}

#pragma mark - SampleRewardedAdDelegate methods

- (void)rewardedAdDidReceiveAd:(nonnull SampleRewardedAd *)rewardedAd {
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)rewardedAdDidFailToLoadWithError:(SampleErrorCode)errorCode {
  NSError *loadError = [NSError
      errorWithDomain:kAdapterErrorDomain
                 code:errorCode
             userInfo:@{NSLocalizedDescriptionKey : @"Sample SDK returned an error callback."}];
  _adLoadCompletionHandler(nil, loadError);
}

- (void)rewardedAd:(nonnull SampleRewardedAd *)rewardedAd userDidEarnReward:(NSUInteger)reward {
  [_adEventDelegate didRewardUser];
}

- (void)rewardedAdDidPresent:(nonnull SampleRewardedAd *)rewardedAd {
  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate didStartVideo];
  [_adEventDelegate reportImpression];
}

- (void)rewardedAdDidDismiss:(nonnull SampleRewardedAd *)rewardedAd {
  [_adEventDelegate willDismissFullScreenView];
  [_adEventDelegate didEndVideo];
  [_adEventDelegate didDismissFullScreenView];
}

@end
