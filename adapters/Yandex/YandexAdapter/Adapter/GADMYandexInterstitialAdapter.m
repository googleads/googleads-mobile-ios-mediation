/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileAds.h>
#import "GADMYandexInterstitialAdapter.h"
#import "GADMYandexAdRequestConfigurator.h"
#import "GADMYandexAdFactory.h"
#import "GADMYandexMediationLoadingData.h"
#import "GADMYandexMediationLoadingDataProvider.h"
#import "GADMYandexErrorFactory.h"

@interface GADMYandexInterstitialAdapter () <YMAInterstitialAdDelegate>

@property (nonatomic, strong, readonly) GADMYandexMediationLoadingDataProvider *loadingDataProvider;
@property (nonatomic, strong, readonly) GADMYandexAdFactory *adFactory;
@property (nonatomic, strong, readonly) GADMYandexAdRequestConfigurator *adRequestConfigurator;;
@property (nonatomic, copy, readonly) GADMediationInterstitialLoadCompletionHandler completionHandler;

@property (nonatomic, strong) YMAInterstitialAd *interstitialAd;
@property (nonatomic, weak) id<GADMediationInterstitialAdEventDelegate> delegate;

@end

@implementation GADMYandexInterstitialAdapter

- (instancetype)initWithCompletionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler
{
    return [self initWithCompletionHandler:completionHandler
                       loadingDataProvider:[[GADMYandexMediationLoadingDataProvider alloc] init]
                                 adFactory:[[GADMYandexAdFactory alloc] init]
                     adRequestConfigurator:[[GADMYandexAdRequestConfigurator alloc] init]];
}

- (instancetype)initWithCompletionHandler:(GADMediationInterstitialLoadCompletionHandler)completionHandler
                      loadingDataProvider:(GADMYandexMediationLoadingDataProvider *)loadingDataProvider
                                adFactory:(GADMYandexAdFactory *)adFactory
                    adRequestConfigurator:(GADMYandexAdRequestConfigurator *)adRequestConfigurator
{
    self = [super init];
    if (self != nil) {
        _completionHandler = completionHandler;
        _loadingDataProvider = loadingDataProvider;
        _adFactory = adFactory;
        _adRequestConfigurator = adRequestConfigurator;
    }
    return self;
}

- (void)loadInterstitialForAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
{
    GADMYandexMediationLoadingData *loadingData =
        [self.loadingDataProvider loadingDataWithAdConfiguration:adConfiguration];
    if (loadingData == nil) {
        self.completionHandler(nil, [GADMYandexErrorFactory nilBlockIDError]);
        return;
    }
    self.interstitialAd = [self.adFactory interstitialAdWithBlockID:loadingData.blockID];
    self.interstitialAd.delegate = self;
    YMAAdRequest *adRequest = [self.adRequestConfigurator adRequestWithLoadingData:loadingData];
    [self.interstitialAd loadWithRequest:adRequest];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(UIViewController *)viewController
{
    if (self.interstitialAd.loaded) {
        [self.interstitialAd presentFromViewController:viewController];
    }
    else {
        NSLog(@"Trying to present not loaded rewarded ad");
    }
}

#pragma mark - YMAInterstitialDelegate

- (void)interstitialAdDidLoad:(YMAInterstitialAd *)interstitialAd
{
    self.delegate = self.completionHandler(self, nil);
}

- (void)interstitialAdDidFailToLoad:(YMAInterstitialAd *)interstitialAd error:(NSError *)error
{
    self.completionHandler(nil, error);
}

- (void)interstitialAdWillAppear:(YMAInterstitialAd *)interstitialAd
{
    [self.delegate willPresentFullScreenView];
}

- (void)interstitialAdDidAppear:(YMAInterstitialAd *)interstitialAd
{
    // do nothing
}

- (void)interstitialAdWillDisappear:(YMAInterstitialAd *)interstitialAd
{
    [self.delegate willDismissFullScreenView];
}

- (void)interstitialAdDidDisappear:(YMAInterstitialAd *)interstitialAd
{
    [self.delegate didDismissFullScreenView];
}

- (void)interstitialAd:(YMAInterstitialAd *)interstitialAd willPresentScreen:(UIViewController *)webBrowser
{
    [self.delegate reportClick];
}

- (void)interstitialAdWillLeaveApplication:(YMAInterstitialAd *)interstitialAd
{
    [self.delegate reportClick];
}

- (void)interstitialAdDidFailToPresent:(YMAInterstitialAd *)interstitialAd error:(NSError *)error
{
    [self.delegate didFailToPresentWithError:error];
}

- (void)interstitialAd:(YMAInterstitialAd *)interstitialAd
        didTrackImpressionWithData:(id<YMAImpressionData>)impressionData
{
    [self.delegate reportImpression];
}

@end
