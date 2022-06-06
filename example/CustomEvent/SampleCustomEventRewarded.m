//
// Copyright 2019 Google LLC
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

#import "SampleCustomEventRewarded.h"
#import "SampleCustomEventConstants.h"
#import "SampleCustomEventUtils.h"

#include <stdatomic.h>

@interface SampleCustomEventRewarded () <SampleRewardedAdDelegate, GADMediationRewardedAd> {
  /// Handle rewarded ads from Sample SDK.
  SampleRewardedAd *_rewardedAd;

  /// Completion handler to call when sample rewarded ad finishes loading.
  GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;

  ///  Delegate for receiving rewarded ad notifications.
  id<GADMediationRewardedAdEventDelegate> _adEventDelegate;
}

@end

@implementation SampleCustomEventRewarded

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];

  _loadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
      _Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {
    // Only allow completion handler to be called once.
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }

    id<GADMediationRewardedAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      // Call original handler and hold on to its return value.
      delegate = originalCompletionHandler(ad, error);
    }

    // Release reference to handler. Objects retained by the handler will also be released.
    originalCompletionHandler = nil;

    return delegate;
  };

  NSString *adUnit = adConfiguration.credentials.settings[@"parameter"];
  _rewardedAd = [[SampleRewardedAd alloc] initWithAdUnitID:adUnit];
  _rewardedAd.delegate = self;
  SampleAdRequest *adRequest = [[SampleAdRequest alloc] init];
  adRequest.testMode = adConfiguration.isTestRequest;
  [_rewardedAd fetchAd:adRequest];
}

#pragma mark GADMediationRewardedAd implementation

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewardedAd presentFromRootViewController:viewController];
}

#pragma mark SampleRewardedAdDelegate implementation

- (void)rewardedAdDidReceiveAd:(nonnull SampleRewardedAd *)rewardedAd {
  _adEventDelegate = _loadCompletionHandler(self, nil);
}

- (void)rewardedAdDidDismiss:(nonnull SampleRewardedAd *)rewardedAd {
  [_adEventDelegate willDismissFullScreenView];
  [_adEventDelegate didEndVideo];
  [_adEventDelegate didDismissFullScreenView];
}

- (void)rewardedAdDidFailToLoadWithError:(SampleErrorCode)errorCode {
  NSError *error = SampleCustomEventErrorWithCodeAndDescription(
      SampleCustomEventErrorAdLoadFailureCallback,
      [NSString
          stringWithFormat:@"Sample SDK returned an ad load failure callback with error code: %@",
                           errorCode]);
  _adEventDelegate = _loadCompletionHandler(nil, error);
}

- (void)rewardedAdDidPresent:(SampleRewardedAd *)rewardedAd {
  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate didStartVideo];
}

- (void)rewardedAd:(nonnull SampleRewardedAd *)rewardedAd userDidEarnReward:(NSUInteger)reward {
  GADAdReward *aReward =
      [[GADAdReward alloc] initWithRewardType:@""
                                 rewardAmount:[NSDecimalNumber numberWithUnsignedInt:reward]];
  [_adEventDelegate didRewardUserWithReward:aReward];
}

@end
