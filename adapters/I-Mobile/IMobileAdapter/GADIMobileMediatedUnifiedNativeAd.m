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

/// Mapper for GADMediatedUnifiedNativeAd.
@interface GADIMobileMediatedUnifiedNativeAd ()

/// i-mobile native ad.
@property(nonatomic, strong) ImobileSdkAdsNativeObject *iMobileNativeAd;

/// Ad image.
@property(nonatomic, strong) GADNativeAdImage *adImage;

@end

@implementation GADIMobileMediatedUnifiedNativeAd

/// Initialize.
- (instancetype)initWithIMobileNativeAd:(ImobileSdkAdsNativeObject *)iMobileNativeAd
                                  image:(UIImage*)image {

    // Validate arguments.
    if (!iMobileNativeAd || !image) {
        return nil;
    }

    // Initialize fields.
    self = [super init];
    if (self) {
        self.iMobileNativeAd = iMobileNativeAd;
        self.adImage = [[GADNativeAdImage alloc] initWithImage:image];
    }
    return self;
}

#pragma mark - GADMediatedUnifiedNativeAd

- (NSString *)headline {
    return [self.iMobileNativeAd getAdTitle];
}

- (NSArray<GADNativeAdImage *> *)images {
    return @[self.adImage];
}

- (NSString *)body {
    return [self.iMobileNativeAd getAdDescription];
}

- (GADNativeAdImage *)icon {
    return nil;
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
    return [self.iMobileNativeAd getAdSponsored];
}

- (NSDictionary<NSString *, id> *)extraAssets {
    return nil;
}

- (void)didRecordClickOnAssetWithName:(GADUnifiedNativeAssetIdentifier)assetName
                                 view:(UIView *)view
                       viewController:(UIViewController *)viewController {

    [self.iMobileNativeAd sendClick];
}

@end
