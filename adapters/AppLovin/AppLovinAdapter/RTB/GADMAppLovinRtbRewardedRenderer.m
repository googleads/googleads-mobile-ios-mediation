//
//  GADMAppLovinRtbRewardedRenderer.m
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMAppLovinRtbRewardedRenderer.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"

#import <AppLovinSDK/AppLovinSDK.h>

@interface GADMAppLovinRtbRewardedRenderer () <GADMediationRewardedAd, ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate, ALAdRewardDelegate>

/// Data used to render an RTB rewarded ad.
@property (nonatomic, strong) GADMediationRewardedAdConfiguration *adConfiguration;

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property (nonatomic, copy) GADRewardedRenderCompletionHandler renderCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of rewarded presentation events.
@property (nonatomic, strong, nullable) id<GADMediationRewardedAdEventDelegate> adEventDelegate;

/// Controlled Properties
@property (nonatomic, strong) ALSdk *sdk;
@property (nonatomic, strong) ALIncentivizedInterstitialAd *incentivizedAd;
@property (nonatomic, strong) ALAd *ad;
@property (nonatomic, assign) BOOL fullyWatched;
@property (nonatomic, strong) GADAdReward *reward;

@end

@implementation GADMAppLovinRtbRewardedRenderer

- (instancetype)initWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                      completionHandler:(nonnull GADRewardedRenderCompletionHandler)handler {
    self = [super init];
    if (self) {
        self.adConfiguration = adConfiguration;
        self.renderCompletionHandler = handler;
        
        self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:adConfiguration.credentials.settings];
    }
    return self;
}

- (void)loadAd {
    // Create incentivized interstitial object
    self.incentivizedAd = [[ALIncentivizedInterstitialAd alloc] initWithSdk:self.sdk];
    self.incentivizedAd.adDisplayDelegate = self;
    self.incentivizedAd.adVideoPlaybackDelegate = self;
    
    // Load ad
    [self.sdk.adService loadNextAdForAdToken:self.adConfiguration.bidResponse andNotify:self];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(UIViewController *)viewController {
    // Update mute state
    GADMAdapterAppLovinExtras *extras = self.adConfiguration.extras;
    self.sdk.settings.muted = extras.muteAudio;
    
    [self.incentivizedAd showOver:[UIApplication sharedApplication].keyWindow
                         renderAd:self.ad
                        andNotify:self];
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
    [GADMAdapterAppLovinUtils log:@"Rewarded video did load ad: %@", ad.adIdNumber];
    
    self.ad = ad;
    
    self.adEventDelegate = self.renderCompletionHandler(self, nil);
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
    [GADMAdapterAppLovinUtils log:@"Failed to load rewarded video with error: %d", code];
    
    NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.rtbErrorDomain
                                         code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                                     userInfo:nil];
    self.renderCompletionHandler(nil, error);
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
    [GADMAdapterAppLovinUtils log:@"Rewarded video displayed"];
    [self.adEventDelegate reportImpression];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
    [GADMAdapterAppLovinUtils log:@"Rewarded video hidden"];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
    [GADMAdapterAppLovinUtils log:@"Interstitial clicked"];
    [self.adEventDelegate reportClick];
    [self.adEventDelegate willBackgroundApplication];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(ALAd *)ad {
    [GADMAdapterAppLovinUtils log:@"Interstitial video playback began"];
}

- (void)videoPlaybackEndedInAd:(ALAd *)ad
             atPlaybackPercent:(NSNumber *)percentPlayed
                  fullyWatched:(BOOL)wasFullyWatched {
    [GADMAdapterAppLovinUtils log:@"Interstitial video playback ended at playback percent: %lu%%",
     percentPlayed.unsignedIntegerValue];
}

#pragma mark - Reward Delegate

- (void)rewardValidationRequestForAd:(ALAd *)ad
          didExceedQuotaWithResponse:(NSDictionary *)response {
    [GADMAdapterAppLovinUtils log:@"Rrewarded video validation request for ad did exceed quota with response: %@", response];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad didFailWithError:(NSInteger)responseCode {
    [GADMAdapterAppLovinUtils log:@"Rewarded video validation request for ad failed with error code: %d", responseCode];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad wasRejectedWithResponse:(NSDictionary *)response {
    [GADMAdapterAppLovinUtils log:@"Rewarded video validation request was rejected with response: %@", response];
}

- (void)userDeclinedToViewAd:(ALAd *)ad {
    [GADMAdapterAppLovinUtils log:@"User deliced to view rewarded video"];
}

- (void)rewardValidationRequestForAd:(ALAd *)ad didSucceedWithResponse:(NSDictionary *)response {
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:response[@"amount"]];
    NSString *currency = response[@"currency"];
    
    [GADMAdapterAppLovinUtils log:@"Rewarded %@ %@", amount, currency];
    
    self.reward = [[GADAdReward alloc] initWithRewardType:currency rewardAmount:amount];
}

@end
