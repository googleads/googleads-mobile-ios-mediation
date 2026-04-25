// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMWaterfallAppLovinBannerRenderer.h"
#import <Foundation/Foundation.h>
#include <stdatomic.h>
#import "GADMAdapterAppLovinUtils.h"

#pragma mark - Ad lifecyle events declaration

/// These events are expected to be invoked by AppLovin's delegate (i.e.
/// GADMWaterfallAppLovinBannerDelegate).
@interface GADMWaterfallAppLovinBannerRenderer (AdLifeCycleEvents)

- (void)loadedAd:(nonnull ALAd *)ad;

- (void)failedToLoadAdWithError:(int)code;

- (void)displayedAdInView:(nonnull UIView *)view;

- (void)hidAdInView:(nonnull UIView *)view;

- (void)reportClickOnAdInView:(nonnull UIView *)view;

- (void)didPresentFullscreenForAdView:(nonnull ALAdView *)adView;

- (void)willDismissFullscreenForAdView:(nonnull ALAdView *)adView;

- (void)didDismissFullscreenForAdView:(nonnull ALAdView *)adView;

- (void)willLeaveApplicationForAdView:(nonnull ALAdView *)adView;

- (void)didFailToDisplayInAdView:(nonnull ALAdView *)adView
                       withError:(ALAdViewDisplayErrorCode)code;

@end

#pragma mark - Private Delegate Class

/// Delegate for handling AppLovin banner ad events. AppLovin's delegate protocols are
/// implemented in a separate class to avoid a retain cycle, as the AppLovin SDK keeps a strong
/// reference to its delegate.
@interface GADMWaterfallAppLovinBannerDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdViewEventDelegate>

- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMWaterfallAppLovinBannerRenderer *)parentRenderer;

@end

@implementation GADMWaterfallAppLovinBannerDelegate {
  __weak GADMWaterfallAppLovinBannerRenderer *_parentRenderer;
}

- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMWaterfallAppLovinBannerRenderer *)parentRenderer {
  self = [super init];
  if (self) {
    _parentRenderer = parentRenderer;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad {
  [_parentRenderer loadedAd:ad];
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code {
  [_parentRenderer failedToLoadAdWithError:code];
}

#pragma mark - Ad Display Delegate

- (void)ad:(nonnull ALAd *)ad wasDisplayedIn:(nonnull UIView *)view {
  [_parentRenderer displayedAdInView:view];
}

- (void)ad:(nonnull ALAd *)ad wasHiddenIn:(nonnull UIView *)view {
  [_parentRenderer hidAdInView:view];
}

- (void)ad:(nonnull ALAd *)ad wasClickedIn:(nonnull UIView *)view {
  [_parentRenderer reportClickOnAdInView:view];
}

#pragma mark - Ad View Event Delegate

- (void)ad:(nonnull ALAd *)ad didPresentFullscreenForAdView:(nonnull ALAdView *)adView {
  [_parentRenderer didPresentFullscreenForAdView:adView];
}

- (void)ad:(nonnull ALAd *)ad willDismissFullscreenForAdView:(nonnull ALAdView *)adView {
  [_parentRenderer willDismissFullscreenForAdView:adView];
}

- (void)ad:(nonnull ALAd *)ad didDismissFullscreenForAdView:(nonnull ALAdView *)adView {
  [_parentRenderer didDismissFullscreenForAdView:adView];
}

- (void)ad:(nonnull ALAd *)ad willLeaveApplicationForAdView:(nonnull ALAdView *)adView {
  [_parentRenderer willLeaveApplicationForAdView:adView];
}

- (void)ad:(nonnull ALAd *)ad
    didFailToDisplayInAdView:(nonnull ALAdView *)adView
                   withError:(ALAdViewDisplayErrorCode)code {
  [_parentRenderer didFailToDisplayInAdView:adView withError:code];
}

@end

#pragma mark - Main Renderer Class

/// Renderer for AppLovin waterfall banner ad. Loads a banner ad and handles ad lifecycle events.
@interface GADMWaterfallAppLovinBannerRenderer ()

/// Block to notify the Google Mobile Ads SDK if ad loading succeeded or failed.
@property(nonatomic, copy, nullable)
    GADMediationBannerLoadCompletionHandler adLoadCompletionHandler;

/// Identifier to identify AppLovin's ad zone.
@property(nonatomic, nullable) NSString *zoneIdentifier;

/// An AppLovin banner ad view.
@property(nonatomic, nullable) ALAdView *adView;

/// Delegate to notify the Google Mobile Ads SDK of presentation events.
@property(nonatomic, weak, nullable) id<GADMediationBannerAdEventDelegate> delegate;

@end

@implementation GADMWaterfallAppLovinBannerRenderer {
  GADMediationBannerAdConfiguration *_adConfiguration;

  /// Once token for ensuring that [_adView render] is called only once.
  dispatch_once_t _adViewRenderOnceToken;

  /// Boolean to check that loadAd() isn't called more than once.
  BOOL _loadAlreadyStarted;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationBannerAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadAdWithCompletion:(GADMediationBannerLoadCompletionHandler _Nonnull __strong)completion {
#if DEBUG
  NSAssert(!_loadAlreadyStarted, @"Trying to load a new ad while already loading/loaded one");
  _loadAlreadyStarted = YES;
#endif
  // Store the completion handler for later use.
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationBannerLoadCompletionHandler originalCompletionHandler = [completion copy];
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

  ALSdk *sharedALSdk = [ALSdk shared];
  if (!sharedALSdk) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorAppLovinSDKNotInitialized,
        @"Failed to retrieve ALSdk shared instance. ");
    _adLoadCompletionHandler(nil, error);
    return;
  }

  _zoneIdentifier = [GADMAdapterAppLovinUtils zoneIdentifierForAdConfiguration:_adConfiguration];
  // Unable to resolve a valid zone - error out
  if (!_zoneIdentifier) {
    NSString *errorString = @"Invalid custom zone entered. Please double-check your credentials.";
    NSError *zoneIdentifierError = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorInvalidServerParameters, errorString);
    _adLoadCompletionHandler(nil, zoneIdentifierError);
    return;
  }

  GADAdSize adSize = _adConfiguration.adSize;

  [GADMAdapterAppLovinUtils log:@"NEW API: Requesting banner of size %@ for zone: %@.",
                                NSStringFromGADAdSize(adSize), _zoneIdentifier];

  // Convert requested size to AppLovin Ad Size.
  ALAdSize *appLovinAdSize = [GADMAdapterAppLovinUtils appLovinAdSizeFromRequestedSize:adSize];
  if (!appLovinAdSize) {
    NSString *errorMessage = [NSString
        stringWithFormat:@"Adapter requested to display a banner ad of unsupported size: %@",
                         NSStringFromGADAdSize(adSize)];
    NSError *adSizeError = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorBannerSizeMismatch, errorMessage);
    _adLoadCompletionHandler(nil, adSizeError);
    return;
  }

  _adView = [[ALAdView alloc] initWithSdk:sharedALSdk size:appLovinAdSize];

  CGSize size = CGSizeFromGADAdSize(adSize);
  _adView.frame = CGRectMake(0, 0, size.width, size.height);

  GADMWaterfallAppLovinBannerDelegate *appLovinDelegate =
      [[GADMWaterfallAppLovinBannerDelegate alloc] initWithParentRenderer:self];
  _adView.adLoadDelegate = appLovinDelegate;
  _adView.adDisplayDelegate = appLovinDelegate;
  _adView.adEventDelegate = appLovinDelegate;

  if (_zoneIdentifier.length) {
    [sharedALSdk.adService loadNextAdForZoneIdentifier:_zoneIdentifier andNotify:appLovinDelegate];
  } else {
    [sharedALSdk.adService loadNextAd:appLovinAdSize andNotify:appLovinDelegate];
  }
}

