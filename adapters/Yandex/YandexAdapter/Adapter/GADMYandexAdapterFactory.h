/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@class GADMYandexBannerAdapter;
@class GADMYandexInterstitialAdapter;
@class GADMYandexRewardedAdapter;
@class GADMYandexNativeAdapter;

NS_ASSUME_NONNULL_BEGIN

@interface GADMYandexAdapterFactory : NSObject

- (GADMYandexBannerAdapter *)bannerAdapterWithCompletionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler;

- (GADMYandexInterstitialAdapter *)interstitialAdapterWithCompletionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler;

- (GADMYandexRewardedAdapter *)rewardedAdapterWithCompletionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler;

- (GADMYandexNativeAdapter *)nativeAdapterWithCompletionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler;

@end

NS_ASSUME_NONNULL_END
