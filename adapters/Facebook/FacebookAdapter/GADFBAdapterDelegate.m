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

#import <GoogleMobileAds/GoogleMobileAds.h>

@interface GADFBAdapterDelegate () {
  /// Connector from Google AdMob SDK which will receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;
  /// Adapter for receiving notification of ad request.
  __weak id<GADMAdNetworkAdapter> _adapter;
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

@end
