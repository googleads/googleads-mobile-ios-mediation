// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADPangleRTBRewardedRenderer.h"
#import <BUAdSDK/BUAdSDK.h>
#include <stdatomic.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"

@interface GADPangleRTBRewardedRenderer () <BURewardedVideoAdDelegate>

@end

@implementation GADPangleRTBRewardedRenderer {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;
  /// The Pangle rewarded ad.
  BURewardedVideoAd *_rewardedVideoAd;
  /// An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationRewardedAdEventDelegate> _delegate;
}

- (void)renderRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                         completionHandler:
                             (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _loadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
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

  NSString *placementId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID] ?: @"";
  if (!placementId.length) {
    NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(
        GADPangleErrorInvalidServerParameters,
        [NSString
            stringWithFormat:@"%@ cannot be nil,please update Pangle SDK to the latest version.",
                             GADMAdapterPanglePlacementID]);
    _loadCompletionHandler(nil, error);
    return;
  }
  BURewardedVideoModel *model = [[BURewardedVideoModel alloc] init];
  _rewardedVideoAd = [[BURewardedVideoAd alloc] initWithSlotID:placementId
                                            rewardedVideoModel:model];
  _rewardedVideoAd.delegate = self;
  [_rewardedVideoAd setAdMarkup:adConfiguration.bidResponse];
}

#pragma mark - GADMediationRewardedAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewardedVideoAd showAdFromRootViewController:viewController];
}

#pragma mark - BURewardedVideoAdDelegate
- (void)rewardedVideoAdDidLoad:(BURewardedVideoAd *)rewardedVideoAd {
  if (_loadCompletionHandler) {
    _delegate = _loadCompletionHandler(self, nil);
  }
}

- (void)rewardedVideoAd:(BURewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
  if (_loadCompletionHandler) {
    _loadCompletionHandler(nil, error);
  }
}

- (void)rewardedVideoAdDidVisible:(BURewardedVideoAd *)rewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)rewardedVideoAdWillClose:(BURewardedVideoAd *)rewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
  [delegate willDismissFullScreenView];
}

- (void)rewardedVideoAdDidClose:(BURewardedVideoAd *)rewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
  [delegate didDismissFullScreenView];
}

- (void)rewardedVideoAdDidClick:(BURewardedVideoAd *)rewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
  [delegate reportClick];
}

- (void)rewardedVideoAdServerRewardDidSucceed:(BURewardedVideoAd *)rewardedVideoAd
                                       verify:(BOOL)verify {
  if (verify) {
    NSNumber *amount =
        [NSDecimalNumber numberWithInteger:rewardedVideoAd.rewardedVideoModel.rewardAmount];
    GADAdReward *reward = [[GADAdReward alloc]
        initWithRewardType:@""
              rewardAmount:[NSDecimalNumber decimalNumberWithDecimal:[amount decimalValue]]];

    id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
    [delegate didRewardUserWithReward:reward];
  }
}

@end
