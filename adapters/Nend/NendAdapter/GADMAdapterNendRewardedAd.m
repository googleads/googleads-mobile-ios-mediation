// Copyright 2019 Google Inc.
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

#import "GADMAdapterNendRewardedAd.h"

#import <NendAd/NendAd.h>

#include <stdatomic.h>

#import "GADMAdapterNendConstants.h"
#import "GADMAdapterNendExtras.h"
#import "GADMAdapterNendUtils.h"
#import "GADMediationAdapterNend.h"

@interface GADMAdapterNendRewardedAd () <NADRewardedVideoDelegate>

@end

@implementation GADMAdapterNendRewardedAd {
  /// The completion handler to call when ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _completionHandler;

  /// Rewarded ad configuration of the ad request.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  ///  nend rewarded video.
  NADRewardedVideo *_rewardedVideo;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];

    _completionHandler = ^id<GADMediationRewardedAdEventDelegate>(
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

    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadRewardedAd {
  NSString *spotId = _adConfiguration.credentials.settings[GADMAdapterNendSpotID];
  NSString *apiKey = _adConfiguration.credentials.settings[GADMAdapterNendApiKey];
  if (!spotId.length || !apiKey.length) {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        GADMAdapterNendInvalidServerParameters, @"Spot ID and/or API key must not be nil.");
    _completionHandler(nil, error);
    return;
  }

  _rewardedVideo = [[NADRewardedVideo alloc] initWithSpotID:spotId.integerValue apiKey:apiKey];
  _rewardedVideo.mediationName = GADMAdapterNendMediationName;

  GADMAdapterNendExtras *extras = _adConfiguration.extras;
  if (extras) {
    _rewardedVideo.userId = extras.userId;
  }

  _rewardedVideo.delegate = self;
  [_rewardedVideo loadAd];
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (!_rewardedVideo.isReady) {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        GADMAdapterNendErrorShowAdNotReady, @"The rewarded ad is not ready to be shown.");
    [_adEventDelegate didFailToPresentWithError:error];
    return;
  }

  [_rewardedVideo showAdFromViewController:viewController];
}

#pragma mark - NADRewardedVideoDelegate

- (void)nadRewardVideoAdDidReceiveAd:(nonnull NADRewardedVideo *)nadRewardedVideoAd {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)nadRewardVideoAd:(nonnull NADRewardedVideo *)nadRewardedVideoAd
    didFailToLoadWithError:(NSError *)error {
  _completionHandler(nil, error);
}

- (void)nadRewardVideoAdDidOpen:(nonnull NADRewardedVideo *)nadRewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = _adEventDelegate;
  [strongAdEventDelegate willPresentFullScreenView];
  [strongAdEventDelegate reportImpression];
}

- (void)nadRewardVideoAdDidClose:(nonnull NADRewardedVideo *)nadRewardedVideoAd {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)nadRewardVideoAdDidStartPlaying:(nonnull NADRewardedVideo *)nadRewardedVideoAd {
  [_adEventDelegate didStartVideo];
}

- (void)nadRewardVideoAdDidCompletePlaying:(nonnull NADRewardedVideo *)nadRewardedVideoAd {
  [_adEventDelegate didEndVideo];
}

- (void)nadRewardVideoAdDidClickAd:(nonnull NADRewardedVideo *)nadRewardedVideoAd {
  [_adEventDelegate reportClick];
}

- (void)nadRewardVideoAdDidClickInformation:(nonnull NADRewardedVideo *)nadRewardedVideoAd {
  // do nothing
}

- (void)nadRewardVideoAd:(nonnull NADRewardedVideo *)nadRewardedVideoAd
               didReward:(NADReward *)reward {
  NSDecimalNumber *amount = [NSDecimalNumber
      decimalNumberWithDecimal:[NSNumber numberWithInteger:reward.amount].decimalValue];
  GADAdReward *gadReward = [[GADAdReward alloc] initWithRewardType:reward.name rewardAmount:amount];
  [_adEventDelegate didRewardUserWithReward:gadReward];
}

- (void)nadRewardVideoAdDidFailedToPlay:(nonnull NADRewardedVideo *)nadRewardedVideoAd {
  NSError *error = GADMAdapterNendSDKPresentError();
  [_adEventDelegate didFailToPresentWithError:error];
}

@end
