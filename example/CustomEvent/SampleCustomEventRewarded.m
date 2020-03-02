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

#include <stdatomic.h>

/// Constant for Sample Ad Network custom event error domain.
static NSString *const customEventErrorDomain = @"com.google.CustomEvent";

@interface SampleCustomEventRewarded () <SampleRewardedAdDelegate, GADMediationRewardedAd> {
  /// Handle rewarded ads from Sample SDK.
  SampleRewardedAd *_rewardedAd;

  /// Completion handler to call when sample rewarded ad finishes loading.
  GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;

  ///  Delegate for receiving rewarded ad notifications.
  __weak id<GADMediationRewardedAdEventDelegate> _delegate;
}

@end

@implementation SampleCustomEventRewarded

#pragma mark GADMediationAdapter implementation

+ (GADVersionNumber)adSDKVersion {
  NSString *versionString = @"1.0.0";
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 3) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
  }
  return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return nil;
}

+ (GADVersionNumber)version {
  NSString *versionString = @"1.0.0.0";
  NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
  GADVersionNumber version = {0};
  if (versionComponents.count >= 4) {
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];

    // Adapter versions have 2 patch versions. Multiply the first patch by 100.
    version.patchVersion =
        [versionComponents[2] integerValue] * 100 + [versionComponents[3] integerValue];
  }
  return version;
}

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

  NSString *adUnit = adConfiguration.credentials.settings[@"ad_unit_id"];
  _rewardedAd = [[SampleRewardedAd alloc] initWithAdUnitID:adUnit];
  _rewardedAd.delegate = self;
  [_rewardedAd fetchAd:[[SampleAdRequest alloc] init]];
}

#pragma mark GADMediationRewardedAd implementation

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewardedAd presentFromRootViewController:viewController];
}

#pragma mark SampleRewardedAdDelegate implementation

- (void)rewardedAdDidReceiveAd:(nonnull SampleRewardedAd *)rewardedAd {
  _delegate = _loadCompletionHandler(self, nil);
}

- (void)rewardedAdDidDismiss:(nonnull SampleRewardedAd *)rewardedAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _delegate;
  [strongDelegate willDismissFullScreenView];
  [strongDelegate didEndVideo];
  [strongDelegate didDismissFullScreenView];
}

- (void)rewardedAdDidFailToLoadWithError:(SampleErrorCode)error {
  [_delegate didFailToPresentWithError:[NSError errorWithDomain:SampleCustomEventErrorDomain
                                                           code:error
                                                       userInfo:nil]];
}

- (void)rewardedAdDidPresent:(SampleRewardedAd *)rewardedAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _delegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate didStartVideo];
}

- (void)rewardedAd:(nonnull SampleRewardedAd *)rewardedAd userDidEarnReward:(NSUInteger)reward {
  GADAdReward *aReward =
      [[GADAdReward alloc] initWithRewardType:@""
                                 rewardAmount:[NSDecimalNumber numberWithUnsignedInt:reward]];
  [_delegate didRewardUserWithReward:aReward];
}

@end
