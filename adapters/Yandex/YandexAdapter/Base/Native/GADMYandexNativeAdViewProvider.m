/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import "GADMYandexNativeAdViewProvider.h"
#import "GADMYandexNativeAdView.h"

@implementation GADMYandexNativeAdViewProvider

- (UIView<GADMYandexNativeAdView> *)adViewWithView:(UIView *)view
{
    UIView<GADMYandexNativeAdView> *adView = nil;
    if ([view conformsToProtocol:@protocol(GADMYandexNativeAdView)]) {
        adView = (UIView<GADMYandexNativeAdView> *)view;
    }
    else {
        NSLog(@"Ad view must conform to GADMYandexNativeAdView protocol for Yandex Ad");
    }
    return adView;
}

@end
