/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <GoogleMobileAds/GoogleMobileAds.h>
#import "GADMYandexAdRequestParametersProvider.h"
#import "GADMYandexAdapterVersionProvider.h"

static NSString *const kGADMYandexAdapterNetworkNameKey = @"adapter_network_name";
static NSString *const kGADMYandexAdapterNetworkSDKVersionKey = @"adapter_network_sdk_version";
static NSString *const kGADMYandexAdapterVersionKey = @"adapter_version";

static NSString *const kGADMYandexAdapterNetworkName = @"admob";

@interface GADMYandexAdRequestParametersProvider ()

@property (nonatomic, copy, readonly) NSString *adapterSDKVersion;
@property (nonatomic, strong, readonly) GADMYandexAdapterVersionProvider *adapterVersionProvider;

@end

@implementation GADMYandexAdRequestParametersProvider

- (instancetype)init
{
    return [self initWithAdapterSDKVersion:[[GADMobileAds sharedInstance] sdkVersion]
                    adapterVersionProvider:[[GADMYandexAdapterVersionProvider alloc] init]];
}

- (instancetype)initWithAdapterSDKVersion:(NSString *)adapterSDKVersion
                   adapterVersionProvider:(GADMYandexAdapterVersionProvider *)adapterVersionProvider
{
    self = [super init];
    if (self != nil) {
        _adapterSDKVersion = [adapterSDKVersion copy];
        _adapterVersionProvider = adapterVersionProvider;
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *)adRequestParameters
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    NSString *adapterVersion = [self.adapterVersionProvider adapterVersion];
    parameters[kGADMYandexAdapterNetworkNameKey] = kGADMYandexAdapterNetworkName;
    parameters[kGADMYandexAdapterNetworkSDKVersionKey] = self.adapterSDKVersion;
    parameters[kGADMYandexAdapterVersionKey] = adapterVersion;
    return [parameters copy];
}

@end
