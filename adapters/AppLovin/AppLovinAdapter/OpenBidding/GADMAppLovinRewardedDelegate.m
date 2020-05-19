// Copyright 2019 Google LLC.
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

#import "GADMAppLovinRewardedDelegate.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"

@implementation GADMAppLovinRewardedDelegate {
  /// AppLovin rewarded ad renderer to which the events are delegated.
  __weak GADMAdapterAppLovinRewardedRenderer *_parentRenderer;

  /// Indicates whether the user has watched the rewarded ad completely.
  BOOL _fullyWatched;

  /// Reward information for AppLovin ads.
  GADAdReward *_reward;
}

#pragma mark - Initialization

- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMAdapterAppLovinRewardedRenderer *)parentRenderer {
  self = [super init];
  if (self) {
    _parentRenderer = parentRenderer;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad did load ad: %@", ad];

  GADMAdapterAppLovinRewardedRenderer *parentRenderer = _parentRenderer;
  parentRenderer.ad = ad;
  dispatch_async(dispatch_get_main_queue(), ^{
    if (parentRenderer.adLoadCompletionHandler) {
      parentRenderer.delegate = parentRenderer.adLoadCompletionHandler(parentRenderer, nil);
    }
  });
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code {
  GADMAdapterAppLovinRewardedRenderer *parentRenderer = _parentRenderer;
  [GADMAdapterAppLovinMediationManager.sharedInstance
      removeRewardedZoneIdentifier:parentRenderer.zoneIdentifier];
  if (parentRenderer.adLoadCompletionHandler) {
    NSError *error = GADMAdapterAppLovinSDKErrorWithCode(code);
    parentRenderer.adLoadCompletionHandler(nil, error);
  }
}

#pragma mark - Ad Display Delegate

- (void)ad:(nonnull ALAd *)ad wasClickedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad clicked"];
  [_parentRenderer.delegate reportClick];
}

- (void)ad:(nonnull ALAd *)ad wasDisplayedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad displayed"];

  id<GADMediationRewardedAdEventDelegate> delegate = _parentRenderer.delegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)ad:(nonnull ALAd *)ad wasHiddenIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad dismissed"];
  GADMAdapterAppLovinRewardedRenderer *parentRenderer = _parentRenderer;
  id<GADMediationRewardedAdEventDelegate> delegate = parentRenderer.delegate;
  if (_fullyWatched && _reward) {
    [delegate didRewardUserWithReward:_reward];
  }
  [GADMAdapterAppLovinMediationManager.sharedInstance
      removeRewardedZoneIdentifier:parentRenderer.zoneIdentifier];

  [delegate willDismissFullScreenView];
  [delegate didDismissFullScreenView];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(nonnull ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad playback began"];
  [_parentRenderer.delegate didStartVideo];
}

- (void)videoPlaybackEndedInAd:(nonnull ALAd *)ad
             atPlaybackPercent:(nonnull NSNumber *)percentPlayed
                  fullyWatched:(BOOL)wasFullyWatched {
  [GADMAdapterAppLovinUtils log:@"Rewarded ad playback ended at playback percent: %lu%%",
                                (unsigned long)percentPlayed.unsignedIntegerValue];

  GADMAdapterAppLovinRewardedRenderer *parentRenderer = _parentRenderer;
  _fullyWatched = wasFullyWatched;
  if (_fullyWatched) {
    [parentRenderer.delegate didEndVideo];
  }
}

#pragma mark - Reward Delegate

- (void)rewardValidationRequestForAd:(nonnull ALAd *)ad
          didExceedQuotaWithResponse:(nonnull NSDictionary *)response {
  [GADMAdapterAppLovinUtils
      log:@"Rewarded ad validation request for ad did exceed quota with response: %@", response];
}

- (void)rewardValidationRequestForAd:(nonnull ALAd *)ad didFailWithError:(NSInteger)responseCode {
  [GADMAdapterAppLovinUtils
      log:@"Rewarded ad validation request for ad failed with error code: %ld", (long)responseCode];
}

- (void)rewardValidationRequestForAd:(nonnull ALAd *)ad
             wasRejectedWithResponse:(nonnull NSDictionary *)response {
  [GADMAdapterAppLovinUtils
      log:@"Rewarded ad validation request was rejected with response: %@", response];
}

- (void)rewardValidationRequestForAd:(nonnull ALAd *)ad
              didSucceedWithResponse:(nonnull NSDictionary *)response {
  NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:response[@"amount"]];
  NSString *currency = response[@"currency"];

  [GADMAdapterAppLovinUtils log:@"Rewarded %@ %@", amount, currency];

  _reward = [[GADAdReward alloc] initWithRewardType:currency rewardAmount:amount];
}

@end
