// Copyright 2025 Google LLC
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

#import "GADMWaterfallAppLovinAppOpenRenderer.h"
#import "GADMAdapterAppLovinConstant.h"
#import "GADMAdapterAppLovinExtras.h"
#import "GADMAdapterAppLovinUtils.h"
#import "GADMediationAdapterAppLovin.h"

#import <AppLovinSDK/AppLovinSDK.h>
#include <GoogleMobileAds/GoogleMobileAds.h>
#include <stdatomic.h>

@implementation GADMWaterfallAppLovinAppOpenRenderer {
  /// Data used to render an app open ad.
  GADMediationAppOpenAdConfiguration *_adConfiguration;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationAppOpenAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationAppOpenLoadCompletionHandler)handler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    // Store the completion handler for later use.
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationAppOpenLoadCompletionHandler originalCompletionHandler = [handler copy];
    _adLoadCompletionHandler = ^id<GADMediationAppOpenAdEventDelegate>(
        _Nullable id<GADMediationAppOpenAd> ad, NSError *_Nullable error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }
      id<GADMediationAppOpenAdEventDelegate> delegate = nil;
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
  NSString *adUnitID = _adConfiguration.credentials.settings[GADMAdapterAppLovinAdUnitID];
  if (!adUnitID) {
    NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
        GADMAdapterAppLovinErrorMissingAdUnitID, @"AppLovin ad unit ID is missing.");
    _adLoadCompletionHandler(nil, error);
    return;
  }
  _appOpenAd = [[MAAppOpenAd alloc] initWithAdUnitIdentifier:adUnitID];
  _appOpenAd.delegate = self;
  [_appOpenAd loadAd];
}

#pragma mark - GADMediationAppOpenAd

- (void)presentFromViewController:(UIViewController *)viewController {
  // appOpenAd won't be nil here since presentFromViewController can be called by GMA SDK only after
  // appOpenAd was assigned.
  if ([_appOpenAd isReady]) {
    [_appOpenAd showAd];
    id<GADMediationAppOpenAdEventDelegate> strongDelegate = _adEventDelegate;
    if (strongDelegate) {
      [strongDelegate willPresentFullScreenView];
    }
  } else {
    id<GADMediationAppOpenAdEventDelegate> strongDelegate = _adEventDelegate;
    if (strongDelegate) {
      NSError *error = GADMAdapterAppLovinErrorWithCodeAndDescription(
          GADMAdapterAppLovinErrorAdNotReady, @"Ad is not ready to be displayed");
      [strongDelegate didFailToPresentWithError:error];
    }
  }
}

#pragma mark - MAAdDelegate

- (void)didLoadAd:(MAAd *)ad {
  if (_adLoadCompletionHandler) {
    _adEventDelegate = _adLoadCompletionHandler(self, nil);
  }
}

- (void)didFailToLoadAdForAdUnitIdentifier:(NSString *)adUnitIdentifier withError:(MAError *)error {
  if (_adLoadCompletionHandler) {
    NSError *gmaError = GADMAdapterAppLovinSDKErrorWithCode(error.code);
    _adLoadCompletionHandler(nil, gmaError);
  }
}

- (void)didDisplayAd:(MAAd *)ad {
  id<GADMediationAppOpenAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate reportImpression];
  }
}

- (void)didClickAd:(MAAd *)ad {
  id<GADMediationAppOpenAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate reportClick];
  }
}

- (void)didHideAd:(MAAd *)ad {
  id<GADMediationAppOpenAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    [strongDelegate willDismissFullScreenView];
    [strongDelegate didDismissFullScreenView];
  }
}

- (void)didFailToDisplayAd:(MAAd *)ad withError:(MAError *)error {
  id<GADMediationAppOpenAdEventDelegate> strongDelegate = _adEventDelegate;
  if (strongDelegate) {
    NSError *gmaError = GADMAdapterAppLovinSDKErrorWithCode(error.code);
    [strongDelegate didFailToPresentWithError:gmaError];
  }
}

@end
