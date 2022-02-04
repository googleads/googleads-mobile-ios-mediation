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

#import "GADMAdapterInMobiRewardedAd.h"
#import <InMobiSDK/InMobiSDK.h>
#include <stdatomic.h>
#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiDelegateManager.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"
#import "GADMediationAdapterInMobi.h"

@interface GADMAdapterInMobiRewardedAd () <IMInterstitialDelegate>
@end

@implementation GADMAdapterInMobiRewardedAd {
  /// Ad Configuration for the ad to be rendered.
  GADMediationRewardedAdConfiguration *_adConfig;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _renderCompletionHandler;

  /// An ad event delegate to invoke when ad rendering events occur.
  /// Intentionally keeping a strong reference to the delegate because this is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// InMobi rewarded ad.
  IMInterstitial *_rewardedAd;

  /// InMobi Placement identifier.
  NSNumber *_placementIdentifier;
}

- (nonnull instancetype)initWithPlacementIdentifier:(nonnull NSNumber *)placementIdentifier {
  self = [super init];
  if (self) {
    _placementIdentifier = placementIdentifier;
    _rewardedAd = [[IMInterstitial alloc] initWithPlacementId:_placementIdentifier.longLongValue];
    _rewardedAd.delegate = self;
  }
  return self;
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  _adConfig = adConfiguration;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _renderCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
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

  GADMAdapterInMobiRewardedAd *__weak weakSelf = self;
  NSString *accountID = _adConfig.credentials.settings[GADMAdapterInMobiAccountID];
  [GADMAdapterInMobiInitializer.sharedInstance
      initializeWithAccountID:accountID
            completionHandler:^(NSError *_Nullable error) {
              GADMAdapterInMobiRewardedAd *strongSelf = weakSelf;
              if (!strongSelf) {
                return;
              }

              if (error) {
                NSLog(@"[InMobi] Initialization failed: %@", error.localizedDescription);
                strongSelf->_renderCompletionHandler(nil, error);
                return;
              }

              [strongSelf requestRewardedAd];
            }];
}

- (void)requestRewardedAd {
  // Converting a string to a long long value.
  long long placement =
      [_adConfig.credentials.settings[GADMAdapterInMobiPlacementID] longLongValue];

  // Converting a long long value to a NSNumber so that it can be used as a key to store in a
  // dictionary.
  _placementIdentifier = @(placement);

  // Validates the placement identifier.
  NSError *error = GADMAdapterInMobiValidatePlacementIdentifier(_placementIdentifier);
  if (error) {
    _renderCompletionHandler(nil, error);
    return;
  }

  GADMAdapterInMobiDelegateManager *delegateManager =
      GADMAdapterInMobiDelegateManager.sharedInstance;
  if ([delegateManager containsDelegateForPlacementIdentifier:_placementIdentifier]) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorAdAlreadyLoaded,
        @"[InMobi] Error - cannot request multiple ads using same placement ID.");
    _renderCompletionHandler(nil, error);
    return;
  }

  [delegateManager addDelegate:self forPlacementIdentifier:_placementIdentifier];

  if (_adConfig.isTestRequest) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to receive test ads from "
          @"Inmobi");
  }

  GADInMobiExtras *extras = _adConfig.extras;
  if (extras && extras.keywords) {
    [_rewardedAd setKeywords:extras.keywords];
  }

  GADMAdapterInMobiSetTargetingFromAdConfiguration(_adConfig);
  NSDictionary<NSString *, id> *requestParameters =
      GADMAdapterInMobiCreateRequestParametersFromAdConfiguration(_adConfig);
  [_rewardedAd setExtras:requestParameters];

  [_rewardedAd load];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if ([_rewardedAd isReady]) {
    [_rewardedAd showFromViewController:viewController];
  }
}

#pragma mark IMInterstitialDelegate methods

- (void)interstitialDidFinishLoading:(nonnull IMInterstitial *)interstitial {
  _adEventDelegate = _renderCompletionHandler(self, nil);
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didFailToLoadWithError:(nonnull IMRequestStatus *)error {
  GADMAdapterInMobiDelegateManager *delegateManager =
      GADMAdapterInMobiDelegateManager.sharedInstance;
  [delegateManager removeDelegateForPlacementIdentifier:_placementIdentifier];
  _renderCompletionHandler(nil, error);
}

- (void)interstitialWillPresent:(nonnull IMInterstitial *)interstitial {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)interstitialDidPresent:(nonnull IMInterstitial *)interstitial {
  [_adEventDelegate reportImpression];
  [_adEventDelegate didStartVideo];
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didFailToPresentWithError:(nonnull IMRequestStatus *)error {
  GADMAdapterInMobiDelegateManager *delegateManager =
      GADMAdapterInMobiDelegateManager.sharedInstance;
  [delegateManager removeDelegateForPlacementIdentifier:_placementIdentifier];
  [_adEventDelegate didFailToPresentWithError:error];
}

- (void)interstitialWillDismiss:(nonnull IMInterstitial *)interstitial {
  [_adEventDelegate willDismissFullScreenView];
}

- (void)interstitialDidDismiss:(nonnull IMInterstitial *)interstitial {
  GADMAdapterInMobiDelegateManager *delegateManager =
      GADMAdapterInMobiDelegateManager.sharedInstance;
  [delegateManager removeDelegateForPlacementIdentifier:_placementIdentifier];
  [_adEventDelegate didDismissFullScreenView];
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didInteractWithParams:(nonnull NSDictionary *)params {
  [_adEventDelegate reportClick];
}

- (void)interstitialDidReceiveAd:(nonnull IMInterstitial *)interstitial {
  // No equivalent callback in the Google Mobile Ads SDK.
  // This event indicates that InMobi fetched an ad from the server, but hasn't loaded it yet.
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    rewardActionCompletedWithRewards:(nonnull NSDictionary *)rewards {
  NSString *key = rewards.allKeys.firstObject;
  if (key) {
    GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:key rewardAmount:rewards[key]];
    [_adEventDelegate didRewardUserWithReward:reward];
  }
  [_adEventDelegate didEndVideo];
}

@end
