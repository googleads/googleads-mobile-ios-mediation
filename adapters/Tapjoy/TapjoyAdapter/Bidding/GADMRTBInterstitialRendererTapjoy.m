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

#import "GADMRTBInterstitialRendererTapjoy.h"

#import <Tapjoy/Tapjoy.h>

#import "GADMAdapterTapjoy.h"
#import "GADMAdapterTapjoyConstants.h"
#import "GADMAdapterTapjoyDelegate.h"
#import "GADMAdapterTapjoySingleton.h"
#import "GADMAdapterTapjoyUtils.h"
#import "GADMTapjoyExtras.h"
#import "GADMediationAdapterTapjoy.h"

@interface GADMRTBInterstitialRendererTapjoy () <GADMediationInterstitialAd,
                                                 GADMAdapterTapjoyDelegate>
@end

@implementation GADMRTBInterstitialRendererTapjoy {
  /// Interstitial ad configuration for the ad to be loaded.
  GADMediationInterstitialAdConfiguration *_adConfig;

  /// Completion handler to call when an ad loads successfully or fails.
  GADMediationInterstitialLoadCompletionHandler _renderCompletionHandler;

  /// The ad event delegate to forward ad events to the Google Mobile Ads SDK.
  /// Intentionally keeping a strong reference to the delegate because this is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationInterstitialAdEventDelegate> _delegate;

  /// Tapjoy interstitial ad object.
  TJPlacement *_interstitialAd;

  /// Tapjoy placement name.
  NSString *_placementName;
}

/// Asks the receiver to render the ad configuration.
- (void)renderInterstitialForAdConfig:(nonnull GADMediationInterstitialAdConfiguration *)adConfig
                    completionHandler:
                        (nonnull GADMediationInterstitialLoadCompletionHandler)handler {
  _renderCompletionHandler = handler;
  _adConfig = adConfig;
  _placementName = adConfig.credentials.settings[GADMAdapterTapjoyPlacementKey];
  NSString *sdkKey = adConfig.credentials.settings[GADMAdapterTapjoySdkKey];

  if (!sdkKey.length || !_placementName.length) {
    NSError *adapterError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorInvalidServerParameters,
        @"Did not receive valid Tapjoy server parameters.");
    handler(nil, adapterError);
    return;
  }

  GADMTapjoyExtras *extras = adConfig.extras;
  GADMAdapterTapjoySingleton *sharedInstance = [GADMAdapterTapjoySingleton sharedInstance];

  if (Tapjoy.isConnected) {
    [self requestInterstitialAd];
    return;
  }

  // Tapjoy is not yet connected. Wait for initialization to complete before requesting a placement.
  NSDictionary<NSString *, NSNumber *> *connectOptions =
      @{TJC_OPTION_ENABLE_LOGGING : @(extras.debugEnabled)};
  GADMRTBInterstitialRendererTapjoy *__weak weakSelf = self;
  [sharedInstance initializeTapjoySDKWithSDKKey:sdkKey
                                        options:connectOptions
                              completionHandler:^(NSError *error) {
                                GADMRTBInterstitialRendererTapjoy *__strong strongSelf = weakSelf;
                                if (!strongSelf) {
                                  return;
                                }

                                if (error) {
                                  handler(nil, error);
                                  return;
                                }
                                [strongSelf requestInterstitialAd];
                              }];
}

- (void)requestInterstitialAd {
  GADMTapjoyExtras *extras = _adConfig.extras;
  [Tapjoy setDebugEnabled:extras.debugEnabled];
  _interstitialAd =
      [[GADMAdapterTapjoySingleton sharedInstance] requestAdForPlacementName:_placementName
                                                                 bidResponse:_adConfig.bidResponse
                                                                    delegate:self];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (_interstitialAd.isContentAvailable) {
    [_interstitialAd showContentWithViewController:viewController];
  }
}

#pragma mark - TajoyPlacementDelegate methods

- (void)requestDidSucceed:(nonnull TJPlacement *)placement {
  // If the placement's content is not available at this time, then the request is considered a
  // failure.
  if (!placement.contentAvailable) {
    NSError *loadError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorPlacementContentNotAvailable, @"Ad not available.");
    _renderCompletionHandler(nil, loadError);
  }
}

- (void)requestDidFail:(nonnull TJPlacement *)placement error:(nullable NSError *)error {
  if (!error) {
    NSError *nullError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorUnknown, @"Tapjoy SDK placement unknown error.");
    _renderCompletionHandler(nil, nullError);
    return;
  }
  _renderCompletionHandler(nil, error);
}

- (void)contentIsReady:(nonnull TJPlacement *)placement {
  _delegate = _renderCompletionHandler(self, nil);
}

- (void)contentDidAppear:(nonnull TJPlacement *)placement {
  [_delegate willPresentFullScreenView];
  [_delegate reportImpression];
}

- (void)didClick:(TJPlacement *)placement {
  [_delegate reportClick];
  [_delegate willBackgroundApplication];
}

- (void)contentDidDisappear:(nonnull TJPlacement *)placement {
  [_delegate willDismissFullScreenView];
  [_delegate didDismissFullScreenView];
}

#pragma mark - TJPlacementVideoDelegate methods

- (void)videoDidStart:(nonnull TJPlacement *)placement {
  // Do nothing.
}

- (void)videoDidComplete:(nonnull TJPlacement *)placement {
  // Do nothing.
}

- (void)videoDidFail:(nonnull TJPlacement *)placement error:(nullable NSString *)errorMsg {
  // Do nothing.
}

#pragma mark - GADMAdapterTapjoyDelegate

- (void)didFailToLoadWithError:(nonnull NSError *)error {
  _renderCompletionHandler(nil, error);
}

@end
