/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileAds.h>
#import <CoreLocation/CoreLocation.h>
#import "GADMYandexBannerAdapter.h"
#import "GADMYandexAdFactory.h"
#import "GADMYandexAdRequestConfigurator.h"
#import "GADMYandexMediationLoadingData.h"
#import "GADMYandexMediationLoadingDataProvider.h"
#import "GADMYandexErrorFactory.h"

@interface GADMYandexBannerAdapter () <YMAAdViewDelegate>

@property (nonatomic, strong, readonly) GADMYandexMediationLoadingDataProvider *loadingDataProvider;
@property (nonatomic, strong, readonly) GADMYandexAdFactory *adFactory;
@property (nonatomic, strong, readonly) GADMYandexAdRequestConfigurator *adRequestConfigurator;;
@property (nonatomic, copy, readonly) GADMediationBannerLoadCompletionHandler loadCompletionHandler;

@property (nonatomic, assign) BOOL shouldOpenLinksInApp;
@property (nonatomic, strong) YMAAdView *adView;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) id<GADMediationBannerAdEventDelegate> delegate;

@end

@implementation GADMYandexBannerAdapter

- (instancetype)initWithCompletionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler
{
    return [self initWithCompletionHandler:completionHandler
                       loadingDataProvider:[[GADMYandexMediationLoadingDataProvider alloc] init]
                                 adFactory:[[GADMYandexAdFactory alloc] init]
                     adRequestConfigurator:[[GADMYandexAdRequestConfigurator alloc] init]];
}

- (instancetype)initWithCompletionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler
                      loadingDataProvider:(GADMYandexMediationLoadingDataProvider *)loadingDataProvider
                                adFactory:(GADMYandexAdFactory *)adFactory
                    adRequestConfigurator:(GADMYandexAdRequestConfigurator *)adRequestConfigurator
{
    self = [super init];
    if (self != nil) {
        _loadCompletionHandler = completionHandler;
        _loadingDataProvider = loadingDataProvider;
        _adFactory = adFactory;
        _adRequestConfigurator = adRequestConfigurator;
    }
    return self;
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
{
    GADMYandexMediationLoadingData *loadingData =
        [self.loadingDataProvider loadingDataWithAdConfiguration:adConfiguration];
    if (loadingData == nil) {
        self.loadCompletionHandler(nil, [GADMYandexErrorFactory nilBlockIDError]);
        return;
    }

    YMAAdSize *adSize = [YMAAdSize fixedSizeWithCGSize:adConfiguration.adSize.size];
    self.adView = [self.adFactory bannerAdViewWithBlockID:loadingData.blockID adSize:adSize];
    self.adView.delegate = self;
    self.viewController = adConfiguration.topViewController;
    YMAAdRequest *adRequest = [self.adRequestConfigurator adRequestWithLoadingData:loadingData];
    [self.adView loadAdWithRequest:adRequest];
}

#pragma mark GADMediationBannerAd

- (UIView *)view
{
    return self.adView;
}

#pragma mark - YMAAdViewDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    if (self.shouldOpenLinksInApp == NO) {
        return nil;
    }
    return self.viewController;
}

- (void)adViewDidLoad:(YMAAdView *)adView
{
    id<GADMediationBannerAdEventDelegate> strongDelegate = self.loadCompletionHandler(self, nil);
    self.delegate = strongDelegate;
}

- (void)adViewDidFailLoading:(YMAAdView *)adView error:(NSError *)error
{
    self.loadCompletionHandler(nil, error);
}

- (void)adViewWillLeaveApplication:(YMAAdView *)adView
{
    [self.delegate reportClick];
}

- (void)adView:(YMAAdView *)adView willPresentScreen:(UIViewController *)viewController
{
    [self.delegate willPresentFullScreenView];
    [self.delegate reportClick];
}

- (void)adView:(YMAAdView *)adView didDismissScreen:(UIViewController *)viewController
{
    [self.delegate willDismissFullScreenView];
    [self.delegate didDismissFullScreenView];
}

- (void)adView:(YMAAdView *)adView didTrackImpressionWithData:(id<YMAImpressionData>)impressionData
{
    [self.delegate reportImpression];
}

@end
