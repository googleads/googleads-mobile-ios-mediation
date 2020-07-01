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

#import "GADMAdapterVungleBannerRequest.h"
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

  /// Indicates whether a banner ad is loaded.
  BOOL _isAdLoaded;

  /// Indicates whether the banner ad finished presenting.
  BOOL _didBannerFinishPresenting;
}

@synthesize desiredPlacement;
@synthesize bannerState;
@synthesize bannerRequest;
@synthesize isRefreshedForBannerAd;
@synthesize isRequestingBannerAdForRefresh;

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
    NSError *error =
        GADMAdapterVungleErrorWithCodeAndDescription(kGADErrorMediationInvalidAdSize, errorMessage);
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  VungleAdNetworkExtras *networkExtras = [strongConnector networkExtras];
  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]
                                                  networkExtras:networkExtras];
  self.bannerRequest =
      [[GADMAdapterVungleBannerRequest alloc] initWithPlacementID:self.desiredPlacement ?: @""
                                               uniquePubRequestID:networkExtras.UUID];
  if (!self.desiredPlacement) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(kGADErrorMediationDataError,
                                                                  @"Placement ID not specified.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  // Check if a banner or MREC ad has been initiated with the same PlacementID or not.
  // Vungle supports 4 types of banner currently.
  if (![[GADMAdapterVungleRouter sharedInstance]
          canRequestBannerAdForPlacementID:self.bannerRequest]) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError, @"A banner ad type has already been "
                                        @"instantiated. Multiple banner ads are not "
                                        @"supported with Vungle iOS SDK.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([sdk isInitialized]) {
    [self loadAd];
    return;
  }

  NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
  if (!appID) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(kGADErrorMediationDataError,
                                                                  @"Vungle app ID not specified.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }
  [[GADMAdapterVungleRouter sharedInstance] initWithAppId:appID delegate:self];
}

- (GADAdSize)vungleAdSizeForAdSize:(GADAdSize)adSize {
  // An array of supported ad sizes.
  GADAdSize shortBannerSize = GADAdSizeFromCGSize(kVNGBannerShortSize);
  NSArray<NSValue *> *potentials = @[
    NSValueFromGADAdSize(kGADAdSizeMediumRectangle), NSValueFromGADAdSize(kGADAdSizeBanner),
    NSValueFromGADAdSize(kGADAdSizeLeaderboard), NSValueFromGADAdSize(shortBannerSize)
  ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(adSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
  if (size.height == kGADAdSizeBanner.size.height) {
    if (size.width < kGADAdSizeBanner.size.width) {
      return shortBannerSize;
    } else {
      return kGADAdSizeBanner;
    }
  } else if (size.height == kGADAdSizeLeaderboard.size.height) {
    return kGADAdSizeLeaderboard;
  } else if (size.height == kGADAdSizeMediumRectangle.size.height) {
    return kGADAdSizeMediumRectangle;
  }

  return kGADAdSizeInvalid;
}

- (void)loadAd {
  NSError *error = [[GADMAdapterVungleRouter sharedInstance] loadAd:self.desiredPlacement
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

  [[GADMAdapterVungleRouter sharedInstance] completeBannerAdViewForPlacementID:self];
  [[GADMAdapterVungleRouter sharedInstance] removeDelegate:self];
}

#pragma mark - GADMAdapterVungleDelegate delegates

- (GADAdSize)bannerAdSize {
  return _bannerSize;
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

  if (_isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  _isAdLoaded = YES;

  UIView *bannerView = [[UIView alloc]
      initWithFrame:CGRectMake(0, 0, _bannerSize.size.width, _bannerSize.size.height)];
  bannerView =
      [[GADMAdapterVungleRouter sharedInstance] renderBannerAdInView:bannerView
                                                            delegate:self
                                                              extras:[strongConnector networkExtras]
                                                      forPlacementID:self.desiredPlacement];
  if (!bannerView) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(kGADErrorMediationAdapterError,
                                                                  @"Couldn't create ad view.");
    [strongConnector adapter:strongAdapter didFailAd:error];
    return;
  }

  self.bannerState = BannerRouterDelegateStateWillPlay;
  [strongConnector adapter:strongAdapter didReceiveAdView:bannerView];
}

- (void)adNotAvailable:(nonnull NSError *)error {
  if (_isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  [_connector adapter:_adapter didFailAd:error];
}

- (void)willShowAd {
  self.bannerState = BannerRouterDelegateStatePlaying;
}

- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  if (didDownload) {
    [_connector adapterDidGetAdClick:_adapter];
  }
  self.bannerState = BannerRouterDelegateStateClosing;
}

- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  self.bannerState = BannerRouterDelegateStateClosed;
}

@end
