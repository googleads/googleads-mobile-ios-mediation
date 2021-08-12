/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <UIKit/UIKit.h>

@protocol GADMYandexNativeAdView;

@interface GADMYandexNativeAdViewProvider : NSObject

- (UIView<GADMYandexNativeAdView> *)adViewWithView:(UIView *)view;

@end
