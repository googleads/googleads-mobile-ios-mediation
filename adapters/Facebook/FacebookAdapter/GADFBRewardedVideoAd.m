// Copyright 2017 Google Inc.
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

#import "GADFBRewardedVideoAd.h"
#import "GADFBError.h"
#import "GADMediationAdapterFacebook.h"
@import FBAudienceNetwork;

@interface GADFBRewardedVideoAd () {
  // The completion handler to call when the ad loading succeeds or fails.
  GADRewardedLoadCompletionHandler _adLoadCompletionHandler;

  // Ad configuration for the ad to be rendered.
  GADMediationAdConfiguration *_adConfiguration;

  // The Facebook rewarded ad.
  FBRewardedVideoAd *_rewardedVideoAd;

  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;
}
@end

@implementation GADFBRewardedVideoAd

- (instancetype)initWithGADMediationRewardedAdConfiguration:
                    (GADMediationRewardedAdConfiguration *)adConfiguration
                                          completionHandler:
                                              (GADRewardedLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adLoadCompletionHandler = completionHandler;
    _adConfiguration = adConfiguration;
  }
  return self;
}

/// Starts fetching a rewarded video ad from Facebook's Audience Network.
- (void)requestRewardedVideoAd {
  NSString *placementID = [[_adConfiguration.credentials settings]
      objectForKey:kGADMediationAdapterFacebookPublisherID];

  if (!placementID) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _rewardedVideoAd = [[FBRewardedVideoAd alloc] initWithPlacementID:placementID];

  if (!_rewardedVideoAd) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to initialize.", NSStringFromClass([FBRewardedVideoAd class])];
    NSError *error = GADFBErrorWithDescription(description);
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _rewardedVideoAd.delegate = self;
  [FBAdSettings
      setMediationService:[NSString stringWithFormat:@"ADMOB_%@", [GADRequest sdkVersion]]];
  [_rewardedVideoAd loadAd];
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
  if (strongDelegate) {
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
    [strongDelegate didRewardUserWithReward:reward];
    [strongDelegate didEndVideo];
  }
}

- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate reportImpression];
}

#pragma mark GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  /// The FAN SDK doesn't have callbacks for a rewarded ad opening or playing. Invoke callbacks on
  /// the Google Mobile Ads SDK within this method instead.
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (!strongDelegate) {
    return;
  }
  if ([_rewardedVideoAd isAdValid]) {
    [_rewardedVideoAd showAdFromRootViewController:viewController];
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
