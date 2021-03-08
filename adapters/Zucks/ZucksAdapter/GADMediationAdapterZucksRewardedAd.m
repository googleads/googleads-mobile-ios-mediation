// Copyright 2021 Google LLC
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

#import "GADMediationAdapterZucksRewardedAd.h"

#import "stdatomic.h"

@interface GADMediationAdapterZucksRewardedAd () <GADMediationRewardedAd>
@end

@implementation GADMediationAdapterZucksRewardedAd {
  /// Configuration of the rewarded ad request.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// Mediation callback for ad load events.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationRewardedAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadRewardedAdWithCompletionHandler:
    (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _adLoadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
      _Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationRewardedAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(ad, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  // TODO: Load rewarded ad and forward the success callback:
  _adLoadCompletionHandler(self, nil);
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  // TODO: Present the rewarded ad.
}

@end
