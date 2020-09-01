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
#import "GADMAdapterUnityConstants.h"
#import "GADUnityError.h"

@interface GADMUnityInterstitialAd ()
@end

@implementation GADMUnityInterstitialAd {
  NSString *_placementID;
  NSString *_gameID;
  BOOL _isLoading;
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;
  
  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;
}


- (instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                     adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  if (![UnityAds isInitialized]) {
      NSLog(@"Unity Ads Adapter Error: Unity Ads is not initialized.");
      return nil;
  }
  self = [super init];
  if (self) {
      _adapter = adapter;
      _connector = connector;
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
      NSError *error = GADUnityErrorWithDescription(kMISSING_ID_ERROR);
      [strongConnector adapter:strongAdapter didFailAd:error];
      return;
  }
  _isLoading = YES;
  [UnityAds addDelegate:self];
  [UnityAds load:_placementID loadDelegate:self];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  // We will send adapterWillPresentInterstitial callback before presenting unity ad because the ad has already loaded.
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
  
  [strongConnector adapterWillPresentInterstitial:strongAdapter];
  if ([UnityAds isReady:_placementID]) {
      [UnityAds show:rootViewController placementId:_placementID];
  }
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsPlacementStateChanged:(NSString *)placementId
                           oldState:(UnityAdsPlacementState)oldState
                           newState:(UnityAdsPlacementState)newState {
  // This callback is not forwarded to the adapter. The adapter
  // should use the unityAdsReady: and unityAdsDidError: callbacks to forward Unity Ads SDK state to
  // Google Mobile Ads SDK.
}

- (void)unityAdsDidFinish:(NSString *)placementID withFinishState:(UnityAdsFinishState)state {
  id<GADMAdNetworkConnector> strongNetworkConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongNetworkConnector && strongAdapter) {
      [strongNetworkConnector adapterWillDismissInterstitial:strongAdapter];
      [strongNetworkConnector adapterDidDismissInterstitial:strongAdapter];
  }
}

- (void)unityAdsDidClick:(NSString *)placementID {
  id<GADMAdNetworkConnector> strongNetworkConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  // The Unity Ads SDK doesn't provide an event for leaving the application, so the adapter assumes
  // that a click event indicates the user is leaving the application for a browser or deeplink, and
  // notifies the Google Mobile Ads SDK accordingly.
  if (strongNetworkConnector && strongAdapter) {
      [strongNetworkConnector adapterDidGetAdClick:strongAdapter];
      [strongNetworkConnector adapterWillLeaveApplication:strongAdapter];
  }
}

- (void)unityAdsDidError:(UnityAdsError)error withMessage:(NSString *)message {
  id<GADMAdNetworkConnector> strongNetworkConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!_isLoading) {
      // Unity Ads show error will only happen after the ad has been loaded. So, we will send
      // dismiss/close callbacks.
      if (error == kUnityAdsErrorShowError) {
          if (strongNetworkConnector && strongAdapter) {
              [strongNetworkConnector adapterWillDismissInterstitial:strongAdapter];
              [strongNetworkConnector adapterDidDismissInterstitial:strongAdapter];
          }
      }
      return;
  }
  
  NSError *errorWithDescription = GADUnityErrorWithDescription(message);
  if (strongNetworkConnector && strongAdapter) {
      [strongNetworkConnector adapter:strongAdapter didFailAd:errorWithDescription];
  }
  _isLoading = NO;
}

- (void)unityAdsDidStart:(nonnull NSString *)placementId {
  // nothing to do
}

- (void)unityAdsReady:(nonnull NSString *)placementId {
  // nothing to do
}


// UnityAdsLoadDelegate methods

- (void)unityAdsAdFailedToLoad:(nonnull NSString *)placementId {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
      NSError *error = GADUnityErrorWithDescription(@"unityAdsAdFailedToLoad");
      [strongConnector adapter:strongAdapter didFailAd:error];
  }
}

- (void)unityAdsAdLoaded:(nonnull NSString *)placementId {
  id<GADMAdNetworkConnector> strongNetworkConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!_isLoading) {
      return;
  }
  if (strongNetworkConnector && strongAdapter) {
      [strongNetworkConnector adapterDidReceiveInterstitial:strongAdapter];
  }
  _isLoading = NO;
}

@end
