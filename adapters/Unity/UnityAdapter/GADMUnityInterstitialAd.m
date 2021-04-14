// Copyright 2020 Google LLC.
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

#import "GADMUnityInterstitialAd.h"
#import "GADMAdapterUnity.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"
#import "GADUnityError.h"

@implementation GADMUnityInterstitialAd {
  NSString *_placementID;
  NSString *_gameID;
  BOOL _isLoading;
  BOOL _loadComplete;

  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Serializes  dispatch queue.
  dispatch_queue_t _lockQueue;
}

/// A map to keep track loaded Placement IDs
static NSMapTable<NSString *, GADMUnityInterstitialAd *> *_placementInUse;

- (instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                       adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _loadComplete = NO;
    _adapter = adapter;
    _connector = connector;
    _placementInUse = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory
                                            valueOptions:NSPointerFunctionsWeakMemory];
    _lockQueue = dispatch_queue_create("unityAds-rewardedAd", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector) {
    NSLog(@"Unity Ads Adapter Error: No GADMAdNetworkConnector found.");
    return;
  }

  if (!strongAdapter) {
    NSLog(@"Unity Ads Adapter Error: No GADMAdNetworkAdapter found.");
    return;
  }

  _gameID = [[[strongConnector credentials] objectForKey:kGADMAdapterUnityGameID] copy];
  _placementID = [[[strongConnector credentials] objectForKey:kGADMAdapterUnityPlacementID] copy];
  if (!_gameID || !_placementID) {
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
        GADMAdapterUnityErrorInvalidServerParameters, @"Game ID and Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  if (![UnityAds isInitialized]) {
    [[GADMAdapterUnity alloc] initializeWithGameID:_gameID withCompletionHandler:nil];
  }

  __block GADMUnityInterstitialAd *interstitialAd = nil;
  dispatch_sync(_lockQueue, ^{
    interstitialAd = [_placementInUse objectForKey:_placementID];
  });

  if (interstitialAd) {
    if (strongConnector && strongAdapter) {
      NSString *errorMsg = [NSString
          stringWithFormat:@"An ad is already loading for placement ID: %@.", _placementID];
      NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
          GADMAdapterUnityErrorAdAlreadyLoaded, errorMsg);
      [strongConnector adapter:strongAdapter didFailAd:error];
    }
    return;
  }

  dispatch_async(_lockQueue, ^{
    GADMAdapterUnityMapTableSetObjectForKey(_placementInUse, _placementID, self);
  });

  [UnityAds load:_placementID loadDelegate:self];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  dispatch_async(_lockQueue, ^{
    GADMAdapterUnityMapTableRemoveObjectForKey(_placementInUse, self->_placementID);
  });

  // We will send adapterWillPresentInterstitial callback before presenting unity ad because the ad
  // has already loaded.
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector) {
    NSLog(@"Unity Ads Adapter Error: No GADMAdNetworkConnector found.");
    return;
  }

  if (!strongAdapter) {
    NSLog(@"Unity Ads Adapter Error: No GADMAdNetworkAdapter found.");
    return;
  }

  if (!_loadComplete) {
    NSLog(@"Unity Ads received call to show before successfully loading an ad");
  }

  [UnityAds show:rootViewController placementId:_placementID showDelegate:self];
}

#pragma mark - UnityAdsLoadDelegate Methods

- (void)unityAdsAdLoaded:(nonnull NSString *)placementId {
  _loadComplete = YES;

  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector || !strongAdapter) {
    return;
  }

  [strongConnector adapterDidReceiveInterstitial:strongAdapter];
}

- (void)unityAdsAdFailedToLoad:(NSString *)placementId withError:(UnityAdsLoadError)error withMessage:(NSString *)message {
  _loadComplete = YES;

  dispatch_async(_lockQueue, ^{
    GADMAdapterUnityMapTableRemoveObjectForKey(_placementInUse, placementId);
  });

  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    NSString *errorMsg =
        [NSString stringWithFormat:@"No ad available for the placement ID: %@", placementId];
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
        GADMAdapterUnityErrorPlacementStateNoFill, errorMsg);
    [strongConnector adapter:strongAdapter didFailAd:error];
  }
}

#pragma mark - UnityAdsShowDelegate Methods

- (void)unityAdsShowStart:(nonnull NSString *)placementId {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  [strongConnector adapterWillPresentInterstitial:strongAdapter];
}

- (void)unityAdsShowClick:(NSString *)placementId {
  id<GADMAdNetworkConnector> strongNetworkConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongAdapter) {
    return;
  }

  // The Unity Ads SDK doesn't provide an event for leaving the application, so the adapter assumes
  // that a click event indicates the user is leaving the application for a browser or deeplink, and
  // notifies the Google Mobile Ads SDK accordingly.

  [strongNetworkConnector adapterDidGetAdClick:strongAdapter];
  [strongNetworkConnector adapterWillLeaveApplication:strongAdapter];
}

- (void)unityAdsShowComplete:(NSString *)placementId withFinishState:(UnityAdsShowCompletionState)state {
  id<GADMAdNetworkConnector> strongNetworkConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongAdapter) {
    return;
  }

  [strongNetworkConnector adapterWillDismissInterstitial:strongAdapter];
  [strongNetworkConnector adapterDidDismissInterstitial:strongAdapter];
}

- (void)unityAdsShowFailed:(NSString *)placementId withError:(UnityAdsShowError)error withMessage:(NSString *)message {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongAdapter) {
    return;
  }

  NSError *errorWithDescription =
      GADMAdapterUnitySDKErrorWithUnityAdsShowErrorAndMessage(error, message);
  [strongConnector adapter:strongAdapter didFailAd:errorWithDescription];

  [strongConnector adapterWillDismissInterstitial:strongAdapter];
  [strongConnector adapterDidDismissInterstitial:strongAdapter];
}

@end
