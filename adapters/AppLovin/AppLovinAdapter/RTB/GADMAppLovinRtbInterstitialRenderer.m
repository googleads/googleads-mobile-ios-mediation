//
//  GADMAppLovinRtbInterstitialRenderer.m
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMAppLovinRtbInterstitialRenderer.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"

#import <AppLovinSDK/AppLovinSDK.h>

@interface GADMAppLovinRtbInterstitialRenderer () <GADMediationInterstitialAd, ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate>

/// Data used to render an RTB interstitial ad.
@property (nonatomic, strong) GADMediationInterstitialAdConfiguration *adConfiguration;

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property (nonatomic, copy) GADInterstitialRenderCompletionHandler renderCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of interstitial presentation events.
@property (nonatomic, strong, nullable) id<GADMediationInterstitialAdEventDelegate> adEventDelegate;

/// Controlled Properties
@property (nonatomic, strong) ALSdk *sdk;
@property (nonatomic, strong) ALInterstitialAd *interstitialAd;
@property (nonatomic, strong) ALAd *ad;

@end

@implementation GADMAppLovinRtbInterstitialRenderer

- (instancetype)initWithAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                      completionHandler:(nonnull GADInterstitialRenderCompletionHandler)handler {
    self = [super init];
    if (self) {
        self.adConfiguration = adConfiguration;
        self.renderCompletionHandler = handler;
        
        self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:adConfiguration.credentials.settings];
    }
    return self;
}

- (void)loadAd {
    // Create interstitial object
    self.interstitialAd = [[ALInterstitialAd alloc] initWithSdk:self.sdk];
    self.interstitialAd.adDisplayDelegate = self;
    self.interstitialAd.adVideoPlaybackDelegate = self;
    
    // Load ad
    [self.sdk.adService loadNextAdForAdToken:self.adConfiguration.bidResponse andNotify:self];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(UIViewController *)viewController {
    // Update mute state
    GADMAdapterAppLovinExtras *extras = self.adConfiguration.extras;
    self.sdk.settings.muted = extras.muteAudio;
    
    [self.interstitialAd showOver:[UIApplication sharedApplication].keyWindow
                        andRender:self.ad];
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
    [GADMAdapterAppLovinUtils log:@"Interstitial did load ad: %@", ad.adIdNumber];
    
    self.ad = ad;
    
    self.adEventDelegate = self.renderCompletionHandler(self, nil);
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
    [GADMAdapterAppLovinUtils log:@"Failed to load interstitial ad with error: %d", code];
    
    NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.rtbErrorDomain
                                         code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                                     userInfo:nil];
    self.renderCompletionHandler(nil, error);
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
    [GADMAdapterAppLovinUtils log:@"Interstitial displayed"];
    [self.adEventDelegate reportImpression];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
    [GADMAdapterAppLovinUtils log:@"Interstitial hidden"];
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

@end
