/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@class GADMYandexAdFactory;
@class GADMYandexAdRequestConfigurator;
@class GADMYandexMediationLoadingDataProvider;

NS_ASSUME_NONNULL_BEGIN

@interface GADMYandexInterstitialAdapter : NSObject <GADMediationInterstitialAd>

- (instancetype)initWithCompletionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler;

- (instancetype)initWithCompletionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler
                      loadingDataProvider:(GADMYandexMediationLoadingDataProvider *)loadingDataProvider
                                adFactory:(GADMYandexAdFactory *)adFactory
                    adRequestConfigurator:(GADMYandexAdRequestConfigurator *)adRequestConfigurator;

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration;

@end

NS_ASSUME_NONNULL_END
