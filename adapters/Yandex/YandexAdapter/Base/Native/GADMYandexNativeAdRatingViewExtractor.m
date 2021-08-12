/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileNativeAds.h>
#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "GADMYandexNativeAdRatingViewExtractor.h"
#import "GADMYandexNativeAdView.h"

@implementation GADMYandexNativeAdRatingViewExtractor

- (UIView<YMARating> *)ratingViewWithAdView:(UIView<GADMYandexNativeAdView> *)adView
                                 assetViews:(NSDictionary *)assetViews
{
    return [self ratingViewWithAdView:adView] ?: [self ratingViewWithAssetViews:assetViews];
}

- (UIView<YMARating> *)ratingViewWithAdView:(UIView<GADMYandexNativeAdView> *)adView
{
    UIView<YMARating> *ratingView = nil;
    if ([adView respondsToSelector:@selector(nativeRatingView)]) {
        ratingView = adView.nativeRatingView;
    }
    return ratingView;
}

- (UIView<YMARating> *)ratingViewWithAssetViews:(NSDictionary *)assetViews
{
    UIView<YMARating> *ratingView = nil;
    UIView *starRatingAssetView = assetViews[GADNativeStarRatingAsset];
    if ([starRatingAssetView conformsToProtocol:@protocol(YMARating)]) {
        ratingView = (UIView<YMARating> *)starRatingAssetView;
    }
    return ratingView;
}

@end
