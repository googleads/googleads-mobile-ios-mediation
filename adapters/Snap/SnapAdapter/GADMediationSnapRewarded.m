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

#import "GADMediationSnapRewarded.h"

#import "GADMediationAdapterSnapConstants.h"

#import <SAKSDK/SAKSDK.h>

@interface GADMediationSnapRewarded () <SAKRewardedAdDelegate>
@end

@implementation GADMediationSnapRewarded {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _completionHandler;
  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;
  // The Snap rewarded ad.
  SAKRewardedAd *_rewardedAd;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _rewardedAd = [[SAKRewardedAd alloc] init];
    _rewardedAd.delegate = self;
  }
  return self;
}

- (void)renderRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                         completionHandler:
                             (GADMediationRewardedLoadCompletionHandler)completionHandler {
  if (!adConfiguration.bidResponse.length) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"No or empty bid response"};
    NSError *error = [NSError errorWithDomain:GADErrorDomain
                                         code:GADErrorMediationDataError
                                     userInfo:userInfo];
    completionHandler(nil, error);
    return;
  }
  NSString *slotID = adConfiguration.credentials.settings[GADMAdapterSnapAdSlotID];
  if (!slotID.length) {
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"No slotId found"};
    completionHandler(nil, [[NSError alloc] initWithDomain:GADErrorDomain
                                                      code:GADErrorInvalidRequest
                                                  userInfo:userInfo]);
    return;
  }

  _completionHandler = [completionHandler copy];
  NSData *bidPayload = [[NSData alloc] initWithBase64EncodedString:adConfiguration.bidResponse
                                                           options:0];
  [_rewardedAd loadAdWithBidPayload:bidPayload publisherSlotId:slotID];
}

#pragma mark - SAKRewardedAdDelegate

- (void)rewardedAdDidLoad:(SAKRewardedAd *)ad {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)rewardedAd:(SAKRewardedAd *)ad didFailWithError:(NSError *)error {
  _adEventDelegate = _completionHandler(self, error);
}

- (void)rewardedAdDidExpire:(SAKRewardedAd *)ad {
  NSError *error = [NSError errorWithDomain:GADErrorDomain
                                       code:GADErrorMediationAdapterError
                                   userInfo:@{NSLocalizedDescriptionKey : @"Ad expired"}];
  [_adEventDelegate didFailToPresentWithError:error];
}

- (void)rewardedAdWillAppear:(SAKRewardedAd *)ad {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)rewardedAdDidAppear:(SAKRewardedAd *)ad {
  [_adEventDelegate didStartVideo];
}

- (void)rewardedAdWillDisappear:(SAKRewardedAd *)ad {
  [_adEventDelegate didEndVideo];
}

- (void)rewardedAdDidDisappear:(SAKRewardedAd *)ad {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)rewardedAdDidShowAttachment:(SAKRewardedAd *)ad {
  [_adEventDelegate reportClick];
}

- (void)rewardedAdDidEarnReward:(SAKRewardedAd *)ad {
  GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@""
                                                   rewardAmount:NSDecimalNumber.one];
  [_adEventDelegate didRewardUserWithReward:reward];
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(UIViewController *)viewController {
  [_rewardedAd presentFromRootViewController:viewController
                           dismissTransition:viewController.view.bounds];
}

@end
