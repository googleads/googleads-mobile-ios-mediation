/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <GoogleMobileAds/GoogleMobileAds.h>
#import "GADMYandexMediationLoadingDataProvider.h"
#import "GADMYandexMediationLoadingData.h"

static NSString *const kGADMYandexMediationLoadingDataBlockID = @"blockID";

@implementation GADMYandexMediationLoadingDataProvider

- (GADMYandexMediationLoadingData *)loadingDataWithAdConfiguration:(GADMediationAdConfiguration *)configuration
{
    NSString *blockID = configuration.credentials.settings[kGADMYandexMediationLoadingDataBlockID];
    GADMYandexMediationLoadingData *loadingData = nil;
    if ([blockID isKindOfClass:[NSString class]] && blockID.length != 0) {
        CLLocation *location = nil;
        if (configuration.hasUserLocation) {
            location = [[CLLocation alloc] initWithLatitude:configuration.userLatitude
                                                  longitude:configuration.userLongitude];
        }
        loadingData = [[GADMYandexMediationLoadingData alloc] initWithBlockID:blockID location:location];
    }
    return loadingData;
}

@end
