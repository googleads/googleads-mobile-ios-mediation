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

#import "GADMAdapterUnityRewardedAd.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnitySingleton.h"
#import "GADUnityError.h"

@interface GADMAdapterUnityRewardedAd () <GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate> {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;

  // Ad configuration for the ad to be rendered.
  GADMediationAdConfiguration *_adConfiguration;

  // An ad event delegate to invoke when ad rendering events occur.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// Game ID of Unity Ads network.
  NSString *_gameID;

  /// Placement ID of Unity Ads network.
  NSString *_placementID;

  /// YES if the adapter is loading.
  BOOL _isLoading;
}

@end

@implementation GADMAdapterUnityRewardedAd

- (instancetype)initWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                      completionHandler:
                          (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adLoadCompletionHandler = completionHandler;
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)requestRewardedAd {
  _gameID = [_adConfiguration.credentials.settings objectForKey:kGADMAdapterUnityGameID];
  _placementID = [_adConfiguration.credentials.settings objectForKey:kGADMAdapterUnityPlacementID];
  NSLog(@"Requesting unity rewarded ad with placement: %@", _placementID);

  GADMAdapterUnityRewardedAd __weak *weakSelf = self;

  if (!_gameID || !_placementID) {
    if (_adLoadCompletionHandler) {
      NSError *error = GADUnityErrorWithDescription(@"Game ID and Placement ID cannot be nil.");
      _adLoadCompletionHandler(nil, error);
      _adLoadCompletionHandler = nil;
    }
    return;
  }

  if (![UnityAds isSupported]) {
    NSString *description =
        [[NSString alloc] initWithFormat:@"%@ is not supported for this device.",
                                         NSStringFromClass([UnityAds class])];

    if (_adLoadCompletionHandler) {
      NSError *error = GADUnityErrorWithDescription(description);
      _adLoadCompletionHandler(nil, error);
      _adLoadCompletionHandler = nil;
    }
    return;
  }

  if ([UnityAds isReady:_placementID]) {
    if (_adLoadCompletionHandler) {
      _adEventDelegate = _adLoadCompletionHandler(self, nil);
      _adLoadCompletionHandler = nil;
    }
    _isLoading = NO;
  } else {
    _isLoading = YES;
  }

  [[GADMAdapterUnitySingleton sharedInstance] requestRewardedAdWithDelegate:weakSelf];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (_isLoading) {
    NSError *presentError = GADUnityErrorWithDescription(@"Ad has not finished loading.");
    [_adEventDelegate didFailToPresentWithError:presentError];
  } else {
    [[GADMAdapterUnitySingleton sharedInstance] presentRewardedAdForViewController:viewController
                                                                          delegate:self];
  }
}

#pragma mark GADMAdapterUnityDataProvider Methods

- (NSString *)getGameID {
  return _gameID;
}

- (NSString *)getPlacementID {
  return _placementID;
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsDidError:(UnityAdsError)error withMessage:(nonnull NSString *)message {
  if (!_isLoading) {
    if (error == kUnityAdsErrorShowError) {
      NSError *presentError = GADUnityErrorWithDescription(message);
      [_adEventDelegate didFailToPresentWithError:presentError];
    }
    return;
  }

  if (_adLoadCompletionHandler) {
    NSError *errorWithDescription = GADUnityErrorWithDescription(message);
    _adLoadCompletionHandler(nil, errorWithDescription);
    _adLoadCompletionHandler = nil;
  }
  _isLoading = NO;
}

- (void)unityAdsDidFinish:(nonnull NSString *)placementId
          withFinishState:(UnityAdsFinishState)state {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (state == kUnityAdsFinishStateCompleted) {
    [strongDelegate didEndVideo];
    // Unity Ads doesn't provide a way to set the reward on their front-end. Default to a reward
    // amount of 1. Publishers using this adapter should override the reward on the AdMob
    // front-end.
    GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@""
                                                     rewardAmount:[NSDecimalNumber one]];
    [strongDelegate didRewardUserWithReward:reward];
  }
  [strongDelegate willDismissFullScreenView];
  [strongDelegate didDismissFullScreenView];
}

- (void)unityAdsDidStart:(nonnull NSString *)placementId {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate didStartVideo];
}

- (void)unityAdsReady:(nonnull NSString *)placementId {
  if (!_isLoading) {
    return;
  }

  if (_adLoadCompletionHandler) {
    _adEventDelegate = _adLoadCompletionHandler(self, nil);
    _adLoadCompletionHandler = nil;
  }
  _isLoading = NO;
}

- (void)unityAdsDidClick:(nonnull NSString *)placementId {
  // The Unity Ads SDK doesn't provide an event for leaving the application, so the adapter assumes
  // that a click event indicates the user is leaving the application for a browser or deeplink, and
  // notifies the Google Mobile Ads SDK accordingly.
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate reportClick];
}

- (void)unityAdsPlacementStateChanged:(nonnull NSString *)placementId
                             oldState:(UnityAdsPlacementState)oldState
                             newState:(UnityAdsPlacementState)newState {
  // This callback is not forwarded to the adapter by the GADMAdapterUnitySingleton and the adapter
  // should use the unityAdsReady: and unityAdsDidError: callbacks to forward Unity Ads SDK state to
  // Google Mobile Ads SDK.
}

@end
