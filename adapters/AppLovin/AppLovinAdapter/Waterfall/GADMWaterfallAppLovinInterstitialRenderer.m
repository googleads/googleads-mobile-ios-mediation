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
#import "GADMWaterfallAppLovinInterstitialDelegate.h"

#include <GoogleMobileAds/GoogleMobileAds.h>
#include <stdatomic.h>

/// Renderer for AppLovin waterfall interstitial ads.
@implementation GADMWaterfallAppLovinInterstitialRenderer {
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// AppLovin interstitial object used to request an ad.
  ALInterstitialAd *_interstitial;
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
  if (!ALSdk.shared) {
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

  [GADMAdapterAppLovinUtils log:@"Requesting interstitial for zone: %@", self.zoneIdentifier];

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

  ALSdk.shared.settings.muted = GADMobileAds.sharedInstance.applicationMuted;
  _interstitial = [[ALInterstitialAd alloc] initWithSdk:ALSdk.shared];
  GADMWaterfallAppLovinInterstitialDelegate *interstitialDelegate =
      [[GADMWaterfallAppLovinInterstitialDelegate alloc] initWithParentRenderer:self];
  _interstitial.adDisplayDelegate = interstitialDelegate;
  _interstitial.adVideoPlaybackDelegate = interstitialDelegate;

  if (_zoneIdentifier.length > 0) {
    [ALSdk.shared.adService loadNextAdForZoneIdentifier:_zoneIdentifier
                                              andNotify:interstitialDelegate];
  } else {
    [ALSdk.shared.adService loadNextAd:ALAdSize.interstitial andNotify:interstitialDelegate];
  }
}

#pragma mark - GADMediationInterstitalAd

- (void)presentFromViewController:(UIViewController *)viewController {
  [GADMAdapterAppLovinUtils log:@"Showing interstitial ad for zone: %@.", _zoneIdentifier];
  [_interstitial showAd:_interstitialAd];
}

@end
