//
//  GADMAdapterAdColonyBannerRenderer.m
//


#import "GADMAdapterAdColonyBannerRenderer.h"
#import "GADMAdapterAdColonyHelper.h"

@interface GADMAdapterAdColonyBannerRenderer () <GADMediationBannerAd, AdColonyAdViewDelegate>

@property(nonatomic, copy) GADMediationBannerLoadCompletionHandler loadCompletionHandler;
@property(nonatomic, strong) AdColonyAdView *bannerAdView;
@property(nonatomic, weak) id<GADMediationBannerAdEventDelegate> adEventDelegate;

@end

@implementation GADMAdapterAdColonyBannerRenderer

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler{
    self.loadCompletionHandler = completionHandler;
    GADMAdapterAdColonyBannerRenderer *__weak weakSelf = self;
    [GADMAdapterAdColonyHelper setupZoneFromAdConfig:adConfiguration
                                            callback:^(NSString *zone, NSError *error) {
                                                __strong typeof(weakSelf) strongSelf = weakSelf;
                                                if (error && strongSelf) {
                                                    strongSelf.loadCompletionHandler(nil, error);
                                                    return;
                                                }
                                                [strongSelf getBannerAdFromZoneId:zone
                                                                       withAdConfig:adConfiguration];
                                            }];
}

- (void)getBannerAdFromZoneId:(NSString *)zone
                 withAdConfig:(GADMediationBannerAdConfiguration *)adConfiguration {
    self.bannerAdView = nil;
    AdColonyAdSize adSize = [GADMAdapterAdColonyHelper getAdColonyAdSizeFrom:adConfiguration.adSize];
    UIViewController *viewController = adConfiguration.topViewController;
    [AdColony requestAdViewInZone:zone withSize:adSize viewController:viewController andDelegate:self];
}

#pragma mark - AdColony Banner Delegate

- (void)adColonyAdViewDidLoad:(AdColonyAdView *)adView {
    GADMAdapterAdColonyLog(@"Banner ad loaded");
    self.bannerAdView = adView;
    self.adEventDelegate = self.loadCompletionHandler(self, nil);
}

- (void)adColonyAdViewDidFailToLoad:(AdColonyAdRequestError *)error {
    GADMAdapterAdColonyLog(@"Failed to load banner ad: %@", error.localizedDescription);
    self.loadCompletionHandler(nil, error);
}

- (void)adColonyAdViewWillLeaveApplication:(AdColonyAdView *)adView{
    [self.adEventDelegate willBackgroundApplication];
}

- (void)adColonyAdViewWillOpen:(AdColonyAdView *)adView{
    [self.adEventDelegate willPresentFullScreenView];
}

- (void)adColonyAdViewDidClose:(AdColonyAdView *)adView{
    [self.adEventDelegate didDismissFullScreenView];
}

- (void)adColonyAdViewDidReceiveClick:(AdColonyAdView *)adView{
    [self.adEventDelegate reportClick];
}

#pragma mark GADMediationBannerAd

// Called after the invokation of the GADBannerRenderCompletionHandler.
- (UIView *)view {
    return self.bannerAdView;
}

@end
