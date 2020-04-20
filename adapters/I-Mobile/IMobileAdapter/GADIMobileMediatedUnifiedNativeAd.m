// Copyright 2019 Google Inc.
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

#import "GADIMobileMediatedUnifiedNativeAd.h"
#import "GADMAdapterIMobileConstants.h"

@implementation GADIMobileMediatedUnifiedNativeAd {
  /// i-mobile native ad.
  ImobileSdkAdsNativeObject *_iMobileNativeAd;

  /// Ad image.
  GADNativeAdImage *_adImage;

  /// Ad image view.
  UIImageView *_adImageView;
}

- (nonnull instancetype)initWithIMobileNativeAd:(nonnull ImobileSdkAdsNativeObject *)iMobileNativeAd
                                          image:(nonnull UIImage *)image {
  // Initialize fields.
  self = [super init];
  if (self) {
    _iMobileNativeAd = iMobileNativeAd;
    _adImage = [[GADNativeAdImage alloc] initWithImage:image];
    _adImageView = [[UIImageView alloc] initWithImage:image];
  }
  return self;
}

#pragma mark - GADMediatedUnifiedNativeAd

- (NSString *)headline {
  return [_iMobileNativeAd getAdTitle];
}

- (NSArray<GADNativeAdImage *> *)images {
  return @[ _adImage ];
}

- (NSString *)body {
  return [_iMobileNativeAd getAdDescription];
}

- (GADNativeAdImage *)icon {
  // Creates a 40 x 40 transparent image which acts as a placeholder image as the I-Mobile
  // SDK does not send any image asset for the icon.
  UIGraphicsImageRenderer *renderer =
      [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(40, 40)];
  UIImage *image =
      [renderer imageWithActions:^(UIGraphicsImageRendererContext *_Nonnull rendererContext){
      }];
  return [[GADNativeAdImage alloc] initWithImage:image];
}

- (NSString *)callToAction {
  return kGADMAdapterIMobileCallToAction;
}

- (NSDecimalNumber *)starRating {
  return nil;
}

- (NSString *)store {
  return nil;
}

- (NSString *)price {
  return nil;
}

- (NSString *)advertiser {
  return [_iMobileNativeAd getAdSponsored];
}

- (NSDictionary<NSString *, id> *)extraAssets {
  return nil;
}

- (UIView *)adChoicesView {
  return nil;
}

- (UIView *)mediaView {
  return _adImageView;
}

- (CGFloat)mediaContentAspectRatio {
  if (_adImageView.image.size.height > 0) {
    return _adImageView.image.size.width / _adImageView.image.size.height;
  }
  return 0.0f;
}

- (void)didRecordClickOnAssetWithName:(GADUnifiedNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {
  [_iMobileNativeAd sendClick];
}

@end
