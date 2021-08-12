/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import "GADMYandexAdapterVersionProvider.h"
#import "GADMYandexVersion.h"

@implementation GADMYandexAdapterVersionProvider

+ (instancetype)sharedInstance
{
    static GADMYandexAdapterVersionProvider *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSString *)adapterVersion
{
    return [NSString stringWithFormat:@"%d.%d.%d", GADM_YANDEX_ADMOB_VERSION_MAJOR, GADM_YANDEX_ADMOB_VERSION_MINOR,
            GADM_YANDEX_ADMOB_VERSION_PATCH  * 100 + GADM_YANDEX_ADMOB_VERSION_ADAPTER_PATCH];
}

- (GADVersionNumber)GADAdapterVersion
{
    return (GADVersionNumber){GADM_YANDEX_ADMOB_VERSION_MAJOR, GADM_YANDEX_ADMOB_VERSION_MINOR,
        GADM_YANDEX_ADMOB_VERSION_PATCH * 100 + GADM_YANDEX_ADMOB_VERSION_ADAPTER_PATCH};
}

@end
