// Copyright 2019 Google LLC.
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

#import "GADMAdapterAppLovinInterstitialDelegate.h"
#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"

@implementation GADMAdapterAppLovinInterstitialDelegate {
  /// AppLovin interstitial ad renderer to which the events are delegated.
  __weak GADMAdapterAppLovin *_parentRenderer;
}

#pragma mark - Initialization

- (nonnull instancetype)initWithParentRenderer:(nonnull GADMAdapterAppLovin *)parentRenderer {
  self = [super init];
  if (self) {
    _parentRenderer = parentRenderer;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad {
  GADMAdapterAppLovin *parentRenderer = _parentRenderer;
  [GADMAdapterAppLovinUtils log:@"Interstitial did load ad: %@", ad];
  parentRenderer.interstitialAd = ad;
  [parentRenderer.connector adapterDidReceiveInterstitial:parentRenderer];
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code {
  GADMAdapterAppLovin *parentRenderer = _parentRenderer;
  [GADMAdapterAppLovinMediationManager.sharedInstance
      removeInterstitialZoneIdentifier:parentRenderer.zoneIdentifier];
  NSError *error = GADMAdapterAppLovinSDKErrorWithCode(code);
  [parentRenderer.connector adapter:parentRenderer didFailAd:error];
}

#pragma mark - Ad Display Delegate

- (void)ad:(nonnull ALAd *)ad wasDisplayedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial displayed"];
  GADMAdapterAppLovin *parentRenderer = _parentRenderer;
  [parentRenderer.connector adapterWillPresentInterstitial:parentRenderer];
}

- (void)ad:(nonnull ALAd *)ad wasHiddenIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial hidden"];
  GADMAdapterAppLovin *parentRenderer = _parentRenderer;
  [GADMAdapterAppLovinMediationManager.sharedInstance
      removeInterstitialZoneIdentifier:parentRenderer.zoneIdentifier];
  id<GADMAdNetworkConnector> strongConnector = parentRenderer.connector;
  [strongConnector adapterWillDismissInterstitial:parentRenderer];
  [strongConnector adapterDidDismissInterstitial:parentRenderer];
}

- (void)ad:(nonnull ALAd *)ad wasClickedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Interstitial clicked"];
  GADMAdapterAppLovin *parentRenderer = _parentRenderer;
  id<GADMAdNetworkConnector> strongConnector = parentRenderer.connector;
  [GADMAdapterAppLovinUtils log:@"Interstitial clicked"];
  [strongConnector adapterDidGetAdClick:parentRenderer];
  [strongConnector adapterWillLeaveApplication:parentRenderer];
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
