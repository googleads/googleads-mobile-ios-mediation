//
//  GADMRTBAdapterAppLovinRewardedRenderer.m
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMAdapterAppLovinRewardedRenderer.h"
#include <stdatomic.h>
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMAppLovinRewardedDelegate.h"
#import "GADMediationAdapterAppLovin.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation GADMAdapterAppLovinRewardedRenderer {
  /// Data used to render a rewarded ad.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// Delegate to get notified by the AppLovin SDK of rewarded presentation events.
  GADMAppLovinRewardedDelegate *_appLovinDelegate;

  /// Instance of the AppLovin SDK.
  ALSdk *_sdk;

  /// AppLovin incentivized interstitial object used to load an ad.
  ALIncentivizedInterstitialAd *_incent;

  /// Serializes the map table usage.
  dispatch_queue_t _lockQueue;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    // Store the completion handler for later use.
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler = [handler copy];
    _adLoadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
        _Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }
      id<GADMediationRewardedAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(ad, error);
      }
      originalCompletionHandler = nil;
      return delegate;
    };
    _sdk =
        [GADMAdapterAppLovinUtils retrieveSDKFromCredentials:_adConfiguration.credentials.settings];
    _lockQueue = dispatch_queue_create("applovin-rewardedAdapterDelegates", DISPATCH_QUEUE_SERIAL);
    _appLovinDelegate = [[GADMAppLovinRewardedDelegate alloc] initWithParentRenderer:self];

    // Create rewarded video object.
    _incent = [[ALIncentivizedInterstitialAd alloc] initWithSdk:_sdk];
    _incent.adDisplayDelegate = _appLovinDelegate;
    _incent.adVideoPlaybackDelegate = _appLovinDelegate;
  }
  return self;
}

- (void)requestRewardedAd {
  if (!_sdk) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, @"Invalid server parameters.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _zoneIdentifier = [GADMAdapterAppLovinUtils zoneIdentifierForAdConfiguration:_adConfiguration];

  // Unable to resolve a valid zone - error out
  if (!self.zoneIdentifier) {
    NSString *errorMessage = @"Invalid custom zone entered. Please double-check your credentials.";
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, errorMessage);

    _adLoadCompletionHandler(nil, error);
    return;
  }

  GADMAdapterAppLovinMediationManager *sharedInstance =
      GADMAdapterAppLovinMediationManager.sharedInstance;
  if ([sharedInstance containsAndAddRewardedZoneIdentifier:_zoneIdentifier]) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorAdAlreadyLoaded,
        @"Can't request a second ad for the same zone identifier without showing the first ad.");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  [GADMAdapterAppLovinUtils log:@"Requesting rewarded ad for zone: %@", _zoneIdentifier];

  if (_adConfiguration.bidResponse) {
    // Load ad.
    [_sdk.adService loadNextAdForAdToken:_adConfiguration.bidResponse andNotify:_appLovinDelegate];
    return;
  }

  // If this is a default Zone, create the incentivized ad normally.
  if ([GADMAdapterAppLovinDefaultZoneIdentifier isEqual:_zoneIdentifier]) {
    // Loading an ad for default zone must be done through zone-agnostic
    // `ALIncentivizedInterstitialAd` instance
    [_incent preloadAndNotify:_appLovinDelegate];
  }
  // If custom zone id
  else {
    [_sdk.adService loadNextAdForZoneIdentifier:_zoneIdentifier andNotify:_appLovinDelegate];
  }
}

- (void)presentFromViewController:(UIViewController *)viewController {
  // Update mute state.
  GADMAdapterAppLovinExtras *networkExtras = _adConfiguration.extras;
  _sdk.settings.muted = networkExtras.muteAudio;

  if (_ad) {
    [GADMAdapterAppLovinUtils log:@"Showing rewarded video for zone: %@", _zoneIdentifier];
    [_incent showAd:_ad andNotify:_appLovinDelegate];
  } else {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorShow, @"Attempting to show rewarded video before one was loaded");
    [_delegate didFailToPresentWithError:error];
  }
}

- (void)dealloc {
  _appLovinDelegate = nil;
  _incent.adVideoPlaybackDelegate = nil;
  _incent.adDisplayDelegate = nil;
  [GADMAdapterAppLovinMediationManager.sharedInstance removeRewardedZoneIdentifier:_zoneIdentifier];
}

@end
