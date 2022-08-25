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

#import "GADMAdapterMyTargetMediatedUnifiedNativeAd.h"

#import "GADMAdapterMyTargetExtraAssets.h"
#import "GADMAdapterMyTargetUtils.h"

@interface MTRGNativeAd ()

- (void)registerView:(nonnull UIView *)containerView
      withController:(nonnull UIViewController *)controller
  withClickableViews:(nullable NSArray<UIView *> *)clickableViews
     withMediaAdView:(nonnull MTRGMediaAdView *)mediaAdView;

@end

@implementation GADMAdapterMyTargetMediatedUnifiedNativeAd {
  /// myTarget native ad object.
  MTRGNativeAd *_nativeAd;

  /// myTarget native ad headline text.
  NSString *_headline;

  /// myTarget native ad images.
  NSArray<GADNativeAdImage *> *_images;

  /// myTarget native ad body text.
  NSString *_body;

  /// myTarget native ad icon image.
  GADNativeAdImage *_icon;

  /// myTarget native ad call to action text.
  NSString *_callToAction;

  /// myTarget native ad star rating.
  NSDecimalNumber *_starRating;

  /// myTarget native ad advertiser text.
  NSString *_advertiser;

  /// Additional myTarget native ad assets/
  NSMutableDictionary<NSString *, id> *_extraAssets;

  /// myTarget media view.
  MTRGMediaAdView *_mediaAdView;
}

+ (nullable id<GADMediatedUnifiedNativeAd>)
    mediatedUnifiedNativeAdWithNativePromoBanner:(nonnull MTRGNativePromoBanner *)promoBanner
                                        nativeAd:(nonnull MTRGNativeAd *)nativeAd
                                  autoLoadImages:(BOOL)autoLoadImages
                                     mediaAdView:(nonnull MTRGMediaAdView *)mediaAdView {
  if (!promoBanner.title || !promoBanner.descriptionText || !promoBanner.image ||
      !promoBanner.ctaText) {
    return nil;
  }

  if ((autoLoadImages && !promoBanner.image.image) || (!autoLoadImages && !promoBanner.image.url)) {
    return nil;
  }

  if (promoBanner.navigationType == MTRGNavigationTypeWeb && !promoBanner.domain) {
    return nil;
  }

  if (promoBanner.navigationType == MTRGNavigationTypeStore) {
    if (!promoBanner.icon) {
      return nil;
    }

    if ((autoLoadImages && !promoBanner.icon.image) || (!autoLoadImages && !promoBanner.icon.url)) {
      return nil;
    }
  }

  return [[GADMAdapterMyTargetMediatedUnifiedNativeAd alloc] initWithNativePromoBanner:promoBanner
                                                                              nativeAd:nativeAd
                                                                           mediaAdView:mediaAdView];
}

- (nullable id<GADMediatedUnifiedNativeAd>)
    initWithNativePromoBanner:(nonnull MTRGNativePromoBanner *)promoBanner
                     nativeAd:(nonnull MTRGNativeAd *)nativeAd
                  mediaAdView:(nonnull MTRGMediaAdView *)mediaAdView {
  self = [super init];
  if (self) {
    _nativeAd = nativeAd;
    if (promoBanner) {
      _headline = promoBanner.title;
      _body = promoBanner.descriptionText;
      _callToAction = promoBanner.ctaText;
      _starRating = [NSDecimalNumber decimalNumberWithDecimal:promoBanner.rating.decimalValue];
      _advertiser = promoBanner.domain;
      _mediaAdView = mediaAdView;
      GADNativeAdImage *image = GADMAdapterMyTargetNativeAdImageWithImageData(promoBanner.image);
      _images = (image != nil) ? @[ image ] : nil;
      _icon = GADMAdapterMyTargetNativeAdImageWithImageData(promoBanner.icon);

      _extraAssets = [[NSMutableDictionary alloc] init];
      GADMAdapterMyTargetMutableDictionarySetObjectForKey(
          _extraAssets, GADMAdapterMyTargetExtraAssetAdvertisingLabel,
          promoBanner.advertisingLabel);
      GADMAdapterMyTargetMutableDictionarySetObjectForKey(
          _extraAssets, GADMAdapterMyTargetExtraAssetAgeRestrictions, promoBanner.ageRestrictions);
      GADMAdapterMyTargetMutableDictionarySetObjectForKey(
          _extraAssets, GADMAdapterMyTargetExtraAssetCategory, promoBanner.category);
      GADMAdapterMyTargetMutableDictionarySetObjectForKey(
          _extraAssets, GADMAdapterMyTargetExtraAssetSubcategory, promoBanner.subcategory);
      if (promoBanner.votes > 0) {
        GADMAdapterMyTargetMutableDictionarySetObjectForKey(
            _extraAssets, GADMAdapterMyTargetExtraAssetVotes,
            [NSNumber numberWithUnsignedInteger:promoBanner.votes]);
      }
    }
  }
  return self;
}

- (nullable NSString *)headline {
  return _headline;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  return _images;
}

- (nullable NSString *)body {
  return _body;
}

- (nullable GADNativeAdImage *)icon {
  return _icon;
}

- (nullable NSString *)callToAction {
  return _callToAction;
}

- (nullable NSDecimalNumber *)starRating {
  return _starRating;
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSString *)price {
  return nil;
}

- (nullable NSString *)advertiser {
  return _advertiser;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  return _extraAssets;
}

- (nullable UIView *)adChoicesView {
  return nil;
}

- (nullable UIView *)mediaView {
  return _mediaAdView;
}

- (BOOL)hasVideoContent {
  return YES;  // For correct behaviour of GADMediaView return true instead of promoBanner.hasVideo
}

- (CGFloat)mediaContentAspectRatio {
  return _mediaAdView.aspectRatio;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  MTRGLogInfo();
  if (!_nativeAd) {
    return;
  }

  // NOTE: This is a workaround. Subview GADMediaView does not contain mediaView at this moment but
  // it will appear a little bit later.
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([self->_nativeAd respondsToSelector:@selector(registerView:withController:withClickableViews:withMediaAdView:)]) {
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

- (void)didRecordImpression {
  MTRGLogInfo();
}

- (void)didRecordClickOnAssetWithName:(nonnull GADNativeAssetIdentifier)assetName
                                 view:(nonnull UIView *)view
                       viewController:(nonnull UIViewController *)viewController {
  MTRGLogInfo();
}

- (void)didUntrackView:(nullable UIView *)view {
  MTRGLogInfo();
  if (!_nativeAd) {
    return;
  }

  [_nativeAd unregisterView];
}

@end
