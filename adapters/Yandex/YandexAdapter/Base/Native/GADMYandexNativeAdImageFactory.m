/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileNativeAds.h>
#import "GADMYandexNativeAdImageFactory.h"

@implementation GADMYandexNativeAdImageFactory

- (GADNativeAdImage *)imageWithYandexNativeAdImage:(YMANativeAdImage *)image
{
    GADNativeAdImage *nativeAdImage = nil;
    UIImage *imageValue = image.imageValue;
    if (imageValue != nil) {
        nativeAdImage = [[GADNativeAdImage alloc] initWithImage:imageValue];
    }
    return nativeAdImage;
}

@end
