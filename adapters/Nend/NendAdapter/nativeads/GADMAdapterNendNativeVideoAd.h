//
//  GADMAdapterNendNativeVideoAd.h
//  NendAdapter
//
//  Copyright © 2019 FAN Communications. All rights reserved.
//

#import <Foundation/Foundation.h>
@import GoogleMobileAds;
@import NendAd;

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterNendNativeVideoAd : NSObject <GADMediationNativeAd>

- (instancetype)initWithVideo:(NADNativeVideo *)ad;

@end

NS_ASSUME_NONNULL_END
