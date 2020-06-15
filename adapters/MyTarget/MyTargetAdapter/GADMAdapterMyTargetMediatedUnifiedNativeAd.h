//
//  GADMAdapterMyTargetMediatedUnifiedNativeAd.h
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 23.05.2018.
//  Copyright © 2018 Mail.Ru Group. All rights reserved.
//

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <MyTargetSDK/MyTargetSDK.h>

@interface GADMAdapterMyTargetMediatedUnifiedNativeAd : NSObject <GADMediatedUnifiedNativeAd>

/// Creates a unified native ad from the specified myTarget native ad objects and configurations.
+ (nullable id<GADMediatedUnifiedNativeAd>)
    mediatedUnifiedNativeAdWithNativePromoBanner:(nonnull MTRGNativePromoBanner *)promoBanner
                                        nativeAd:(nonnull MTRGNativeAd *)nativeAd
                                  autoLoadImages:(BOOL)autoLoadImages
                                     mediaAdView:(nonnull MTRGMediaAdView *)mediaAdView;

@end
