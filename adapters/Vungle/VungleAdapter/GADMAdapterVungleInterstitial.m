// Copyright 2019 Google LLC
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

#import "GADMAdapterVungleInterstitial.h"
#import <GoogleMobileAds/Mediation/GADMAdNetworkConnectorProtocol.h>
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMAdapterVungleInterstitial () <GADMAdapterVungleDelegate>
@end

@implementation GADMAdapterVungleInterstitial {
  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Indicates whether the banner ad finished presenting or not.
  BOOL _didBannerFinishPresenting;

  /// Indicates whether a banner or interstitial ad is loaded.
  BOOL _isAdLoaded;

  /// The CGSize of Banner Ad view
  CGSize _bannerSize;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [VungleAdNetworkExtras class];
}

+ (NSString *)adapterVersion {
  return kGADMAdapterVungleVersion;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
    self.adapterAdType = GADMAdapterVungleAdTypeUnknown;
  }
  return self;
}

- (void)dealloc {
  //[self stopBeingDelegate];
}

#pragma mark - GAD Ad Network Protocol Banner Methods (MREC)

- (void)getBannerWithSize:(GADAdSize)adSize {
  // An array of supported ad sizes.
  GADAdSize shortBannerSize = GADAdSizeFromCGSize(kVNGBannerShortSize);
  NSArray *potentials = @[NSValueFromGADAdSize(kGADAdSizeMediumRectangle), NSValueFromGADAdSize(kGADAdSizeBanner), NSValueFromGADAdSize(kGADAdSizeLeaderboard), NSValueFromGADAdSize(shortBannerSize)];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(adSize, potentials);
  CGSize size = CGSizeFromGADAdSize(closestSize);
  if (size.height == kGADAdSizeBanner.size.height) {
    if (size.width < kGADAdSizeBanner.size.width) {
      _bannerSize = kVNGBannerShortSize;
      self.adapterAdType = GADMAdapterVungleAdTypeShortBanner;
    } else {
      _bannerSize = kGADAdSizeBanner.size;
      self.adapterAdType = GADMAdapterVungleAdTypeBanner;
    }
  } else if (size.height == kGADAdSizeLeaderboard.size.height) {
    _bannerSize = kGADAdSizeLeaderboard.size;
    self.adapterAdType = GADMAdapterVungleAdTypeLeaderboardBanner;
  } else if (size.height == kGADAdSizeMediumRectangle.size.height) {
    _bannerSize = kGADAdSizeMediumRectangle.size;
    self.adapterAdType = GADMAdapterVungleAdTypeMREC;
  } else {
    _bannerSize = kGADAdSizeInvalid.size;
    self.adapterAdType = GADMAdapterVungleAdTypeUnknown;
  }

  // Check if given banner size is valid
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (CGSizeEqualToSize(_bannerSize, kGADAdSizeInvalid.size)) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationInvalidAdSize, @"Vungle only supports banner ad size in 300 x 250, 320 x 50, 300 x 50 and 728 x 90.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  VungleAdNetworkExtras *networkExtras = [strongConnector networkExtras];
  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]
                                                  networkExtras:networkExtras];
  self.uniquePubRequestID = [networkExtras.UUID copy];
  if (!self.desiredPlacement.length) {
    [strongConnector adapter:self
                   didFailAd:GADMAdapterVungleErrorWithCodeAndDescription(
                                 kGADErrorMediationDataError, @"Placement ID not specified.")];
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
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  [[GADMAdapterVungleRouter sharedInstance] initWithAppId:appID delegate:self];
}

#pragma mark - GAD Ad Network Protocol Interstitial Methods

- (void)getInterstitial {
  self.adapterAdType = GADMAdapterVungleAdTypeInterstitial;
  id<GADMAdNetworkConnector> strongConnector = _connector;
  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]
                                                  networkExtras:[strongConnector networkExtras]];
  if (!self.desiredPlacement.length) {
    [strongConnector adapter:self
                   didFailAd:GADMAdapterVungleErrorWithCodeAndDescription(
                                 kGADErrorMediationDataError, @"Placement ID not specified.")];
    return;
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([[GADMAdapterVungleRouter sharedInstance]
          hasDelegateForPlacementID:self.desiredPlacement
                        adapterType:GADMAdapterVungleAdTypeInterstitial]) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorInvalidRequest,
        @"Only a maximum of one ad per placement can be requested from Vungle.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  if ([sdk isInitialized]) {
    [self loadAd];
    return;
  }

  NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
  if (!appID) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(kGADErrorMediationDataError,
                                                                  @"Vungle app ID not specified.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  [[GADMAdapterVungleRouter sharedInstance] initWithAppId:appID delegate:self];
}

