// Copyright 2017 Google LLC
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

#import "GADMAdapterMyTargetNative.h"

#import <MyTargetSDK/MyTargetSDK.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetMediatedUnifiedNativeAd.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMAdapterMyTargetNative () <MTRGNativeAdDelegate>
@end

@implementation GADMAdapterMyTargetNative {
  /// myTarget mediated unified native ad wrapper.
  GADMAdapterMyTargetMediatedUnifiedNativeAd *_mediatedUnifiedNativeAd;

  /// Google Mobile Ads SDK ad network connector.
  __weak id<GADMAdNetworkConnector> _connector;

  /// myTarget native ad object.
  MTRGNativeAd *_nativeAd;

  /// myTarget media view.
  MTRGMediaAdView *_mediaAdView;

  /// Indicates whether native ad images should be loaded.
  BOOL _autoLoadImages;
}

+ (nonnull NSString *)adapterVersion {
  return GADMAdapterMyTargetVersion;
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
      GADMAdapterMyTargetUtils.logEnabled = extras.isDebugMode;
    }

    MTRGLogInfo();
    MTRGLogDebug(@"Credentials: %@", connector.credentials);
    _connector = connector;
  }
  return self;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }
  NSString *description = [NSString
      stringWithFormat:
          @"GADMAdapterMyTargetNative asked to load a banner ad. This should never happen."];
  NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
      GADMAdapterMyTargetErrorUnsupportedAdFormat, description);
  [strongConnector adapter:self didFailAd:error];
}

- (void)getInterstitial {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }
  NSString *description = [NSString
      stringWithFormat:
          @"GADMAdapterMyTargetNative asked to load an interstitial ad. This should never happen."];
  NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
      GADMAdapterMyTargetErrorUnsupportedAdFormat, description);
  [strongConnector adapter:self didFailAd:error];
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
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }
  NSString *description = [NSString
      stringWithFormat:
          @"GADMAdapterMyTargetNative asked to show an interstitial ad. This should never happen."];
  NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
      GADMAdapterMyTargetErrorUnsupportedAdFormat, description);
  [strongConnector adapter:self didFailAd:error];
}

- (void)getNativeAdWithAdTypes:(nonnull NSArray<GADAdLoaderAdType> *)adTypes
                       options:(nullable NSArray<GADAdLoaderOptions *> *)options {
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  NSUInteger slotId = GADMAdapterMyTargetSlotIdFromCredentials(strongConnector.credentials);
  if (slotId <= 0) {
    NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorInvalidServerParameters, @"Slot ID cannot be nil.");
    [strongConnector adapter:self didFailAd:error];
    return;
  }

  _autoLoadImages = YES;
  MTRGCachePolicy cachePolicy = MTRGCachePolicyAll;
  for (GADAdLoaderOptions *adLoaderOptions in options) {
    if (![adLoaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      continue;
    }

    GADNativeAdImageAdLoaderOptions *imageOptions =
        (GADNativeAdImageAdLoaderOptions *)adLoaderOptions;
    if (imageOptions.disableImageLoading) {
      _autoLoadImages = NO;
      cachePolicy = MTRGCachePolicyVideo;
      break;
    }
  }

  _nativeAd = [[MTRGNativeAd alloc] initWithSlotId:slotId];
  _nativeAd.delegate = self;
  _nativeAd.cachePolicy = cachePolicy;
  GADMAdapterMyTargetFillCustomParams(_nativeAd.customParams, strongConnector.networkExtras);
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
  MTRGLogInfo();
  id<GADMAdNetworkConnector> strongConnector = _connector;
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
    NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorMissingNativeAssets, @"Missing required native ad assets.");

    [strongConnector adapter:self didFailAd:error];
    return;
  }
  [strongConnector adapter:self didReceiveMediatedUnifiedNativeAd:_mediatedUnifiedNativeAd];
}

- (void)onNoAdWithReason:(nonnull NSString *)reason nativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogError(reason);
  id<GADMAdNetworkConnector> strongConnector = _connector;
  if (!strongConnector) {
    return;
  }

  NSError *error =
      GADMAdapterMyTargetErrorWithCodeAndDescription(GADMAdapterMyTargetErrorNoFill, reason);
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
