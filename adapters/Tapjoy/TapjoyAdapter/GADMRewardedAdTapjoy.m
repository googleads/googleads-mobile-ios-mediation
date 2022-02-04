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

#import "GADMRewardedAdTapjoy.h"

#import <Tapjoy/Tapjoy.h>

#include <stdatomic.h>

#import "GADMAdapterTapjoy.h"
#import "GADMAdapterTapjoyConstants.h"
#import "GADMAdapterTapjoyDelegate.h"
#import "GADMAdapterTapjoySingleton.h"
#import "GADMAdapterTapjoyUtils.h"
#import "GADMTapjoyExtras.h"

@interface GADMRewardedAdTapjoy () <GADMediationRewardedAd, GADMAdapterTapjoyDelegate>
@end

@implementation GADMRewardedAdTapjoy {
  /// Rewarded ad configuration for the ad to be loaded.
  GADMediationRewardedAdConfiguration *_adConfig;

  /// Completion handler to call when an ad loads successfully or fails.
  GADMediationRewardedLoadCompletionHandler _completionHandler;

  /// The ad event delegate to forward ad events to the Google Mobile Ads SDK.
  /// Intentionally keeping a strong reference to the delegate because this is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// Tapjoy rewarded ad object.
  TJPlacement *_rewardedAd;

  /// Tapjoy placement name.
  NSString *_placementName;
}

- (void)loadRewardedAdForAdConfiguration:
            (nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  _adConfig = adConfiguration;

  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];

  // Ensure the original completion handler is only called once, and is deallocated once called.
  _completionHandler = ^id<GADMediationRewardedAdEventDelegate>(
      _Nullable id<GADMediationRewardedAd> ad, NSError *_Nullable error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }

    id<GADMediationRewardedAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(ad, error);
    }

    originalCompletionHandler = nil;
    return delegate;
  };

  _placementName = adConfiguration.credentials.settings[GADMAdapterTapjoyPlacementKey];
  NSString *sdkKey = adConfiguration.credentials.settings[GADMAdapterTapjoySdkKey];

  if (!sdkKey.length || !_placementName.length) {
    NSError *adapterError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorInvalidServerParameters,
        @"Did not receive valid Tapjoy server parameters.");
    _completionHandler(nil, adapterError);
    return;
  }

  GADMTapjoyExtras *extras = adConfiguration.extras;
  GADMAdapterTapjoySingleton *sharedInstance = [GADMAdapterTapjoySingleton sharedInstance];

  if (Tapjoy.isConnected) {
    [self requestRewardedAd];
    return;
  }

  // Tapjoy is not yet connected. Wait for initialization to complete before requesting a placement.
  NSDictionary<NSString *, NSNumber *> *connectOptions =
      @{TJC_OPTION_ENABLE_LOGGING : @(extras.debugEnabled)};
  __weak GADMRewardedAdTapjoy *weakSelf = self;
  [sharedInstance initializeTapjoySDKWithSDKKey:sdkKey
                                        options:connectOptions
                              completionHandler:^(NSError *error) {
                                GADMRewardedAdTapjoy *strongSelf = weakSelf;
                                if (!strongSelf) {
                                  return;
                                }

                                if (error) {
                                  completionHandler(nil, error);
                                  return;
                                }
                                [strongSelf requestRewardedAd];
                              }];
}

- (void)requestRewardedAd {
  GADMTapjoyExtras *extras = _adConfig.extras;
  [Tapjoy setDebugEnabled:extras.debugEnabled];
  GADMediationRewardedAdConfiguration *adConfig = _adConfig;
  if (adConfig.bidResponse) {
    _rewardedAd =
        [[GADMAdapterTapjoySingleton sharedInstance] requestAdForPlacementName:_placementName
                                                                   bidResponse:adConfig.bidResponse
                                                                      delegate:self];
  } else {
    _rewardedAd =
        [[GADMAdapterTapjoySingleton sharedInstance] requestAdForPlacementName:_placementName
                                                                      delegate:self];
  }
}

#pragma mark - GADMediationRewardedAd methods

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewardedAd showContentWithViewController:viewController];
}

#pragma mark - TJPlacementDelegate methods

- (void)requestDidSucceed:(nonnull TJPlacement *)placement {
  // If the placement's content is not available at this time, then the request is considered a
  // failure.
  if (!placement.contentAvailable) {
    NSError *loadError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorPlacementContentNotAvailable, @"Ad not available.");
    _completionHandler(nil, loadError);
  }
}

- (void)requestDidFail:(nonnull TJPlacement *)placement error:(nullable NSError *)error {
  if (!error) {
    NSError *nullError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        GADMAdapterTapjoyErrorUnknown, @"Tapjoy SDK placement unknown error.");
    _completionHandler(nil, nullError);
    return;
  }
  _completionHandler(nil, error);
}

- (void)contentIsReady:(nonnull TJPlacement *)placement {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)contentDidAppear:(nonnull TJPlacement *)placement {
  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate reportImpression];
}

- (void)didClick:(nonnull TJPlacement *)placement {
  [_adEventDelegate reportClick];
}

- (void)contentDidDisappear:(nonnull TJPlacement *)placement {
  [_adEventDelegate willDismissFullScreenView];
  [_adEventDelegate didDismissFullScreenView];
}

#pragma mark - TJPlacementVideoDelegate methods

- (void)videoDidStart:(nonnull TJPlacement *)placement {
  [_adEventDelegate didStartVideo];
}

- (void)videoDidComplete:(nonnull TJPlacement *)placement {
  [_adEventDelegate didEndVideo];
  // Tapjoy only supports fixed rewards and doesn't provide a reward type or amount.
  GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@""
                                                   rewardAmount:NSDecimalNumber.one];
  [_adEventDelegate didRewardUserWithReward:reward];
}

- (void)videoDidFail:(nonnull TJPlacement *)placement error:(nullable NSString *)errorMsg {
  NSError *adapterError =
      GADMAdapterTapjoyErrorWithCodeAndDescription(GADMAdapterTapjoyErrorPlacementVideo, errorMsg);
  [_adEventDelegate didFailToPresentWithError:adapterError];
}

#pragma mark - GADMAdapterTapjoyDelegate

- (void)didFailToLoadWithError:(nonnull NSError *)error {
  _completionHandler(nil, error);
}

@end
