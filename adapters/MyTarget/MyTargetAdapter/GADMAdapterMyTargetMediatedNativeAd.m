//
//  GADMAdapterMyTargetMediatedNativeAd.m
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 29.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

#import "GADMAdapterMyTargetMediatedNativeAd.h"
#import "GADMAdapterMyTargetExtraAssets.h"
#import "GADMAdapterMyTargetUtils.h"

#define guard(CONDITION) \
  if (CONDITION) {       \
  }

@interface GADMAdapterMyTargetMediatedNativeContentAd : NSObject <GADMediatedNativeContentAd>

@end

@implementation GADMAdapterMyTargetMediatedNativeContentAd {
  __weak id<GADMediatedNativeAdDelegate> _delegate;
  NSString *_headline;
  NSString *_body;
  NSArray<GADNativeAdImage *> *_images;
  GADNativeAdImage *_logo;
  MTRGMediaAdView *_mediaAdView;
  NSString *_callToAction;
  NSString *_advertiser;
  NSMutableDictionary *_extraAssets;
}

- (instancetype)initWithPromoBanner:(MTRGNativePromoBanner *)promoBanner
                           delegate:(id<GADMediatedNativeAdDelegate>)delegate
                        mediaAdView:(MTRGMediaAdView *)mediaAdView {
  self = [super init];
  if (self) {
    _delegate = delegate;
    if (promoBanner) {
      _headline = promoBanner.title;
      _body = promoBanner.descriptionText;
      _callToAction = promoBanner.ctaText;
      _advertiser = promoBanner.domain;
      _logo = [GADMAdapterMyTargetUtils nativeAdImageWithImageData:promoBanner.icon];

      GADNativeAdImage *image =
          [GADMAdapterMyTargetUtils nativeAdImageWithImageData:promoBanner.image];
      _images = (image != nil) ? @[ image ] : nil;

      _mediaAdView = mediaAdView;

      _extraAssets = [NSMutableDictionary new];
      [self addExtraAsset:promoBanner.advertisingLabel
                   forKey:kGADMAdapterMyTargetExtraAssetAdvertisingLabel];
      [self addExtraAsset:promoBanner.ageRestrictions
                   forKey:kGADMAdapterMyTargetExtraAssetAgeRestrictions];
    }
  }
  return self;
}

- (void)addExtraAsset:(NSString *)asset forKey:(NSString *)key {
  guard(asset && ![asset isEqualToString:@""]) else return;
  [_extraAssets setObject:asset forKey:key];
}

- (id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate {
  return _delegate;
}

- (NSDictionary *)extraAssets {
  return (_extraAssets.count > 0) ? _extraAssets : nil;
}

- (NSString *)headline {
  return _headline;
}

- (NSString *)body {
  return _body;
}

- (NSArray *)images {
  return _images;
}

- (GADNativeAdImage *)logo {
  return _logo;
}

- (NSString *)callToAction {
  return _callToAction;
}

- (NSString *)advertiser {
  return _advertiser;
}

- (UIView *)adChoicesView {
  return nil;
}

- (UIView *)mediaView {
  return _mediaAdView;
}

- (BOOL)hasVideoContent {
  return YES;
}

@end

@interface GADMAdapterMyTargetMediatedNativeAppInstallAd : NSObject <GADMediatedNativeAppInstallAd>

@end

@implementation GADMAdapterMyTargetMediatedNativeAppInstallAd {
  __weak id<GADMediatedNativeAdDelegate> _delegate;
  NSString *_headline;
  NSString *_body;
  NSArray<GADNativeAdImage *> *_images;
  GADNativeAdImage *_icon;
  MTRGMediaAdView *_mediaAdView;
  NSString *_callToAction;
  NSDecimalNumber *_starRating;
  NSMutableDictionary *_extraAssets;
}

- (instancetype)initWithPromoBanner:(MTRGNativePromoBanner *)promoBanner
                           delegate:(id<GADMediatedNativeAdDelegate>)delegate
                        mediaAdView:(MTRGMediaAdView *)mediaAdView {
  self = [super init];
  if (self) {
    _delegate = delegate;
    if (promoBanner) {
      _headline = promoBanner.title;
      _body = promoBanner.descriptionText;
      _callToAction = promoBanner.ctaText;
      _starRating = [NSDecimalNumber decimalNumberWithDecimal:promoBanner.rating.decimalValue];
      _icon = [GADMAdapterMyTargetUtils nativeAdImageWithImageData:promoBanner.icon];

      GADNativeAdImage *image =
          [GADMAdapterMyTargetUtils nativeAdImageWithImageData:promoBanner.image];
      _images = (image != nil) ? @[ image ] : nil;

      _mediaAdView = mediaAdView;

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

- (void)addExtraAsset:(NSString *)asset forKey:(NSString *)key {
  guard(asset && ![asset isEqualToString:@""]) else return;
  [_extraAssets setObject:asset forKey:key];
}

- (id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate {
  return _delegate;
}

- (NSDictionary *)extraAssets {
  return (_extraAssets.count > 0) ? _extraAssets : nil;
}

- (NSString *)headline {
  return _headline;
}

- (NSArray *)images {
  return _images;
}

- (NSString *)body {
  return _body;
}

- (GADNativeAdImage *)icon {
  return _icon;
}

- (NSString *)callToAction {
  return _callToAction;
}

- (NSDecimalNumber *)starRating {
  return _starRating;
}

- (NSString *)store {
  return nil;
}

- (NSString *)price {
  return nil;
}

- (UIView *)adChoicesView {
  return nil;
}

- (UIView *)mediaView {
  return _mediaAdView;
}

- (BOOL)hasVideoContent {
  return YES;
}

@end

@implementation GADMAdapterMyTargetMediatedNativeAd

+ (id<GADMediatedNativeAd>)
    mediatedNativeAdWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner
                                 delegate:(id<GADMediatedNativeAdDelegate>)delegate
                           autoLoadImages:(BOOL)autoLoadImages
                              mediaAdView:(MTRGMediaAdView *)mediaAdView {
  if (promoBanner.navigationType == MTRGNavigationTypeWeb) {
    guard(promoBanner.title && promoBanner.descriptionText && promoBanner.image &&
          promoBanner.ctaText && promoBanner.domain) else return nil;
    guard((autoLoadImages && promoBanner.image.image) ||
          (!autoLoadImages && promoBanner.image.url)) else return nil;
    GADMAdapterMyTargetMediatedNativeContentAd *mediatedNativeContentAd =
        [[GADMAdapterMyTargetMediatedNativeContentAd alloc] initWithPromoBanner:promoBanner
                                                                       delegate:delegate
                                                                    mediaAdView:mediaAdView];
    return mediatedNativeContentAd;
  } else if (promoBanner.navigationType == MTRGNavigationTypeStore) {
    guard(promoBanner.title && promoBanner.descriptionText && promoBanner.image &&
          promoBanner.icon && promoBanner.ctaText) else return nil;
    guard((autoLoadImages && promoBanner.image.image) ||
          (!autoLoadImages && promoBanner.image.url)) else return nil;
    guard((autoLoadImages && promoBanner.icon.image) ||
          (!autoLoadImages && promoBanner.icon.url)) else return nil;
    GADMAdapterMyTargetMediatedNativeAppInstallAd *mediatedNativeAppInstallAd =
        [[GADMAdapterMyTargetMediatedNativeAppInstallAd alloc] initWithPromoBanner:promoBanner
                                                                          delegate:delegate
                                                                       mediaAdView:mediaAdView];
    return mediatedNativeAppInstallAd;
  }
  return nil;
}

@end
