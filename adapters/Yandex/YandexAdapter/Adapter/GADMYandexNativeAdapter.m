/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileNativeAds.h>
#import "GADMYandexNativeAdapter.h"
#import "GADMYandexNativeAdLoaderFactory.h"
#import "GADMYandexNativeAdFactory.h"
#import "GADMYandexNativeRequestConfigurationFactory.h"
#import "GADMYandexNativeAd.h"
#import "GADMYandexMediationLoadingDataProvider.h"
#import "GADMYandexMediationLoadingData.h"
#import "GADMYandexErrorFactory.h"

@interface GADMYandexNativeAdapter () <YMANativeAdLoaderDelegate>

@property (nonatomic, strong, readonly) GADMYandexMediationLoadingDataProvider *loadingDataProvider;
@property (nonatomic, strong, readonly) GADMYandexNativeAdLoaderFactory *loaderFactory;
@property (nonatomic, strong, readonly) GADMYandexNativeAdFactory *adFactory;
@property (nonatomic, strong, readonly) GADMYandexNativeRequestConfigurationFactory *requestConfigurationFactory;;
@property (nonatomic, copy, readonly) GADMediationNativeLoadCompletionHandler completionHandler;

@property (nonatomic, strong) YMANativeAdLoader *adLoader;

@end

@implementation GADMYandexNativeAdapter

- (instancetype)initWithCompletionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler
{
    return [self initWithCompletionHandler:completionHandler
                       loadingDataProvider:[[GADMYandexMediationLoadingDataProvider alloc] init]
                             loaderFactory:[[GADMYandexNativeAdLoaderFactory alloc] init]
                                 adFactory:[[GADMYandexNativeAdFactory alloc] init]
               requestConfigurationFactory:[[GADMYandexNativeRequestConfigurationFactory alloc] init]];
}

- (instancetype)initWithCompletionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler
                      loadingDataProvider:(GADMYandexMediationLoadingDataProvider *)loadingDataProvider
                            loaderFactory:(GADMYandexNativeAdLoaderFactory *)loaderFactory
                                adFactory:(GADMYandexNativeAdFactory *)adFactory
              requestConfigurationFactory:(GADMYandexNativeRequestConfigurationFactory *)requestConfigurationFactory
{
    self = [super init];
    if (self != nil) {
        _completionHandler = completionHandler;
        _loadingDataProvider = loadingDataProvider;
        _loaderFactory = loaderFactory;
        _adFactory = adFactory;
        _requestConfigurationFactory = requestConfigurationFactory;
    }
    return self;
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
{
    GADMYandexMediationLoadingData *loadingData =
        [self.loadingDataProvider loadingDataWithAdConfiguration:adConfiguration];
    if (loadingData == nil) {
        self.completionHandler(nil, [GADMYandexErrorFactory nilBlockIDError]);
        return;
    }

    [self requestNativeAdWithLoadingData:loadingData];
}

- (void)requestNativeAdWithLoadingData:(GADMYandexMediationLoadingData *)loadingData
{
    self.adLoader = [self.loaderFactory adLoader];
    self.adLoader.delegate = self;
    YMANativeAdRequestConfiguration *requestConfiguration =
        [self.requestConfigurationFactory requestConfigurationWithLoadingData:loadingData];
    [self.adLoader loadAdWithRequestConfiguration:requestConfiguration];
}

#pragma mark - YMANativeAdLoaderDelegate

- (void)nativeAdLoader:(YMANativeAdLoader *)loader didLoadAd:(id<YMANativeAd>)ad
{
    GADMYandexNativeAd *nativeAd = [self.adFactory adMobNativeAdWithNativeAd:ad];
    id<GADMediationNativeAdEventDelegate> delegate = self.completionHandler(nativeAd, nil);
    nativeAd.delegate = delegate;
}

- (void)nativeAdLoader:(YMANativeAdLoader *)loader didFailLoadingWithError:(NSError *)error
{
    self.completionHandler(nil, error);
}

@end
