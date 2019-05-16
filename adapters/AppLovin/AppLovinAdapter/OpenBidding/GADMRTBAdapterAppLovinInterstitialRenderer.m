//
//  GADMRTBAdapterAppLovinInterstitialRenderer.m
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMRTBAdapterAppLovinInterstitialRenderer.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinUtils.h"

#import <AppLovinSDK/AppLovinSDK.h>

/// AppLovin Interstitial Delegate.
@interface GADMAppLovinRtbInterstitialDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate>
@property(nonatomic, weak) GADMRTBAdapterAppLovinInterstitialRenderer *parentRenderer;
- (instancetype)initWithParentRenderer:(GADMRTBAdapterAppLovinInterstitialRenderer *)parentRenderer;
@end

@interface GADMRTBAdapterAppLovinInterstitialRenderer () <GADMediationInterstitialAd>

/// Data used to render an RTB interstitial ad.
@property(nonatomic, strong) GADMediationInterstitialAdConfiguration *adConfiguration;

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property(nonatomic, copy) GADMediationInterstitialLoadCompletionHandler adLoadCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of interstitial presentation events.
@property(nonatomic, strong, nullable) id<GADMediationInterstitialAdEventDelegate> delegate;

/// Controlled Properties
@property(nonatomic, strong) ALSdk *sdk;
@property(nonatomic, strong) ALInterstitialAd *interstitialAd;
@property(nonatomic, strong) ALAd *ad;

@end

@implementation GADMRTBAdapterAppLovinInterstitialRenderer

- (instancetype)initWithAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration
                      completionHandler:(GADMediationInterstitialLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    self.adConfiguration = adConfiguration;
    self.adLoadCompletionHandler = handler;

    self.sdk =
        [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:adConfiguration.credentials.settings];
  }
  return self;
}

- (void)loadAd {
  // Create interstitial object
  self.interstitialAd = [[ALInterstitialAd alloc] initWithSdk:self.sdk];

  GADMAppLovinRtbInterstitialDelegate *delegate =
      [[GADMAppLovinRtbInterstitialDelegate alloc] initWithParentRenderer:self];
  self.interstitialAd.adDisplayDelegate = delegate;
  self.interstitialAd.adVideoPlaybackDelegate = delegate;

  // Load ad
  [self.sdk.adService loadNextAdForAdToken:self.adConfiguration.bidResponse andNotify:delegate];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(UIViewController *)viewController {
  // Update mute state
  GADMAdapterAppLovinExtras *extras = self.adConfiguration.extras;
  self.sdk.settings.muted = extras.muteAudio;

  [self.interstitialAd showOver:[UIApplication sharedApplication].keyWindow andRender:self.ad];
}

- (void)dealloc {
  self.interstitialAd.adDisplayDelegate = nil;
  self.interstitialAd.adVideoPlaybackDelegate = nil;
}

@end

@implementation GADMAppLovinRtbInterstitialDelegate

#pragma mark - Initialization

- (instancetype)initWithParentRenderer:
    (GADMRTBAdapterAppLovinInterstitialRenderer *)parentRenderer {
  self = [super init];
  if (self) {
    self.parentRenderer = parentRenderer;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(ALAdService *)adService didLoadAd:(ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"Interstitial did load ad: %@", ad.adIdNumber];

  GADMRTBAdapterAppLovinInterstitialRenderer *parentRenderer = self.parentRenderer;
  parentRenderer.ad = ad;
  dispatch_async(dispatch_get_main_queue(), ^{
    if (parentRenderer.adLoadCompletionHandler) {
      parentRenderer.delegate = parentRenderer.adLoadCompletionHandler(parentRenderer, nil);
    }
  });
}

- (void)adService:(ALAdService *)adService didFailToLoadAdWithError:(int)code {
  [GADMAdapterAppLovinUtils log:@"Failed to load interstitial ad with error: %d", code];

  NSError *error = [NSError errorWithDomain:GADMAdapterAppLovinConstant.rtbErrorDomain
                                       code:[GADMAdapterAppLovinUtils toAdMobErrorCode:code]
                                   userInfo:nil];
  if (_parentRenderer.adLoadCompletionHandler) {
    self.parentRenderer.adLoadCompletionHandler(nil, error);
  }
}

#pragma mark - Ad Display Delegate

- (void)ad:(ALAd *)ad wasDisplayedIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial displayed"];

  GADMRTBAdapterAppLovinInterstitialRenderer *parentRenderer = self.parentRenderer;
  [parentRenderer.delegate willPresentFullScreenView];
  [parentRenderer.delegate reportImpression];
}

- (void)ad:(ALAd *)ad wasHiddenIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial hidden"];

  GADMRTBAdapterAppLovinInterstitialRenderer *parentRenderer = self.parentRenderer;
  [parentRenderer.delegate willDismissFullScreenView];
  [parentRenderer.delegate didDismissFullScreenView];
}

- (void)ad:(ALAd *)ad wasClickedIn:(UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial clicked"];

  GADMRTBAdapterAppLovinInterstitialRenderer *parentRenderer = self.parentRenderer;
  [parentRenderer.delegate reportClick];
  [parentRenderer.delegate willBackgroundApplication];
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
