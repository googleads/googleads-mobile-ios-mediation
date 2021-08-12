/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@class YMANativeMediaView;
@protocol YMANativeAd;

typedef NSDictionary<NSString *, UIView *> GADMYandexAssetViews;

@protocol GADMYandexNativeAdAssetViewsExtracting <NSObject>

- (GADMYandexAssetViews *)assetViewsInAdView:(UIView *)adView
                           yandexMediaView:(YMANativeMediaView *)yandexMediaView
                              feedbackButton:(UIButton *)feedbackButton
                       clickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)clickableAssetViews
                    nonclickableAssetViews:(NSDictionary<GADNativeAssetIdentifier, UIView *> *)nonclickableAssetViews
                                    nativeAd:(id<YMANativeAd>)nativeAd;

@end
