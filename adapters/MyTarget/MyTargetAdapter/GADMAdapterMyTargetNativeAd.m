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

@interface MTRGNativeAd ()

- (void)registerView:(nonnull UIView *)containerView
        withController:(nonnull UIViewController *)controller
    withClickableViews:(nullable NSArray<UIView *> *)clickableViews
       withMediaAdView:(nonnull MTRGMediaAdView *)mediaAdView;

@end

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

  /// Whether to load image.
  BOOL _shouldLoadImage;
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
  [self setShouldLoadImage];
  _nativeAd.cachePolicy = _shouldLoadImage ? MTRGCachePolicyAll : MTRGCachePolicyVideo;
  GADMAdapterMyTargetFillCustomParams(_nativeAd.customParams, networkExtras);
  [_nativeAd.customParams setCustomParam:kMTRGCustomParamsMediationAdmob
                                  forKey:kMTRGCustomParamsMediationKey];
  [_nativeAd load];
}

- (void)setShouldLoadImage {
  NSArray<GADAdLoaderOptions *> *adLoaderOptionsArray = _adConfiguration.options;
  _shouldLoadImage = YES;
  for (GADAdLoaderOptions *adLoaderOptions in adLoaderOptionsArray) {
    if (![adLoaderOptions isKindOfClass:[GADNativeAdImageAdLoaderOptions class]]) {
      continue;
    }

    GADNativeAdImageAdLoaderOptions *imageOptions =
        (GADNativeAdImageAdLoaderOptions *)adLoaderOptions;
    if (imageOptions.disableImageLoading) {
      _shouldLoadImage = NO;
      break;
    }
  }
}

- (BOOL)validateLoadedPromoBanner:(MTRGNativePromoBanner *)promoBanner {
  if (!promoBanner.title || !promoBanner.descriptionText || !promoBanner.image ||
      !promoBanner.ctaText) {
    return NO;
  }

  if ((_shouldLoadImage && !promoBanner.image.image) ||
      (!_shouldLoadImage && !promoBanner.image.url)) {
    return NO;
  }

  if (promoBanner.navigationType == MTRGNavigationTypeWeb && !promoBanner.domain) {
    return NO;
  }

  if (promoBanner.navigationType == MTRGNavigationTypeStore) {
    if (!promoBanner.icon) {
      return NO;
    }

    if ((_shouldLoadImage && !promoBanner.icon.image) ||
        (!_shouldLoadImage && !promoBanner.icon.url)) {
      return NO;
    }
  }
  return YES;
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
  return _mediaAdView.aspectRatio;
}

- (nullable GADNativeAdImage *)icon {
  return GADMAdapterMyTargetNativeAdImageWithImageData(_promoBanner.icon);
}

- (nullable NSString *)headline {
  return _promoBanner.title;
}

- (nullable NSString *)body {
  return _promoBanner.descriptionText;
}

- (nullable NSString *)callToAction {
  return _promoBanner.ctaText;
}

- (nullable NSString *)advertiser {
  return _promoBanner.domain;
}

- (nullable UIView *)mediaView {
  return _mediaAdView;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  GADNativeAdImage *image = GADMAdapterMyTargetNativeAdImageWithImageData(_promoBanner.image);
  return image ? @[ image ] : nil;
}

- (nullable NSDecimalNumber *)starRating {
  return [NSDecimalNumber decimalNumberWithDecimal:_promoBanner.rating.decimalValue];
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  NSMutableDictionary<NSString *, id> *extraAssets = [[NSMutableDictionary alloc] init];
  GADMAdapterMyTargetMutableDictionarySetObjectForKey(
      extraAssets, GADMAdapterMyTargetExtraAssetAdvertisingLabel, _promoBanner.advertisingLabel);
  GADMAdapterMyTargetMutableDictionarySetObjectForKey(
      extraAssets, GADMAdapterMyTargetExtraAssetAgeRestrictions, _promoBanner.ageRestrictions);
  GADMAdapterMyTargetMutableDictionarySetObjectForKey(
      extraAssets, GADMAdapterMyTargetExtraAssetCategory, _promoBanner.category);
  GADMAdapterMyTargetMutableDictionarySetObjectForKey(
      extraAssets, GADMAdapterMyTargetExtraAssetSubcategory, _promoBanner.subcategory);
  if (_promoBanner.votes > 0) {
    GADMAdapterMyTargetMutableDictionarySetObjectForKey(
        extraAssets, GADMAdapterMyTargetExtraAssetVotes,
        [NSNumber numberWithUnsignedInteger:_promoBanner.votes]);
  }
  return [extraAssets copy];
}

- (nullable UIView *)adChoicesView {
  return nil;
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSString *)price {
  return nil;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  MTRGLogInfo();

  // NOTE: This is a workaround. Subview GADMediaView does not contain mediaView at this moment but
  // it will appear a little bit later.
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([self->_nativeAd respondsToSelector:@selector
                         (registerView:withController:withClickableViews:withMediaAdView:)]) {
      [self->_nativeAd registerView:view
                     withController:viewController
                 withClickableViews:clickableAssetViews.allValues
                    withMediaAdView:self->_mediaAdView];
    } else {
      [self->_nativeAd registerView:view
                     withController:viewController
                 withClickableViews:clickableAssetViews.allValues];
    }
  });
}

- (void)didUntrackView:(UIView *)view {
  MTRGLogInfo();

  [_nativeAd unregisterView];
}

#pragma mark - MTRGNativeAdDelegate

- (void)onLoadWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner
                           nativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();

  if (![self validateLoadedPromoBanner:promoBanner]) {
    NSError *error = GADMAdapterMyTargetErrorWithCodeAndDescription(
        GADMAdapterMyTargetErrorMissingNativeAssets, @"Missing required native ad assets.");
    _completionHandler(nil, error);
    return;
  }

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

- (void)onShowModalWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
}

- (void)onDismissModalWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();

  [_adEventDelegate didDismissFullScreenView];
}

- (void)onLeaveApplicationWithNativeAd:(MTRGNativeAd *)nativeAd {
  MTRGLogInfo();
}

@end
