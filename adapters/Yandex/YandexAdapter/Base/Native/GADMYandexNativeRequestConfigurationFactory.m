/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileNativeAds.h>
#import "GADMYandexNativeRequestConfigurationFactory.h"
#import "GADMYandexAdRequestParametersProvider.h"
#import "GADMYandexMediationLoadingData.h"

@interface GADMYandexNativeRequestConfigurationFactory ()

@property (nonatomic, strong, readonly) GADMYandexAdRequestParametersProvider *adRequestParametersProvider;

@end

@implementation GADMYandexNativeRequestConfigurationFactory

- (instancetype)init
{
    return [self initWithAdRequestParametersProvider:[[GADMYandexAdRequestParametersProvider alloc] init]];
}

- (instancetype)initWithAdRequestParametersProvider:(GADMYandexAdRequestParametersProvider *)adRequestParametersProvider
{
    self = [super init];
    if (self != nil) {
        _adRequestParametersProvider = adRequestParametersProvider;
    }
    return self;
}

- (YMANativeAdRequestConfiguration *)requestConfigurationWithLoadingData:(GADMYandexMediationLoadingData *)loadingData
{
    YMAMutableNativeAdRequestConfiguration *requestConfiguration =
        [[YMAMutableNativeAdRequestConfiguration alloc] initWithBlockID:loadingData.blockID];
    NSDictionary *parameters = [self.adRequestParametersProvider adRequestParameters];
    requestConfiguration.parameters = [parameters copy];
    requestConfiguration.location = loadingData.location;
    return requestConfiguration;
}

@end
