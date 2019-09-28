//
//  GADMAppLovinMediatedNativeUnifiedAd.m
//  SDK Network Adapters Test App
//
//  Created by Santosh Bagadi on 4/12/18.
//  Copyright © 2018 AppLovin Corp. All rights reserved.
//

#import "GADMAppLovinMediatedNativeUnifiedAd.h"

#import "GADMAppLovinExtraAssets.h"

@interface GADMAppLovinMediatedNativeUnifiedAd ()

@property(nonatomic, strong) ALNativeAd *nativeAd;
@property(nonatomic, strong) NSArray *nativeAdImages;
@property(nonatomic, strong) GADNativeAdImage *nativeAdIcon;
@property(nonatomic, strong) UIImageView *mainImageView;
@property(nonatomic, copy) NSDictionary<NSString *, id> *extras;

@end

@implementation GADMAppLovinMediatedNativeUnifiedAd

- (instancetype)initWithNativeAd:(ALNativeAd *)nativeAd {
  if (!nativeAd) {
    return nil;
  }

  self = [super init];
  if (self) {
    self.nativeAd = nativeAd;
    UIImage *downloadedImage =
        [UIImage imageWithData:[NSData dataWithContentsOfURL:self.nativeAd.imageURL]];
    GADNativeAdImage *image = [[GADNativeAdImage alloc] initWithImage:downloadedImage];
    self.nativeAdImages = @[ image ];
    UIImage *downloadedIcon =
        [UIImage imageWithData:[NSData dataWithContentsOfURL:self.nativeAd.iconURL]];
    self.nativeAdIcon = [[GADNativeAdImage alloc] initWithImage:downloadedIcon];
    self.mainImageView = [[UIImageView alloc] initWithImage:downloadedImage];

    NSMutableDictionary *extraAssets =
        [NSMutableDictionary dictionaryWithObject:self.nativeAd.adIdNumber forKey:GADMAppLovinAdID];
    if (self.nativeAd.captionText) {
      extraAssets[GADMAppLovinCaption] = self.nativeAd.captionText;
    }
    self.extras = extraAssets;
  }
  return self;
}

- (NSString *)headline {
  return self.nativeAd.title;
}

- (NSString *)body {
  return self.nativeAd.descriptionText;
}

- (NSString *)callToAction {
  return self.nativeAd.ctaText;
}

- (GADNativeAdImage *)icon {
  return self.nativeAdIcon;
}

- (NSArray<GADNativeAdImage *> *)images {
  return self.nativeAdImages;
}

- (NSDecimalNumber *)starRating {
  return [[NSDecimalNumber alloc] initWithFloat:self.nativeAd.starRating.floatValue];
}

- (NSString *)advertiser {
  return nil;
}

- (NSString *)store {
  return nil;
}

- (NSString *)price {
  return nil;
}

- (NSDictionary<NSString *, id> *)extraAssets {
  return self.extras;
}

- (BOOL)hasVideoContent {
  return NO;
}

- (CGFloat)mediaContentAspectRatio {
  if (self.mainImageView) {
    return self.mainImageView.frame.size.width / self.mainImageView.frame.size.height;
  }
  return 0.0f;
}

- (UIView *)mediaView {
  return self.mainImageView;
}

- (void)didRecordImpression {
  [self.nativeAd trackImpression];
}

- (void)didRecordClickOnAssetWithName:(GADUnifiedNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  [self.nativeAd launchClickTarget];
}

@end
