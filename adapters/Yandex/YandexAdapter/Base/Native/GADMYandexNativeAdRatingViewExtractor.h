/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <Foundation/Foundation.h>

@protocol YMARating;
@protocol GADMYandexNativeAdView;

@interface GADMYandexNativeAdRatingViewExtractor : NSObject

- (UIView<YMARating> *)ratingViewWithAdView:(UIView<GADMYandexNativeAdView> *)adView
                                 assetViews:(NSDictionary *)assetViews;

@end
