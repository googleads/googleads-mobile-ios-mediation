//
//  GADMRTBAdapterAppLovinBannerRenderer.m
//  Adapter
//
//  Created by Christopher Cong on 7/17/18.
//  Copyright © 2018 Google. All rights reserved.
//

#import "GADMRTBAdapterAppLovinBannerRenderer.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinUtils.h"

#import <AppLovinSDK/AppLovinSDK.h>
#include <stdatomic.h>

/// AppLovin Banner Delegate wrapper. AppLovin banner protocols are implemented in a separate class
/// to avoid a retain cycle, as the AppLovin SDK keep a strong reference to its delegate.
@interface GADMAppLovinRtbBannerDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>

/// AppLovin banner ad renderer to which the events are delegated.
@property(nonatomic, weak) GADMRTBAdapterAppLovinBannerRenderer *parentRenderer;

- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMRTBAdapterAppLovinBannerRenderer *)parentRenderer;

@end

@interface GADMRTBAdapterAppLovinBannerRenderer () <GADMediationBannerAd>

/// Callback object to notify the Google Mobile Ads SDK if ad rendering succeeded or failed.
@property(nonatomic, readonly) GADMediationBannerLoadCompletionHandler adLoadCompletionHandler;

/// Delegate to notify the Google Mobile Ads SDK of banner presentation events.
@property(nonatomic, weak, nullable) id<GADMediationBannerAdEventDelegate> delegate;

/// AppLovin banner ad view.
@property(nonatomic, readonly) ALAdView *adView;

@end

@implementation GADMRTBAdapterAppLovinBannerRenderer {
  /// Data used to render an banner ad.
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// Instance of the AppLovin SDK.
  ALSdk *_sdk;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationBannerAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationBannerLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    // Store the completion handler for later use.
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationBannerLoadCompletionHandler originalCompletionHandler = [handler copy];
    _adLoadCompletionHandler = ^id<GADMediationBannerAdEventDelegate>(
        _Nullable id<GADMediationBannerAd> ad, NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }
      id<GADMediationBannerAdEventDelegate> delegate = nil;
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

  // Convert requested size to AppLovin Ad Size.
  ALAdSize *appLovinAdSize =
      [GADMAdapterAppLovinUtils appLovinAdSizeFromRequestedSize:_adConfiguration.adSize];

  if (!appLovinAdSize) {
    NSString *errorString =
        [NSString stringWithFormat:@"Failed to request banner with unsupported size : %@",
                                   NSStringFromCGSize(_adConfiguration.adSize.size)];
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(kGADErrorMediationInvalidAdSize,
                                                                    errorString);
    _adLoadCompletionHandler(nil, error);
    return;
  }

  // Create adview object.
  _adView = [[ALAdView alloc] initWithSdk:_sdk size:appLovinAdSize];

  GADMAppLovinRtbBannerDelegate *delegate =
      [[GADMAppLovinRtbBannerDelegate alloc] initWithParentRenderer:self];
  _adView.adDisplayDelegate = delegate;
  _adView.adEventDelegate = delegate;

  // Load ad.
  [_sdk.adService loadNextAdForAdToken:_adConfiguration.bidResponse andNotify:delegate];
}

#pragma mark - GADMediationBannerAd

- (nonnull UIView *)view {
  return _adView;
}

- (void)dealloc {
  _adView.adDisplayDelegate = nil;
  _adView.adEventDelegate = nil;
}

@end

@implementation GADMAppLovinRtbBannerDelegate

#pragma mark - Initialization

- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMRTBAdapterAppLovinBannerRenderer *)parentRenderer {
  self = [super init];
  if (self) {
    _parentRenderer = parentRenderer;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"Banner did load ad: %@", ad];

  GADMRTBAdapterAppLovinBannerRenderer *parentRenderer = _parentRenderer;
  dispatch_async(dispatch_get_main_queue(), ^{
    if (parentRenderer.adLoadCompletionHandler) {
      parentRenderer.delegate = parentRenderer.adLoadCompletionHandler(parentRenderer, nil);
    }
  });
  [parentRenderer.adView render:ad];
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code {
  NSString *errorString =
      [NSString stringWithFormat:@"Failed to load banner ad with error: %d", code];
  [GADMAdapterAppLovinUtils log:errorString];
  GADMRTBAdapterAppLovinBannerRenderer *parentRenderer = _parentRenderer;
  NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
      [GADMAdapterAppLovinUtils toAdMobErrorCode:code], errorString);
  if (parentRenderer.adLoadCompletionHandler) {
    parentRenderer.adLoadCompletionHandler(nil, error);
  }
}

#pragma mark - Ad Display Delegate

- (void)ad:(nonnull ALAd *)ad wasDisplayedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Banner displayed"];
  [_parentRenderer.delegate reportImpression];
}

- (void)ad:(nonnull ALAd *)ad wasHiddenIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Banner dismissed"];
}

- (void)ad:(nonnull ALAd *)ad wasClickedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Banner clicked"];
  [_parentRenderer.delegate reportClick];
}

#pragma mark - Ad View Event Delegate

- (void)ad:(nonnull ALAd *)ad didPresentFullscreenForAdView:(nonnull ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner presented fullscreen"];
  [_parentRenderer.delegate willPresentFullScreenView];
}

- (void)ad:(nonnull ALAd *)ad willDismissFullscreenForAdView:(nonnull ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner will dismiss fullscreen"];
  [_parentRenderer.delegate willDismissFullScreenView];
}

- (void)ad:(nonnull ALAd *)ad didDismissFullscreenForAdView:(nonnull ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner did dismiss fullscreen"];
  [_parentRenderer.delegate didDismissFullScreenView];
}

- (void)ad:(nonnull ALAd *)ad willLeaveApplicationForAdView:(nonnull ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner left application"];
  [_parentRenderer.delegate willBackgroundApplication];
}

- (void)ad:(nonnull ALAd *)ad
    didFailToDisplayInAdView:(nonnull ALAdView *)adView
                   withError:(ALAdViewDisplayErrorCode)code {
  [GADMAdapterAppLovinUtils log:@"Banner failed to display: %ld", (long)code];
}

@end
