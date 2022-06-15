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

@interface GADMAdapterVungleBanner () <GADMAdapterVungleDelegate>
@end

@implementation GADMAdapterVungleBanner {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// The requested ad size.
  GADAdSize _bannerSize;

  /// Indicates whether the banner ad finished presenting.
  BOOL _didBannerFinishPresenting;
}

@synthesize desiredPlacement;
@synthesize bannerState;
@synthesize uniquePubRequestID;
@synthesize isRefreshedForBannerAd;
@synthesize isRequestingBannerAdForRefresh;
@synthesize isAdLoaded;

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  _bannerSize = [self vungleAdSizeForAdSize:adSize];
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
  self.uniquePubRequestID = [networkExtras.UUID copy];
  if (!self.desiredPlacement.length) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorInvalidServerParameters, @"Placement ID not specified.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  VungleSDK *sdk = VungleSDK.sharedSDK;
  if ([sdk isInitialized]) {
    [self loadAd];
    return;
  }

  NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
  if (!appID) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorInvalidServerParameters, @"Vungle app ID not specified.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }
  [GADMAdapterVungleRouter.sharedInstance initWithAppId:appID delegate:self];
}

- (GADAdSize)vungleAdSizeForAdSize:(GADAdSize)adSize {
  // An array of supported ad sizes.
  GADAdSize shortBannerSize = GADAdSizeFromCGSize(kVNGBannerShortSize);
  NSArray<NSValue *> *potentials = @[
    NSValueFromGADAdSize(GADAdSizeMediumRectangle), NSValueFromGADAdSize(GADAdSizeBanner),
    NSValueFromGADAdSize(GADAdSizeLeaderboard), NSValueFromGADAdSize(shortBannerSize)
  ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(adSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
  if (size.height == GADAdSizeBanner.size.height) {
    if (size.width < GADAdSizeBanner.size.width) {
      return shortBannerSize;
    } else {
      return GADAdSizeBanner;
    }
  } else if (size.height == GADAdSizeLeaderboard.size.height) {
    return GADAdSizeLeaderboard;
  } else if (size.height == GADAdSizeMediumRectangle.size.height) {
    return GADAdSizeMediumRectangle;
  }

  return GADAdSizeInvalid;
}

- (void)loadAd {
  NSError *error = [GADMAdapterVungleRouter.sharedInstance loadAd:self.desiredPlacement
                                                     withDelegate:self];
  if (error) {
    [_connector adapter:_adapter didFailAd:error];
  }
}

- (void)cleanUp {
  if (_didBannerFinishPresenting) {
    return;
  }
  _didBannerFinishPresenting = YES;

  [GADMAdapterVungleRouter.sharedInstance completeBannerAdViewForPlacementID:self];
  [GADMAdapterVungleRouter.sharedInstance removeDelegate:self];
}

#pragma mark - GADMAdapterVungleDelegate delegates

- (GADAdSize)bannerAdSize {
  return _bannerSize;
}

- (nullable NSString *)bidResponse {
  // This is the waterfall banner section. It won't have a bid response.
  return nil;
}

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    [_connector adapter:_adapter didFailAd:error];
    return;
  }
  [self loadAd];
}

- (void)adAvailable {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  if (self.isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  self.isAdLoaded = YES;
  UIView *bannerView = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, _bannerSize.size.width, _bannerSize.size.height)];
  NSError *bannerViewError =
      [GADMAdapterVungleRouter.sharedInstance renderBannerAdInView:bannerView
                                                          delegate:self
                                                            extras:[strongConnector networkExtras]
                                                    forPlacementID:self.desiredPlacement];
  if (bannerViewError) {
    [strongConnector adapter:strongAdapter didFailAd:bannerViewError];
    return;
  }

  self.bannerState = BannerRouterDelegateStateWillPlay;
  [strongConnector adapter:strongAdapter didReceiveAdView:bannerView];
}

- (void)adNotAvailable:(nonnull NSError *)error {
  if (self.isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  [_connector adapter:_adapter didFailAd:error];
}

- (void)willShowAd {
  self.bannerState = BannerRouterDelegateStatePlaying;
}

- (void)didViewAd {
  // Do nothing.
}

- (void)willCloseAd {
  self.bannerState = BannerRouterDelegateStateClosing;
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewWillDismissScreen:.
}

- (void)didCloseAd {
  self.bannerState = BannerRouterDelegateStateClosed;
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewDidDismissScreen:.
}

- (void)trackClick {
  [_connector adapterDidGetAdClick:_adapter];
}

- (void)willLeaveApplication {
  [_connector adapterWillLeaveApplication:_adapter];
}

- (void)rewardUser {
  // Do nothing.
}

@end
