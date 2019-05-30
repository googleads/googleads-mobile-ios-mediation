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

#import "GADFBRewardedRenderer.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <AdSupport/AdSupport.h>

#import "GADFBError.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADFBRewardedRenderer () <GADMediationRewardedAd, FBRewardedVideoAdDelegate> {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;

  // The Facebook rewarded ad.
  FBRewardedVideoAd *_rewardedAd;

  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  BOOL _isRTBRequest;
}

@end

@implementation GADFBRewardedRenderer

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  // Store the ad config and completion handler for later use.
  _adLoadCompletionHandler = completionHandler;
  if (adConfiguration.bidResponse) {
    _isRTBRequest = YES;
  }

  NSString *placementID =
      [GADMediationAdapterFacebook getPlacementIDFromCredentials:adConfiguration.credentials];

  if (!placementID) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _rewardedAd = [[FBRewardedVideoAd alloc] initWithPlacementID:placementID];

  if (!_rewardedAd) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to initialize.", NSStringFromClass([FBRewardedVideoAd class])];
    NSError *error = GADFBErrorWithDescription(description);
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _rewardedAd.delegate = self;
  [FBAdSettings
      setMediationService:[NSString stringWithFormat:@"GOOGLE_%@:%@", [GADRequest sdkVersion],
                                                     kGADMAdapterFacebookVersion]];

  if (_isRTBRequest) {
    [_rewardedAd loadAdWithBidPayload:adConfiguration.bidResponse];
  } else {
    [_rewardedAd loadAd];
  }
}

#pragma mark FBRewardedVideoAdDelegate

- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd {
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate && !_isRTBRequest) {
    [strongDelegate reportClick];
  }
}

- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate didDismissFullScreenView];
  }
}

- (void)rewardedVideoAdWillClose:(FBRewardedVideoAd *)rewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate willDismissFullScreenView];
  }
}

- (void)rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@""
                                                     rewardAmount:[NSDecimalNumber one]];
    [strongDelegate didEndVideo];
    [strongDelegate didRewardUserWithReward:reward];
  }
}

- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate && !_isRTBRequest) {
    [strongDelegate reportImpression];
  }
}

#pragma mark GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  /// The FAN SDK doesn't have callbacks for a rewarded ad opening or playing. Invoke callbacks on
  /// the Google Mobile Ads SDK within this method instead.
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (!strongDelegate) {
    return;
  }
  if ([_rewardedAd isAdValid]) {
    [_rewardedAd showAdFromRootViewController:viewController];
    [strongDelegate willPresentFullScreenView];
    [strongDelegate didStartVideo];
  } else {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to present.", NSStringFromClass([FBRewardedVideoAd class])];
    NSError *error = GADFBErrorWithDescription(description);
    [strongDelegate didFailToPresentWithError:error];
  }
}

@end
