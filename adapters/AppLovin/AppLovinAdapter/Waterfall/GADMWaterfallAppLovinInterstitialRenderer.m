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

#import "GADMWaterfallAppLovinInterstitialRenderer.h"
#import "GADMAdapterAppLovinInitializer.h"
#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"

#include <GoogleMobileAds/GoogleMobileAds.h>
#include <stdatomic.h>

#pragma mark - Ad lifecyle events declaration

/// These events are expected to be invoked by AppLovin's delegate (i.e.
/// GADMWaterfallAppLovinInterstitialDelegate).
@interface GADMWaterfallAppLovinInterstitialRenderer (AdLifeCycleEvents)

/// To be called by AppLovin's delegate to notify that the interstitial ad is loaded.
- (void)loadedAd:(nonnull ALAd *)ad;

/// To be called by AppLovin's delegate to notify that the interstitial ad failed to load.
- (void)failedToLoadAdWithError:(int)code;

/// To be called by AppLovin's delegate to notify that the interstitial ad was displayed.
- (void)displayedAd:(nonnull ALAd *)ad;

/// To be called by AppLovin's delegate to notify that the interstitial ad was hidden.
- (void)hidAd:(nonnull ALAd *)ad;

/// To be called by AppLovin's delegate to report that the interstitial ad was clicked.
- (void)reportClickOnAd:(nonnull ALAd *)ad;

@end

#pragma mark - Private Delegate Class

/// Delegate for handling AppLovin interstitial ad events. AppLovin's delegate protocols are
/// implemented in a separate class to avoid a retain cycle, as the AppLovin SDK keeps a strong
/// reference to its delegate.
@interface GADMWaterfallAppLovinInterstitialDelegate
    : NSObject <ALAdLoadDelegate, ALAdDisplayDelegate, ALAdVideoPlaybackDelegate>

/// Initializes an interstitial ad delegate with parent renderer. Here parent renderer is a wrapper
/// to the AppLovin's interstitial ad and is used to request and present interstitial ads from
/// AppLovin SDK.
- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMWaterfallAppLovinInterstitialRenderer *)parentRenderer;

@end

@implementation GADMWaterfallAppLovinInterstitialDelegate {
  /// AppLovin interstitial ad renderer.
  __weak GADMWaterfallAppLovinInterstitialRenderer *_parentRenderer;
}

- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMWaterfallAppLovinInterstitialRenderer *)parentRenderer {
  self = [super init];
  if (self) {
    _parentRenderer = parentRenderer;
  }
  return self;
}

- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad {
  [_parentRenderer loadedAd:ad];
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code {
  [_parentRenderer failedToLoadAdWithError:code];
}

- (void)ad:(nonnull ALAd *)ad wasDisplayedIn:(nonnull UIView *)view {
  [_parentRenderer displayedAd:ad];
}

- (void)ad:(nonnull ALAd *)ad wasHiddenIn:(nonnull UIView *)view {
  [_parentRenderer hidAd:ad];
}

- (void)ad:(nonnull ALAd *)ad wasClickedIn:(nonnull UIView *)view {
  [_parentRenderer reportClickOnAd:ad];
}

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

#pragma mark - Main Renderer Class

/// Renderer for AppLovin waterfall interstitial ads. Loads and shows an interstitial ad and handles
/// ad lifecycle events.
@interface GADMWaterfallAppLovinInterstitialRenderer ()

/// Block to notify the Google Mobile Ads SDK if ad loading succeeded or failed.
@property(nonatomic, copy, nullable)
    GADMediationInterstitialLoadCompletionHandler adLoadCompletionHandler;

/// Identifier to identify AppLovin's ad zone.
@property(nonatomic, nullable) NSString *zoneIdentifier;

/// Object holding loaded AppLovin interstitial ad.
@property(nonatomic, nullable) ALAd *interstitialAd;

/// Delegate to notify the Google Mobile Ads SDK of presentation events.
@property(nonatomic, weak, nullable) id<GADMediationInterstitialAdEventDelegate> delegate;

@end

@implementation GADMWaterfallAppLovinInterstitialRenderer {
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// AppLovin object used to request and show an interstitial ad.
  ALInterstitialAd *_interstitial;

  /// Once token for ensuring that self.interstitalAd is set only once.
  dispatch_once_t _interstitialAdOnceToken;

  /// Boolean to check that loadAd() isn't called more than once.
  BOOL _loadAlreadyStarted;
}

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationInterstitialAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadAdWithCompletion:(GADMediationInterstitialLoadCompletionHandler _Nonnull)completion {
#if DEBUG
  NSCAssert(!_loadAlreadyStarted, @"Trying to load a new ad while already loading/loaded one");
  _loadAlreadyStarted = YES;
#endif
  // Store the completion handler for later use.
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
      [completion copy];
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

  [GADMAdapterAppLovinUtils log:@"Requesting interstitial for zone: %@", _zoneIdentifier];

  GADMAdapterAppLovinMediationManager *sharedManager =
      GADMAdapterAppLovinMediationManager.sharedInstance;
  if ([sharedManager containsAndAddInterstitialZoneIdentifier:_zoneIdentifier]) {
    NSError *adAlreadyLoadedError = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorAdAlreadyLoaded,
        @"Can't request a second ad for the same zone identifier without showing "
        @"the first ad.");
    _adLoadCompletionHandler(nil, adAlreadyLoadedError);
    return;
  }

  sharedALSdk.settings.muted = GADMobileAds.sharedInstance.applicationMuted;
  _interstitial = [[ALInterstitialAd alloc] initWithSdk:sharedALSdk];
  GADMWaterfallAppLovinInterstitialDelegate *interstitialDelegate =
      [[GADMWaterfallAppLovinInterstitialDelegate alloc] initWithParentRenderer:self];
  _interstitial.adDisplayDelegate = interstitialDelegate;
  _interstitial.adVideoPlaybackDelegate = interstitialDelegate;

  if (_zoneIdentifier.length > 0) {
    [sharedALSdk.adService loadNextAdForZoneIdentifier:_zoneIdentifier
                                             andNotify:interstitialDelegate];
  } else {
    [sharedALSdk.adService loadNextAd:ALAdSize.interstitial andNotify:interstitialDelegate];
  }
}

