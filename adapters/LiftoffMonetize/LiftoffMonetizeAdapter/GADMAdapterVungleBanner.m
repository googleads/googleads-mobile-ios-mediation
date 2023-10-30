// Copyright 2020 Google LLC
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

#import "GADMAdapterVungleBanner.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMAdapterVungleBanner () <GADMAdapterVungleDelegate, VungleBannerDelegate>
@end

@implementation GADMAdapterVungleBanner {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// The requested ad size.
  GADAdSize _bannerSize;

  /// Liftoff Monetize banner ad instance.
  VungleBanner *_bannerAd;

  /// UIView that contains a Liftoff Monetize banner ad.
  UIView *_bannerView;
}

@synthesize desiredPlacement;

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (void)dealloc {
  _adapter = nil;
  _connector = nil;
  _bannerAd = nil;
  _bannerView = nil;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  _bannerSize = GADMAdapterVungleAdSizeForAdSize(adSize);
  if (!IsGADAdSizeValid(_bannerSize)) {
    NSString *errorMessage =
        [NSString stringWithFormat:@"Unsupported ad size requested for Liftoff Monetize. Size: %@",
                                   NSStringFromGADAdSize(adSize)];
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorBannerSizeMismatch, errorMessage);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]];
  if ([VungleAds isInitialized]) {
    [self loadAd];
    return;
  }

  NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
  [GADMAdapterVungleRouter.sharedInstance initWithAppId:appID delegate:self];
}

- (void)loadAd {
  _bannerAd = [[VungleBanner alloc]
      initWithPlacementId:self.desiredPlacement
                     size:GADMAdapterVungleConvertGADAdSizeToBannerSize(_bannerSize)];
  _bannerAd.delegate = self;
  // Pass nil for the payload because this is not bidding
  [_bannerAd load:nil];
}

#pragma mark - VungleBannerDelegate

- (void)bannerAdDidLoad:(nonnull VungleBanner *)banner {
  _bannerView = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, _bannerSize.size.width, _bannerSize.size.height)];
  [_bannerAd presentOn:_bannerView];
}

- (void)bannerAdDidFailToLoad:(nonnull VungleBanner *)banner withError:(nonnull NSError *)error {
  [_connector adapter:_adapter didFailAd:error];
}

- (void)bannerAdWillPresent:(nonnull VungleBanner *)banner {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdDidPresent:(nonnull VungleBanner *)banner {
  [_connector adapter:_adapter didReceiveAdView:_bannerView];
}

- (void)bannerAdDidFailToPresent:(nonnull VungleBanner *)banner withError:(nonnull NSError *)error {
  [_connector adapter:_adapter didFailAd:error];
}

- (void)bannerAdWillClose:(nonnull VungleBanner *)banner {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewWillDismissScreen:.
}

- (void)bannerAdDidClose:(nonnull VungleBanner *)banner {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewDidDismissScreen:.
}

- (void)bannerAdDidTrackImpression:(nonnull VungleBanner *)banner {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdDidClick:(nonnull VungleBanner *)banner {
  [_connector adapterDidGetAdClick:_adapter];
}

- (void)bannerAdWillLeaveApplication:(nonnull VungleBanner *)banner {
  [_connector adapterWillLeaveApplication:_adapter];
}

#pragma mark - GADMAdapterVungleDelegate delegates

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    [_connector adapter:_adapter didFailAd:error];
    return;
  }
  [self loadAd];
}

@end
