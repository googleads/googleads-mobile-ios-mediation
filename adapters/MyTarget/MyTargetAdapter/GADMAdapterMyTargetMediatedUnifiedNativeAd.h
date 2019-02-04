//
//  GADMAdapterMyTargetMediatedUnifiedNativeAd.h
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 23.05.2018.
//  Copyright © 2018 Mail.Ru Group. All rights reserved.
//

@import GoogleMobileAds;
@import MyTargetSDK;

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterMyTargetMediatedUnifiedNativeAd : NSObject <GADMediatedUnifiedNativeAd>

+ (nullable id<GADMediatedUnifiedNativeAd>)
    mediatedUnifiedNativeAdWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner
                                        nativeAd:(MTRGNativeAd *)nativeAd
                                  autoLoadImages:(BOOL)autoLoadImages
                                     mediaAdView:(MTRGMediaAdView *)mediaAdView;

@end

NS_ASSUME_NONNULL_END
