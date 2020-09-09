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

#import "GADMAppLovinRTBBannerDelegate.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinMediationManager.h"
#import "GADMAdapterAppLovinUtils.h"

@implementation GADMAppLovinRTBBannerDelegate {
  /// AppLovin banner ad renderer to which the events are delegated.
  __weak GADMRTBAdapterAppLovinBannerRenderer *_parentRenderer;
}

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
  GADMRTBAdapterAppLovinBannerRenderer *parentRenderer = _parentRenderer;
  if (parentRenderer.adLoadCompletionHandler) {
    NSError *error = GADMAdapterAppLovinSDKErrorWithCode(code);
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
