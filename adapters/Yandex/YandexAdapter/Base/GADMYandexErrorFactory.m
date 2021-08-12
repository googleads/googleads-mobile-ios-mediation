/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import "GADMYandexErrorFactory.h"

NSString *const kGADMYandexMediationErrorDomain = @"com.yandex.mobile.YandexMobileAds.AdMob";

@implementation GADMYandexErrorFactory

+ (NSError *)nilBlockIDError
{
    NSString *description = @"BlockID cannot be nil";
    return [self errorWithCode:kGADMYandexMediationErrorCodeNilBlockID description:description];
}

+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description
{
    return [NSError errorWithDomain:kGADMYandexMediationErrorDomain
                               code:code
                           userInfo:@{ NSLocalizedDescriptionKey : description }];
}


@end
