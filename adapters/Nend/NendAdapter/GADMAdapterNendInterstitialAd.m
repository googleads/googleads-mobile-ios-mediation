// Copyright 2023 Google LLC
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

#import "GADMAdapterNendInterstitialAd.h"

#import <NendAd/NendAd.h>

#include <stdatomic.h>

#import "GADMAdapterNendConstants.h"
#import "GADMAdapterNendExtras.h"
#import "GADMAdapterNendUtils.h"
#import "GADMediationAdapterNend.h"

@interface GADMAdapterNendInterstitialAd () <NADInterstitialLoadingDelegate,
                                             NADInterstitialClickDelegate,
                                             NADInterstitialVideoDelegate>
@end

@implementation GADMAdapterNendInterstitialAd {
  /// The completion handler to call when ad loading succeeds or fails.
  GADMediationInterstitialLoadCompletionHandler _completionHandler;

  /// Interstitial ad configuration of the ad request.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  id<GADMediationInterstitialAdEventDelegate> _adEventDelegate;

  /// nend interstitial.
  NADInterstitial *_interstitial;

  /// nend interstitial video.
  NADInterstitialVideo *_interstitialVideo;

  /// Interstitial type.
  GADMAdapterNendInterstitialType _interstitialType;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationInterstitialAdConfiguration *)adConfiguration
          completionHandler:
              (nonnull GADMediationInterstitialLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationInterstitialLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];

    _completionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
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

    _adConfiguration = adConfiguration;
    _interstitial = nil;
    _interstitialVideo = nil;
    _interstitialType = GADMAdapterNendInterstitialTypeNormal;
  }
  return self;
}

- (void)loadInterstitialAd {
  NSString *spotID = _adConfiguration.credentials.settings[GADMAdapterNendSpotID];
  NSString *APIKey = _adConfiguration.credentials.settings[GADMAdapterNendApiKey];

  NSError *serverParameterError = GADMAdapterNendValidateSpotID(spotID);
  if (serverParameterError) {
    _completionHandler(nil, serverParameterError);
    return;
  }

  serverParameterError = GADMAdapterNendValidateAPIKey(APIKey);
  if (serverParameterError) {
    _completionHandler(nil, serverParameterError);
    return;
  }

  GADMAdapterNendExtras *extras = _adConfiguration.extras;
  if (extras) {
    _interstitialType = extras.interstitialType;
  }

  if (_interstitialType == GADMAdapterNendInterstitialTypeVideo) {
    _interstitialVideo = [[NADInterstitialVideo alloc] initWithSpotID:spotID.integerValue
                                                               apiKey:APIKey];
    _interstitialVideo.delegate = self;
    _interstitialVideo.mediationName = GADMAdapterNendMediationName;
    [_interstitialVideo loadAd];
  } else {
    _interstitial = [NADInterstitial sharedInstance];
    _interstitial.loadingDelegate = self;
    _interstitial.clickDelegate = self;
    _interstitial.enableAutoReload = NO;
    [_interstitial loadAdWithSpotID:spotID.integerValue apiKey:APIKey];
  }
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (_interstitialType == GADMAdapterNendInterstitialTypeVideo) {
    [self presentNendVideoInterstitialAdFromViewController:viewController];
  } else {
    [self presentNendInterstitialAdFromViewController:viewController];
  }
}

- (void)presentNendVideoInterstitialAdFromViewController:
    (nonnull UIViewController *)viewController {
  id<GADMediationInterstitialAdEventDelegate> adEventDelegate = _adEventDelegate;

  if (!_interstitialVideo.isReady) {
    [adEventDelegate didFailToPresentWithError:GADMAdapterNendErrorWithCodeAndDescription(
                                                   GADMAdapterNendErrorShowAdNotReady,
                                                   @"nend interstitial video ad is not ready.")];
    return;
  }

  [adEventDelegate willPresentFullScreenView];
  [_interstitialVideo showAdFromViewController:viewController];
}

- (void)presentNendInterstitialAdFromViewController:(nonnull UIViewController *)viewController {
  id<GADMediationInterstitialAdEventDelegate> adEventDelegate = _adEventDelegate;
  [adEventDelegate willPresentFullScreenView];
  NADInterstitialShowResult result = [_interstitial showAdFromViewController:viewController];

  if (result != AD_SHOW_SUCCESS) {
    [adEventDelegate didFailToPresentWithError:GADMAdapterNendErrorForShowResult(result)];
    return;
  }

  if (result == AD_SHOW_SUCCESS) {
    [adEventDelegate reportImpression];
  }
}

#pragma mark - NADInterstitialLoadingDelegate

- (void)didFinishLoadInterstitialAdWithStatus:(NADInterstitialStatusCode)status {
  if (status != SUCCESS) {
    _completionHandler(nil, GADMAdapterNendSDKLoadError());
    return;
  }

  _adEventDelegate = _completionHandler(self, nil);
}

#pragma mark - NADInterstitialClickDelegate

- (void)didClickWithType:(NADInterstitialClickType)type {
  id<GADMediationInterstitialAdEventDelegate> adEventDelegate = _adEventDelegate;
  if (!adEventDelegate) {
    return;
  }

  switch (type) {
    case DOWNLOAD:
      [adEventDelegate reportClick];
      [adEventDelegate willDismissFullScreenView];
      [adEventDelegate didDismissFullScreenView];
      break;
    case INFORMATION:
      [adEventDelegate willDismissFullScreenView];
      [adEventDelegate didDismissFullScreenView];
      break;
    case CLOSE:
      [adEventDelegate willDismissFullScreenView];
      [adEventDelegate didDismissFullScreenView];
      break;
    default:
      break;
  }
}

#pragma mark - NADInterstitialVideoDelegate

- (void)nadInterstitialVideoAdDidReceiveAd:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  _adEventDelegate = _completionHandler(self, nil);
}

- (void)nadInterstitialVideoAd:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd
        didFailToLoadWithError:(nonnull NSError *)error {
  _completionHandler(nil, GADMAdapterNendSDKLoadError());
}

- (void)nadInterstitialVideoAdDidOpen:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  [_adEventDelegate reportImpression];
}

- (void)nadInterstitialVideoAdDidClose:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  id<GADMediationInterstitialAdEventDelegate> adEventDelegate = _adEventDelegate;
  if (!adEventDelegate) {
    return;
  }

  [adEventDelegate willDismissFullScreenView];
  [adEventDelegate didDismissFullScreenView];
}

- (void)nadInterstitialVideoAdDidClickAd:(nonnull NADInterstitialVideo *)nadInterstitialVideoAd {
  [_adEventDelegate reportClick];
}

@end
