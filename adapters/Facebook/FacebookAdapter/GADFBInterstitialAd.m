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

#import "GADFBInterstitialAd.h"

#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GADFBAdapterDelegate.h"
#import "GADFBError.h"
#import "GADMAdapterFacebookConstants.h"

@interface GADFBInterstitialAd () {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Facebook Audience Network interstitial.
  FBInterstitialAd *_interstitialAd;

  /// Handles delegate notifications from interstitialAd.
  GADFBAdapterDelegate *_adapterDelegate;
}
@end

@implementation GADFBInterstitialAd

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector
                                       adapter:(id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
    _adapterDelegate = [[GADFBAdapterDelegate alloc] initWithAdapter:adapter connector:connector];
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

  // -[FBInterstitialAd initWithPlacementID:adSize:rootViewController:] throws an
  // NSInvalidArgumentException if the placement ID is nil.
  NSString *placementID = [strongConnector publisherId];
  if (!placementID) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _interstitialAd = [[FBInterstitialAd alloc] initWithPlacementID:placementID];
  if (!_interstitialAd) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to initialize.", NSStringFromClass([FBInterstitialAd class])];
    NSError *error = GADFBErrorWithDescription(description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _interstitialAd.delegate = _adapterDelegate;
  [FBAdSettings setMediationService:[NSString
      stringWithFormat:@"GOOGLE_%@:%@", [GADRequest sdkVersion], kGADMAdapterFacebookVersion]];
  [_interstitialAd loadAd];
}

- (void)stopBeingDelegate {
  _adapterDelegate = nil;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_interstitialAd showAdFromRootViewController:rootViewController];
}

@end
