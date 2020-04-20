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
#import "GADMAdapterTapjoySingleton.h"
#import "GADMAdapterTapjoyUtils.h"
#import "GADMTapjoyExtras.h"

@interface GADMRewardedAdTapjoy () <GADMediationRewardedAd,
                                    TJPlacementDelegate,
                                    TJPlacementVideoDelegate>
@end

@implementation GADMRewardedAdTapjoy {
  /// Rewarded ad configuration for the ad to be loaded.
  GADMediationRewardedAdConfiguration *_adConfig;

  /// Completion handler to call when an ad loads successfully or fails.
  GADMediationRewardedLoadCompletionHandler _completionHandler;

  /// The ad event delegate to forward ad events to the Google Mobile Ads SDK.
  __weak id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

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

  _placementName = adConfiguration.credentials.settings[kGADMAdapterTapjoyPlacementKey];
  NSString *sdkKey = adConfiguration.credentials.settings[kGADMAdapterTapjoySdkKey];

  if (!sdkKey.length || !_placementName.length) {
    NSError *adapterError = GADMAdapterTapjoyErrorWithCodeAndDescription(
        kGADErrorMediationDataError, @"Did not receive valid Tapjoy server parameters.");
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
  GADMRewardedAdTapjoy *__weak weakSelf = self;
  [sharedInstance initializeTapjoySDKWithSDKKey:sdkKey
                                        options:connectOptions
                              completionHandler:^(NSError *error) {
                                GADMRewardedAdTapjoy *__strong strongSelf = weakSelf;
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

#pragma mark GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewardedAd showContentWithViewController:viewController];
}

#pragma mark - TJPlacementDelegate methods
- (void)requestDidSucceed:(nonnull TJPlacement *)placement {
  // If the placement's content is not available at this time, then the request is considered a
  // failure.
  if (!placement.contentAvailable) {
    NSError *loadError =
        GADMAdapterTapjoyErrorWithCodeAndDescription(kGADErrorNoFill, @"Ad not available.");
    _completionHandler(nil, loadError);
  }
}

- (void)requestDidFail:(nonnull TJPlacement *)placement error:(nonnull NSError *)error {
  NSError *adapterError =
      GADMAdapterTapjoyErrorWithCodeAndDescription(kGADErrorNoFill, error.localizedDescription);
  _completionHandler(nil, adapterError);
}

- (void)contentIsReady:(nonnull TJPlacement *)placement {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)contentDidAppear:(nonnull TJPlacement *)placement {
  [_adEventDelegate willPresentFullScreenView];
}

- (void)contentDidDisappear:(nonnull TJPlacement *)placement {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)didClick:(nonnull TJPlacement *)placement {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate reportClick];
  [strongDelegate willDismissFullScreenView];
}

#pragma mark Tapjoy Video
- (void)videoDidStart:(nonnull TJPlacement *)placement {
  [_adEventDelegate didStartVideo];
}

- (void)videoDidComplete:(nonnull TJPlacement *)placement {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate didEndVideo];
  // Tapjoy only supports fixed rewards and doesn't provide a reward type or amount.
  GADAdReward *reward = [[GADAdReward alloc] initWithRewardType:@""
                                                   rewardAmount:NSDecimalNumber.one];
  [strongDelegate didRewardUserWithReward:reward];
}

- (void)videoDidFail:(nonnull TJPlacement *)placement error:(nonnull NSString *)errorMsg {
  NSError *adapterError =
      GADMAdapterTapjoyErrorWithCodeAndDescription(GADPresentationErrorCodeInternal, errorMsg);
  [_adEventDelegate didFailToPresentWithError:adapterError];
}

@end
