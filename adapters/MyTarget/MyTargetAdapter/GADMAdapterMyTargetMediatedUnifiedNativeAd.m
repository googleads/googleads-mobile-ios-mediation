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

#define guard(CONDITION) \
  if (CONDITION) {       \
  }

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
    mediatedUnifiedNativeAdWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner
                                        nativeAd:(MTRGNativeAd *)nativeAd
                                  autoLoadImages:(BOOL)autoLoadImages
                                     mediaAdView:(MTRGMediaAdView *)mediaAdView {
  guard(promoBanner.title && promoBanner.descriptionText && promoBanner.image &&
        promoBanner.ctaText) else return nil;
  guard((autoLoadImages && promoBanner.image.image) ||
        (!autoLoadImages && promoBanner.image.url)) else return nil;
  if (promoBanner.navigationType == MTRGNavigationTypeWeb) {
    guard(promoBanner.domain) else return nil;
  } else if (promoBanner.navigationType == MTRGNavigationTypeStore) {
    guard(promoBanner.icon) else return nil;
    guard((autoLoadImages && promoBanner.icon.image) ||
          (!autoLoadImages && promoBanner.icon.url)) else return nil;
  }
  return
      [[GADMAdapterMyTargetMediatedUnifiedNativeAd alloc] initWithNativePromoBanner:promoBanner
                                                                           nativeAd:nativeAd
                                                                     autoLoadImages:autoLoadImages
                                                                        mediaAdView:mediaAdView];
}

- (nullable id<GADMediatedUnifiedNativeAd>)
    initWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner
                     nativeAd:(MTRGNativeAd *)nativeAd
               autoLoadImages:(BOOL)autoLoadImages
                  mediaAdView:(MTRGMediaAdView *)mediaAdView {
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

- (void)addExtraAsset:(NSString *)asset forKey:(NSString *)key {
  guard(asset && ![asset isEqualToString:@""]) else return;
  [_extraAssets setObject:asset forKey:key];
}

- (NSString *)headline {
  return _headline;
}

- (NSArray<GADNativeAdImage *> *)images {
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

- (NSString *)advertiser {
  return _advertiser;
}

- (NSDictionary<NSString *, id> *)extraAssets {
  return _extraAssets;
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

- (CGFloat)mediaContentAspectRatio {
  return _mediaAdView.aspectRatio;
}

- (void)didRenderInView:(UIView *)view
       clickableAssetViews:
           (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(UIViewController *)viewController {
  MTRGLogInfo();
  guard(_nativeAd) else return;

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

- (void)didRecordClickOnAssetWithName:(GADUnifiedNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  // do nothing
}

- (void)didUntrackView:(nullable UIView *)view {
  MTRGLogInfo();
  guard(_nativeAd) else return;
  [_nativeAd unregisterView];
}

@end
