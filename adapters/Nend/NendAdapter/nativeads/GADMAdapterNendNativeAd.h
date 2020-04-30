//
//  GADMAdapterNendNativeAd.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <NendAd/NendAd.h>

@interface GADMAdapterNendNativeAd : NSObject <GADMediationNativeAd>

- (nonnull instancetype)initWithNativeAd:(nonnull NADNative *)ad
                                    logo:(nullable GADNativeAdImage *)logo
                                   image:(nullable GADNativeAdImage *)image;

@end
