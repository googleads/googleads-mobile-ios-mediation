/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <YandexMobileAds/YandexMobileNativeAds.h>
#import "GADMYandexNativeAdAssetViewsExtracting.h"

@class GADMYandexNativeAdRatingViewExtractor;
@class GADMYandexNativeAdViewProvider;

@interface GADMYandexNativeAdAssetViewsExtractor : NSObject <GADMYandexNativeAdAssetViewsExtracting>

- (instancetype)initWithRatingViewExtractor:(GADMYandexNativeAdRatingViewExtractor *)ratingViewExtractor
                             adViewProvider:(GADMYandexNativeAdViewProvider *)adViewProvider;

@end
