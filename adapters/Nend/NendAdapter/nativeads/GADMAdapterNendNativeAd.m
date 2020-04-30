//
//  GADMAdapterNendNativeAd.m
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import "GADMAdapterNendNativeAd.h"

#import "GADMAdapterNend.h"
#import "GADMAdapterNendConstants.h"
#import "GADMAdapterNendNativeAdLoader.h"

@interface GADMAdapterNendNativeAd () <NADNativeDelegate>

@end

@implementation GADMAdapterNendNativeAd {
  /// nend native ad.
  NADNative *_nativeAd;

  /// Icon image.
  GADNativeAdImage *_mappedIcon;

  /// Array of Images.
  NSArray *_mappedImages;

  /// nend AdChoices view.
  UILabel *_advertisingExplicitlyView;

  /// nend media view.
  UIImageView *_imageView;

  /// Media content aspect ratio.
  CGFloat _mediaContentAspectRatio;
}

- (nonnull instancetype)initWithNormal:(nonnull NADNative *)ad
                                  logo:(nullable GADNativeAdImage *)logo
                                 image:(nullable GADNativeAdImage *)image {
  self = [super init];
  if (self) {
    _nativeAd = ad;
    _nativeAd.delegate = self;
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

- (nullable NSArray *)images {
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

- (nullable NSDictionary *)extraAssets {
  return nil;
}

- (nullable UIView *)adChoicesView {
  return _advertisingExplicitlyView;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  [_nativeAd activateAdView:view withPrLabel:self.adChoicesView];
}

- (BOOL)handlesUserImpressions {
  return YES;
}

- (BOOL)handlesUserClicks {
  return YES;
}

#pragma mark - NADNativeDelegate
- (void)nadNativeDidImpression:(nonnull NADNative *)ad {
  // Note : Adapter report click event here,
  //       but Google-Mobile-Ads-SDK does'n send event to App...
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordImpression:self];
}

- (void)nadNativeDidClickAd:(nonnull NADNative *)ad {
  // Note : Adapter report click event here,
  //       but Google-Mobile-Ads-SDK does'n send event to App...
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdDidRecordClick:self];

  // It's OK to reach event to App.
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

- (void)nadNativeDidClickInformation:(nonnull NADNative *)ad {
  [GADMediatedUnifiedNativeAdNotificationSource mediatedNativeAdWillLeaveApplication:self];
}

@end
