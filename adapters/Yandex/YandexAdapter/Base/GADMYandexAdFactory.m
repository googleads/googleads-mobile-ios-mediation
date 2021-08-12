/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileAds.h>
#import "GADMYandexAdFactory.h"

@implementation GADMYandexAdFactory

- (YMARewardedAd *)rewardedAdWithBlockID:(NSString *)blockID
{
    return [[YMARewardedAd alloc] initWithBlockID:blockID];
}

- (YMAAdView *)bannerAdViewWithBlockID:(NSString *)blockID adSize:(YMAAdSize *)adSize
{
    return [[YMAAdView alloc] initWithBlockID:blockID adSize:adSize];
}

- (YMAInterstitialAd *)interstitialAdWithBlockID:(NSString *)blockID
{
    return [[YMAInterstitialAd alloc] initWithBlockID:blockID];
}

@end
