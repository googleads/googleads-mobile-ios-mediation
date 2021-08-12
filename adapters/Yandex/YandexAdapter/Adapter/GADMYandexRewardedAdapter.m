/*
 * Version for iOS © 2015–2021 YANDEX
 *
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at https://yandex.com/legal/mobileads_sdk_agreement/
 */

#import <YandexMobileAds/YandexMobileAds.h>
#import <CoreLocation/CoreLocation.h>
#import "GADMYandexRewardedAdapter.h"
#import "GADMYandexAdFactory.h"
#import "GADMYandexAdRequestConfigurator.h"
#import "GADMYandexMediationLoadingData.h"
#import "GADMYandexMediationLoadingDataProvider.h"
#import "GADMYandexErrorFactory.h"

@interface GADMYandexRewardedAdapter () <YMARewardedAdDelegate>

@property (nonatomic, strong, readonly) GADMYandexMediationLoadingDataProvider *loadingDataProvider;
@property (nonatomic, strong, readonly) GADMYandexAdFactory *adFactory;
@property (nonatomic, strong, readonly) GADMYandexAdRequestConfigurator *adRequestConfigurator;;
@property (nonatomic, copy, readonly) GADMediationRewardedLoadCompletionHandler completionHandler;

@property (nonatomic, strong) YMARewardedAd *rewardedAd;
@property (nonatomic, weak) id<GADMediationRewardedAdEventDelegate> delegate;

@end

@implementation GADMYandexRewardedAdapter

- (instancetype)initWithCompletionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler
{
    return [self initWithCompletionHandler:completionHandler
                       loadingDataProvider:[[GADMYandexMediationLoadingDataProvider alloc] init]
                                 adFactory:[[GADMYandexAdFactory alloc] init]
                     adRequestConfigurator:[[GADMYandexAdRequestConfigurator alloc] init]];
}

- (instancetype)initWithCompletionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler
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

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
{
    GADMYandexMediationLoadingData *loadingData =
        [self.loadingDataProvider loadingDataWithAdConfiguration:adConfiguration];
    if (loadingData == nil) {
        self.completionHandler(nil, [GADMYandexErrorFactory nilBlockIDError]);
        return;
    }
    self.rewardedAd = [self rewardedAdWithLoadingData:loadingData];
    YMAAdRequest *adRequest = [self.adRequestConfigurator adRequestWithLoadingData:loadingData];
    [self.rewardedAd loadWithRequest:adRequest];
}

- (YMARewardedAd *)rewardedAdWithLoadingData:(GADMYandexMediationLoadingData *)loadingData
{
    YMARewardedAd *rewardedAd = [self.adFactory rewardedAdWithBlockID:loadingData.blockID];
    rewardedAd.delegate = self;
    return rewardedAd;
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(UIViewController *)viewController
{
    if (self.rewardedAd.loaded) {
        [self.rewardedAd presentFromViewController:viewController];
    }
    else {
        NSLog(@"Trying to present not loaded rewarded ad");
    }
}

#pragma mark - YMARewardedAdDelegate

- (void)rewardedAd:(YMARewardedAd *)rewardedAd didReward:(id<YMAReward>)reward
{
    NSDecimalNumber *rewardAmount = [NSDecimalNumber decimalNumberWithDecimal:[@(reward.amount) decimalValue]];
    GADAdReward *admobReward = [[GADAdReward alloc] initWithRewardType:reward.type rewardAmount:rewardAmount];
    [self.delegate didRewardUserWithReward:admobReward];
}

- (void)rewardedAdDidLoad:(YMARewardedAd *)rewardedAd
{
    self.delegate = self.completionHandler(self, nil);
}

- (void)rewardedAdDidFailToLoad:(YMARewardedAd *)rewardedAd error:(NSError *)error
{
    self.completionHandler(nil, error);
}

- (void)rewardedAdWillAppear:(YMARewardedAd *)rewardedAd
{
    [self.delegate willPresentFullScreenView];
}

- (void)rewardedAdDidAppear:(YMARewardedAd *)rewardedAd
{
    [self.delegate didStartVideo];
}

- (void)rewardedAdWillDisappear:(YMARewardedAd *)rewardedAd
{
    [self.delegate didEndVideo];
    [self.delegate willDismissFullScreenView];
}

- (void)rewardedAdDidDisappear:(YMARewardedAd *)rewardedAd
{
    [self.delegate didDismissFullScreenView];
}

- (void)rewardedAd:(YMARewardedAd *)rewardedAd willPresentScreen:(UIViewController *)viewController
{
    [self.delegate reportClick];
}

- (void)rewardedAdWillLeaveApplication:(YMARewardedAd *)rewardedAd
{
    [self.delegate reportClick];
}

- (void)rewardedAdDidFailToPresent:(YMARewardedAd *)rewardedAd error:(NSError *)error
{
    [self.delegate didFailToPresentWithError:error];
}

- (void)rewardedAd:(YMARewardedAd *)rewardedAd didTrackImpressionWithData:(id<YMAImpressionData>)impressionData
{
    [self.delegate reportImpression];
}

@end
