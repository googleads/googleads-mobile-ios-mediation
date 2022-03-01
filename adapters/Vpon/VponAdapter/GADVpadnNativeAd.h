//
//  GADVpadnNativeAd.h
//  VponAdapter
//
//  Created by EricChien on 2018/10/24.
//  Copyright © 2018 Vpon. All rights reserved.
//

@import Foundation;
@import GoogleMobileAds;
@import VpadnSDKAdKit;

NS_ASSUME_NONNULL_BEGIN

@class GADVpadnNativeAd;

@protocol GADVpadnNativeAdDelegate <NSObject>

- (void) onGADVpadnNativeAdDidImageLoaded:(GADVpadnNativeAd *)mediatedAd;

@end

@interface GADVpadnNativeAd : NSObject <GADMediatedUnifiedNativeAd>

- (null_unspecified instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithNativeAd:(VpadnNativeAd *)nativeAd adOptions:(GADNativeAdViewAdOptions *)options delegate:(id<GADVpadnNativeAdDelegate>)delegate NS_DESIGNATED_INITIALIZER;

- (void) loadImages;

@end

NS_ASSUME_NONNULL_END
