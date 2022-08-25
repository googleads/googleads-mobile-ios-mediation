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
#import "GADMediationAdapterAppLovin.h"

#import <AppLovinSDK/AppLovinSDK.h>
#include <stdatomic.h>

#import "GADMAppLovinRTBInterstitialDelegate.h"

@implementation GADMRTBAdapterAppLovinInterstitialRenderer {
  /// Data used to render an interstitial ad.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// Instance of the AppLovin SDK.
  ALSdk *_SDK;

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
  }
  return self;
}

- (void)loadAd {
  NSString *SDKKey = [GADMAdapterAppLovinUtils
      retrieveSDKKeyFromCredentials:_adConfiguration.credentials.settings];
  if (!SDKKey) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, @"Invalid server parameters.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _SDK = [GADMAdapterAppLovinUtils retrieveSDKFromSDKKey:SDKKey];
  if (!_SDK) {
    NSError *error = GADMAdapterAppLovinNilSDKError(SDKKey);
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // Create interstitial object.
  _interstitialAd = [[ALInterstitialAd alloc] initWithSdk:_SDK];

  GADMAppLovinRTBInterstitialDelegate *delegate =
      [[GADMAppLovinRTBInterstitialDelegate alloc] initWithParentRenderer:self];
  _interstitialAd.adDisplayDelegate = delegate;
  _interstitialAd.adVideoPlaybackDelegate = delegate;

  // Load ad.
  [_SDK.adService loadNextAdForAdToken:_adConfiguration.bidResponse andNotify:delegate];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(UIViewController *)viewController {
  // Update mute state
  GADMAdapterAppLovinExtras *extras = _adConfiguration.extras;
  _SDK.settings.muted = extras.muteAudio;

  [_interstitialAd showAd:_ad];
}

- (void)dealloc {
  _interstitialAd.adDisplayDelegate = nil;
  _interstitialAd.adVideoPlaybackDelegate = nil;
}

@end
