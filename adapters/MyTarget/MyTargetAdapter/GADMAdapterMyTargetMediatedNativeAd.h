//
//  GADMAdapterMyTargetMediatedNativeAd.h
//  MyTargetAdapter
//
//  Created by Andrey Seredkin on 29.09.17.
//  Copyright © 2017 Mail.Ru Group. All rights reserved.
//

@import GoogleMobileAds;
@import MyTargetSDK;

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterMyTargetMediatedNativeAd : NSObject

+ (nullable id<GADMediatedNativeAd>)mediatedNativeAdWithNativePromoBanner:(MTRGNativePromoBanner *)promoBanner
																 delegate:(nullable id<GADMediatedNativeAdDelegate>)delegate
														   autoLoadImages:(BOOL)autoLoadImages
															  mediaAdView:(MTRGMediaAdView *)mediaAdView;

@end

NS_ASSUME_NONNULL_END
