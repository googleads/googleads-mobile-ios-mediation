//
//  GADMAdapterInMobi.m
//
//  Copyright (c) 2015 InMobi. All rights reserved.
//

#import "GADMAdapterInMobi.h"

#import <InMobiSDK/IMSdk.h>

#import "GADInMobiExtras.h"
#import "GADMAdapterInMobiConstants.h"
#import "GADMAdapterInMobiInitializer.h"
#import "GADMAdapterInMobiUnifiedNativeAd.h"
#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"
#import "GADMediationAdapterInMobi.h"
#import "NativeAdKeys.h"

/// Find closest supported ad size from a given ad size.
static CGSize GADMAdapterInMobiSupportedAdSizeFromGADAdSize(GADAdSize gadAdSize) {
  // Supported sizes
  // 320 x 50
  // 300 x 250
  // 728 x 90

  NSArray<NSValue *> *potentialSizeValues =
      @[ @(GADAdSizeBanner), @(GADAdSizeMediumRectangle), @(GADAdSizeLeaderboard) ];

  GADAdSize closestSize = GADClosestValidSizeForAdSizes(gadAdSize, potentialSizeValues);
  return CGSizeFromGADAdSize(closestSize);
}

@implementation GADMAdapterInMobi {
  /// Google Mobile Ads SDK ad network connector.
  __weak id<GADMAdNetworkConnector> _connector;

  /// InMobi banner ad object.
  IMBanner *_adView;

  /// InMobi interstitial ad object.
  IMInterstitial *_interstitial;

  /// Google Mobile Ads unified native ad wrapper.
  GADMAdapterInMobiUnifiedNativeAd *_nativeAd;
}

+ (nonnull Class<GADMediationAdapter>)mainAdapterClass {
  return [GADMediationAdapterInMobi class];
}

+ (nonnull NSString *)adapterVersion {
  return GADMAdapterInMobiVersion;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADInMobiExtras class];
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id)connector {
  if (self = [super init]) {
    _connector = connector;
  }
  return self;
}

- (void)getNativeAdWithAdTypes:(nonnull NSArray<GADAdLoaderAdType> *)adTypes
                       options:(nullable NSArray<GADAdLoaderOptions *> *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongSelf = self;
  if (!strongConnector || !strongSelf) {
    return;
  }

  _nativeAd =
      [[GADMAdapterInMobiUnifiedNativeAd alloc] initWithGADMAdNetworkConnector:strongConnector
                                                                       adapter:strongSelf];
  [_nativeAd requestNativeAdWithOptions:options];
}

- (BOOL)handlesUserImpressions {
  return YES;
}

- (BOOL)handlesUserClicks {
  return NO;
}

- (void)getInterstitial {
  NSString *accountID = _connector.credentials[GADMAdapterInMobiAccountID];
  GADMAdapterInMobi *__weak weakSelf = self;
  [GADMAdapterInMobiInitializer.sharedInstance
      initializeWithAccountID:accountID
            completionHandler:^(NSError *_Nullable error) {
              GADMAdapterInMobi *strongSelf = weakSelf;
              if (!strongSelf) {
                return;
              }

              if (error) {
                NSLog(@"[InMobi] Initialization failed: %@", error.localizedDescription);
                [strongSelf->_connector adapter:strongSelf didFailAd:error];
                return;
              }

              [strongSelf requestInterstitialAd];
            }];
}

- (void)requestInterstitialAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  long long placementId =
      [strongConnector.credentials[GADMAdapterInMobiPlacementID] longLongValue];
  if (placementId == 0) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorInvalidServerParameters,
        @"[InMobi] Error - Placement ID not specified.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  if ([strongConnector testMode]) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to receive test ads from "
          @"InMobi");
  }

  _interstitial = [[IMInterstitial alloc] initWithPlacementId:placementId];

  GADInMobiExtras *extras = [strongConnector networkExtras];
  if (extras && extras.keywords) {
    [_interstitial setKeywords:extras.keywords];
  }

  GADMAdapterInMobiSetTargetingFromConnector(strongConnector);
  NSDictionary<NSString *, id> *requestParameters =
      GADMAdapterInMobiCreateRequestParametersFromConnector(strongConnector);
  [_interstitial setExtras:requestParameters];

  _interstitial.delegate = self;
  [_interstitial load];
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  NSString *accountID = _connector.credentials[GADMAdapterInMobiAccountID];
  GADMAdapterInMobi *__weak weakSelf = self;
  [GADMAdapterInMobiInitializer.sharedInstance
      initializeWithAccountID:accountID
            completionHandler:^(NSError *_Nullable error) {
              GADMAdapterInMobi *strongSelf = weakSelf;
              if (!strongSelf) {
                return;
              }

              if (error) {
                NSLog(@"[InMobi] Initialization failed: %@", error.localizedDescription);
                [strongSelf->_connector adapter:strongSelf didFailAd:error];
                return;
              }

              [strongSelf requestBannerWithSize:adSize];
            }];
}

