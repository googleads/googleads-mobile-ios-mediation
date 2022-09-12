//
//  GADMAdapterNendNativeAd.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendNativeAd.h"

#import "GADMAdapterNend.h"
#import "GADMAdapterNendConstants.h"

@implementation GADMAdapterNendNativeAd {
  /// nend native ad.
  NADNative *_nativeAd;

  /// Icon image.
  GADNativeAdImage *_mappedIcon;

  /// Array of Images.
  NSArray<GADNativeAdImage *> *_mappedImages;

  /// nend AdChoices view.
  UILabel *_advertisingExplicitlyView;

  /// nend media view.
  UIImageView *_imageView;

  /// Media content aspect ratio.
  CGFloat _mediaContentAspectRatio;
}

- (nonnull instancetype)initWithNativeAd:(nonnull NADNative *)ad
                                    logo:(nullable GADNativeAdImage *)logo
                                   image:(nullable GADNativeAdImage *)image {
  self = [super init];
  if (self) {
    _nativeAd = ad;
    _advertisingExplicitlyView = [[UILabel alloc] init];
    _advertisingExplicitlyView.text =
        [_nativeAd prTextForAdvertisingExplicitly:NADNativeAdvertisingExplicitlyPR];
    _imageView = [[UIImageView alloc] init];

    if (logo) {
      _mappedIcon = logo;
    }

    if (image) {
      _mappedImages = [NSArray arrayWithObject:image];
      _imageView.image = image.image;
      _mediaContentAspectRatio = image.image.size.height / image.image.size.width;
    } else {
      _mediaContentAspectRatio = 0.0f;
    }
  }
  return self;
}

- (BOOL)hasVideoContent {
  return false;
}

- (nullable UIView *)mediaView {
  return _imageView;
}

- (CGFloat)mediaContentAspectRatio {
  return _mediaContentAspectRatio;
}

- (nullable NSString *)advertiser {
  return _nativeAd.promotionName;
}

- (nullable NSString *)headline {
  return _nativeAd.shortText;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  return _mappedImages;
}

- (nullable NSString *)body {
  return _nativeAd.longText;
}

- (nullable GADNativeAdImage *)icon {
  return _mappedIcon;
}

- (nullable NSString *)callToAction {
  return _nativeAd.actionButtonText;
}

- (nullable NSDecimalNumber *)starRating {
  return nil;
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSString *)price {
  return nil;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  return nil;
}

- (nullable UIView *)adChoicesView {
  return _advertisingExplicitlyView;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  [_nativeAd activateAdView:view withPrLabel:self.adChoicesView];
}

- (BOOL)handlesUserImpressions {
  return YES;
}

- (BOOL)handlesUserClicks {
  return YES;
}

@end
