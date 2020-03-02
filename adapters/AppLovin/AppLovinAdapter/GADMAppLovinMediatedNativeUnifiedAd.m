//
//  GADMAppLovinMediatedNativeUnifiedAd.m
//  SDK Network Adapters Test App
//
//  Created by Santosh Bagadi on 4/12/18.
//  Copyright © 2018 AppLovin Corp. All rights reserved.
//

#import "GADMAppLovinMediatedNativeUnifiedAd.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAppLovinExtraAssets.h"

@implementation GADMAppLovinMediatedNativeUnifiedAd {
  /// AppLovin Native object used to request an ad.
  ALNativeAd *_nativeAd;

  /// Array of GADNativeAdImage objects.
  NSArray<GADNativeAdImage *> *_nativeAdImages;

  /// Icon image.
  GADNativeAdImage *_nativeAdIcon;

  /// Main image view sent to Google Mobile Ads SDK.
  UIImageView *_mainImageView;
}

- (nonnull instancetype)initWithNativeAd:(nonnull ALNativeAd *)nativeAd
                               mainImage:(nonnull UIImage *)mainImage
                               iconImage:(nonnull UIImage *)iconImage {
  self = [super init];
  if (self) {
    _nativeAd = nativeAd;
    _mainImageView = [[UIImageView alloc] initWithImage:mainImage];
    _nativeAdImages = @[ [[GADNativeAdImage alloc] initWithImage:mainImage] ];
    _nativeAdIcon = [[GADNativeAdImage alloc] initWithImage:iconImage];
  }
  return self;
}

- (nullable NSString *)headline {
  return _nativeAd.title;
}

- (nullable NSString *)body {
  return _nativeAd.descriptionText;
}

- (nullable NSString *)callToAction {
  return _nativeAd.ctaText;
}

- (nullable GADNativeAdImage *)icon {
  return _nativeAdIcon;
}

- (nullable NSArray<GADNativeAdImage *> *)images {
  return _nativeAdImages;
}

- (nullable NSDecimalNumber *)starRating {
  return [[NSDecimalNumber alloc] initWithFloat:_nativeAd.starRating.floatValue];
}

- (nullable NSString *)advertiser {
  return nil;
}

- (nullable NSString *)store {
  return nil;
}

- (nullable NSString *)price {
  return nil;
}

- (nullable NSDictionary<NSString *, id> *)extraAssets {
  NSMutableDictionary<NSString *, id> *_extras = [[NSMutableDictionary alloc] init];
  GADMAdapterAppLovinMutableDictionarySetObjectForKey(_extras, GADMAppLovinAdID,
                                                      _nativeAd.adIdNumber);
  GADMAdapterAppLovinMutableDictionarySetObjectForKey(_extras, GADMAppLovinCaption,
                                                      _nativeAd.captionText);
  return _extras;
}

- (BOOL)hasVideoContent {
  return NO;
}

- (nullable UIView *)mediaView {
  return _mainImageView;
}

- (CGFloat)mediaContentAspectRatio {
  if (_mainImageView.frame.size.height) {
    return _mainImageView.frame.size.width / _mainImageView.frame.size.height;
  }
  return 0.0f;
}

- (void)didRecordImpression {
  [_nativeAd trackImpression];
}

- (void)didRecordClickOnAssetWithName:(GADUnifiedNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  [_nativeAd launchClickTarget];
}

@end
