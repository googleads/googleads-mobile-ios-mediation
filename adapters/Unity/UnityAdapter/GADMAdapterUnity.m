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

#import "GADMAdapterUnityBannerAd.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMAdapterUnityUtils.h"
#import "GADMUnityInterstitialAd.h"
#import "GADMAdapterUnityConstants.h"
#import "GADMediationAdapterUnity.h"

@interface GADMAdapterUnity () {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _networkConnector;

  /// Game ID of Unity Ads network.
  NSString *_gameID;

  /// Placement ID of Unity Ads network.
  NSString *_placementID;

  /// Unity Ads Banner wrapper
  GADMAdapterUnityBannerAd *_bannerAd;
    
    /// Unity Ads Interstitial Ad wrapper
  GADMUnityInterstitialAd *_interstitialAd;

  /// UUID for Unity instrument analysis
  NSString *_uuid;

  /// MetaData for storing Unity instrument analysis
  UADSMetaData *_metaData;
}

@end

@implementation GADMAdapterUnity

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterUnity class];
}

+ (NSString *)adapterVersion {
  return kGADMAdapterUnityVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return Nil;
}

- (void)stopBeingDelegate {
  if (_bannerAd != nil) {
    [_bannerAd stopBeingDelegate];
  }
}

#pragma mark Interstitial Methods

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }
  self = [super init];
  if (self) {
    _networkConnector = connector;

    _uuid = [[NSUUID UUID] UUIDString];

    _metaData = [[UADSMetaData alloc] init];

    [_metaData setCategory:@"mediation_adapter"];
    [_metaData set:_uuid value:@"create-adapter"];
    [_metaData commit];
  }
  return self;
}


- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _networkConnector;
  _interstitialAd = [[GADMUnityInterstitialAd alloc] initWithGADMAdNetworkConnector:strongConnector adapter:self];
  [_interstitialAd getInterstitial];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
    id<GADMAdNetworkConnector> strongConnector = _networkConnector;
    [strongConnector adapterWillPresentInterstitial:self];
    [_interstitialAd presentInterstitialFromRootViewController:rootViewController];
}

#pragma mark Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _networkConnector;
  _gameID = [strongConnector.credentials[kGADMAdapterUnityGameID] copy];
  _placementID = [strongConnector.credentials[kGADMAdapterUnityPlacementID] copy];
  if (!_gameID || !_placementID) {
    NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
        GADMAdapterUnityErrorInvalidServerParameters, @"Game ID and Placement ID cannot be nil.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _bannerAd = [[GADMAdapterUnityBannerAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                       adapter:self];
  [_bannerAd loadBannerWithSize:adSize];
}

#pragma mark GADMAdapterUnityDataProvider Methods

- (NSString *)getGameID {
  return _gameID;
}

- (NSString *)getPlacementID {
  return _placementID;
}

- (void)didFailToLoadWithError:(nonnull NSError *)error {
  id<GADMAdNetworkConnector> strongConnector = _networkConnector;
  if (strongConnector != nil) {
    [strongConnector adapter:self didFailAd:error];
  }
}

#pragma mark - Unity Delegate Methods

- (void)unityAdsPlacementStateChanged:(NSString *)placementID
                             oldState:(UnityAdsPlacementState)oldState
                             newState:(UnityAdsPlacementState)newState {
  if (![placementID isEqualToString:_placementID]) {
    return;
  }

  id<GADMAdNetworkConnector> strongNetworkConnector = _networkConnector;
  if (newState == kUnityAdsPlacementStateNoFill) {
    if (strongNetworkConnector) {
      NSString *errorMsg =
          [NSString stringWithFormat:@"No ad available for the placement ID: %@", placementID];
      NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
          GADMAdapterUnityErrorPlacementStateNoFill, errorMsg);
      [strongNetworkConnector adapter:self didFailAd:error];
    }
  }
  if (newState == kUnityAdsPlacementStateDisabled) {
    if (strongNetworkConnector) {
      NSString *errorMsg =
          [NSString stringWithFormat:@"This placement ID is currently disabled: %@", placementID];
      NSError *error = GADMAdapterUnityErrorWithCodeAndDescription(
          GADMAdapterUnityErrorPlacementStateDisabled, errorMsg);
      [strongNetworkConnector adapter:self didFailAd:error];
    }
  }
}

- (void)unityAdsDidFinish:(NSString *)placementID withFinishState:(UnityAdsFinishState)state {
  if ([placementID isEqualToString:_placementID]) {
    id<GADMAdNetworkConnector> strongNetworkConnector = _networkConnector;
    if (strongNetworkConnector) {
      [strongNetworkConnector adapterDidDismissInterstitial:self];
    }
  }
}

- (void)unityAdsReady:(NSString *)placementID {
  id<GADMAdNetworkConnector> strongNetworkConnector = _networkConnector;
  if (strongNetworkConnector && [placementID isEqualToString:_placementID]) {
    [strongNetworkConnector adapterDidReceiveInterstitial:self];
  }
}

- (void)unityAdsDidClick:(NSString *)placementID {
  id<GADMAdNetworkConnector> strongNetworkConnector = _networkConnector;
  // The Unity Ads SDK doesn't provide an event for leaving the application, so the adapter assumes
  // that a click event indicates the user is leaving the application for a browser or deeplink, and
  // notifies the Google Mobile Ads SDK accordingly.
  if (strongNetworkConnector && [placementID isEqualToString:_placementID]) {
    [strongNetworkConnector adapterDidGetAdClick:self];
    [strongNetworkConnector adapterWillLeaveApplication:self];
  }
}

- (void)unityAdsDidError:(UnityAdsError)error withMessage:(NSString *)message {
  id<GADMAdNetworkConnector> strongNetworkConnector = _networkConnector;
  if (strongNetworkConnector) {
    [strongNetworkConnector adapterWillDismissInterstitial:self];
    [strongNetworkConnector adapterDidDismissInterstitial:self];
  }
}

- (void)unityAdsDidStart:(nonnull NSString *)placementID {
  // nothing to do
}

@end
