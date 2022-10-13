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
#import "GADMAdapterVungleBanner.h"
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"
#import "GADMediationAdapterVungle.h"
#import "VungleRouterConsentPrivate.h"

@interface GADMAdapterVungleInterstitial () <GADMAdapterVungleDelegate, VungleInterstitialDelegate>
@end

@implementation GADMAdapterVungleInterstitial {
  /// Connector from the Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Vungle banner ad wrapper.
  GADMAdapterVungleBanner *_bannerAd;
    
  /// Vungle interstitial ad instance.
  VungleInterstitial *_interstitialAd;
}

@synthesize desiredPlacement;

// Redirect to the main adapter class for bidding
// but still implement GADMAdNetworkAdapter for waterfall.
+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterVungle class];
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [VungleAdNetworkExtras class];
}

+ (NSString *)adapterVersion {
  return GADMAdapterVungleVersion;
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
  }
  return self;
}

#pragma mark - GAD Ad Network Protocol Banner Methods (MREC)

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (strongConnector.childDirectedTreatment) {
    [VungleRouterConsent updateCOPPAStatus:[strongConnector.childDirectedTreatment boolValue]];
  }
  _bannerAd = [[GADMAdapterVungleBanner alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                      adapter:self];
  [_bannerAd getBannerWithSize:adSize];
}

#pragma mark - GAD Ad Network Protocol Interstitial Methods

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (strongConnector.childDirectedTreatment) {
    [VungleRouterConsent updateCOPPAStatus:[strongConnector.childDirectedTreatment boolValue]];
  }
  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]
                                                  networkExtras:[strongConnector networkExtras]];
  if (!self.desiredPlacement.length) {
    [strongConnector adapter:self
                   didFailAd:GADMAdapterVungleErrorWithCodeAndDescription(
                                 GADMAdapterVungleErrorInvalidServerParameters,
                                 @"Placement ID not specified.")];
    return;
  }

  if ([VungleAds isInitialized]) {
    [self loadAd];
    return;
  }

  NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
  if (!appID) {
    NSError *error = GADMAdapterVungleErrorWithCodeAndDescription(
        GADMAdapterVungleErrorInvalidServerParameters, @"Vungle app ID not specified.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }
  [GADMAdapterVungleRouter.sharedInstance initWithAppId:appID delegate:self];
}

- (void)stopBeingDelegate {
  _bannerAd = nil;
  _connector = nil;
  _interstitialAd = nil;
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  [_interstitialAd presentWith:rootViewController];
}

#pragma mark - Private methods

- (void)loadAd {
  _interstitialAd = [[VungleInterstitial alloc] initWithPlacementId:self.desiredPlacement];
  _interstitialAd.delegate = self;
  [_interstitialAd load:nil];
}

#pragma mark - VungleInterstitialDelegate

- (void)interstitialAdDidLoad:(VungleInterstitial *)interstitial {
  [_connector adapterDidReceiveInterstitial:self];
}

- (void)interstitialAdDidFailToLoad:(VungleInterstitial *)interstitial withError:(NSError *)error {
  [_connector adapter:self didFailAd:error];
}

- (void)interstitialAdWillPresent:(VungleInterstitial *)interstitial {
  [_connector adapterWillPresentInterstitial:self];
}

- (void)interstitialAdDidPresent:(VungleInterstitial *)interstitial {
  // No-op.
}

- (void)interstitialAdDidFailToPresent:(VungleInterstitial *)interstitial withError:(NSError *)error {
  [_connector adapter:self didFailAd:error];
}

- (void)interstitialAdWillClose:(VungleInterstitial *)interstitial {
  [_connector adapterWillDismissInterstitial:self];
}

- (void)interstitialAdDidClose:(VungleInterstitial *)interstitial {
  [_connector adapterDidDismissInterstitial:self];
}

- (void)interstitialAdDidTrackImpression:(VungleInterstitial *)interstitial {
  // No-op.
}

- (void)interstitialAdDidClick:(VungleInterstitial *)interstitial {
  [_connector adapterDidGetAdClick:self];
}

- (void)interstitialAdWillLeaveApplication:(VungleInterstitial *)interstitial {
  [_connector adapterWillLeaveApplication:self];
}

#pragma mark - GADMAdapterVungleDelegate

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    [_connector adapter:self didFailAd:error];
    return;
  }
  [self loadAd];
}

@end
