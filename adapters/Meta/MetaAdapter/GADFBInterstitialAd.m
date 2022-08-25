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
#import "GADFBUtils.h"
#import "GADMAdapterFacebookConstants.h"
#import "GADMediationAdapterFacebook.h"

@interface GADFBInterstitialAd () <FBInterstitialAdDelegate>

@end

@implementation GADFBInterstitialAd {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// Meta Audience Network interstitial.
  FBInterstitialAd *_interstitialAd;

  /// Handles delegate notifications from interstitialAd.
  GADFBAdapterDelegate *_adapterDelegate;

  /// Indicates whether presentFromViewController: was called on this renderer.
  BOOL _presentCalled;
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
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

  if (!strongConnector || !strongAdapter) {
    return;
  }

  // -[FBInterstitialAd initWithPlacementID:adSize:rootViewController:] throws an
  // NSInvalidArgumentException if the placement ID is nil.
  NSString *placementID = [strongConnector publisherId];
  if (!placementID) {
    NSError *error =
        GADFBErrorWithCodeAndDescription(GADFBErrorInvalidRequest, @"Placement ID cannot be nil.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _interstitialAd = [[FBInterstitialAd alloc] initWithPlacementID:placementID];
  if (!_interstitialAd) {
    NSString *description = [NSString
        stringWithFormat:@"%@ failed to initialize.", NSStringFromClass([FBInterstitialAd class])];
    NSError *error = GADFBErrorWithCodeAndDescription(GADFBErrorAdObjectNil, description);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  _interstitialAd.delegate = self;
  GADFBConfigureMediationService();
  [_interstitialAd loadAd];
}

- (void)stopBeingDelegate {
  _adapterDelegate = nil;
}

#pragma mark FBInterstitialAdDelegate

- (void)interstitialAdWillLogImpression:(FBInterstitialAd *)interstitialAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    [strongConnector adapterWillPresentInterstitial:strongAdapter];
  }
}

- (void)interstitialAdDidClick:(FBInterstitialAd *)interstitialAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    [strongConnector adapterDidGetAdClick:strongAdapter];
    [strongConnector adapterWillLeaveApplication:strongAdapter];
  }
}

- (void)interstitialAdDidClose:(FBInterstitialAd *)interstitialAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    [strongConnector adapterDidDismissInterstitial:strongAdapter];
  }
}

- (void)interstitialAdWillClose:(FBInterstitialAd *)interstitialAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    [strongConnector adapterWillDismissInterstitial:strongAdapter];
  }
}

- (void)interstitialAdDidLoad:(FBInterstitialAd *)interstitialAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    [strongConnector adapterDidReceiveInterstitial:strongAdapter];
  }
}

- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }
  if (_presentCalled) {
    // Treat this error as a presentation error.
    [strongConnector adapterWillDismissFullScreenModal:strongAdapter];
    [strongConnector adapterDidDismissFullScreenModal:strongAdapter];
    return;
  }
  [strongConnector adapter:strongAdapter didFailAd:error];
}

#pragma mark GADMediationInterstitialAd

- (void)presentInterstitialFromRootViewController:(nonnull UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }
  _presentCalled = YES;

  if (![_interstitialAd showAdFromRootViewController:rootViewController]) {
    NSLog(@"%@ failed to present.", NSStringFromClass([FBInterstitialAd class]));
    [strongConnector adapterWillDismissFullScreenModal:strongAdapter];
    [strongConnector adapterDidDismissFullScreenModal:strongAdapter];
    return;
  }
  [strongConnector adapterWillPresentFullScreenModal:strongAdapter];
}
@end
