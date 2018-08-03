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

#import "GADFBAdapterDelegate.h"

@import GoogleMobileAds;

@interface GADFBAdapterDelegate () {
  /// Connector from Google AdMob SDK which will receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;
  /// Adapter for receiving notification of ad request.
  __weak id<GADMAdNetworkAdapter> _adapter;
  /// Connector from Google Mobile Ads SDK which will receive reward-based video ad configurations.
  __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardBasedVideoAdConnector;
  /// Adapter for receiving notification of reward-based video ad request.
  __weak id<GADMRewardBasedVideoAdNetworkAdapter> _rewardBasedVideoAdAdapter;
}
@end

@implementation GADFBAdapterDelegate

- (instancetype)initWithAdapter:(id<GADMAdNetworkAdapter>)adapter
                      connector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
    _adapter = adapter;
  }
  return self;
}

- (instancetype)init {
  return nil;
}
/// Initializes a new instance for reward-based video ads with |adapter| and |connector|.
- (instancetype)initWithRewardBasedVideoAdAdapter:(id<GADMRewardBasedVideoAdNetworkAdapter>)adapter
                      rewardBasedVideoAdconnector:
                          (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _rewardBasedVideoAdConnector = connector;
    _rewardBasedVideoAdAdapter = adapter;
  }
  return self;
}

#pragma mark - FBAdViewDelegate

- (void)adViewDidClick:(FBAdView *)adView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    if ([strongConnector respondsToSelector:@selector(adapterDidGetAdClick:)]) {
      [strongConnector adapterDidGetAdClick:strongAdapter];
    } else {
      [strongConnector adapterDidGetAdClick:strongAdapter];
    }

    [strongConnector adapterWillPresentFullScreenModal:strongAdapter];
  }
}

- (void)adViewDidLoad:(FBAdView *)adView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!CGSizeEqualToSize(_finalBannerSize, CGSizeZero)) {
    CGRect frame = adView.frame;
    frame.size = _finalBannerSize;
    adView.frame = frame;
    _finalBannerSize = CGSizeZero;
  }
  if (strongConnector && strongAdapter) {
    [strongConnector adapter:strongAdapter didReceiveAdView:adView];
  }
}

- (void)adView:(FBAdView *)adView didFailWithError:(NSError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    [strongConnector adapter:strongAdapter didFailAd:error];
  }
}

- (void)adViewDidFinishHandlingClick:(FBAdView *)adView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongAdapter && strongConnector) {
    [strongConnector adapterDidDismissFullScreenModal:strongAdapter];
  }
}

- (UIViewController *)viewControllerForPresentingModalView {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  return [strongConnector viewControllerForPresentingModalView];
}

#pragma mark - FBInterstitialAdDelegate

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
    if ([strongConnector respondsToSelector:@selector(adapterDidGetAdClick:)]) {
      [strongConnector adapterDidGetAdClick:strongAdapter];
    }

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
    if ([strongConnector respondsToSelector:@selector(adapterDidReceiveInterstitial:)]) {
      [strongConnector adapterDidReceiveInterstitial:strongAdapter];
    } else {
      [strongConnector adapterDidReceiveInterstitial:strongAdapter];
    }
  }
}

- (void)interstitialAd:(FBInterstitialAd *)interstitialAd didFailWithError:(NSError *)error {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (strongConnector && strongAdapter) {
    [strongConnector adapter:strongAdapter didFailAd:error];
  }
}

#pragma mark - FBRewardedVideoAdDelegate

- (void)rewardedVideoAdDidClick:(FBRewardedVideoAd *)rewardedVideoAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterDidGetAdClick:strongAdapter];
}

- (void)rewardedVideoAdDidLoad:(FBRewardedVideoAd *)rewardedVideoAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterDidReceiveRewardBasedVideoAd:strongAdapter];
}

- (void)rewardedVideoAdDidClose:(FBRewardedVideoAd *)rewardedVideoAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterDidCloseRewardBasedVideoAd:strongAdapter];
}

- (void)rewardedVideoAdWillClose:(FBRewardedVideoAd *)rewardedVideoAd {
  // Google Mobile Ads SDK doesn't have a matching event, do nothing.
}

- (void)rewardedVideoAd:(FBRewardedVideoAd *)rewardedVideoAd didFailWithError:(NSError *)error {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapter:strongAdapter didFailToLoadRewardBasedVideoAdwithError:error];
}

- (void)rewardedVideoAdVideoComplete:(FBRewardedVideoAd *)rewardedVideoAd {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterDidCompletePlayingRewardBasedVideoAd:strongAdapter];
  [strongConnector adapter:strongAdapter
      didRewardUserWithReward:[[GADAdReward alloc] initWithRewardType:@""
                                                         rewardAmount:[NSDecimalNumber one]]];
}

- (void)rewardedVideoAdWillLogImpression:(FBRewardedVideoAd *)rewardedVideoAd {
  // Google Mobile Ads SDK does its own impression tracking for reward-based video ads.
}
@end
