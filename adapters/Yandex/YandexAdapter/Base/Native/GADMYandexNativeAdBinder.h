/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileNativeAds.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <Foundation/Foundation.h>

@protocol YMANativeAd;
@protocol GADMYandexNativeAdAssetViewsExtracting;
@protocol GADMediatedUnifiedNativeAd;
@class GADMYandexNativeAdAssetViewsExtractor;
@class GADMYandexCallToActionBinder;
@class GADMYandexMediaViewBinder;
@class GADMYandexNativeAssetViewBinder;
@class GADMYandexNativeAdViewProvider;

@interface GADMYandexNativeAdBinder : NSObject

- (instancetype)initWithNativeAd:(id<YMANativeAd>)nativeAd
             assetViewsExtractor:(id<GADMYandexNativeAdAssetViewsExtracting>)assetViewsExtractor;

- (instancetype)initWithNativeAd:(id<YMANativeAd>)nativeAd
             assetViewsExtractor:(id<GADMYandexNativeAdAssetViewsExtracting>)assetViewsExtractor
              callToActionBinder:(GADMYandexCallToActionBinder *)callToActionBinder
                 mediaViewBinder:(GADMYandexMediaViewBinder *)mediaViewBinder
           yandexAssetViewBinder:(GADMYandexNativeAssetViewBinder *)yandexAssetViewBinder
                  adViewProvider:(GADMYandexNativeAdViewProvider *)adViewProvider;

- (void)bindToView:(UIView *)view
        adMobAd:(id<GADMediatedUnifiedNativeAd>)adMobAd
        yandexMediaView:(YMANativeMediaView *)mediaView
        feedbackButton:(UIButton *)feedbackButton
        clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
        nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews;

- (void)unbind;

@end
