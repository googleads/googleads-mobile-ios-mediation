/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileAds.h>
#import "GADMediationAdapterYandex.h"
#import "GADMYandexVersion.h"
#import "GADMYandexBannerAdapter.h"
#import "GADMYandexInterstitialAdapter.h"
#import "GADMYandexRewardedAdapter.h"
#import "GADMYandexNativeAdapter.h"
#import "GADMYandexAdapterFactory.h"

@interface GADMediationAdapterYandex ()

@property (nonatomic, strong, readonly) GADMYandexAdapterFactory *adapterFactory;
@property (nonatomic, strong) GADMYandexBannerAdapter *bannerAdapter;
@property (nonatomic, strong) GADMYandexInterstitialAdapter *interstitialAdapter;
@property (nonatomic, strong) GADMYandexRewardedAdapter *rewardedAdapter;
@property (nonatomic, strong) GADMYandexNativeAdapter *nativeAdapter;

@end

@implementation GADMediationAdapterYandex

+ (GADVersionNumber)adapterVersion
{
    GADVersionNumber version = { 0 };
    version.majorVersion = GADM_YANDEX_ADMOB_VERSION_MAJOR;
    version.minorVersion = GADM_YANDEX_ADMOB_VERSION_MINOR;
    version.patchVersion = GADM_YANDEX_ADMOB_VERSION_PATCH * 100 + GADM_YANDEX_ADMOB_VERSION_ADAPTER_PATCH;
    return version;
}

+ (GADVersionNumber)adSDKVersion
{
    GADVersionNumber version = { 0 };
    version.majorVersion = YMA_VERSION_MAJOR;
    version.minorVersion = YMA_VERSION_MINOR;
    version.patchVersion = YMA_VERSION_PATCH;
    return version;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass
{
    return Nil;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler
{
    completionHandler(nil);
}

- (instancetype)init
{
    return [self initWithAdapterFactory:[[GADMYandexAdapterFactory alloc] init]];
}

- (instancetype)initWithAdapterFactory:(GADMYandexAdapterFactory *)adapterFactory
{
    self = [super init];
    if (self != nil) {
        _adapterFactory = adapterFactory;
    }
    return self;
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler
{
    self.bannerAdapter = [self.adapterFactory bannerAdapterWithCompletionHandler:completionHandler];
    [self.bannerAdapter loadBannerForAdConfiguration:adConfiguration];
}

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler
{
    self.interstitialAdapter = [self.adapterFactory interstitialAdapterWithCompletionHandler:completionHandler];
    [self.interstitialAdapter loadInterstitialForAdConfiguration:adConfiguration];
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler
{
    self.rewardedAdapter = [self.adapterFactory rewardedAdapterWithCompletionHandler:completionHandler];
    [self.rewardedAdapter loadRewardedAdForAdConfiguration:adConfiguration];
}

- (void)loadNativeAdForAdConfiguration:(GADMediationNativeAdConfiguration *)adConfiguration
                     completionHandler:(GADMediationNativeLoadCompletionHandler)completionHandler
{
    self.nativeAdapter = [self.adapterFactory nativeAdapterWithCompletionHandler:completionHandler];
    [self.nativeAdapter loadNativeAdForAdConfiguration:adConfiguration];
}

@end
