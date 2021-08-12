/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import "GADMYandexNativeAssetViewBinder.h"
#import "GADMYandexNativeAdView.h"

@interface GADMYandexNativeAssetViewBinder ()

@property (nonatomic, weak) UIView<GADMYandexNativeAdView> *adView;

@end

@implementation GADMYandexNativeAssetViewBinder

- (void)bindWithAdView:(UIView<GADMYandexNativeAdView> *)adView
{
    self.adView = adView;
}

- (void)unbind
{
    if (self.adView == nil) {
        return;
    }
    UIView<GADMYandexNativeAdView> *adView = self.adView;
    if ([adView respondsToSelector:@selector(nativeAgeLabel)]) {
        [self cleanLabel:adView.nativeAgeLabel];
    }
    if ([adView respondsToSelector:@selector(nativeReviewCountLabel)]) {
        [self cleanLabel:adView.nativeReviewCountLabel];
    }
    if ([adView respondsToSelector:@selector(nativeWarningLabel)]) {
        [self cleanLabel:adView.nativeWarningLabel];
    }
    self.adView = nil;
}

- (void)cleanLabel:(UILabel *)label
{
    label.text = nil;
}

@end
