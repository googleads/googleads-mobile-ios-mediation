/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import "GADMYandexAdapterFactory.h"
#import "GADMYandexBannerAdapter.h"
#import "GADMYandexInterstitialAdapter.h"
#import "GADMYandexRewardedAdapter.h"
#import "GADMYandexNativeAdapter.h"

@implementation GADMYandexAdapterFactory

- (GADMYandexBannerAdapter *)bannerAdapterWithCompletionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler
{
    return [[GADMYandexBannerAdapter alloc] initWithCompletionHandler:completionHandler];
}

- (GADMYandexInterstitialAdapter *)interstitialAdapterWithCompletionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler
{
    return [[GADMYandexInterstitialAdapter alloc] initWithCompletionHandler:completionHandler];
}

- (GADMYandexRewardedAdapter *)rewardedAdapterWithCompletionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler
{
    return [[GADMYandexRewardedAdapter alloc] initWithCompletionHandler:completionHandler];
}

- (GADMYandexNativeAdapter *)nativeAdapterWithCompletionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler
{
    return [[GADMYandexNativeAdapter alloc] initWithCompletionHandler:completionHandler];
}

@end
