// Copyright 2019 Google LLC
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

#import "GADMAppLovinRTBInterstitialDelegate.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"

@implementation GADMAppLovinRTBInterstitialDelegate {
  /// AppLovin interstitial ad renderer to which the events are delegated.
  __weak GADMRTBAdapterAppLovinInterstitialRenderer *_parentRenderer;
}

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
    NSError *error = GADMAdapterAppLovinSDKErrorWithCode(code);
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
