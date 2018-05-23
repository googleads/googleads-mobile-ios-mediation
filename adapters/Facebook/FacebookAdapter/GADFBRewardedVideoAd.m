// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,software
// distributed under  the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADFBRewardedVideoAd.h"

@import FBAudienceNetwork;
@import GoogleMobileAds;

#import "GADFBAdapterDelegate.h"
#import "GADMAdapterFacebook.h"
#import "GADFBError.h"

@interface GADFBRewardedVideoAd () {
  /// Connector from Google Mobile Ads SDK which will receive ad configurations.
  __weak id<GADMRewardBasedVideoAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMRewardBasedVideoAdNetworkAdapter> _adapter;

  /// Facebook Audience Network rewardedVideoAd.
  FBRewardedVideoAd *_rewardedVideoAd;

  /// Handles delegate notifications from rewardedVideoAd.
  GADFBAdapterDelegate *_adapterDelegate;
}
@end

@implementation GADFBRewardedVideoAd

/// Initializes a new instance with |connector| and |adapter|.
- (instancetype)initWithGADMAdNetworkConnector:(id<GADMRewardBasedVideoAdNetworkConnector>)connector
                                       adapter:(id<GADMRewardBasedVideoAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
    _adapterDelegate = [[GADFBAdapterDelegate alloc] initWithRewardBasedVideoAdAdapter:_adapter
                                                           rewardBasedVideoAdconnector:_connector];
  }
  return self;
}

- (instancetype)init {
  return nil;
}

/// Sets up the adapter.
- (void)setUp {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }
  NSString *publisherId = [strongConnector publisherId];
  if (!publisherId) {
    NSError *error = GADFBErrorWithDescription(@"Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailToSetUpRewardBasedVideoAdWithError:error];
    return;
  }
  [strongConnector adapterDidSetUpRewardBasedVideoAd:strongAdapter];
}

/// Starts fetching a rewarded video ad from Facebook's Audience Network.
- (void)getRewardedVideoAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  NSString *publisherId = [strongConnector publisherId];
  _rewardedVideoAd = [[FBRewardedVideoAd alloc] initWithPlacementID:publisherId];
  if (!_rewardedVideoAd) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to initialize.", NSStringFromClass([FBRewardedVideoAd class])];
    NSError *error = GADFBErrorWithDescription(description);
    [strongConnector adapter:strongAdapter didFailToLoadRewardBasedVideoAdwithError:error];
    return;
  }
  _rewardedVideoAd.delegate = _adapterDelegate;
  [FBAdSettings setMediationService:[NSString stringWithFormat:@"ADMOB_%@", [GADRequest sdkVersion]]];
  [_rewardedVideoAd loadAd];
}

/// Stops the receiver from delegating any notifications from Facebook's Audience Network.
- (void)stopBeingDelegate {
  _adapterDelegate = nil;
}

/// Presents a full screen rewarded video ad from |rootViewController|.
- (void)presentRewardedVideoAdFromRootViewController:(UIViewController *)rootViewController {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _connector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }
  if ([_rewardedVideoAd isAdValid]) {
    [_rewardedVideoAd showAdFromRootViewController:rootViewController];

    /// Calling delegate methods of GADMRewardBasedVideoAdNetworkConnector on connector as FAN
    /// doesn't have open and playing methods.
    [strongConnector adapterDidOpenRewardBasedVideoAd:strongAdapter];
    [strongConnector adapterDidStartPlayingRewardBasedVideoAd:strongAdapter];
  } else {
    /// Calling delegate methods of GADMRewardBasedVideoAdNetworkConnector on connector when the Ad
    /// is not valid.
    [strongConnector adapterDidOpenRewardBasedVideoAd:strongAdapter];
    [strongConnector adapterDidCloseRewardBasedVideoAd:strongAdapter];
  }
}
@end
