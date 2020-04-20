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

@property(nonatomic, strong) NADNative *nativeAd;
@property(nonatomic, strong) GADNativeAdImage *mappedIcon;
@property(nonatomic, strong) NSArray *mappedImages;
@property(nonatomic, strong) UILabel *advertisingExplicitlyView;
@property(nonatomic, strong) UIImageView *imageView;
@property(nonatomic) CGFloat mediaContentAspectRatio;

@end

@implementation GADMAdapterNendNativeAd

- (nonnull instancetype)initWithNormal:(nonnull NADNative *)ad
                                  logo:(nullable GADNativeAdImage *)logo
                                 image:(nullable GADNativeAdImage *)image {
  self = [super init];
  if (self) {
    _nativeAd = ad;
    _nativeAd.delegate = self;
    _advertisingExplicitlyView = [UILabel new];
    _advertisingExplicitlyView.text =
        [_nativeAd prTextForAdvertisingExplicitly:NADNativeAdvertisingExplicitlyPR];
    _imageView = [UIImageView new];

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

- (UIView *)mediaView {
  return self.imageView;
}

- (CGFloat)mediaContentAspectRatio {
  return self.mediaContentAspectRatio;
}

- (nullable NSString *)advertiser {
  return self.nativeAd.promotionName;
}

- (nullable NSString *)headline {
  return self.nativeAd.shortText;
}

- (nullable NSArray *)images {
  return self.mappedImages;
}

- (nullable NSString *)body {
  return self.nativeAd.longText;
}

- (nullable GADNativeAdImage *)icon {
  return self.mappedIcon;
}

- (nullable NSString *)callToAction {
  return self.nativeAd.actionButtonText;
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
  return self.advertisingExplicitlyView;
}

- (void)didRenderInView:(nonnull UIView *)view
       clickableAssetViews:
           (nonnull NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)clickableAssetViews
    nonclickableAssetViews:
        (nonnull NSDictionary<GADUnifiedNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
            viewController:(nonnull UIViewController *)viewController {
  [self.nativeAd activateAdView:view withPrLabel:self.adChoicesView];
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
