// Copyright 2016 Google Inc.
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

#import "GADMAdapterUnity.h"

#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnitySingleton.h"
#import "GADUnityError.h"

@interface GADMAdapterUnity () {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardBasedVideoAdConnector;

  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _interstitialConnector;

  /// Placement ID of Unity Ads network.
  NSString *_placementID;

  /// YES if the adapter is loading.
  BOOL _isLoading;
}

@end

@implementation GADMAdapterUnity

+ (NSString *)adapterVersion {
  return GADMAdapterUnityVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

#pragma mark Reward-based Video Ad Methods

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
        (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }

  self = [super init];
  if (self) {
    _rewardBasedVideoAdConnector = connector;
  }
  return self;
}

- (void)setUp {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  NSString *gameID =
      [[[strongConnector credentials] objectForKey:GADMAdapterUnityGameID] copy];
  _placementID =
      [[[strongConnector credentials] objectForKey:GADMAdapterUnityPlacementID] copy];
  if (!gameID || !_placementID) {
    NSError *error = GADUnityErrorWithDescription(@"Game ID and Placement ID cannot be nil.");
    [strongConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
    return;
  }
  BOOL isConfigured =
      [[GADMAdapterUnitySingleton sharedInstance] configureRewardBasedVideoAdWithGameID:gameID
                                                                               delegate:self];
  if (isConfigured) {
    [strongConnector adapterDidSetUpRewardBasedVideoAd:self];
  } else {
    NSString *description =
        [[NSString alloc] initWithFormat:@"%@ is not supported for this device.",
                                         NSStringFromClass([UnityAds class])];
    NSError *error = GADUnityErrorWithDescription(description);
    [strongConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
  }
}

- (void)requestRewardBasedVideoAd {
  _placementID =
      [[[_rewardBasedVideoAdConnector credentials] objectForKey:GADMAdapterUnityPlacementID] copy];
  _isLoading = YES;
  [[GADMAdapterUnitySingleton sharedInstance] requestRewardBasedVideoAdWithDelegate:self];
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  // We will send adapterDidOpenRewardBasedVideoAd callback before presenting the unity ad because
  // the ad has already loaded.
  [_rewardBasedVideoAdConnector adapterDidOpenRewardBasedVideoAd:self];
  [[GADMAdapterUnitySingleton sharedInstance]
      presentRewardBasedVideoAdForViewController:viewController
                                        delegate:self];
}

- (void)stopBeingDelegate {
  [[GADMAdapterUnitySingleton sharedInstance] stopTrackingDelegate:self];
}

#pragma mark Interstitial Methods

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }

  self = [super init];
  if (self) {
    _interstitialConnector = connector;
  }
  return self;
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
  NSString *gameID =
      [[[strongConnector credentials] objectForKey:GADMAdapterUnityGameID] copy];
  _placementID =
      [[[strongConnector credentials] objectForKey:GADMAdapterUnityPlacementID] copy];
  if (!gameID || !_placementID) {
    NSError *error = GADUnityErrorWithDescription(@"Game ID and Placement ID cannot be nil.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  _isLoading = YES;
  [[GADMAdapterUnitySingleton sharedInstance] configureInterstitialAdWithGameID:gameID
                                                                       delegate:self];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  // We will send adapterWillPresentInterstitial callback before presenting unity ad because the ad
  // has already loaded.
  [_interstitialConnector adapterWillPresentInterstitial:self];
  [[GADMAdapterUnitySingleton sharedInstance]
      presentInterstitialAdForViewController:rootViewController
                                    delegate:self];
}

#pragma mark Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  // Unity Ads doesn't support banner ads.
  id<GADMAdNetworkConnector> strongConnector = _interstitialConnector;
  NSError *error = GADUnityErrorWithDescription(@"Unity Ads doesn't support banner ads.");
  [strongConnector adapter:self didFailAd:error];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

#pragma mark GADMAdapterUnityDataProvider Methods

- (NSString *)getPlacementID {
  return _placementID;
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsPlacementStateChanged:(NSString *)placementId
                             oldState:(UnityAdsPlacementState)oldState
                             newState:(UnityAdsPlacementState)newState {
  // This callback is not forwarded to the adapter by the GADMAdapterUnitySingleton and the adapter
  // should use the unityAdsReady: and unityAdsDidError: callbacks to forward Unity Ads SDK state to
  // Google Mobile Ads SDK.
}

- (void)unityAdsDidFinish:(NSString *)placementID withFinishState:(UnityAdsFinishState)state {
  id<GADMAdNetworkConnector> strongInterstitialConnector = _interstitialConnector;
  id<GADMRewardBasedVideoAdNetworkConnector> strongRewardedConnector = _rewardBasedVideoAdConnector;
  if (strongInterstitialConnector) {
    [strongInterstitialConnector adapterWillDismissInterstitial:self];
    [strongInterstitialConnector adapterDidDismissInterstitial:self];
  } else if (strongRewardedConnector) {
    if (state == kUnityAdsFinishStateCompleted) {
      [strongRewardedConnector adapterDidCompletePlayingRewardBasedVideoAd:self];
      // Unity Ads doesn't provide a way to set the reward on their front-end. Default to a reward
      // amount of 1. Publishers using this adapter should override the reward on the AdMob
      // front-end.
      GADAdReward *reward =
          [[GADAdReward alloc] initWithRewardType:@"" rewardAmount:[NSDecimalNumber one]];
      [strongRewardedConnector adapter:self didRewardUserWithReward:reward];
    }
    [strongRewardedConnector adapterDidCloseRewardBasedVideoAd:self];
  }
}

- (void)unityAdsDidStart:(NSString *)placementID {
  id<GADMRewardBasedVideoAdNetworkConnector> strongRewardedConnector = _rewardBasedVideoAdConnector;
  if (strongRewardedConnector) {
    [strongRewardedConnector adapterDidStartPlayingRewardBasedVideoAd:self];
  }
}

- (void)unityAdsReady:(NSString *)placementID {
  id<GADMAdNetworkConnector> strongInterstitialConnector = _interstitialConnector;
  if (!_isLoading) {
    return;
  }

  if (strongInterstitialConnector) {
    [strongInterstitialConnector adapterDidReceiveInterstitial:self];
  } else {
    [_rewardBasedVideoAdConnector adapterDidReceiveRewardBasedVideoAd:self];
  }
  _isLoading = NO;
}

- (void)unityAdsDidClick:(NSString *)placementID {
  id<GADMAdNetworkConnector> strongInterstitialConnector = _interstitialConnector;
  id<GADMRewardBasedVideoAdNetworkConnector> strongRewardedConnector = _rewardBasedVideoAdConnector;
  // The Unity Ads SDK doesn't provide an event for leaving the application, so the adapter assumes
  // that a click event indicates the user is leaving the application for a browser or deeplink, and
  // notifies the Google Mobile Ads SDK accordingly.
  if (strongInterstitialConnector) {
    [strongInterstitialConnector adapterDidGetAdClick:self];
    [strongInterstitialConnector adapterWillLeaveApplication:self];
  } else {
    [strongRewardedConnector adapterDidGetAdClick:self];
    [strongRewardedConnector adapterWillLeaveApplication:self];
  }
}

- (void)unityAdsDidError:(UnityAdsError)error withMessage:(NSString *)message {
  id<GADMAdNetworkConnector> strongInterstitialConnector = _interstitialConnector;
  id<GADMRewardBasedVideoAdNetworkConnector> strongRewardedConnector = _rewardBasedVideoAdConnector;
  if (!_isLoading) {
    // Unity Ads show error will only happen after the ad has been loaded. So, we will send
    // dismiss/close callbacks.
    if (error == kUnityAdsErrorShowError) {
      if (strongInterstitialConnector) {
        [strongInterstitialConnector adapterWillDismissInterstitial:self];
        [strongInterstitialConnector adapterDidDismissInterstitial:self];
      } else {
        [strongRewardedConnector adapterDidCloseRewardBasedVideoAd:self];
      }
    }
    return;
  }

  NSError *errorWithDescription = GADUnityErrorWithDescription(message);
  if (strongInterstitialConnector) {
    [strongInterstitialConnector adapter:self didFailAd:errorWithDescription];
  } else if (strongRewardedConnector) {
    [strongRewardedConnector adapter:self
        didFailToLoadRewardBasedVideoAdwithError:errorWithDescription];
  }
  _isLoading = NO;
}

@end
