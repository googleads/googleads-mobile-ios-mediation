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

@implementation GADFBAdapterDelegate {
  /// Connector from Google AdMob SDK which will receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;
  /// Adapter for receiving notification of ad request.
  __weak id<GADMAdNetworkAdapter> _adapter;
}

- (nonnull instancetype)initWithAdapter:(nonnull id<GADMAdNetworkAdapter>)adapter
                              connector:(nonnull id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
    _adapter = adapter;
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

@end