#pragma mark - GADMediationInterstitalAd implementation

- (void)presentFromViewController:(UIViewController *)viewController {
  [GADMAdapterAppLovinUtils log:@"Showing interstitial ad for zone: %@.", _zoneIdentifier];
  [_interstitial showAd:_interstitialAd];
}

#pragma mark - Handle ad lifecycle events

- (void)loadedAd:(nonnull ALAd *)ad {
  BOOL isMultipleAdsEnabled = GADMAdapterAppLovinIsMultipleAdsLoadingEnabled();
  if (isMultipleAdsEnabled) {
    [GADMAdapterAppLovinMediationManager.sharedInstance
        removeInterstitialZoneIdentifier:_zoneIdentifier];
  }
  [GADMAdapterAppLovinUtils log:@"Interstitial did load ad: %@", ad];
  dispatch_once(&_interstitialAdOnceToken, ^{
    self->_interstitialAd = ad;
  });
  if (_adLoadCompletionHandler) {
    _delegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)failedToLoadAdWithError:(int)code {
  [GADMAdapterAppLovinMediationManager.sharedInstance
      removeInterstitialZoneIdentifier:_zoneIdentifier];
  NSError *error = GADMAdapterAppLovinSDKErrorWithCode(code);
  if (_adLoadCompletionHandler) {
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)displayedAd:(nonnull ALAd *)ad {
#if DEBUG
  NSCAssert([ad isEqual:_interstitialAd],
            @"AppLovinAdapter: Received ad displayed callback for an unexpected ad");
#endif
  [GADMAdapterAppLovinUtils log:@"Interstitial ad displayed"];
  id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)hidAd:(nonnull ALAd *)ad {
#if DEBUG
  NSCAssert([ad isEqual:_interstitialAd],
            @"AppLovinAdapter: Received ad hidden callback for an unexpected ad");
#endif
  [GADMAdapterAppLovinUtils log:@"Interstitial ad hidden"];
  [GADMAdapterAppLovinMediationManager.sharedInstance
      removeInterstitialZoneIdentifier:_zoneIdentifier];
  id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
  [delegate willDismissFullScreenView];
  [delegate didDismissFullScreenView];
}

- (void)reportClickOnAd:(nonnull ALAd *)ad {
#if DEBUG
  NSCAssert([ad isEqual:_interstitialAd],
            @"AppLovinAdapter: Received ad clicked callback for an unexpected ad");
#endif
  [GADMAdapterAppLovinUtils log:@"Interstitial ad clicked"];
  [_delegate reportClick];
}

@end
