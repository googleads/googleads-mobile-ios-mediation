//
//  GADMAdapterMyTargetMediatedUnifiedNativeAd.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 23.05.2018.
//  Copyright © 2018 Mail.Ru Group. All rights reserved.
//

#import "GADMAdapterMyTargetMediatedUnifiedNativeAd.h"
#import "GADMAdapterMyTargetExtraAssets.h"
#import "GADMAdapterMyTargetUtils.h"

@interface GADMAdapterMyTargetMediatedUnifiedNativeAd ()

@property(nonatomic, strong) MTRGNativeAd *nativeAd;

@end

@implementation GADMAdapterMyTargetMediatedUnifiedNativeAd {
  NSString *_headline;
  NSArray<GADNativeAdImage *> *_images;
  NSString *_body;
  GADNativeAdImage *_icon;
  NSString *_callToAction;
  NSDecimalNumber *_starRating;
  NSString *_advertiser;
  NSMutableDictionary *_extraAssets;
  MTRGMediaAdView *_mediaAdView;
}

+ (nullable id<GADMediatedUnifiedNativeAd>)
    mediatedUnifiedNativeAdWithNativePromoBanner:(nonnull MTRGNativePromoBanner *)promoBanner
                                        nativeAd:(nonnull MTRGNativeAd *)nativeAd
                                     mediaAdView:(nonnull MTRGMediaAdView *)mediaAdView {
  if (!promoBanner.title || !promoBanner.descriptionText || !promoBanner.image ||
      !promoBanner.ctaText) {
    return nil;
  }

  BOOL autoLoadImages = (nativeAd.cachePolicy == MTRGCachePolicyImages) || (nativeAd.cachePolicy == MTRGCachePolicyAll);
  
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

  return
      [[GADMAdapterMyTargetMediatedUnifiedNativeAd alloc] initWithNativePromoBanner:promoBanner
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
      GADNativeAdImage *image =
          [GADMAdapterMyTargetUtils nativeAdImageWithImageData:promoBanner.image];
      _images = (image != nil) ? @[ image ] : nil;
      _icon = [GADMAdapterMyTargetUtils nativeAdImageWithImageData:promoBanner.icon];

      _extraAssets = [NSMutableDictionary new];
      [self addExtraAsset:promoBanner.advertisingLabel
                   forKey:kGADMAdapterMyTargetExtraAssetAdvertisingLabel];
      [self addExtraAsset:promoBanner.ageRestrictions
                   forKey:kGADMAdapterMyTargetExtraAssetAgeRestrictions];
      [self addExtraAsset:promoBanner.category forKey:kGADMAdapterMyTargetExtraAssetCategory];
      [self addExtraAsset:promoBanner.subcategory forKey:kGADMAdapterMyTargetExtraAssetSubcategory];
      if (promoBanner.votes > 0) {
        [_extraAssets setObject:[NSNumber numberWithUnsignedInteger:promoBanner.votes]
                         forKey:kGADMAdapterMyTargetExtraAssetVotes];
      }
    }
  }
  return self;
}

- (void)addExtraAsset:(nullable NSString *)asset forKey:(nonnull NSString *)key {
  if (!asset.length) {
    return;
  }
  [_extraAssets setObject:asset forKey:key];
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
  return YES; // For correct behaviour of GADMediaView return true instead of promoBanner.hasVideo
}

- (CGFloat)mediaContentAspectRatio {
  return _mediaAdView.aspectRatio;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  MTRGLogInfo();
  if (!_nativeAd) {
    return;
  }

  // NOTE: This is a workaround. Subview GADMediaView does not contain mediaView at this moment but
  // it will appear a little bit later.
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.nativeAd registerView:view
                 withController:viewController
             withClickableViews:clickableAssetViews.allValues];
  });
}

- (void)didRecordImpression {
  // do nothing
}

- (void)didRecordClickOnAssetWithName:(nonnull GADUnifiedNativeAssetIdentifier)assetName
                                 view:(nonnull UIView *)view
                       viewController:(nonnull UIViewController *)viewController {
  // do nothing
}

- (void)didUntrackView:(nullable UIView *)view {
  MTRGLogInfo();
  if (!_nativeAd) {
    return;
  }

  [_nativeAd unregisterView];
}

@end
