// Copyright 2020 Google Inc.
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
#import "GADUnityError.h"
#import "GADMAdapterUnityUtils.h"

@interface GADMAdapterUnityRewardedAd () <UnityAdsExtendedDelegate, UnityAdsLoadDelegate> {
  // The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _adLoadCompletionHandler;
  
  // Ad configuration for the ad to be rendered.
  GADMediationAdConfiguration *_adConfiguration;
  
  // An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationRewardedAdEventDelegate> _adEventDelegate;
  
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
                      completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
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
  NSLog(@"Requesting Unity rewarded ad with placement: %@", _placementID);
  if (!_gameID || !_placementID) {
    if (_adLoadCompletionHandler) {
      NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorInvalidServerParameters, kMISSING_ID_ERROR);
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
      NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorDeviceNotSupported, description);
      _adLoadCompletionHandler(nil, error);
      _adLoadCompletionHandler = nil;
    }
    return;
  }
  
  [UnityAds addDelegate:self];
  [UnityAds load:_placementID loadDelegate:self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (![UnityAds isReady:_placementID]) {
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorShowAdNotReady, @"Failed to show Unity Ads rewarded video.");
    [_adEventDelegate didFailToPresentWithError:error];
    return;
  }
  [_adEventDelegate willPresentFullScreenView];
  [UnityAds show:viewController placementId:_placementID];
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsDidError:(UnityAdsError)error withMessage:(nonnull NSString *)message {
  if (_adEventDelegate) {
    [UnityAds removeDelegate:self];
    NSError *errorWithDescription =
    GADMAdapterUnitySDKErrorWithUnityAdsErrorAndMessage(error, message);
    [_adEventDelegate didFailToPresentWithError:errorWithDescription];
  }
}

- (void)unityAdsDidFinish:(nonnull NSString *)placementID
          withFinishState:(UnityAdsFinishState)state {
  [UnityAds removeDelegate:self];
  
  if (state == kUnityAdsFinishStateCompleted) {
    [_adEventDelegate didEndVideo];
    
    // Unity Ads doesn't provide a way to set the reward on their front-end. Default to a reward
    // amount of 1. Publishers using this adapter should override the reward on the AdMob
    // front-end.
    GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@""
                                                     rewardAmount:[NSDecimalNumber one]];
    [_adEventDelegate didRewardUserWithReward:reward];
  } else if (state == kUnityAdsFinishStateError) {
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorFinish,
                                                                 @"UnityAds finished presenting with error state kUnityAdsFinishStateError.");
    [_adEventDelegate didFailToPresentWithError:error];
  }
  
  [_adEventDelegate willDismissFullScreenView];
  [_adEventDelegate didDismissFullScreenView];
}

- (void)unityAdsDidStart:(nonnull NSString *)placementID {
  [_adEventDelegate didStartVideo];
}

- (void)unityAdsReady:(nonnull NSString *)placementID {
}

- (void)unityAdsDidClick:(nonnull NSString *)placementID {
  // The Unity Ads SDK doesn't provide an event for leaving the application, so the adapter assumes
  // that a click event indicates the user is leaving the application for a browser or deeplink, and
  // notifies the Google Mobile Ads SDK accordingly.
  [_adEventDelegate reportClick];
}

- (void)unityAdsPlacementStateChanged:(nonnull NSString *)placementID
                             oldState:(UnityAdsPlacementState)oldState
                             newState:(UnityAdsPlacementState)newState {
}

- (void)unityAdsAdFailedToLoad:(nonnull NSString *)placementId {
  [UnityAds removeDelegate:self];
  if (_adLoadCompletionHandler) {
    NSError *error = GADUnityErrorWithDescription([NSString stringWithFormat:@"Failed to load rewarded ad with placement ID '%@'", placementId]);
    _adEventDelegate = _adLoadCompletionHandler(nil, error);
  }
}

- (void)unityAdsAdLoaded:(nonnull NSString *)placementId { 
  if (_adLoadCompletionHandler) {
    _adEventDelegate = _adLoadCompletionHandler(self, nil);
  }
}

@end