- (void)stopBeingDelegate {
  if ([self isBannerAd]) {
    if (_didBannerFinishPresenting) {
      return;
    }
    _didBannerFinishPresenting = YES;

    [[GADMAdapterVungleRouter sharedInstance]
        completeBannerAdViewForPlacementID:self];
  }
  _connector = nil;
  [[GADMAdapterVungleRouter sharedInstance] removeDelegate:self];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (![[GADMAdapterVungleRouter sharedInstance] playAd:rootViewController
                                               delegate:self
                                                 extras:[strongConnector networkExtras]]) {
    [strongConnector adapterWillPresentInterstitial:self];
    [strongConnector adapterDidDismissInterstitial:self];
    return;
  }
}

#pragma mark - Private methods

- (void)loadAd {
  NSError *error = [[GADMAdapterVungleRouter sharedInstance] loadAd:self.desiredPlacement
                                                       withDelegate:self];
  if (error) {
    [_connector adapter:self didFailAd:error];
  }
}

- (void)connectAdViewToViewController {
  UIView *bannerView =
      [[UIView alloc] initWithFrame:CGRectMake(0, 0, _bannerSize.width, _bannerSize.height)];
  bannerView =
      [[GADMAdapterVungleRouter sharedInstance] renderBannerAdInView:bannerView
                                                            delegate:self
                                                              extras:[_connector networkExtras]
                                                      forPlacementID:self.desiredPlacement];
  if (!bannerView) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(kGADErrorMediationAdapterError,
                                                                  @"Couldn't create ad view.");
    [_connector adapter:self didFailAd:error];
    return;
  }

  self.bannerState = BannerRouterDelegateStateWillPlay;
  [_connector adapter:self didReceiveAdView:bannerView];
}

- (BOOL)isBannerAd {
  if (self.adapterAdType == GADMAdapterVungleAdTypeMREC || self.adapterAdType == GADMAdapterVungleAdTypeBanner || self.adapterAdType == GADMAdapterVungleAdTypeShortBanner || self.adapterAdType == GADMAdapterVungleAdTypeLeaderboardBanner) {
    return YES;
  }
  return NO;
}

#pragma mark - VungleRouter delegates

@synthesize desiredPlacement;
@synthesize adapterAdType;
@synthesize bannerState;
@synthesize uniquePubRequestID;
@synthesize isRefreshedForBannerAd;
@synthesize isRequestingBannerAdForRefresh;

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    [_connector adapter:self didFailAd:error];
    return;
  }
  [self loadAd];
}

- (void)adAvailable {
  if (_isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  _isAdLoaded = YES;

  if (self.adapterAdType == GADMAdapterVungleAdTypeInterstitial) {
    [_connector adapterDidReceiveInterstitial:self];
  }

  if ([self isBannerAd]) {
    self.bannerState = BannerRouterDelegateStateCached;
    [self connectAdViewToViewController];
  }
}

- (void)adNotAvailable:(nonnull NSError *)error {
  if (_isAdLoaded) {
    // Already invoked an ad load callback.
    return;
  }
  [_connector adapter:self didFailAd:error];
}

- (void)willShowAd {
  if ([self isBannerAd]) {
    self.bannerState = BannerRouterDelegateStatePlaying;
  }

  if (self.adapterAdType == GADMAdapterVungleAdTypeInterstitial) {
    [_connector adapterWillPresentInterstitial:self];
  }
}

- (void)willCloseAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if ([self isBannerAd]) {
    self.bannerState = BannerRouterDelegateStateClosing;
  }

  if (self.adapterAdType == GADMAdapterVungleAdTypeInterstitial) {
    [strongConnector adapterWillDismissInterstitial:self];
  }
}

- (void)didCloseAd {
  if ([self isBannerAd]) {
    self.bannerState = BannerRouterDelegateStateClosed;
  }

  if (self.adapterAdType == GADMAdapterVungleAdTypeInterstitial) {
    [_connector adapterDidDismissInterstitial:self];
  }
}

- (void)trackClick {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterDidGetAdClick:self];
}

- (void)willLeaveApplication {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  [strongConnector adapterWillLeaveApplication:self];
}

@end
