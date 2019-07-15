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

#define guard(CONDITION) \
  if (CONDITION) {       \
  }

@interface GADMAdapterMyTargetNative () <MTRGNativeAdDelegate>

@property(nonatomic, strong) MTRGNativeAd *nativeAd;

@end

@implementation GADMAdapterMyTargetNative {
  id<GADMediatedUnifiedNativeAd> _mediatedUnifiedNativeAd;
  __weak id<GADMAdNetworkConnector> _connector;
  MTRGMediaAdView *_mediaAdView;
  BOOL _autoLoadImages;
  NSString *_adTypesRequested;
}

+ (NSString *)adapterVersion {
  return kGADMAdapterMyTargetVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [GADMAdapterMyTargetExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
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
  guard(strongConnector) else return;
  [strongConnector adapter:self
                 didFailAd:[GADMAdapterMyTargetUtils
                               errorWithDescription:kGADMAdapterMyTargetErrorBannersNotSupported]];
}

- (void)getInterstitial {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;
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

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;
  [strongConnector
        adapter:self
      didFailAd:[GADMAdapterMyTargetUtils
                    errorWithDescription:kGADMAdapterMyTargetErrorInterstitialNotSupported]];
}

- (void)getNativeAdWithAdTypes:(NSArray *)adTypes options:(NSArray *)options {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;

  NSUInteger slotId = [GADMAdapterMyTargetUtils slotIdFromCredentials:strongConnector.credentials];
  guard(slotId > 0) else {
    MTRGLogError(kGADMAdapterMyTargetErrorSlotId);
    [strongConnector
          adapter:self
        didFailAd:[GADMAdapterMyTargetUtils errorWithDescription:kGADMAdapterMyTargetErrorSlotId]];
    return;
  }

  _autoLoadImages = YES;
  for (GADAdLoaderOptions *adLoaderOptions in options) {
    guard([adLoaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) else continue;
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

- (void)onLoadWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner
                           nativeAd:(MTRGNativeAd *)nativeAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  MTRGLogInfo();
  guard(strongConnector) else return;

  _mediaAdView = [MTRGNativeViewsFactory createMediaAdView];
  _mediatedUnifiedNativeAd = [GADMAdapterMyTargetMediatedUnifiedNativeAd
      mediatedUnifiedNativeAdWithNativePromoBanner:promoBanner
                                          nativeAd:_nativeAd
                                    autoLoadImages:_autoLoadImages
                                       mediaAdView:_mediaAdView];
  guard(_mediatedUnifiedNativeAd) else {
    MTRGLogError(kGADMAdapterMyTargetErrorMediatedAdInvalid);
    [strongConnector
          adapter:self
        didFailAd:[GADMAdapterMyTargetUtils
                      errorWithDescription:kGADMAdapterMyTargetErrorMediatedAdInvalid]];
    return;
  }
  [strongConnector adapter:self didReceiveMediatedUnifiedNativeAd:_mediatedUnifiedNativeAd];
}

- (void)onNoAdWithReason:(NSString *)reason nativeAd:(MTRGNativeAd *)nativeAd {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  NSString *description = [GADMAdapterMyTargetUtils noAdWithReason:reason];
  MTRGLogError(description);
  guard(strongConnector) else return;
  NSError *error = [GADMAdapterMyTargetUtils errorWithDescription:description];
  [strongConnector adapter:self didFailAd:error];
}

- (void)onAdShowWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidRecordImpression:_mediatedUnifiedNativeAd];
}

- (void)onAdClickWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidRecordClick:_mediatedUnifiedNativeAd];
}

- (void)onShowModalWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdWillPresentScreen:_mediatedUnifiedNativeAd];
}

- (void)onDismissModalWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdWillDismissScreen:_mediatedUnifiedNativeAd];
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidDismissScreen:_mediatedUnifiedNativeAd];
}

- (void)onLeaveApplicationWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdWillLeaveApplication:_mediatedUnifiedNativeAd];
}

- (void)onVideoPlayWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidPlayVideo:_mediatedUnifiedNativeAd];
}

- (void)onVideoPauseWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidPauseVideo:_mediatedUnifiedNativeAd];
}

- (void)onVideoCompleteWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  [GADMediatedUnifiedNativeAdNotificationSource
      mediatedNativeAdDidEndVideoPlayback:_mediatedUnifiedNativeAd];
}

@end
