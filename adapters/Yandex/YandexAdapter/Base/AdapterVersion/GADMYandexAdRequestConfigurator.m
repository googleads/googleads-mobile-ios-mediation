/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileAds.h>
#import "GADMYandexAdRequestConfigurator.h"
#import "GADMYandexMediationLoadingData.h"
#import "GADMYandexAdRequestParametersProvider.h"

@interface GADMYandexAdRequestConfigurator ()

@property (nonatomic, strong, readonly) GADMYandexAdRequestParametersProvider *adRequestParametersProvider;

@end

@implementation GADMYandexAdRequestConfigurator

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

- (YMAAdRequest *)adRequestWithLoadingData:(GADMYandexMediationLoadingData *)loadingData
{
    YMAMutableAdRequest *adRequest = [[YMAMutableAdRequest alloc] init];
    NSDictionary *parameters = [self.adRequestParametersProvider adRequestParameters];
    adRequest.parameters = [parameters copy];
    adRequest.location = loadingData.location;
    return adRequest;
}

@end
