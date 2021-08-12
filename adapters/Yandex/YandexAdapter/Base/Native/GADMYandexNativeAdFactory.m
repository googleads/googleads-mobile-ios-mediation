/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileNativeAds.h>
#import "GADMYandexNativeAdFactory.h"
#import "GADMYandexNativeAd.h"
#import "GADMYandexNativeAdBinder.h"
#import "GADMYandexNativeAdAssetViewsExtractor.h"

@implementation GADMYandexNativeAdFactory

- (GADMYandexNativeAd *)adMobNativeAdWithNativeAd:(id<YMANativeAd>)ad
{
    GADMYandexNativeAdAssetViewsExtractor *assetViewsExtractor = [[GADMYandexNativeAdAssetViewsExtractor alloc] init];
    GADMYandexNativeAdBinder *binder =
        [[GADMYandexNativeAdBinder alloc] initWithNativeAd:ad assetViewsExtractor:assetViewsExtractor];
    return [[GADMYandexNativeAd alloc] initWithNativeAd:ad binder:binder];
}

@end
