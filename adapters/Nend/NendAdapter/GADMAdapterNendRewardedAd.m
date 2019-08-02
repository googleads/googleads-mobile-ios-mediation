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
#import "GADMAdapterNendConstants.h"
#import "GADNendRewardedNetworkExtras.h"
@import NendAd;

@interface GADMAdapterNendRewardedAd () <NADRewardedVideoDelegate>

@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler completionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;
@property(nonatomic, strong) NADRewardedVideo *rewardedVideo;

@end

@implementation GADMAdapterNendRewardedAd

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.completionHandler = completionHandler;

  NSString *spotId = adConfiguration.credentials.settings[kGADMAdapterNendSpotID];
  NSString *apiKey = adConfiguration.credentials.settings[kGADMAdapterNendApiKey];

  if (spotId.length != 0 && apiKey.length != 0) {
    self.rewardedVideo = [[NADRewardedVideo alloc] initWithSpotId:spotId apiKey:apiKey];
    self.rewardedVideo.mediationName = kGADMAdapterNendMediationName;

    GADNendRewardedNetworkExtras *extras = [adConfiguration extras];
    if (extras) {
      self.rewardedVideo.userId = extras.userId;
    }

    self.rewardedVideo.delegate = self;
  } else {
    NSError *error = [NSError
        errorWithDomain:kGADMAdapterNendErrorDomain
                   code:kGADErrorInternalError
               userInfo:@{NSLocalizedDescriptionKey : @"SpotID and apiKey must not be nil"}];
    completionHandler(nil, error);
    return;
  }

  [self.rewardedVideo loadAd];
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(UIViewController *)viewController {
  if (self.rewardedVideo.isReady) {
    [self.rewardedVideo showAdFromViewController:viewController];
  } else {
    NSError *error = [NSError
                       errorWithDomain:kGADMAdapterNendErrorDomain
                       code:kGADErrorInternalError
                       userInfo:@{NSLocalizedDescriptionKey : @"The rewarded ad is not ready to be shown."}];
    [self.adEventDelegate didFailToPresentWithError:error];
  }
}

#pragma mark - NADRewardedVideoDelegate

- (void)nadRewardVideoAdDidReceiveAd:(NADRewardedVideo *)nadRewardedVideoAd {
  self.adEventDelegate = self.completionHandler(self, nil);
}

- (void)nadRewardVideoAd:(NADRewardedVideo *)nadRewardedVideoAd
    didFailToLoadWithError:(NSError *)error {
  self.completionHandler(nil, error);
}

- (void)nadRewardVideoAdDidOpen:(NADRewardedVideo *)nadRewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> strongAdEventDelegate = self.adEventDelegate;
  [strongAdEventDelegate willPresentFullScreenView];
  [strongAdEventDelegate reportImpression];
}

- (void)nadRewardVideoAdDidClose:(NADRewardedVideo *)nadRewardedVideoAd {
  [self.adEventDelegate didDismissFullScreenView];
}

- (void)nadRewardVideoAdDidStartPlaying:(NADRewardedVideo *)nadRewardedVideoAd {
  [self.adEventDelegate didStartVideo];
}

- (void)nadRewardVideoAdDidCompletePlaying:(NADRewardedVideo *)nadRewardedVideoAd {
  [self.adEventDelegate didEndVideo];
}

- (void)nadRewardVideoAdDidClickAd:(NADRewardedVideo *)nadRewardedVideoAd {
  [self.adEventDelegate reportClick];
}

- (void)nadRewardVideoAdDidClickInformation:(NADRewardedVideo *)nadRewardedVideoAd {
  // do nothing
}

- (void)nadRewardVideoAd:(NADRewardedVideo *)nadRewardedVideoAd didReward:(NADReward *)reward {
  NSDecimalNumber *amount = [NSDecimalNumber
      decimalNumberWithDecimal:[[NSNumber numberWithInteger:reward.amount] decimalValue]];
  GADAdReward *gadReward = [[GADAdReward alloc] initWithRewardType:reward.name rewardAmount:amount];
  [self.adEventDelegate didRewardUserWithReward:gadReward];
}

- (void)nadRewardVideoAdDidFailedToPlay:(NADRewardedVideo *)nadRewardedVideoAd {
  NSError *error = [NSError errorWithDomain:kGADMAdapterNendErrorDomain
                                       code:kGADErrorInternalError
                                   userInfo:@{NSLocalizedDescriptionKey : @"No ads to show."}];
  [self.adEventDelegate didFailToPresentWithError:error];
}

@end
