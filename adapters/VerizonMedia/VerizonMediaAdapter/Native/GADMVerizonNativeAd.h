//
//  GADMVerizonNativeAd.h
//
// @copyright Copyright (c) 2019 Verizon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <VerizonAdsNativePlacement/VerizonAdsNativePlacement.h>

NS_ASSUME_NONNULL_BEGIN

@interface GADMVerizonNativeAd : NSObject<GADMediatedUnifiedNativeAd, GADMediatedNativeAd>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithNativeAd:(VASNativeAd *)nativeAd NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
