// Copyright 2018 Google Inc.
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

#import "GADMAdapterAdColonyRewardedRenderer.h"

#import <AdColony/AdColony.h>
#include <stdatomic.h>

#import "GADMAdapterAdColonyConstants.h"
#import "GADMAdapterAdColonyExtras.h"
#import "GADMAdapterAdColonyHelper.h"
#import "GADMediationAdapterAdColony.h"

@interface GADMAdapterAdColonyRewardedRenderer () <GADMediationRewardedAd>
@end

@implementation GADMAdapterAdColonyRewardedRenderer {
  /// An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// AdColony rewarded ad.
  AdColonyInterstitial *_rewardedAd;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;
}

- (void)loadRewardedAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfig
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)handler {
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler = [handler copy];
  _loadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
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

  GADMAdapterAdColonyRewardedRenderer *__weak weakSelf = self;

  [GADMAdapterAdColonyHelper
      setupZoneFromAdConfig:adConfig
                   callback:^(NSString *zone, NSError *error) {
                     GADMAdapterAdColonyRewardedRenderer *strongSelf = weakSelf;
                     if (error && strongSelf) {
                       strongSelf->_loadCompletionHandler(nil, error);
                       return;
                     }
                     [strongSelf getRewardedAdFromZoneId:zone withAdConfig:adConfig];
                   }];
}

- (void)getRewardedAdFromZoneId:(NSString *)zone
                   withAdConfig:(GADMediationRewardedAdConfiguration *)adConfiguration {
  _rewardedAd = nil;

  GADMAdapterAdColonyRewardedRenderer *__weak weakSelf = self;

  GADMAdapterAdColonyLog(@"Requesting rewarded ad for zone: %@", zone);

  AdColonyAdOptions *options = [GADMAdapterAdColonyHelper getAdOptionsFromAdConfig:adConfiguration];

  [AdColony requestInterstitialInZone:zone
      options:options
      success:^(AdColonyInterstitial *_Nonnull ad) {
        GADMAdapterAdColonyLog(@"Retrieved rewarded ad for zone: %@", zone);
        GADMAdapterAdColonyRewardedRenderer *strongSelf = weakSelf;
        if (strongSelf) {
          [strongSelf handleAdReceived:ad forAdConfig:adConfiguration zone:zone];
        }
      }
      failure:^(AdColonyAdRequestError *_Nonnull err) {
        NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(kGADErrorInvalidRequest,
                                                                        err.localizedDescription);
        GADMAdapterAdColonyRewardedRenderer *strongSelf = weakSelf;
        if (strongSelf) {
          strongSelf->_loadCompletionHandler(nil, error);
        }
        GADMAdapterAdColonyLog(@"Failed to retrieve ad for zone: %@ with error: %@", zone,
                               error.localizedDescription);
      }];
}
- (void)handleAdReceived:(AdColonyInterstitial *_Nonnull)ad
             forAdConfig:(GADMediationRewardedAdConfiguration *)adConfiguration
                    zone:(NSString *)zone {
  AdColonyZone *adZone = [AdColony zoneForID:ad.zoneID];
  if (adZone.rewarded) {
    _rewardedAd = ad;
    _adEventDelegate = _loadCompletionHandler(self, nil);
  } else {
    NSString *errorMessage =
        @"Zone used for rewarded video is not a rewarded video zone on AdColony portal.";
    GADMAdapterAdColonyLog(@"%@", errorMessage);
    NSError *error =
        GADMAdapterAdColonyErrorWithCodeAndDescription(kGADErrorInvalidRequest, errorMessage);
    _loadCompletionHandler(nil, error);
  }
  // Re-request intersitial when expires, this avoids the situation:
  // 1. Admob interstitial request from zone A. Causes ADC configure to occur with zone A,
  // then ADC ad request from zone A. Both succeed.
  // 2. Admob rewarded video request from zone B. Causes ADC configure to occur with zones A,
  // B, then ADC ad request from zone B. Both succeed.
  // 3. Try to present ad loaded from zone A. It doesn’t show because of error: `No session
  // with id: xyz has been registered. Cannot show interstitial`.
  [ad setExpire:^{
    GADMAdapterAdColonyLog(
        @"Rewarded Ad expired from zone: %@ because of configuring "
        @"another Ad. To avoid this situation, use startWithCompletionHandler: to initialize "
        @"Google Mobile Ads SDK and wait for the completion handler to be called before "
        @"requesting an ad.",
        zone);
  }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  GADMAdapterAdColonyRewardedRenderer *__weak weakSelf = self;

  [_rewardedAd setOpen:^{
    GADMAdapterAdColonyRewardedRenderer *strongSelf = weakSelf;
    if (strongSelf) {
      id<GADMediationRewardedAdEventDelegate> adEventDelegate = strongSelf->_adEventDelegate;
      [adEventDelegate willPresentFullScreenView];
      [adEventDelegate reportImpression];
      [adEventDelegate didStartVideo];
    }
  }];

  [_rewardedAd setClick:^{
    GADMAdapterAdColonyRewardedRenderer *strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf->_adEventDelegate reportClick];
    }
  }];

  [_rewardedAd setClose:^{
    GADMAdapterAdColonyRewardedRenderer *strongSelf = weakSelf;
    id<GADMediationRewardedAdEventDelegate> adEventDelegate = strongSelf->_adEventDelegate;
    if (strongSelf) {
      [adEventDelegate didEndVideo];
      [adEventDelegate willDismissFullScreenView];
      [adEventDelegate didDismissFullScreenView];
    }
  }];

  AdColonyZone *zone = [AdColony zoneForID:_rewardedAd.zoneID];
  [zone setReward:^(BOOL success, NSString *_Nonnull name, int amount) {
    GADMAdapterAdColonyRewardedRenderer *strongSelf = weakSelf;
    if (success && strongSelf) {
      GADAdReward *reward = [[GADAdReward alloc]
          initWithRewardType:name
                rewardAmount:(NSDecimalNumber *)[NSDecimalNumber numberWithInt:amount]];
      [strongSelf->_adEventDelegate didRewardUserWithReward:reward];
    }
  }];

  if (![_rewardedAd showWithPresentingViewController:viewController]) {
    NSString *errorMessage = @"Failed to show ad for zone";
    GADMAdapterAdColonyLog(@"%@: %@.", errorMessage, _rewardedAd.zoneID);
    NSError *error = GADMAdapterAdColonyErrorWithCodeAndDescription(kGADErrorMediationAdapterError,
                                                                    errorMessage);
    [_adEventDelegate didFailToPresentWithError:error];
  }
}

@end
