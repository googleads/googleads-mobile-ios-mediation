/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <YandexMobileAds/YandexMobileNativeAds.h>

@class GADMYandexNativeAdBinder;
@class GADMYandexNativeAdImageFactory;
@class GADMYandexNativeAdViewProvider;
@class GADMYandexFeedbackButtonConfigurator;

@interface GADMYandexNativeAd : NSObject <GADMediationNativeAd>

@property (nonatomic, weak) id<GADMediationNativeAdEventDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithNativeAd:(id<YMANativeAd>)nativeAd binder:(GADMYandexNativeAdBinder *)binder;

- (instancetype)initWithBinder:(GADMYandexNativeAdBinder *)binder
          nativeAdImageFactory:(GADMYandexNativeAdImageFactory *)nativeAdImageFactory
                adViewProvider:(GADMYandexNativeAdViewProvider *)adViewProvider
                      nativeAd:(id<YMANativeAd>)nativeAd
               yandexMediaView:(YMANativeMediaView *)mediaView
                feedbackButton:(UIButton *)feedbackButton
     feedbackButtonConfiguator:(GADMYandexFeedbackButtonConfigurator *)feedbackButtonConfiguator;

@end
