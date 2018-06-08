//
//  GADMAppLovinMediatedNativeAppInstallAd.m
//  SDK Network Adapters Test App
//
//  Created by Santosh Bagadi on 4/12/18.
//  Copyright © 2018 AppLovin Corp. All rights reserved.
//

#import "GADMAppLovinMediatedNativeAppInstallAd.h"

#import "GADMAppLovinExtraAssets.h"

@interface GADMAppLovinMediatedNativeAppInstallAd () <GADMediatedNativeAdDelegate>

@property(nonatomic, strong) ALNativeAd *nativeAd;
@property(nonatomic, strong) NSArray *nativeAdImages;
@property(nonatomic, strong) GADNativeAdImage *nativeAdIcon;
@property(nonatomic, strong) UIImageView *mainImageView;
@property(nonatomic, copy) NSDictionary<NSString *, id> *extras;

@end

@implementation GADMAppLovinMediatedNativeAppInstallAd

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

- (NSDictionary *_Nullable)extraAssets {
  return self.extras;
}

- (NSString *_Nullable)body {
  return self.nativeAd.descriptionText;
}

- (NSString *_Nullable)callToAction {
  return self.nativeAd.ctaText;
}

- (NSString *_Nullable)headline {
  return self.nativeAd.title;
}

- (GADNativeAdImage *_Nullable)icon {
  return self.nativeAdIcon;
}

- (NSArray *_Nullable)images {
  return self.nativeAdImages;
}

- (NSString *_Nullable)price {
  return nil;
}

- (NSDecimalNumber *_Nullable)starRating {
  return [[NSDecimalNumber alloc] initWithFloat:self.nativeAd.starRating.floatValue];
}

- (NSString *_Nullable)store {
  return nil;
}

- (UIView *)mediaView {
  return self.mainImageView;
}

- (BOOL)hasVideoContent {
  return NO;
}

- (nullable id<GADMediatedNativeAdDelegate>)mediatedNativeAdDelegate {
  return self;
}

#pragma mark - GADMediatedNativeAdDelegate implementation

- (void)mediatedNativeAdDidRecordImpression:(id<GADMediatedNativeAd>)mediatedNativeAd {
  [self.nativeAd trackImpression];
}

- (void)mediatedNativeAd:(id<GADMediatedNativeAd>)mediatedNativeAd
    didRecordClickOnAssetWithName:(NSString *)assetName
                             view:(UIView *)view
                   viewController:(UIViewController *)viewController {
  [self.nativeAd launchClickTarget];
}

@end
