// Copyright 2023 Google LLC
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

#import "GADMAdapterMyTargetNativeAd.h"

#import <MyTargetSDK/MyTargetSDK.h>

#import <stdatomic.h>

#import "GADMAdapterMyTargetConstants.h"
#import "GADMAdapterMyTargetExtraAssets.h"
#import "GADMAdapterMyTargetExtras.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMAdapterMyTargetNativeAd () <MTRGNativeAdDelegate>
@end

@implementation GADMAdapterMyTargetNativeAd {
  /// Completion handler to forward ad load events to the Google Mobile Ads SDK.
  GADMediationNativeLoadCompletionHandler _completionHandler;

  /// Native ad configuration of the ad request.
  GADMediationNativeAdConfiguration *_adConfiguration;

  /// Ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  __weak id<GADMediationNativeAdEventDelegate> _adEventDelegate;

  /// myTarget native ad object.
  MTRGNativeAd *_nativeAd;

  /// myTarget media view.
  MTRGMediaAdView *_mediaAdView;

  /// myTarget promo banner.
  MTRGNativePromoBanner *_promoBanner;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationNativeAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationNativeLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationNativeLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];

    _completionHandler = ^id<GADMediationNativeAdEventDelegate>(
        _Nullable id<GADMediationNativeAd> ad, NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }

      id<GADMediationNativeAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(ad, error);
      }

      originalCompletionHandler = nil;
      return delegate;
    };

    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadNativeAd {
  MTRGLogInfo();

  id<GADAdNetworkExtras> networkExtras = _adConfiguration.extras;
  if (networkExtras && [networkExtras isKindOfClass:[GADMAdapterMyTargetExtras class]]) {
    GADMAdapterMyTargetExtras *extras = (GADMAdapterMyTargetExtras *)networkExtras;
    GADMAdapterMyTargetUtils.logEnabled = extras.isDebugMode;
  }

  NSDictionary<NSString *, id> *credentials = _adConfiguration.credentials.settings;
  MTRGLogDebug(@"Credentials: %@", credentials);

  NSUInteger slotID = GADMAdapterMyTargetSlotIdFromCredentials(credentials);
  if (slotID <= 0) {
    NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorInvalidServerParameters, @"Slot ID cannot be nil.");
    _completionHandler(nil, error);
    return;
  }

  _nativeAd = [MTRGNativeAd nativeAdWithSlotId:slotID];
  _nativeAd.delegate = self;
  _nativeAd.cachePolicy = [self shouldLoadImage] ? MTRGCachePolicyAll : MTRGCachePolicyVideo;
  GADMAdapterMyTargetFillCustomParams(_nativeAd.customParams, networkExtras);
  [_nativeAd.customParams setCustomParam:kMTRGCustomParamsMediationAdmob
                                  forKey:kMTRGCustomParamsMediationKey];
  [_nativeAd load];
}

- (BOOL)shouldLoadImage {
  NSArray<GADAdLoaderOptions *> *adLoaderOptionsArray = _adConfiguration.options;
  BOOL shouldLoadImages = YES;
  for (GADAdLoaderOptions *adLoaderOptions in adLoaderOptionsArray) {
    if (![adLoaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      continue;
    }

    GADNativeAdImageAdLoaderOptions *imageOptions =
        (GADNativeAdImageAdLoaderOptions *)adLoaderOptions;
    if (imageOptions.disableImageLoading) {
      shouldLoadImages = NO;
      break;
    }
  }
  return shouldLoadImages;
}

#pragma mark - GADMediationNativeAd

- (BOOL)handlesUserClicks {
  return YES;
}

- (BOOL)handlesUserImpressions {
  return YES;
}

#pragma mark - GADMediatedUnifiedNativeAd

- (BOOL)hasVideoContent {
  return YES;
}

- (CGFloat)mediaContentAspectRatio {
  // TODO: impl
  return 0;
}

- (nullable GADNativeAdImage *)icon {
  // TODO: impl
  return nil;
}

- (nullable NSString *)headline {
  // TODO: impl
  return nil;
}

- (nullable NSString *)body {
  // TODO: impl
  return nil;
}

- (nullable NSString *)callToAction {
  // TODO: impl
  return nil;
}

- (nullable NSString *)advertiser {
  // TODO: impl
  return nil;
}

- (nullable UIView *)mediaView {
  // TODO: impl
  return nil;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  // TODO: impl
  return nil;
}

- (nullable NSDecimalNumber *)starRating {
  // TODO: impl
  return nil;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  // TODO: impl
  return nil;
}

- (nullable UIView *)adChoicesView {
  // TODO: impl
  return nil;
}

- (nullable NSString *)store {
  // TODO: impl
  return nil;
}

- (nullable NSString *)price {
  // TODO: impl
  return nil;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  // TODO: impl
}

- (void)didUntrackView:(UIView *)view {
  // TODO: impl
}

#pragma mark - MTRGNativeAdDelegate

- (void)onLoadWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner
                           nativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();

  _promoBanner = promoBanner;
  _nativeAd = nativeAd;
  _mediaAdView = [MTRGNativeViewsFactory createMediaAdView];
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)onLoadFailedWithError:(NSError *)error nativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
  MTRGLogError(error.localizedDescription);

  NSError *noFillError = GADMAdapterMyTargetErrorWithCodeAndDescription(
      GADMAdapterMyTargetErrorNoFill, error.localizedDescription);
  _completionHandler(nil, noFillError);
}

- (void)onAdShowWithNativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogInfo();

  [_adEventDelegate reportImpression];
}

- (void)onAdClickWithNativeAd:(nonnull MTRGNativeAd *)nativeAd {
  MTRGLogInfo();

  [_adEventDelegate reportClick];
}

- (void)onVideoPlayWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();

  [_adEventDelegate didPlayVideo];
}

- (void)onVideoPauseWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();

  [_adEventDelegate didPauseVideo];
}

- (void)onVideoCompleteWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();

  [_adEventDelegate didEndVideo];
}
@end