- (UIView *)view {
  return _adView;
}

#pragma mark - Handle ad lifecycle events

- (void)loadedAd:(nonnull ALAd *)ad {
  [GADMAdapterAppLovinUtils log:@"Banner did load ad: %@", ad];
  dispatch_once(&_adViewRenderOnceToken, ^{
    [_adView render:ad];
  });
  if (_adLoadCompletionHandler) {
    _delegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)failedToLoadAdWithError:(int)code {
  NSError *error = GADMAdapterAppLovinSDKErrorWithCode(code);
  if (_adLoadCompletionHandler) {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)displayedAdInView:(nonnull UIView *)view {
#if DEBUG
  NSAssert([view isEqual:_adView],
           @"AppLovinAdapter: Received ad displayed callback for an unexpected view");
#endif
  [GADMAdapterAppLovinUtils log:@"Banner displayed"];
  [_delegate reportImpression];
}

- (void)hidAdInView:(nonnull UIView *)view {
#if DEBUG
  NSAssert([view isEqual:_adView],
           @"AppLovinAdapter: Received ad hidden callback for an unexpected view");
#endif
  [GADMAdapterAppLovinUtils log:@"Banner dismissed"];
  // There is no callback on GMA SDK for banner ad dismissal.
}

- (void)reportClickOnAdInView:(nonnull UIView *)view {
#if DEBUG
  NSAssert([view isEqual:_adView],
           @"AppLovinAdapter: Received ad click callback for an unexpected view");
#endif
  [GADMAdapterAppLovinUtils log:@"Banner clicked"];
  [_delegate reportClick];
}

- (void)didPresentFullscreenForAdView:(nonnull ALAdView *)adView {
#if DEBUG
  NSAssert([adView isEqual:_adView],
           @"AppLovinAdapter: Received fullscreen present callback for an unexpected view");
#endif
  [GADMAdapterAppLovinUtils log:@"Banner presented fullscreen"];
  // Call willPresentFullScreenView. We don't get an earlier callback from AppLovin on banner view
  // presenting fullscreen and so this is the earliest we can call willPresentFullScreenView. There
  // is no corresponding callback on GMA SDK for didPresentFullscreenForAdView.
  [_delegate willPresentFullScreenView];
}

- (void)willDismissFullscreenForAdView:(nonnull ALAdView *)adView {
#if DEBUG
  NSAssert([adView isEqual:_adView],
           @"AppLovinAdapter: Received will-dismiss-fullscreen callback for an unexpected view");
#endif
  [GADMAdapterAppLovinUtils log:@"Banner will dismiss fullscreen"];
  [_delegate willDismissFullScreenView];
}

- (void)didDismissFullscreenForAdView:(nonnull ALAdView *)adView {
#if DEBUG
  NSAssert([adView isEqual:_adView],
           @"AppLovinAdapter: Received did-dismiss-fullscreen callback for an unexpected view");
#endif
  [GADMAdapterAppLovinUtils log:@"Banner did dismiss fullscreen"];
  [_delegate didDismissFullScreenView];
}

- (void)willLeaveApplicationForAdView:(nonnull ALAdView *)adView {
#if DEBUG
  NSAssert([adView isEqual:_adView],
           @"AppLovinAdapter: Received will-leave-application callback for an unexpected view");
#endif
  [GADMAdapterAppLovinUtils log:@"Banner left application"];
  // There is no corresponding callback on GMA SDK for willLeaveApplicationForAdView.
}

- (void)didFailToDisplayInAdView:(nonnull ALAdView *)adView
                       withError:(ALAdViewDisplayErrorCode)code {
#if DEBUG
  NSAssert([adView isEqual:_adView],
           @"AppLovinAdapter: Received display failure callback for an unexpected view");
#endif
  [GADMAdapterAppLovinUtils log:@"Banner failed to display: %ld", (long)code];
  [_delegate didFailToPresentWithError:GADMAdapterAppLovinSDKErrorWithCode(code)];
}

@end
