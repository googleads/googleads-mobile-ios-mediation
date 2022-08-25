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
#import "GADMAdapterAppLovinInitializer.h"
#import "GADMAdapterAppLovinInterstitialDelegate.h"
#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMediationAdapterAppLovin.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation GADMAdapterAppLovin {
  /// Instance of the AppLovin SDK.
  ALSdk *_SDK;

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
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    [GADMAdapterAppLovinUtils log:@"No GADMAdNetworkConnector found."];
    return;
  }

  NSString *SDKKey =
      [GADMAdapterAppLovinUtils retrieveSDKKeyFromCredentials:[strongConnector credentials]];
  if (!SDKKey) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, @"Invalid server parameters.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  GADMAdapterAppLovin *__weak weakSelf = self;
  [GADMAdapterAppLovinInitializer.sharedInstance
      initializeWithSDKKey:SDKKey
         completionHandler:^(NSError *_Nullable initializationError) {
           GADMAdapterAppLovin *strongSelf = weakSelf;
           if (!strongSelf) {
             return;
           }

           if (initializationError) {
             [strongConnector adapter:strongSelf didFailAd:initializationError];
             return;
           }

           strongSelf->_SDK = [GADMAdapterAppLovinUtils retrieveSDKFromSDKKey:SDKKey];
           if (!strongSelf->_SDK) {
             NSError *nilSDKError = GADMAdapterAppLovinNilSDKError(SDKKey);
             [strongConnector adapter:strongSelf didFailAd:nilSDKError];
             return;
           }

           strongSelf->_zoneIdentifier =
               [GADMAdapterAppLovinUtils zoneIdentifierForConnector:strongConnector];
           // Unable to resolve a valid zone - error out
           if (!strongSelf->_zoneIdentifier) {
             NSString *errorString =
                 @"Invalid custom zone entered. Please double-check your credentials.";
             NSError *zoneIdentifierError = GADMAdapterAppLovinErrorWithCodeAndDescription(
                 GADMAdapterAppLovinErrorInvalidServerParameters, errorString);
             [strongConnector adapter:strongSelf didFailAd:zoneIdentifierError];
             return;
           }

           [GADMAdapterAppLovinUtils
               log:@"Requesting interstitial for zone: %@", self.zoneIdentifier];

           GADMAdapterAppLovinMediationManager *sharedManager =
               GADMAdapterAppLovinMediationManager.sharedInstance;
           if ([sharedManager
                   containsAndAddInterstitialZoneIdentifier:strongSelf->_zoneIdentifier]) {
             NSError *adAlreadyLoadedError = GADMAdapterAppLovinErrorWithCodeAndDescription(
                 GADMAdapterAppLovinErrorAdAlreadyLoaded,
                 @"Can't request a second ad for the same zone identifier without showing "
                 @"the first ad.");
             [strongConnector adapter:strongSelf didFailAd:adAlreadyLoadedError];
             return;
           }

           strongSelf->_interstitialDelegate =
               [[GADMAdapterAppLovinInterstitialDelegate alloc] initWithParentRenderer:strongSelf];
           strongSelf->_interstitial = [[ALInterstitialAd alloc] initWithSdk:strongSelf->_SDK];
           strongSelf->_interstitial.adDisplayDelegate = strongSelf->_interstitialDelegate;
           strongSelf->_interstitial.adVideoPlaybackDelegate = strongSelf->_interstitialDelegate;

           if (strongSelf->_zoneIdentifier.length > 0) {
             [strongSelf->_SDK.adService
                 loadNextAdForZoneIdentifier:strongSelf->_zoneIdentifier
                                   andNotify:strongSelf->_interstitialDelegate];
           } else {
             [strongSelf->_SDK.adService loadNextAd:ALAdSize.interstitial
                                          andNotify:strongSelf->_interstitialDelegate];
           }
         }];
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  GADMAdapterAppLovinExtras *networkExtras = strongConnector.networkExtras;
  _SDK.settings.muted = networkExtras.muteAudio;

  [GADMAdapterAppLovinUtils log:@"Showing interstitial ad: %@ for zone: %@.",
                                _interstitialAd.adIdNumber, _zoneIdentifier];
  [_interstitial showAd:_interstitialAd];
}

