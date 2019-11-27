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

  /// Indicates whether the interstitial ad is presenting or not.
  BOOL _isInterstitialAdPresenting;
}

+ (NSString *)adapterVersion {
  return kGADMAdapterVungleVersion;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [VungleAdNetworkExtras class];
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
  self.adapterAdType = GADMAdapterVungleAdTypeBanner;

  // An array of supported ad sizes.
  NSArray *potentials = @[ NSValueFromGADAdSize(kGADAdSizeMediumRectangle) ];
  GADAdSize closestSize = GADClosestValidSizeForAdSizes(adSize, potentials);
  // Check if given banner size is in MREC.
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!IsGADAdSizeValid(closestSize)) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationInvalidAdSize, @"Vungle only supports banner ad size in 300 x 250.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]
                                                  networkExtras:[strongConnector networkExtras]];

  if (!self.desiredPlacement) {
    [strongConnector adapter:self
                   didFailAd:GADMAdapterVungleErrorWithCodeAndDescription(
                                 kGADErrorMediationDataError, @"Placement ID not specified.")];
    return;
  }

  // Check if a banner (MREC) ad has been initiated with the samne PlacementID
  // or not. (Vungle supports only one banner currently.)
  if (![[GADMAdapterVungleRouter sharedInstance]
          canRequestBannerAdForPlacementID:self.desiredPlacement]) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError, @"A banner ad type has already been "
                                        @"instantiated. Multiple banner ads are not "
                                        @"supported with Vungle iOS SDK.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];

  if (![sdk isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
    if (appID) {
      GADMAdapterVungleInterstitial *__weak weakSelf = self;
      [[GADMAdapterVungleRouter sharedInstance] initWithAppId:appID delegate:weakSelf];
    } else {
      NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
          kGADErrorMediationDataError, @"Vungle app ID not specified.");
      [strongConnector adapter:self didFailAd:error];
    }
  } else {
    [self loadAd];
  }
}

#pragma mark - GAD Ad Network Protocol Interstitial Methods

- (void)getInterstitial {
  self.adapterAdType = GADMAdapterVungleAdTypeInterstitial;
  id<GADMAdNetworkConnector> strongConnector = _connector;
  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]
                                                  networkExtras:[strongConnector networkExtras]];
  if (!self.desiredPlacement) {
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

  if (![sdk isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
    if (appID) {
      GADMAdapterVungleInterstitial *__weak weakSelf = self;
      [[GADMAdapterVungleRouter sharedInstance] initWithAppId:appID delegate:weakSelf];
    } else {
      NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
          kGADErrorMediationDataError, @"Vungle app ID not specified.");
      [strongConnector adapter:self didFailAd:error];
    }
  } else {
    [self loadAd];
  }
}

- (void)stopBeingDelegate {
  if (self.adapterAdType == GADMAdapterVungleAdTypeBanner) {
    if (_didBannerFinishPresenting) {
      return;
    }
    _didBannerFinishPresenting = YES;

    [[GADMAdapterVungleRouter sharedInstance]
        completeBannerAdViewForPlacementID:self.desiredPlacement];
    _connector = nil;
    [[GADMAdapterVungleRouter sharedInstance] removeDelegate:self];
  } else if (self.adapterAdType == GADMAdapterVungleAdTypeInterstitial) {
    _connector = nil;
    [[GADMAdapterVungleRouter sharedInstance] removeDelegate:self];
  }
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
  _isInterstitialAdPresenting = YES;
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
  UIView *mrecAdView =
      [[UIView alloc] initWithFrame:CGRectMake(0, 0, kGADAdSizeMediumRectangle.size.width,
                                               kGADAdSizeMediumRectangle.size.height)];
  mrecAdView =
      [[GADMAdapterVungleRouter sharedInstance] renderBannerAdInView:mrecAdView
                                                            delegate:self
                                                              extras:[_connector networkExtras]
                                                      forPlacementID:self.desiredPlacement];
  if (mrecAdView) {
    self.bannerState = BannerRouterDelegateStatePlaying;
    [_connector adapter:self didReceiveAdView:mrecAdView];
  } else {
    [_connector adapter:self
              didFailAd:GADMAdapterVungleErrorWithCodeAndDescription(kGADErrorMediationAdapterError,
                                                                     @"Error in creating adView")];
  }
}

#pragma mark - VungleRouter delegates

@synthesize desiredPlacement;
@synthesize adapterAdType;
@synthesize bannerState;

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (isSuccess && self.desiredPlacement) {
    [self loadAd];
  } else {
    [_connector adapter:self didFailAd:error];
  }
}

- (void)adAvailable {
  if (self.adapterAdType == GADMAdapterVungleAdTypeBanner) {
    self.bannerState = BannerRouterDelegateStateCached;
    [self connectAdViewToViewController];
  } else if (self.adapterAdType == GADMAdapterVungleAdTypeInterstitial) {
    if (!_isInterstitialAdPresenting) {
      [_connector adapterDidReceiveInterstitial:self];
    }
  }
}

- (void)adNotAvailable:(nonnull NSError *)error {
  [_connector adapter:self didFailAd:error];
}

- (void)willShowAd {
  if (self.adapterAdType == GADMAdapterVungleAdTypeBanner) {
    self.bannerState = BannerRouterDelegateStatePlaying;
  } else if (self.adapterAdType == GADMAdapterVungleAdTypeInterstitial) {
    [_connector adapterWillPresentInterstitial:self];
  }
}

- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (didDownload) {
    [strongConnector adapterDidGetAdClick:self];
  }
  if (self.adapterAdType == GADMAdapterVungleAdTypeBanner) {
    self.bannerState = BannerRouterDelegateStateClosing;
  } else if (self.adapterAdType == GADMAdapterVungleAdTypeInterstitial) {
    [strongConnector adapterWillDismissInterstitial:self];
    _isInterstitialAdPresenting = NO;
  }
}

- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  if (self.adapterAdType == GADMAdapterVungleAdTypeBanner) {
    self.bannerState = BannerRouterDelegateStateClosed;
  } else if (self.adapterAdType == GADMAdapterVungleAdTypeInterstitial) {
    [_connector adapterDidDismissInterstitial:self];
  }
}

@end
