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

#import "GADDuAdInterstitialAd.h"
#import "GADMAdapterDuAdConstants.h"

@import DUModuleSDK;
@import GoogleMobileAds;

#import "GADDuAdAdapterDelegate.h"
#import "GADDuAdError.h"

@interface GADDuAdInterstitialAd () {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// DuAd Audience Network interstitial.
  DUInterstitialAd *_interstitialAd;

  /// Handles delegate notifications from interstitialAd.
  GADDUAdapterDelegate *_adapterDelegate;
}
@end

@implementation GADDuAdInterstitialAd

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
                                       adapter:(id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
    _adapterDelegate = [[GADDUAdapterDelegate alloc] initWithAdapter:adapter connector:connector];
  }
  return self;
}

- (instancetype)init {
  return nil;
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;

  if (!strongConnector || !strongAdapter) {
    return;
  }

  // -[DUInterstitialAd initWithPlacementID:adSize:rootViewController:] throws an
  // NSInvalidArgumentException if the placement ID is nil.
  NSString *placementID = strongConnector.credentials[kGADMAdapterDuAdPlacementID];
  if (!placementID) {
    NSError *error = GADDUErrorWithDescription(@"Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _interstitialAd = [[DUInterstitialAd alloc] initWithPlacementID:placementID];
  if (!_interstitialAd) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to initialize.", NSStringFromClass([DUInterstitialAd class])];
    NSError *error = GADDUErrorWithDescription(description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _interstitialAd.delegate = _adapterDelegate;
  [_interstitialAd loadAd];
}

- (void)stopBeingDelegate {
  _adapterDelegate = nil;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_interstitialAd showAdFromRootViewController:rootViewController];
}

@end