#pragma mark - GADMAdNetworkAdapter Protocol Banner Methods

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    [GADMAdapterAppLovinUtils log:@"No GADMAdNetworkConnector found."];
    return;
  }

  NSString *SDKKey =
      [GADMAdapterAppLovinUtils retrieveSDKKeyFromCredentials:[strongConnector credentials]];
  if (!SDKKey) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, @"Invalid server parameters.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  GADMAdapterAppLovin *__weak weakSelf = self;
  [GADMAdapterAppLovinInitializer.sharedInstance
      initializeWithSDKKey:SDKKey
         completionHandler:^(NSError *_Nullable initializationError) {
           GADMAdapterAppLovin *strongSelf = weakSelf;
           if (!strongSelf) {
             return;
           }

           if (initializationError) {
             [strongConnector adapter:strongSelf didFailAd:initializationError];
             return;
           }

           strongSelf->_SDK = [GADMAdapterAppLovinUtils retrieveSDKFromSDKKey:SDKKey];
           if (!strongSelf->_SDK) {
             NSError *nilSDKError = GADMAdapterAppLovinNilSDKError(SDKKey);
             [strongConnector adapter:strongSelf didFailAd:nilSDKError];
             return;
           }

           strongSelf->_zoneIdentifier =
               [GADMAdapterAppLovinUtils zoneIdentifierForConnector:strongConnector];

           // Unable to resolve a valid zone - error out.
           if (!strongSelf->_zoneIdentifier) {
             NSString *errorString =
                 @"Invalid custom zone entered. Please double-check your credentials.";
             NSError *zoneIdentifierError = GADMAdapterAppLovinErrorWithCodeAndDescription(
                 GADMAdapterAppLovinErrorInvalidServerParameters, errorString);
             [strongConnector adapter:strongSelf didFailAd:zoneIdentifierError];
             return;
           }

           [GADMAdapterAppLovinUtils log:@"Requesting banner of size %@ for zone: %@.",
                                         NSStringFromGADAdSize(adSize),
                                         strongSelf->_zoneIdentifier];

           // Convert requested size to AppLovin Ad Size.
           ALAdSize *appLovinAdSize =
               [GADMAdapterAppLovinUtils appLovinAdSizeFromRequestedSize:adSize];

           if (!appLovinAdSize) {
             NSString *errorMessage =
                 [NSString stringWithFormat:
                               @"Adapter requested to display a banner ad of unsupported size: %@",
                               appLovinAdSize];
             NSError *adSizeError = GADMAdapterAppLovinErrorWithCodeAndDescription(
                 GADMAdapterAppLovinErrorBannerSizeMismatch, errorMessage);
             [strongConnector adapter:strongSelf didFailAd:adSizeError];
             return;
           }

           strongSelf->_adView = [[ALAdView alloc] initWithSdk:strongSelf->_SDK
                                                          size:appLovinAdSize];

           CGSize size = CGSizeFromGADAdSize(adSize);
           strongSelf->_adView.frame = CGRectMake(0, 0, size.width, size.height);

           strongSelf->_bannerDelegate =
               [[GADMAdapterAppLovinBannerDelegate alloc] initWithParentAdapter:strongSelf];
           strongSelf->_adView.adLoadDelegate = strongSelf->_bannerDelegate;
           strongSelf->_adView.adDisplayDelegate = strongSelf->_bannerDelegate;
           strongSelf->_adView.adEventDelegate = strongSelf->_bannerDelegate;

           if (strongSelf->_zoneIdentifier.length) {
             [strongSelf->_SDK.adService loadNextAdForZoneIdentifier:strongSelf->_zoneIdentifier
                                                           andNotify:strongSelf->_bannerDelegate];
           } else {
             [strongSelf->_SDK.adService loadNextAd:appLovinAdSize
                                          andNotify:strongSelf->_bannerDelegate];
           }
         }];
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animationType {
  return YES;
}

@end
