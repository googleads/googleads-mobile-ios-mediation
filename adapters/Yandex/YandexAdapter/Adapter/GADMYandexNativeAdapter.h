/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@class GADMYandexMediationLoadingDataProvider;
@class GADMYandexNativeAdLoaderFactory;
@class GADMYandexNativeAdFactory;
@class GADMYandexNativeRequestConfigurationFactory;

NS_ASSUME_NONNULL_BEGIN

@interface GADMYandexNativeAdapter : NSObject

- (instancetype)initWithCompletionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler;

- (instancetype)initWithCompletionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler
                      loadingDataProvider:(GADMYandexMediationLoadingDataProvider *)loadingDataProvider
                            loaderFactory:(GADMYandexNativeAdLoaderFactory *)loaderFactory
                                adFactory:(GADMYandexNativeAdFactory *)adFactory
              requestConfigurationFactory:(GADMYandexNativeRequestConfigurationFactory *)requestConfigurationFactory;

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration;

@end

NS_ASSUME_NONNULL_END
