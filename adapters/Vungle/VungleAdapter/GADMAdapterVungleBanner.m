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

  /// Vungle banner ad instance.
  VungleBanner *_bannerAd;

  /// UIView that contains a Vungle banner ad.
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
        [NSString stringWithFormat:@"Unsupported ad size requested for Vungle. Size: %@",
                                   NSStringFromGADAdSize(adSize)];
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorBannerSizeMismatch, errorMessage);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  VungleAdNetworkExtras *networkExtras = [strongConnector networkExtras];
  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]
                                                  networkExtras:networkExtras];
  if (!self.desiredPlacement.length) {
    NSError *error = GADMAdapterVungleInvalidPlacementErrorWithCodeAndDescription();
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  if ([VungleAds isInitialized]) {
    [self loadAd];
    return;
  }

  NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
  if (!appID) {
    NSError *error = GADMAdapterVungleInvalidAppIdErrorWithCodeAndDescription();
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }
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

- (void)bannerAdDidLoad:(VungleBanner *)banner {
  _bannerView = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, _bannerSize.size.width, _bannerSize.size.height)];
  [_bannerAd presentOn:_bannerView];
}

- (void)bannerAdDidFailToLoad:(VungleBanner *)banner withError:(NSError *)error {
  NSError *gadError = GADMAdapterVungleErrorToGADError(GADMAdapterVungleErrorAdNotPlayable,
                                                       error.code, error.localizedDescription);
  [_connector adapter:_adapter didFailAd:gadError];
}

- (void)bannerAdWillPresent:(VungleBanner *)banner {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdDidPresent:(VungleBanner *)banner {
  [_connector adapter:_adapter didReceiveAdView:_bannerView];
}

- (void)bannerAdDidFailToPresent:(VungleBanner *)banner withError:(NSError *)error {
  NSError *gadError = GADMAdapterVungleErrorToGADError(GADMAdapterVungleErrorRenderBannerAd,
                                                       error.code, error.localizedDescription);
  [_connector adapter:_adapter didFailAd:gadError];
}

- (void)bannerAdWillClose:(VungleBanner *)banner {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewWillDismissScreen:.
}

- (void)bannerAdDidClose:(VungleBanner *)banner {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewDidDismissScreen:.
}

- (void)bannerAdDidTrackImpression:(VungleBanner *)banner {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdDidClick:(VungleBanner *)banner {
  [_connector adapterDidGetAdClick:_adapter];
}

- (void)bannerAdWillLeaveApplication:(VungleBanner *)banner {
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
