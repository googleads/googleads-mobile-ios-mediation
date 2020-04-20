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

#import "GADMAdapterAppLovinBannerDelegate.h"
#import "GADMAdapterAppLovin.h"
#import "GADMAdapterAppLovinUtils.h"

@implementation GADMAdapterAppLovinBannerDelegate {
  /// AppLovin banner ad renderer to which the events are delegated.
  __weak GADMAdapterAppLovin *_parentAdapter;
}

#pragma mark - Initialization

- (nonnull instancetype)initWithParentAdapter:(nonnull GADMAdapterAppLovin *)parentAdapter {
  self = [super init];
  if (self) {
    _parentAdapter = parentAdapter;
  }
  return self;
}

#pragma mark - Ad Load Delegate

- (void)adService:(nonnull ALAdService *)adService didLoadAd:(nonnull ALAd *)ad {
  GADMAdapterAppLovin *parentAdapter = _parentAdapter;
  [GADMAdapterAppLovinUtils log:@"Banner did load ad: %@", ad];
  [parentAdapter.adView render:ad];
  [parentAdapter.connector adapter:parentAdapter didReceiveAdView:parentAdapter.adView];
}

- (void)adService:(nonnull ALAdService *)adService didFailToLoadAdWithError:(int)code {
  GADMAdapterAppLovin *parentAdapter = _parentAdapter;
  NSError *error = GADMAdapterAppLovinSDKErrorWithCode(code);
  [parentAdapter.connector adapter:parentAdapter didFailAd:error];
}

#pragma mark - Ad Display Delegate

- (void)ad:(nonnull ALAd *)ad wasDisplayedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Banner displayed"];
}

- (void)ad:(nonnull ALAd *)ad wasHiddenIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Banner dismissed"];
}

- (void)ad:(nonnull ALAd *)ad wasClickedIn:(nonnull UIView *)view {
  [GADMAdapterAppLovinUtils log:@"Banner clicked"];
  GADMAdapterAppLovin *parentAdapter = _parentAdapter;
  [parentAdapter.connector adapterDidGetAdClick:parentAdapter];
}

#pragma mark - Ad View Event Delegate

- (void)ad:(nonnull ALAd *)ad didPresentFullscreenForAdView:(nonnull ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner presented fullscreen"];
  GADMAdapterAppLovin *parentAdapter = _parentAdapter;
  [parentAdapter.connector adapterWillPresentFullScreenModal:parentAdapter];
}

- (void)ad:(nonnull ALAd *)ad willDismissFullscreenForAdView:(nonnull ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner will dismiss fullscreen"];
  GADMAdapterAppLovin *parentAdapter = _parentAdapter;
  [parentAdapter.connector adapterWillDismissFullScreenModal:parentAdapter];
}

- (void)ad:(nonnull ALAd *)ad didDismissFullscreenForAdView:(nonnull ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner did dismiss fullscreen"];
  GADMAdapterAppLovin *parentAdapter = _parentAdapter;
  [parentAdapter.connector adapterDidDismissFullScreenModal:parentAdapter];
}

- (void)ad:(nonnull ALAd *)ad willLeaveApplicationForAdView:(nonnull ALAdView *)adView {
  [GADMAdapterAppLovinUtils log:@"Banner left application"];
  GADMAdapterAppLovin *parentAdapter = _parentAdapter;
  [parentAdapter.connector adapterWillLeaveApplication:parentAdapter];
}

- (void)ad:(nonnull ALAd *)ad
    didFailToDisplayInAdView:(nonnull ALAdView *)adView
                   withError:(ALAdViewDisplayErrorCode)code {
  [GADMAdapterAppLovinUtils log:@"Banner failed to display: %ld", (long)code];
}

@end
