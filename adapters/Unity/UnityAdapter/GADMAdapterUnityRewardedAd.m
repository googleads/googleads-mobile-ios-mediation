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
#import "GADMAdapterUnityUtils.h"

@interface GADMAdapterUnityRewardedAd () <GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate> {
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

  /// UUID for Unity instrument analysis
  NSString *_uuid;

  /// MetaData for storing Unity instrument analysis
  UADSMetaData *_metaData;
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

    _uuid = [[NSUUID UUID] UUIDString];

    _metaData = [[UADSMetaData alloc] init];
    [_metaData setCategory:@"mediation_adapter"];
    [_metaData set:_uuid value:@"create-adapter"];
    [_metaData commit];
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
      NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
          GADMAdapterUnityErrorInvalidServerParameters, @"Game ID and Placement ID cannot be nil.");
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
      NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
          GADMAdapterUnityErrorDeviceNotSupported, description);
      _adLoadCompletionHandler(nil, error);
      _adLoadCompletionHandler = nil;
    }
    return;
  }

  [_metaData setCategory:@"mediation_adapter"];
  [_metaData set:_uuid value:@"load-rewarded"];
  [_metaData set:_uuid value:_placementID];
  [_metaData commit];
  [[GADMAdapterUnitySingleton sharedInstance] requestRewardedAdWithDelegate:weakSelf];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (![UnityAds isReady:_placementID]) {
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
        GADMAdapterUnityErrorShowAdNotReady, @"Failed to show Unity Ads rewarded video.");
    [_adEventDelegate didFailToPresentWithError:error];

    [_metaData setCategory:@"mediation_adapter"];
    [_metaData set:_uuid value:@"fail-to-show-rewarded"];
    [_metaData set:_uuid value:_placementID];
    [_metaData commit];
    return;
  }
  [_adEventDelegate willPresentFullScreenView];

  [_metaData setCategory:@"mediation_adapter"];
  [_metaData set:_uuid value:@"show-rewarded"];
  [_metaData set:_uuid value:_placementID];
  [_metaData commit];

  [[GADMAdapterUnitySingleton sharedInstance] presentRewardedAdForViewController:viewController
                                                                        delegate:self];
}

#pragma mark GADMAdapterUnityDataProvider Methods

- (NSString *)getGameID {
  return _gameID;
}

- (NSString *)getPlacementID {
  return _placementID;
}

- (void)didFailToLoadWithError:(nonnull NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsDidError:(UnityAdsError)error withMessage:(nonnull NSString *)message {
  if (error == kUnityAdsErrorNotInitialized) {
    if (_adLoadCompletionHandler) {
      NSError *errorWithDescription =
          GADMAdapterUnitySDKErrorWithUnityAdsErrorAndMessage(error, message);
      _adLoadCompletionHandler(nil, errorWithDescription);
      _adLoadCompletionHandler = nil;
    }
  } else {
    if (_adEventDelegate) {
      NSError *errorWithDescription =
          GADMAdapterUnitySDKErrorWithUnityAdsErrorAndMessage(error, message);
      [_adEventDelegate didFailToPresentWithError:errorWithDescription];
    }
  }
}

- (void)unityAdsDidFinish:(nonnull NSString *)placementID
          withFinishState:(UnityAdsFinishState)state {
  if (![placementID isEqualToString:_placementID]) {
    return;
  }

  if (state == kUnityAdsFinishStateCompleted) {
    [_adEventDelegate didEndVideo];

    // Unity Ads doesn't provide a way to set the reward on their front-end. Default to a reward
    // amount of 1. Publishers using this adapter should override the reward on the AdMob
    // front-end.
    GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@""
                                                     rewardAmount:[NSDecimalNumber one]];
    [_adEventDelegate didRewardUserWithReward:reward];
  } else if (state == kUnityAdsFinishStateError) {
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
        GADMAdapterUnityErrorFinish,
        @"UnityAds finished presenting with error state kUnityAdsFinishStateError.");
    [_adEventDelegate didFailToPresentWithError:error];
  }

  [_adEventDelegate willDismissFullScreenView];
  [_adEventDelegate didDismissFullScreenView];
}

- (void)unityAdsDidStart:(nonnull NSString *)placementID {
  if ([placementID isEqualToString:_placementID]) {
    [_adEventDelegate didStartVideo];
  }
}

- (void)unityAdsReady:(nonnull NSString *)placementID {
  if (_adLoadCompletionHandler && [placementID isEqualToString:_placementID]) {
    _adEventDelegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)unityAdsDidClick:(nonnull NSString *)placementID {
  // The Unity Ads SDK doesn't provide an event for leaving the application, so the adapter assumes
  // that a click event indicates the user is leaving the application for a browser or deeplink, and
  // notifies the Google Mobile Ads SDK accordingly.
  if ([placementID isEqualToString:_placementID]) {
    [_adEventDelegate reportClick];
  }
}

- (void)unityAdsPlacementStateChanged:(nonnull NSString *)placementID
                             oldState:(UnityAdsPlacementState)oldState
                             newState:(UnityAdsPlacementState)newState {
  if (![placementID isEqualToString:_placementID]) {
    return;
  }
  if (newState == kUnityAdsPlacementStateNoFill) {
    if (_adLoadCompletionHandler) {
      NSString *errorMsg =
          [NSString stringWithFormat:@"No ad available for this placement ID: %@", placementID];
      NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
          GADMAdapterUnityErrorPlacementStateNoFill, errorMsg);
      _adLoadCompletionHandler(nil, error);
    }
    [[GADMAdapterUnitySingleton sharedInstance] stopTrackingDelegate:self];
    return;
  }
  if (newState == kUnityAdsPlacementStateDisabled) {
    if (_adLoadCompletionHandler) {
      NSString *errorMsg =
          [NSString stringWithFormat:@"This placement ID is currently disabled: %@", placementID];
      NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
          GADMAdapterUnityErrorPlacementStateDisabled, errorMsg);
      _adLoadCompletionHandler(nil, error);
    }
    [[GADMAdapterUnitySingleton sharedInstance] stopTrackingDelegate:self];
    return;
  }
}

@end
