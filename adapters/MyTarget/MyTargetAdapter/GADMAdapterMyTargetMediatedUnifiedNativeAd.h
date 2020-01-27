//
//  GADMAdapterMyTargetMediatedUnifiedNativeAd.h
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 23.05.2018.
//  Copyright © 2018 Mail.Ru Group. All rights reserved.
//

@import GoogleMobileAds;
@import MyTargetSDK;

@interface GADMAdapterMyTargetMediatedUnifiedNativeAd : NSObject <GADMediatedUnifiedNativeAd>

+ (nullable id<GADMediatedUnifiedNativeAd>)
    mediatedUnifiedNativeAdWithNativePromoBanner:(nonnull MTRGNativePromoBanner *)promoBanner
                                        nativeAd:(nonnull MTRGNativeAd *)nativeAd
                                  autoLoadImages:(BOOL)autoLoadImages
                                     mediaAdView:(nonnull MTRGMediaAdView *)mediaAdView;

@end
