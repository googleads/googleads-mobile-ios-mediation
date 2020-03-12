//
//  GADMAdapterNendNativeAd.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;
@import NendAd;

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterNendNativeAd : NSObject <GADMediationNativeAd>

- (instancetype)initWithNormal:(nonnull NADNative *)ad
                          logo:(nullable GADNativeAdImage *)logo
                         image:(nullable GADNativeAdImage *)image;

@end

NS_ASSUME_NONNULL_END
