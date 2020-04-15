//
//  GADMAdapterAppLovin.m
//
//
//  Created by Thomas So on 1/10/18.
//
//

#import "GADMAdapterAppLovin.h"
#import "GADMAdapterAppLovinBannerDelegate.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinInterstitialDelegate.h"
#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMediationAdapterAppLovin.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation GADMAdapterAppLovin {
  /// Instance of the AppLovin SDK.
  ALSdk *_sdk;

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
    _sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:connector.credentials];
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
  id<GADMAdNetworkConnector> strongConnector = _connector;

  if (!_sdk) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, @"Invalid server parameters.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _zoneIdentifier = [GADMAdapterAppLovinUtils zoneIdentifierForConnector:strongConnector];

  // Unable to resolve a valid zone - error out
  if (!_zoneIdentifier) {
    NSString *errorString = @"Invalid custom zone entered. Please double-check your credentials.";
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, errorString);
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  [GADMAdapterAppLovinUtils log:@"Requesting interstitial for zone: %@", self.zoneIdentifier];

  GADMAdapterAppLovinMediationManager *sharedManager =
      GADMAdapterAppLovinMediationManager.sharedInstance;
  if ([sharedManager containsAndAddInterstitialZoneIdentifier:_zoneIdentifier]) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorAdAlreadyLoaded,
        @"Can't request a second ad for the same zone identifier without showing the first ad.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _interstitialDelegate =
      [[GADMAdapterAppLovinInterstitialDelegate alloc] initWithParentRenderer:self];
  _interstitial = [[ALInterstitialAd alloc] initWithSdk:_sdk];
  _interstitial.adDisplayDelegate = _interstitialDelegate;
  _interstitial.adVideoPlaybackDelegate = _interstitialDelegate;

  if (_zoneIdentifier.length > 0) {
    [_sdk.adService loadNextAdForZoneIdentifier:_zoneIdentifier andNotify:_interstitialDelegate];
  } else {
    [_sdk.adService loadNextAd:[ALAdSize sizeInterstitial] andNotify:_interstitialDelegate];
  }
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  GADMAdapterAppLovinExtras *networkExtras = strongConnector.networkExtras;
  _sdk.settings.muted = networkExtras.muteAudio;

  [GADMAdapterAppLovinUtils log:@"Showing interstitial ad: %@ for zone: %@.",
                                _interstitialAd.adIdNumber, _zoneIdentifier];
  [_interstitial showAd:_interstitialAd];
}

#pragma mark - GADMAdNetworkAdapter Protocol Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;

  if (!_sdk) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, @"Invalid server parameters");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _zoneIdentifier = [GADMAdapterAppLovinUtils zoneIdentifierForConnector:strongConnector];

  // Unable to resolve a valid zone - error out.
  if (!_zoneIdentifier) {
    NSString *errorString = @"Invalid custom zone entered. Please double-check your credentials.";
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, errorString);
    [strongConnector adapter:self didFailAd:error];
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
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorBannerSizeMismatch, errorMessage);
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _adView = [[ALAdView alloc] initWithSdk:_sdk size:appLovinAdSize];

  CGSize size = CGSizeFromGADAdSize(adSize);
  _adView.frame = CGRectMake(0, 0, size.width, size.height);

  _bannerDelegate = [[GADMAdapterAppLovinBannerDelegate alloc] initWithParentAdapter:self];
  _adView.adLoadDelegate = _bannerDelegate;
  _adView.adDisplayDelegate = _bannerDelegate;
  _adView.adEventDelegate = _bannerDelegate;

  if (_zoneIdentifier.length) {
    [_sdk.adService loadNextAdForZoneIdentifier:_zoneIdentifier andNotify:_bannerDelegate];
  } else {
    [_sdk.adService loadNextAd:appLovinAdSize andNotify:_bannerDelegate];
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animationType {
  return YES;
}

@end
