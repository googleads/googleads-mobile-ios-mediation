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

#import "GADMAdapterNendConstants.h"
#import "GADMAdapterNendUtils.h"
#import "GADNendRewardedNetworkExtras.h"

@interface GADMAdapterNendRewardedAd () <NADRewardedVideoDelegate>

@end

@implementation GADMAdapterNendRewardedAd {
  /// The completion handler to call when ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _completionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  ///  nend rewarded video.
  NADRewardedVideo *_rewardedVideo;
}
- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  _completionHandler = completionHandler;

  NSString *spotId = adConfiguration.credentials.settings[kGADMAdapterNendSpotID];
  NSString *apiKey = adConfiguration.credentials.settings[kGADMAdapterNendApiKey];

  if (spotId.length != 0 && apiKey.length != 0) {
    _rewardedVideo = [[NADRewardedVideo alloc] initWithSpotId:spotId apiKey:apiKey];
    _rewardedVideo.mediationName = kGADMAdapterNendMediationName;

    GADNendRewardedNetworkExtras *extras = [adConfiguration extras];
    if (extras) {
      _rewardedVideo.userId = extras.userId;
    }

    _rewardedVideo.delegate = self;
  } else {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        kGADErrorInternalError, @"SpotID and apiKey must not be nil");
    completionHandler(nil, error);
    return;
  }

  [_rewardedVideo loadAd];
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (_rewardedVideo.isReady) {
    [_rewardedVideo showAdFromViewController:viewController];
  } else {
    NSError *error = GADMAdapterNendErrorWithCodeAndDescription(
        kGADErrorInternalError, @"The rewarded ad is not ready to be shown.");
    [_adEventDelegate didFailToPresentWithError:error];
  }
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
      decimalNumberWithDecimal:[[NSNumber numberWithInteger:reward.amount] decimalValue]];
  GADAdReward *gadReward = [[GADAdReward alloc] initWithRewardType:reward.name rewardAmount:amount];
  [_adEventDelegate didRewardUserWithReward:gadReward];
}

- (void)nadRewardVideoAdDidFailedToPlay:(nonnull NADRewardedVideo *)nadRewardedVideoAd {
  NSError *error =
      GADMAdapterNendErrorWithCodeAndDescription(kGADErrorInternalError, @"No ads to show.");
  [_adEventDelegate didFailToPresentWithError:error];
}

@end
