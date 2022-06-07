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

#import <AdSupport/AdSupport.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

#include <stdatomic.h>
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADFBRewardedRenderer () <GADMediationRewardedAd, FBRewardedVideoAdDelegate>

@end

@implementation GADFBRewardedRenderer {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;

  // The Meta Audience Network rewarded ad.
  FBRewardedVideoAd *_rewardedAd;

  // An ad event delegate to invoke when ad rendering events occur.
  // Intentionally keeping a reference to the delegate because this delegate is returned from the
  // GMA SDK, not set on the GMA SDK.
  id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// Indicates whether this renderer is loading a real-time bidding request.
  BOOL _isRTBRequest;

  /// Indicates whether presentFromViewController: was called on this renderer.
  BOOL _presentCalled;
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  // Store the ad config and completion handler for later use.
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

  if (adConfiguration.bidResponse) {
    _isRTBRequest = YES;
  }

  NSString *placementID =
      [GADMediationAdapterFacebook getPlacementIDFromCredentials:adConfiguration.credentials];

  if (!placementID) {
    NSError *error =
        GADFBErrorWithCodeAndDescription(GADFBErrorInvalidRequest, @"Placement ID cannot be nil.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _rewardedAd = [[FBRewardedVideoAd alloc] initWithPlacementID:placementID];

  if (!_rewardedAd) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to initialize.", NSStringFromClass([FBRewardedVideoAd class])];
    NSError *error = GADFBErrorWithCodeAndDescription(GADFBErrorAdObjectNil, description);
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _rewardedAd.delegate = self;
  GADFBConfigureMediationService();

  FBAdExperienceConfig *adExperienceConfig =
      [[FBAdExperienceConfig alloc] initWithAdExperienceType:[self adExperienceType]];
  _rewardedAd.adExperienceConfig = adExperienceConfig;
  NSLog(@"Requesting ad with ad experience type: %@", adExperienceConfig.adExperienceType);

  if (_isRTBRequest) {
    // Adds a watermark to the ad.
    FBAdExtraHint *watermarkHint = [[FBAdExtraHint alloc] init];
    watermarkHint.mediationData = [adConfiguration.watermark base64EncodedStringWithOptions:0];
    _rewardedAd.extraHint = watermarkHint;
    // Load ad.
    [_rewardedAd loadAdWithBidPayload:adConfiguration.bidResponse];
  } else {
    [_rewardedAd loadAd];
  }
}

- (FBAdExperienceType)adExperienceType {
  return FBAdExperienceTypeRewarded;
}

#pragma mark FBRewardedVideoAdDelegate

- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd {
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
  if (_presentCalled) {
    NSLog(@"Received a Meta Audience Network SDK error during presentation: %@",
          error.localizedDescription);
    [_adEventDelegate didFailToPresentWithError:error];
    return;
  }
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
    [strongDelegate didEndVideo];
    [strongDelegate didRewardUserWithReward:reward];
  }
}

- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
  [_adEventDelegate reportImpression];
}

#pragma mark GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  /// The Meta Audience Network SDK doesn't have callbacks for a rewarded ad opening or
  /// playing. Invoke callbacks on the Google Mobile Ads SDK within this method instead.
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  _presentCalled = YES;
  if (![_rewardedAd showAdFromRootViewController:viewController]) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to present.", NSStringFromClass([FBRewardedVideoAd class])];
    NSError *error = GADFBErrorWithCodeAndDescription(GADFBErrorAdNotValid, description);
    [strongDelegate didFailToPresentWithError:error];
    return;
  }
  [strongDelegate willPresentFullScreenView];
  [strongDelegate didStartVideo];
}

@end