- (void)requestBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  long long placementId =
      [strongConnector.credentials[GADMAdapterInMobiPlacementID] longLongValue];
  if (placementId == 0) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorInvalidServerParameters,
        @"[InMobi] Error - Placement ID not specified.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  if ([strongConnector testMode]) {
    NSLog(@"[InMobi] Please enter your device ID in the InMobi console to recieve test ads from "
          @"Inmobi");
  }

  CGSize size = GADMAdapterInMobiSupportedAdSizeFromGADAdSize(adSize);
  if (CGSizeEqualToSize(size, CGSizeZero)) {
    NSString *description =
        [NSString stringWithFormat:@"Invalid size for InMobi mediation adapter. Size: %@",
                                   NSStringFromGADAdSize(adSize)];
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorBannerSizeMismatch, description);
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _adView = [[IMBanner alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                placementId:placementId];

  // Let Mediation do the refresh.
  [_adView shouldAutoRefresh:NO];
  _adView.transitionAnimation = UIViewAnimationTransitionNone;

  GADInMobiExtras *extras = [strongConnector networkExtras];
  if (extras && extras.keywords) {
    [_adView setKeywords:extras.keywords];
  }

  GADMAdapterInMobiSetTargetingFromConnector(strongConnector);
  NSDictionary<NSString *, id> *requestParameters =
      GADMAdapterInMobiCreateRequestParametersFromConnector(strongConnector);
  [_adView setExtras:requestParameters];

  _adView.delegate = self;
  [_adView load];
}

- (void)stopBeingDelegate {
  _adView.delegate = nil;
  _interstitial.delegate = nil;
}

- (void)presentInterstitialFromRootViewController:(nonnull UIViewController *)rootViewController {
  if ([_interstitial isReady]) {
    [_interstitial showFromViewController:rootViewController
                            withAnimation:kIMInterstitialAnimationTypeCoverVertical];
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return [_interstitial isReady];
}

#pragma mark -
#pragma mark IMBannerDelegate methods

- (void)bannerDidFinishLoading:(nonnull IMBanner *)banner {
  NSLog(@"<<<<<ad request completed>>>>>");
  [_connector adapter:self didReceiveAdView:banner];
}

- (void)banner:(nonnull IMBanner *)banner didFailToLoadWithError:(nonnull IMRequestStatus *)error {
  [_connector adapter:self didFailAd:error];
}

- (void)banner:(nonnull IMBanner *)banner didInteractWithParams:(nonnull NSDictionary *)params {
  NSLog(@"<<<< bannerDidInteract >>>>");
  [_connector adapterDidGetAdClick:self];
}

- (void)userWillLeaveApplicationFromBanner:(nonnull IMBanner *)banner {
  NSLog(@"<<<< bannerWillLeaveApplication >>>>");
  [_connector adapterWillLeaveApplication:self];
}

- (void)bannerWillPresentScreen:(nonnull IMBanner *)banner {
  NSLog(@"<<<< bannerWillPresentScreen >>>>");
  [_connector adapterWillPresentFullScreenModal:self];
}

- (void)bannerDidPresentScreen:(nonnull IMBanner *)banner {
  NSLog(@"InMobi banner did present screen");
}

- (void)bannerWillDismissScreen:(nonnull IMBanner *)banner {
  NSLog(@"<<<< bannerWillDismissScreen >>>>");
  [_connector adapterWillDismissFullScreenModal:self];
}

- (void)bannerDidDismissScreen:(nonnull IMBanner *)banner {
  NSLog(@"<<<< bannerDidDismissScreen >>>>");
  [_connector adapterDidDismissFullScreenModal:self];
}

- (void)banner:(nonnull IMBanner *)banner
    rewardActionCompletedWithRewards:(nonnull NSDictionary *)rewards {
  NSLog(@"InMobi banner reward action completed with rewards: %@", rewards.description);
}

#pragma mark IMAdInterstitialDelegate methods

- (void)interstitialDidFinishLoading:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialDidFinishRequest >>>>");
  [_connector adapterDidReceiveInterstitial:self];
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didFailToLoadWithError:(IMRequestStatus *)error {
  [_connector adapter:self didFailAd:error];
}

- (void)interstitialWillPresent:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialWillPresentScreen >>>>");
  [_connector adapterWillPresentInterstitial:self];
}

- (void)interstitialDidPresent:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialDidPresent >>>>");
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didFailToPresentWithError:(IMRequestStatus *)error {
  [_connector adapter:self didFailAd:error];
}

- (void)interstitialWillDismiss:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialWillDismiss >>>>");
  [_connector adapterWillDismissInterstitial:self];
}

- (void)interstitialDidDismiss:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< interstitialDidDismiss >>>>");
  [_connector adapterDidDismissInterstitial:self];
}

- (void)interstitial:(nonnull IMInterstitial *)interstitial
    didInteractWithParams:(nonnull NSDictionary *)params {
  NSLog(@"<<<< interstitialDidInteract >>>>");
  [_connector adapterDidGetAdClick:self];
}

- (void)userWillLeaveApplicationFromInterstitial:(nonnull IMInterstitial *)interstitial {
  NSLog(@"<<<< userWillLeaveApplicationFromInterstitial >>>>");
  [_connector adapterWillLeaveApplication:self];
}

- (void)interstitialDidReceiveAd:(nonnull IMInterstitial *)interstitial {
  NSLog(@"InMobi AdServer returned a response.");
}

@end
