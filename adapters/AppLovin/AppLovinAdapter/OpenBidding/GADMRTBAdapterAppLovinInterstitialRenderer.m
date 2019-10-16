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
#include <stdatomic.h>

/// AppLovin Interstitial Delegate wrapoer. AppLovin interstitial protocols are implemented in a
/// separate class to avoid a retain cycle, as the AppLovin SDK keep a strong reference to its
/// delegate.
@interface GADMAppLovinRtbInterstitialDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate>

/// AppLovin interstitial ad renderer to which the events are delegated.
@property(nonatomic, weak) GADMRTBAdapterAppLovinInterstitialRenderer *parentRenderer;

- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMRTBAdapterAppLovinInterstitialRenderer *)parentRenderer;

@end

@interface GADMRTBAdapterAppLovinInterstitialRenderer () <GADMediationInterstitialAd>

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property(nonatomic, readonly)
    GADMediationInterstitialLoadCompletionHandler adLoadCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of interstitial presentation events.
@property(nonatomic, weak, nullable) id<GADMediationInterstitialAdEventDelegate> delegate;

/// An AppLovin interstitial ad.
@property(nonatomic, strong) ALAd *ad;

@end

@implementation GADMRTBAdapterAppLovinInterstitialRenderer {
  /// Data used to render an interstitial ad.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// Instance of the AppLovin SDK.
  ALSdk *_sdk;

  /// AppLovin interstitial object used to load an ad.
  ALInterstitialAd *_interstitialAd;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationInterstitialLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    // Store the completion handler for later use.
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
        [handler copy];
    _adLoadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
        _Nullable id<GADMediationInterstitialAd> ad, NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }
      id<GADMediationInterstitialAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(ad, error);
      }
      originalCompletionHandler = nil;
      return delegate;
    };

    _sdk =
        [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:adConfiguration.credentials.settings];
  }
  return self;
}

- (void)loadAd {
  if (!_sdk) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        kGADErrorMediationAdapterError, @"Failed to retrieve SDK instance.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // Create interstitial object.
  _interstitialAd = [[ALInterstitialAd alloc] initWithSdk:_sdk];

  GADMAppLovinRtbInterstitialDelegate *delegate =
      [[GADMAppLovinRtbInterstitialDelegate alloc] initWithParentRenderer:self];
  _interstitialAd.adDisplayDelegate = delegate;
  _interstitialAd.adVideoPlaybackDelegate = delegate;

  // Load ad.
  [_sdk.adService loadNextAdForAdToken:_adConfiguration.bidResponse andNotify:delegate];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(UIViewController *)viewController {
  // Update mute state
  GADMAdapterAppLovinExtras *extras = _adConfiguration.extras;
  _sdk.settings.muted = extras.muteAudio;

  [_interstitialAd showAd:_ad];
}

- (void)dealloc {
  _interstitialAd.adDisplayDelegate = nil;
  _interstitialAd.adVideoPlaybackDelegate = nil;
}

@end

@implementation GADMAppLovinRtbInterstitialDelegate

#pragma mark - Initialization

- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMRTBAdapterAppLovinInterstitialRenderer *)parentRenderer {
  self = [super init];
  if (self) {
    _parentRenderer = parentRenderer;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"Interstitial did load ad: %@", ad];

  GADMRTBAdapterAppLovinInterstitialRenderer *parentRenderer = _parentRenderer;
  parentRenderer.ad = ad;
  dispatch_async(dispatch_get_main_queue(), ^{
    if (parentRenderer.adLoadCompletionHandler) {
      parentRenderer.delegate = parentRenderer.adLoadCompletionHandler(parentRenderer, nil);
    }
  });
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code {
  GADMRTBAdapterAppLovinInterstitialRenderer *parentRenderer = _parentRenderer;
  if (parentRenderer.adLoadCompletionHandler) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        [GADMAdapterAppLovinUtils toAdMobErrorCode:code], @"Failed to load interstitial ad");
    parentRenderer.adLoadCompletionHandler(nil, error);
  }
}

#pragma mark - Ad Display Delegate

- (void)ad:(nonnull ALAd *)ad wasDisplayedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial displayed"];
  id<GADMediationInterstitialAdEventDelegate> strongDelegate = _parentRenderer.delegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate reportImpression];
}

- (void)ad:(nonnull ALAd *)ad wasHiddenIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial hidden"];
  id<GADMediationInterstitialAdEventDelegate> strongDelegate = _parentRenderer.delegate;
  [strongDelegate willDismissFullScreenView];
  [strongDelegate didDismissFullScreenView];
}

- (void)ad:(nonnull ALAd *)ad wasClickedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial clicked"];
  id<GADMediationInterstitialAdEventDelegate> strongDelegate = _parentRenderer.delegate;
  [strongDelegate reportClick];
  [strongDelegate willBackgroundApplication];
}

#pragma mark - Video Playback Delegate

- (void)videoPlaybackBeganInAd:(nonnull ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"Interstitial video playback began"];
}

- (void)videoPlaybackEndedInAd:(nonnull ALAd *)ad
             atPlaybackPercent:(nonnull NSNumber *)percentPlayed
                  fullyWatched:(BOOL)wasFullyWatched {
  [GADMAdapterAppLovinUtils log:@"Interstitial video playback ended at playback percent: %lu%%",
                                (unsigned long)percentPlayed.unsignedIntegerValue];
}

@end
