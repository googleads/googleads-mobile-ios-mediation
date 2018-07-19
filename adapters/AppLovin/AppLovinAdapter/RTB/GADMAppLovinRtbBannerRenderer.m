//
//  GADMAppLovinRtbBannerRenderer.m
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMAppLovinRtbBannerRenderer.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAdapterAppLovinConstant.h"

#import <AppLovinSDK/AppLovinSDK.h>

@interface GADMAppLovinRtbBannerRenderer () <GADMediationBannerAd, ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>

/// Data used to render an RTB banner ad.
@property (nonatomic, strong) GADMediationBannerAdConfiguration *adConfiguration;

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property (nonatomic, copy) GADBannerRenderCompletionHandler renderCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of banner presentation events.
@property (nonatomic, strong, nullable) id<GADMediationBannerAdEventDelegate> adEventDelegate;

/// Controlled Properties
@property (nonatomic, strong) ALSdk *sdk;
@property (nonatomic, assign) ALAdSize *adSize;
@property (nonatomic, strong) ALAdView *adView;

@end

@implementation GADMAppLovinRtbBannerRenderer

- (instancetype)initWithAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                      completionHandler:(nonnull GADBannerRenderCompletionHandler)handler {
    self = [super init];
    if (self) {
        self.adConfiguration = adConfiguration;
        self.renderCompletionHandler = handler;
        
        // Convert requested size to AppLovin Ad Size.
        self.adSize = [GADMAdapterAppLovinUtils adSizeFromRequestedSize:adConfiguration.adSize];
        self.sdk = [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:adConfiguration.credentials.settings];
    }
    return self;
}

- (void)loadAd {
    if (self.adSize) {
        // Create adview object
        self.adView = [[ALAdView alloc] initWithSdk:self.sdk size:self.adSize];
        self.adView.adLoadDelegate = self;
        self.adView.adDisplayDelegate = self;
        self.adView.adEventDelegate = self;
        
        // Load ad
        [self.sdk.adService loadNextAdForAdToken:self.adConfiguration.bidResponse andNotify:self];
    } else {
        NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.rtbErrorDomain
                                             code:kGADErrorMediationInvalidAdSize
                                         userInfo:@{
                                                    NSLocalizedFailureReasonErrorKey :
                                                        @"Failed to reuqest banner with unsupported size"
                                                    }];
        self.renderCompletionHandler(nil, error);
    }
}

#pragma mark - GADMediationBannerAd

- (UIView *)view {
    return self.adView;
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
    [GADMAdapterAppLovinUtils log:@"Banner did load ad: %@", ad.adIdNumber];
    
    self.adEventDelegate = self.renderCompletionHandler(self, nil);
    [self.adView render:ad];
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
    [GADMAdapterAppLovinUtils log:@"Failed to load banner ad with error: %d", code];
    
    NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.rtbErrorDomain
                                         code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                                     userInfo:nil];
    self.renderCompletionHandler(nil, error);
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
    [GADMAdapterAppLovinUtils log:@"Banner displayed"];
    [self.adEventDelegate reportImpression];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
    [GADMAdapterAppLovinUtils log:@"Banner dismissed"];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
    [GADMAdapterAppLovinUtils log:@"Banner clicked"];
    [self.adEventDelegate reportClick];
}

#pragma mark - Ad View Event Delegate

- (void)ad:(ALAd *)ad didPresentFullscreenForAdView:(ALAdView *)adView {
    [GADMAdapterAppLovinUtils log:@"Banner presented fullscreen"];
    [self.adEventDelegate willPresentFullScreenView];
}

- (void)ad:(ALAd *)ad willDismissFullscreenForAdView:(ALAdView *)adView {
    [GADMAdapterAppLovinUtils log:@"Banner will dismiss fullscreen"];
    [self.adEventDelegate willDismissFullScreenView];
}

- (void)ad:(ALAd *)ad didDismissFullscreenForAdView:(ALAdView *)adView {
    [GADMAdapterAppLovinUtils log:@"Banner did dismiss fullscreen"];
    [self.adEventDelegate didDismissFullScreenView];
}

- (void)ad:(ALAd *)ad willLeaveApplicationForAdView:(ALAdView *)adView {
    [GADMAdapterAppLovinUtils log:@"Banner left application"];
    [self.adEventDelegate willBackgroundApplication];
}

- (void)ad:(ALAd *)ad didFailToDisplayInAdView:(ALAdView *)adView withError:(ALAdViewDisplayErrorCode)code {
    [GADMAdapterAppLovinUtils log:@"Banner failed to display: %ld", code];
}

@end
