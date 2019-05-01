//
// Copyright (C) 2016 Google, Inc.
//
// SampleAdapter.m
// Sample Ad Network Adapter
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
@import GoogleMobileAds;
@import SampleAdSDK;

#import "SampleAdapterDelegate.h"

#import "SampleAdapterMediatedNativeAd.h"

/// Constant for adapter error domain.
static NSString *const kAdapterErrorDomain = @"com.google.SampleAdapter";

@interface SampleAdapterDelegate () <SampleBannerAdDelegate, SampleInterstitialAdDelegate,
                                     SampleNativeAdLoaderDelegate, SampleRewardBasedVideoDelegate> {
  /// Connector from Google AdMob SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving notification of ad request.
  __weak id<GADMAdNetworkAdapter, SampleAdapterDataProvider> _adapter;

  /// Connector from Google Mobile Ads SDK to receive reward-based video ad configurations.
  __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardBasedVideoAdConnector;

  /// Adapter for receiving notification of reward-based video ad request.
  __weak id<GADMRewardBasedVideoAdNetworkAdapter> _rewardBasedVideoAdAdapter;
}
@end

@implementation SampleAdapterDelegate

- (instancetype)initWithAdapter:(id<GADMAdNetworkAdapter, SampleAdapterDataProvider>)adapter
                      connector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
    _adapter = adapter;
  }
  return self;
}

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

#pragma mark SampleBannerAdDelegate methods

- (void)bannerDidLoad:(SampleBanner *)banner {
  [_connector adapter:_adapter didReceiveAdView:banner];
}

- (void)banner:(SampleBanner *)banner didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain code:errorCode userInfo:nil];
  [_connector adapter:_adapter didFailAd:adapterError];
}

- (void)bannerWillLeaveApplication:(SampleBanner *)banner {
  [_connector adapterDidGetAdClick:_adapter];
  [_connector adapterWillLeaveApplication:_adapter];
}

#pragma mark SampleInterstitialAdDelegate methods

- (void)interstitialDidLoad:(SampleInterstitial *)interstitial {
  [_connector adapterDidReceiveInterstitial:_adapter];
}

- (void)interstitial:(SampleInterstitial *)interstitial
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain code:errorCode userInfo:nil];
  [_connector adapter:_adapter didFailAd:adapterError];
}

- (void)interstitialWillPresentScreen:(SampleInterstitial *)interstitial {
  [_connector adapterWillPresentInterstitial:_adapter];
}

- (void)interstitialWillDismissScreen:(SampleInterstitial *)interstitial {
  [_connector adapterWillDismissInterstitial:_adapter];
}

- (void)interstitialDidDismissScreen:(SampleInterstitial *)interstitial {
  [_connector adapterDidDismissInterstitial:_adapter];
}

- (void)interstitialWillLeaveApplication:(SampleInterstitial *)interstitial {
  [_connector adapterDidGetAdClick:_adapter];
  [_connector adapterWillLeaveApplication:_adapter];
}

#pragma mark SampleNativeAdLoaderDelegate implementation

- (void)adLoader:(SampleNativeAdLoader *)adLoader didReceiveNativeAd:(SampleNativeAd *)nativeAd {
  SampleAdapterMediatedNativeAd *mediatedAd = [[SampleAdapterMediatedNativeAd alloc]
                                               initWithSampleNativeAd:nativeAd
                                               nativeAdViewAdOptions:[_adapter nativeAdViewAdOptions]];
  [_connector adapter:_adapter didReceiveMediatedUnifiedNativeAd:mediatedAd];
}

- (void)adLoader:(SampleNativeAdLoader *)adLoader
    didFailToLoadAdWithErrorCode:(SampleErrorCode)errorCode {
  NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain code:errorCode userInfo:nil];
  [_connector adapter:_adapter didFailAd:adapterError];
}

#pragma mark SampleRewardBasedVideoDelegate methods

- (void)rewardBasedVideoAdInitialized:(SampleRewardBasedVideo *)rewardBasedVideo {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterDidSetUpRewardBasedVideoAd:strongAdapter];
}
- (void)rewardBasedVideoAdDidReceiveAd:(SampleRewardBasedVideo *)rewardBasedVideo {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterDidReceiveRewardBasedVideoAd:strongAdapter];
}

- (void)rewardBasedVideoAdDidOpen:(SampleRewardBasedVideo *)rewardBasedVideo {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterDidOpenRewardBasedVideoAd:strongAdapter];
}

- (void)rewardBasedVideoAdDidStartPlaying:(SampleRewardBasedVideo *)rewardBasedVideo {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterDidStartPlayingRewardBasedVideoAd:strongAdapter];
}

- (void)rewardBasedVideoAdDidClose:(SampleRewardBasedVideo *)rewardBasedVideo {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterDidCloseRewardBasedVideoAd:strongAdapter];
}

- (void)rewardBasedVideoAdWillLeaveApplication:(SampleRewardBasedVideo *)rewardBasedVideo {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterWillLeaveApplication:strongAdapter];
}

- (void)rewardBasedVideoAdDidReceiveAdClick:(SampleRewardBasedVideo *)rewardBasedVideo {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  [strongConnector adapterDidGetAdClick:strongAdapter];
}

- (void)rewardBasedVideoAd:(SampleRewardBasedVideo *)rewardBasedVideo
      rewardUserWithReward:(int)reward {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  // An empty string is passed to the reward type parameter because the Sample SDK doesn't use a
  // reward type and the reward type parameter cannot be nil.
  GADAdReward *rewardItem =
      [[GADAdReward alloc] initWithRewardType:@""
                                 rewardAmount:[NSDecimalNumber numberWithInteger:reward]];
  [strongConnector adapter:strongAdapter didRewardUserWithReward:rewardItem];
}

- (void)rewardBasedVideoAd:(SampleRewardBasedVideo *)rewardBasedVideo
    didFailToLoadWithError:(SampleErrorCode)error {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardBasedVideoAdConnector;
  id<GADMRewardBasedVideoAdNetworkAdapter> strongAdapter = _rewardBasedVideoAdAdapter;
  NSError *adapterError = [NSError errorWithDomain:kAdapterErrorDomain code:error userInfo:nil];
  [strongConnector adapter:strongAdapter didFailToLoadRewardBasedVideoAdwithError:adapterError];
}

@end
