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

#import "GADMAdapterMintegralRTBRewardedAdLoader.h"
#import "GADMAdapterMintegralExtras.h"
#import "GADMAdapterMintegralUtils.h"
#import "GADMediationAdapterMintegralConstants.h"

#import <MTGSDK/MTGSDK.h>
#import <MTGSDKReward/MTGBidRewardAdManager.h>
#import <MTGSDKReward/MTGRewardAd.h>
#include <stdatomic.h>

@interface GADMAdapterMintegralRTBRewardedAdLoader () <MTGRewardAdLoadDelegate,
                                                       MTGRewardAdShowDelegate>

@end

@implementation GADMAdapterMintegralRTBRewardedAdLoader {
  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;

  /// Ad configuration for the ad to be loaded.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// The Mintegral rewarded ad.
  MTGBidRewardAdManager *_rewardedAd;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// The Mintegral rewarded ad Unit ID.
  NSString *_adUnitId;

  /// The Mintegral rewarded ad Placement ID.
  NSString *_placementId;
}

- (void)loadRTBRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                          completionHandler:
                              (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  _adConfiguration = adConfiguration;
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

  _adUnitId = adConfiguration.credentials.settings[GADMAdapterMintegralAdUnitID];
  _placementId = adConfiguration.credentials.settings[GADMAdapterMintegralPlacementID];
  if (!_adUnitId.length || !_placementId.length) {
    NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(
        GADMintegralErrorInvalidServerParameters, @"Ad Unit ID or Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _rewardedAd = [MTGBidRewardAdManager sharedInstance];
  [_rewardedAd loadVideoWithBidToken:_adConfiguration.bidResponse
                         placementId:_placementId
                              unitId:_adUnitId
                            delegate:self];
}

#pragma mark - MTGRewardAdLoadDelegate
- (void)onVideoAdLoadSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
  if (_adLoadCompletionHandler) {
    _adEventDelegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)onVideoAdLoadFailed:(nullable NSString *)placementId
                     unitId:(nullable NSString *)unitId
                      error:(nonnull NSError *)error {
  if (_adLoadCompletionHandler) {
    _adLoadCompletionHandler(nil, error);
  }
}

#pragma mark - MTGRewardAdShowDelegate
- (void)onVideoAdShowSuccess:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate reportImpression];
  [_adEventDelegate didStartVideo];
}

- (void)onVideoAdShowFailed:(nullable NSString *)placementId
                     unitId:(nullable NSString *)unitId
                  withError:(nonnull NSError *)error {
  [_adEventDelegate didFailToPresentWithError:error];
}

- (void)onVideoPlayCompleted:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
  [_adEventDelegate didEndVideo];
}

- (void)onVideoAdClicked:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
  [_adEventDelegate reportClick];
}

- (void)onVideoAdDismissed:(nullable NSString *)placementId
                    unitId:(nullable NSString *)unitId
             withConverted:(BOOL)converted
            withRewardInfo:(nullable MTGRewardAdInfo *)rewardInfo {
  [_adEventDelegate willDismissFullScreenView];
  if (converted) {
    [_adEventDelegate didRewardUser];
  }
}

- (void)onVideoAdDidClosed:(nullable NSString *)placementId unitId:(nullable NSString *)unitId {
  [_adEventDelegate didDismissFullScreenView];
}

#pragma mark - GADMediationRewardedAd
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (!_adUnitId.length || !_placementId.length) {
    NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(
        GADMintegralErrorInvalidServerParameters, @"Ad Unit ID or Placement ID cannot be nil.");
    [_adEventDelegate didFailToPresentWithError:error];
    return;
  }
  GADMAdapterMintegralExtras *extras = _adConfiguration.extras;
  _rewardedAd = MTGBidRewardAdManager.sharedInstance;
  _rewardedAd.playVideoMute = extras.muteVideoAudio;
  if ([_rewardedAd isVideoReadyToPlayWithPlacementId:_placementId unitId:_adUnitId]) {
    [_rewardedAd showVideoWithPlacementId:_placementId
                                   unitId:_adUnitId
                             withRewardId:nil
                                   userId:nil
                                 delegate:self
                           viewController:viewController];
  } else {
    NSError *error = GADMAdapterMintegralErrorWithCodeAndDescription(
        GADMintegralErrorAdFailedToShow,
        @"Mintegral SDK failed to present a bidding rewarded video ad.");
    [_adEventDelegate didFailToPresentWithError:error];
  }
}

@end
