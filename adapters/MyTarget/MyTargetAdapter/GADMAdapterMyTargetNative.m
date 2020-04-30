//
//  GADMAdapterMyTargetNative.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 29.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

@import MyTargetSDK;

#import "GADMAdapterMyTargetNative.h"
#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetMediatedUnifiedNativeAd.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMAdapterMyTargetNative () <MTRGNativeAdDelegate>

@property(nonatomic, strong, nonnull) MTRGNativeAd *nativeAd;

@end

@implementation GADMAdapterMyTargetNative {
  id<GADMediatedUnifiedNativeAd> _mediatedUnifiedNativeAd;
  __weak id<GADMAdNetworkConnector> _connector;
  MTRGMediaAdView *_mediaAdView;
  BOOL _autoLoadImages;
  NSString *_adTypesRequested;
}

+ (nonnull NSString *)adapterVersion {
  return kGADMAdapterMyTargetVersion;
}

+ (nonnull Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterMyTargetExtras class];
}

- (nonnull instancetype)initWithGADMAdNetworkConnector:
    (nonnull id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    id<GADAdNetworkExtras> networkExtras = connector.networkExtras;
    if (networkExtras && [networkExtras isKindOfClass:[GADMAdapterMyTargetExtras class]]) {
      GADMAdapterMyTargetExtras *extras = (GADMAdapterMyTargetExtras *)networkExtras;
      [GADMAdapterMyTargetUtils setLogEnabled:extras.isDebugMode];
    }

    MTRGLogInfo();
    MTRGLogDebug(@"Credentials: %@", connector.credentials);
    _connector = connector;
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  [strongConnector adapter:self
                 didFailAd:[GADMAdapterMyTargetUtils
                               errorWithDescription:kGADMAdapterMyTargetErrorBannersNotSupported]];
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  [strongConnector
        adapter:self
      didFailAd:[GADMAdapterMyTargetUtils
                    errorWithDescription:kGADMAdapterMyTargetErrorInterstitialNotSupported]];
}

- (void)stopBeingDelegate {
  MTRGLogInfo();
  _connector = nil;
  if (_nativeAd) {
    _nativeAd.delegate = nil;
    _nativeAd = nil;
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(nonnull UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  [strongConnector
        adapter:self
      didFailAd:[GADMAdapterMyTargetUtils
                    errorWithDescription:kGADMAdapterMyTargetErrorInterstitialNotSupported]];
}

- (void)getNativeAdWithAdTypes:(nonnull NSArray<GADAdLoaderAdType> *)adTypes
                       options:(nullable NSArray<GADAdLoaderOptions *> *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  NSUInteger slotId = [GADMAdapterMyTargetUtils slotIdFromCredentials:strongConnector.credentials];
  if (slotId <= 0) {
    MTRGLogError(kGADMAdapterMyTargetErrorSlotId);
    [strongConnector
          adapter:self
        didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorSlotId]];
    return;
  }

  _autoLoadImages = YES;
  for (GADAdLoaderOptions *adLoaderOptions in options) {
    if (![adLoaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      continue;
    }

    GADNativeAdImageAdLoaderOptions *imageOptions =
        (GADNativeAdImageAdLoaderOptions *)adLoaderOptions;
    if (imageOptions.disableImageLoading) {
      _autoLoadImages = NO;
      break;
    }
  }

  _nativeAd = [[MTRGNativeAd alloc] initWithSlotId:slotId];
  _nativeAd.delegate = self;
  _nativeAd.autoLoadImages = _autoLoadImages;
  [GADMAdapterMyTargetUtils fillCustomParams:_nativeAd.customParams withConnector:strongConnector];
  [_nativeAd.customParams setCustomParam:kMTRGCustomParamsMediationAdmob
                                  forKey:kMTRGCustomParamsMediationKey];
  [_nativeAd load];
}

- (BOOL)handlesUserClicks {
  return YES;
}

- (BOOL)handlesUserImpressions {
  return YES;
}

#pragma mark - MTRGNativeAdDelegate

- (void)onLoadWithNativePromoBanner:(nonnull MTRGNativePromoBanner *)promoBanner
                           nativeAd:(nonnull MTRGNativeAd *)nativeAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  if (!strongConnector) {
    return;
  }

  _mediaAdView = [MTRGNativeViewsFactory createMediaAdView];
  _mediatedUnifiedNativeAd = [GADMAdapterMyTargetMediatedUnifiedNativeAd
      mediatedUnifiedNativeAdWithNativePromoBanner:promoBanner
                                          nativeAd:_nativeAd
                                    autoLoadImages:_autoLoadImages
                                       mediaAdView:_mediaAdView];
  if (!_mediatedUnifiedNativeAd) {
    MTRGLogError(kGADMAdapterMyTargetErrorMediatedAdInvalid);
    [strongConnector adapter:self
                   didFailAd:[GADMAdapterMyTargetUtils
                                 errorWithDescription:kGADMAdapterMyTargetErrorMediatedAdInvalid]];
    return;
  }
  [strongConnector adapter:self didReceiveMediatedUnifiedNativeAd:_mediatedUnifiedNativeAd];
}

- (void)onNoAdWithReason:(nonnull NSString *)reason nativeAd:(nonnull MTRGNativeAd *)nativeAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSString *description = [GADMAdapterMyTargetUtils noAdWithReason:reason];
  MTRGLogError(description);
  if (!strongConnector) {
    return;
  }

  NSError *error = [GADMAdapterMyTargetUtils errorWithDescription:description];
  [strongConnector adapter:self didFailAd:error];
}

- (void)onAdShowWithNativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidRecordImpression:_mediatedUnifiedNativeAd];
}

- (void)onAdClickWithNativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidRecordClick:_mediatedUnifiedNativeAd];
}

- (void)onShowModalWithNativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdWillPresentScreen:_mediatedUnifiedNativeAd];
}

- (void)onDismissModalWithNativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdWillDismissScreen:_mediatedUnifiedNativeAd];
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidDismissScreen:_mediatedUnifiedNativeAd];
}

- (void)onLeaveApplicationWithNativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdWillLeaveApplication:_mediatedUnifiedNativeAd];
}

- (void)onVideoPlayWithNativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidPlayVideo:_mediatedUnifiedNativeAd];
}

- (void)onVideoPauseWithNativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidPauseVideo:_mediatedUnifiedNativeAd];
}

- (void)onVideoCompleteWithNativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidEndVideoPlayback:_mediatedUnifiedNativeAd];
}

@end
