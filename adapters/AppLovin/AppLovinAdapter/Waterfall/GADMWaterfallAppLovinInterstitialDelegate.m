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

#import "GADMWaterfallAppLovinInterstitialDelegate.h"
#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMWaterfallAppLovinInterstitialRenderer.h"

/// Delegate for handling AppLovin interstitial ad events.
@implementation GADMWaterfallAppLovinInterstitialDelegate {
  /// AppLovin interstitial ad renderer.
  __weak GADMWaterfallAppLovinInterstitialRenderer *_parentRenderer;
}

#pragma mark - Initialization

- (nonnull instancetype)initWithParentRenderer:
    (nonnull GADMWaterfallAppLovinInterstitialRenderer *)parentRenderer {
  self = [super init];
  if (self) {
    _parentRenderer = parentRenderer;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad {
  GADMWaterfallAppLovinInterstitialRenderer *parentRenderer = _parentRenderer;
  if (parentRenderer) {
    BOOL isMultipleAdsEnabled = GADMAdapterAppLovinIsMultipleAdsLoadingEnabled();
    if (isMultipleAdsEnabled) {
      [GADMAdapterAppLovinMediationManager.sharedInstance
          removeInterstitialZoneIdentifier:parentRenderer.zoneIdentifier];
    }

    [GADMAdapterAppLovinUtils log:@"Interstitial did load ad: %@", ad];
    parentRenderer.interstitialAd = ad;
    parentRenderer.delegate = parentRenderer.adLoadCompletionHandler(parentRenderer, nil);
  }
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code {
  GADMWaterfallAppLovinInterstitialRenderer *parentRenderer = _parentRenderer;
  if (parentRenderer) {
    [GADMAdapterAppLovinMediationManager.sharedInstance
        removeInterstitialZoneIdentifier:parentRenderer.zoneIdentifier];
    NSError *error = GADMAdapterAppLovinSDKErrorWithCode(code);
    parentRenderer.adLoadCompletionHandler(nil, error);
  }
}

#pragma mark - Ad Display Delegate

- (void)ad:(nonnull ALAd *)ad wasDisplayedIn:(nonnull UIView *)view {
  id<GADMediationInterstitialAdEventDelegate> delegate = _parentRenderer.delegate;
  [delegate willPresentFullScreenView];
  [delegate reportImpression];
}

- (void)ad:(nonnull ALAd *)ad wasHiddenIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial hidden"];
  GADMWaterfallAppLovinInterstitialRenderer *parentRenderer = _parentRenderer;
  if (parentRenderer) {
    [GADMAdapterAppLovinMediationManager.sharedInstance
        removeInterstitialZoneIdentifier:parentRenderer.zoneIdentifier];
    id<GADMediationInterstitialAdEventDelegate> delegate = parentRenderer.delegate;
    [delegate willDismissFullScreenView];
    [delegate didDismissFullScreenView];
  }
}

- (void)ad:(nonnull ALAd *)ad wasClickedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial clicked"];
  [_parentRenderer.delegate reportClick];
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
