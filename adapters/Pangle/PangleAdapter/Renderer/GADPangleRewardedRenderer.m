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

#import "GADPangleRewardedRenderer.h"
#import <PAGAdSDK/PAGAdSDK.h>
#include <stdatomic.h>
#import "GADMAdapterPangleUtils.h"
#import "GADMediationAdapterPangleConstants.h"
#import "GADPangleNetworkExtras.h"

@interface GADPangleRewardedRenderer () <PAGRewardedAdDelegate>

@end

@implementation GADPangleRewardedRenderer {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;
  /// The Pangle rewarded ad.
  PAGRewardedAd *_rewardedAd;
  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _delegate;
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

  NSString *placementId = adConfiguration.credentials.settings[GADMAdapterPanglePlacementID];
  if (!placementId.length) {
    NSError *error = GADMAdapterPangleErrorWithCodeAndDescription(
        GADPangleErrorInvalidServerParameters,
        [NSString stringWithFormat:@"%@ cannot be nil.", GADMAdapterPanglePlacementID]);
    _loadCompletionHandler(nil, error);
    return;
  }

  PAGRewardedRequest *request = [PAGRewardedRequest request];
  request.adString = adConfiguration.bidResponse;
  if (adConfiguration.watermark) {
    request.extraInfo = @{@"admob_watermark":adConfiguration.watermark?:@""};
  }
  GADPangleRewardedRenderer *__weak weakSelf = self;
  [PAGRewardedAd loadAdWithSlotID:placementId
                          request:request
                completionHandler:^(PAGRewardedAd *_Nullable rewardedAd, NSError *_Nullable error) {
                  GADPangleRewardedRenderer *strongSelf = weakSelf;
                  if (!strongSelf) {
                    return;
                  }

                  if (error) {
                    if (strongSelf->_loadCompletionHandler) {
                      strongSelf->_loadCompletionHandler(nil, error);
                    }
                    return;
                  }

                  strongSelf->_rewardedAd = rewardedAd;
                  strongSelf->_rewardedAd.delegate = strongSelf;

                  if (strongSelf->_loadCompletionHandler) {
                    strongSelf->_delegate = strongSelf->_loadCompletionHandler(strongSelf, nil);
                  }
                }];
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewardedAd presentFromRootViewController:viewController];
}

#pragma mark - PAGRewardedAdDelegate

- (void)adDidShow:(PAGRewardModel *)ad {
  id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)adDidClick:(PAGRewardModel *)ad {
  id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
  [delegate reportClick];
}

- (void)adDidDismiss:(PAGRewardModel *)ad {
  id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
  [delegate willDismissFullScreenView];
  [delegate didDismissFullScreenView];
}

- (void)rewardedAd:(PAGRewardedAd *)rewardedAd userDidEarnReward:(PAGRewardModel *)rewardModel {
  id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
  [delegate didRewardUser];
}

- (void)adDidShowFail:(id<PAGAdProtocol>)ad error:(NSError *)error {
  id<GADMediationRewardedAdEventDelegate> delegate = _delegate;
  [delegate didFailToPresentWithError:error];
}

@end
