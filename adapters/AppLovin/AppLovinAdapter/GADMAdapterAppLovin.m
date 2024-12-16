// Copyright 2018 Google LLC
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

#import "GADMAdapterAppLovin.h"

#import "GADMAdapterAppLovinBannerDelegate.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinInitializer.h"
#import "GADMAdapterAppLovinInterstitialDelegate.h"
#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMediationAdapterAppLovin.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation GADMAdapterAppLovin {
  /// AppLovin interstitial object used to request an ad.
  ALInterstitialAd *_interstitial;

  /// AppLovin interstitial delegate wrapper.
  GADMAdapterAppLovinInterstitialDelegate *_interstitialDelegate;

  /// AppLovin banner delegate wrapper.
  GADMAdapterAppLovinBannerDelegate *_bannerDelegate;
}

#pragma mark - GADMAdNetworkAdapter Protocol Methods

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    _connector = connector;
  }
  return self;
}

+ (NSString *)adapterVersion {
  return GADMAdapterAppLovinAdapterVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterAppLovinExtras class];
}

- (void)stopBeingDelegate {
  if (_interstitial) {
    [GADMAdapterAppLovinMediationManager.sharedInstance
        removeInterstitialZoneIdentifier:_zoneIdentifier];
  }

  _interstitial = nil;
  _connector = nil;
  _interstitialDelegate = nil;
  _bannerDelegate = nil;

  _interstitial.adDisplayDelegate = nil;
  _interstitial.adVideoPlaybackDelegate = nil;

  _adView.adLoadDelegate = nil;
  _adView.adDisplayDelegate = nil;
  _adView.adEventDelegate = nil;
}

#pragma mark - GADMAdNetworkAdapter Protocol Interstitial Methods

- (void)getInterstitial {

  if ([GADMAdapterAppLovinUtils isChildUser]) {
    [_connector adapter:self didFailAd:GADMAdapterAppLovinChildUserError()];
    return;
  }

  if (!ALSdk.shared) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorAppLovinSDKNotInitialized,
        @"Failed to retrieve ALSdk shared instance. ");
    [_connector adapter:self didFailAd:error];
    return;
  }

  _zoneIdentifier = [GADMAdapterAppLovinUtils zoneIdentifierForConnector:_connector];
  // Unable to resolve a valid zone - error out
  if (!_zoneIdentifier) {
    NSString *errorString = @"Invalid custom zone entered. Please double-check your credentials.";
    NSError *zoneIdentifierError = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, errorString);
    [_connector adapter:self didFailAd:zoneIdentifierError];
    return;
  }

           [GADMAdapterAppLovinUtils
               log:@"Requesting interstitial for zone: %@", self.zoneIdentifier];

           GADMAdapterAppLovinMediationManager *sharedManager =
               GADMAdapterAppLovinMediationManager.sharedInstance;
           if ([sharedManager containsAndAddInterstitialZoneIdentifier:_zoneIdentifier]) {
             NSError *adAlreadyLoadedError = GADMAdapterAppLovinErrorWithCodeAndDescription(
                 GADMAdapterAppLovinErrorAdAlreadyLoaded,
                 @"Can't request a second ad for the same zone identifier without showing "
                 @"the first ad.");
             [_connector adapter:self didFailAd:adAlreadyLoadedError];
             return;
           }

           _interstitialDelegate =
               [[GADMAdapterAppLovinInterstitialDelegate alloc] initWithParentRenderer:self];
           _interstitial = [[ALInterstitialAd alloc] initWithSdk:ALSdk.shared];
           _interstitial.adDisplayDelegate = _interstitialDelegate;
           _interstitial.adVideoPlaybackDelegate = _interstitialDelegate;
           _settings = _connector.credentials;

           if (_zoneIdentifier.length > 0) {
             [ALSdk.shared.adService loadNextAdForZoneIdentifier:_zoneIdentifier
                                                       andNotify:_interstitialDelegate];
           } else {
             [ALSdk.shared.adService loadNextAd:ALAdSize.interstitial
                                      andNotify:_interstitialDelegate];
           }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  GADMAdapterAppLovinExtras *networkExtras = strongConnector.networkExtras;
  ALSdk.shared.settings.muted = networkExtras.muteAudio;

  [GADMAdapterAppLovinUtils log:@"Showing interstitial ad for zone: %@.", _zoneIdentifier];
  [_interstitial showAd:_interstitialAd];
}

#pragma mark - GADMAdNetworkAdapter Protocol Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  if ([GADMAdapterAppLovinUtils isChildUser]) {
    [_connector adapter:self didFailAd:GADMAdapterAppLovinChildUserError()];
    return;
  }

  if (!ALSdk.shared) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorAppLovinSDKNotInitialized,
        @"Failed to retrieve ALSdk shared instance. ");
    [_connector adapter:self didFailAd:error];
    return;
  }

  _zoneIdentifier = [GADMAdapterAppLovinUtils zoneIdentifierForConnector:_connector];

  // Unable to resolve a valid zone - error out.
  if (!_zoneIdentifier) {
    NSString *errorString = @"Invalid custom zone entered. Please double-check your credentials.";
    NSError *zoneIdentifierError = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, errorString);
    [_connector adapter:self didFailAd:zoneIdentifierError];
    return;
  }

  [GADMAdapterAppLovinUtils log:@"Requesting banner of size %@ for zone: %@.",
                                NSStringFromGADAdSize(adSize), _zoneIdentifier];

  // Convert requested size to AppLovin Ad Size.
  ALAdSize *appLovinAdSize = [GADMAdapterAppLovinUtils appLovinAdSizeFromRequestedSize:adSize];

  if (!appLovinAdSize) {
    NSString *errorMessage = [NSString
        stringWithFormat:@"Adapter requested to display a banner ad of unsupported size: %@",
                         appLovinAdSize];
    NSError *adSizeError = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorBannerSizeMismatch, errorMessage);
    [_connector adapter:self didFailAd:adSizeError];
    return;
  }

  _adView = [[ALAdView alloc] initWithSdk:ALSdk.shared size:appLovinAdSize];

  CGSize size = CGSizeFromGADAdSize(adSize);
  _adView.frame = CGRectMake(0, 0, size.width, size.height);

  _bannerDelegate = [[GADMAdapterAppLovinBannerDelegate alloc] initWithParentAdapter:self];
  _adView.adLoadDelegate = _bannerDelegate;
  _adView.adDisplayDelegate = _bannerDelegate;
  _adView.adEventDelegate = _bannerDelegate;

  if (_zoneIdentifier.length) {
    [ALSdk.shared.adService loadNextAdForZoneIdentifier:_zoneIdentifier andNotify:_bannerDelegate];
  } else {
    [ALSdk.shared.adService loadNextAd:appLovinAdSize andNotify:_bannerDelegate];
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animationType {
  return YES;
}

@end
