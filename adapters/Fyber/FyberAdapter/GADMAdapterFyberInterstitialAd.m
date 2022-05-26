// Copyright 2020 Google LLC
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

#import "GADMAdapterFyberInterstitialAd.h"

#import <IASDKCore/IASDKCore.h>

#import <stdatomic.h>

#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberUtils.h"

@interface GADMAdapterFyberInterstitialAd () <GADMediationInterstitialAd, IAUnitDelegate>
@end

@implementation GADMAdapterFyberInterstitialAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationInterstitialAdConfiguration *_adConfiguration;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationInterstitialLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  /// Intentionally keeping a reference to the delegate because this delegate is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationInterstitialAdEventDelegate> _delegate;

  /// Fyber Ad Spot to be loaded.
  IAAdSpot *_adSpot;

  /// Fyber MRAID controller to support HTML ads.
  IAMRAIDContentController *_MRAIDContentController;

  /// Fyber video controller to support video ads and to catch video progress events.
  IAVideoContentController *_videoContentController;

  /// Fyber fullscreen controller to catch interstitial related ad events.
  IAFullscreenUnitController *_fullscreenUnitController;
}

- (instancetype)initWithAdConfiguration:(GADMediationInterstitialAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)loadInterstitialAdWithCompletionHandler:
    (GADMediationInterstitialLoadCompletionHandler)completionHandler {
  __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationInterstitialLoadCompletionHandler originalAdLoadHandler =
      [completionHandler copy];

  // Ensure the original completion handler is only called once, and is deallocated once called.
  _loadCompletionHandler = ^id<GADMediationInterstitialAdEventDelegate>(
      id<GADMediationInterstitialAd> interstitialAd, NSError *error) {
    if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
      return nil;
    }

    id<GADMediationInterstitialAdEventDelegate> delegate = nil;
    if (originalAdLoadHandler) {
      delegate = originalAdLoadHandler(interstitialAd, error);
    }

    originalAdLoadHandler = nil;
    return delegate;
  };

  GADMAdapterFyberInterstitialAd *__weak weakSelf = self;
  GADMAdapterFyberInitializeWithAppId(
      _adConfiguration.credentials.settings[GADMAdapterFyberApplicationID],
      ^(NSError *_Nullable error) {
        GADMAdapterFyberInterstitialAd *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        if (error) {
          GADMAdapterFyberLog(@"Failed to initialize Fyber Marketplace SDK: %@",
                              error.localizedDescription);
          strongSelf->_loadCompletionHandler(nil, error);
          return;
        }

        [self loadInterstitialAd];
      });
}

- (void)loadInterstitialAd {
  NSString *spotID = _adConfiguration.credentials.settings[GADMAdapterFyberSpotID];
  if (!spotID.length) {
    NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
        GADMAdapterFyberErrorInvalidServerParameters, @"Missing or Invalid Spot ID.");
    GADMAdapterFyberLog(@"%@", error.localizedDescription);
    _loadCompletionHandler(nil, error);
    return;
  }

  _MRAIDContentController =
      [IAMRAIDContentController build:^(id<IAMRAIDContentControllerBuilder> _Nonnull builder){
      }];
  _videoContentController =
      [IAVideoContentController build:^(id<IAVideoContentControllerBuilder> _Nonnull builder){
      }];

  GADMAdapterFyberInterstitialAd *__weak weakSelf = self;
  _fullscreenUnitController =
      [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder> _Nonnull builder) {
        GADMAdapterFyberInterstitialAd *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        builder.unitDelegate = strongSelf;
        [builder addSupportedContentController:strongSelf->_MRAIDContentController];
        [builder addSupportedContentController:strongSelf->_videoContentController];
      }];

  IAAdRequest *request =
      GADMAdapterFyberBuildRequestWithSpotIDAndAdConfiguration(spotID, _adConfiguration);
  _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
    builder.adRequest = request;
    builder.mediationType = [[IAMediationAdMob alloc] init];

    GADMAdapterFyberInterstitialAd *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    [builder addSupportedUnitController:strongSelf->_fullscreenUnitController];
  }];

  [_adSpot fetchAdWithCompletion:^(IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel,
                                   NSError *_Nullable error) {
    GADMAdapterFyberInterstitialAd *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    if (error) {
      GADMAdapterFyberLog(@"Failed to load interstitial ad: %@", error.localizedDescription);
      strongSelf->_loadCompletionHandler(nil, error);
      return;
    }

    strongSelf->_delegate = strongSelf->_loadCompletionHandler(strongSelf, nil);
  }];
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (_fullscreenUnitController.isPresented) {
    NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
        GADMAdapterFyberErrorAdAlreadyUsed, @"Fyber Interstitial ad has already been presented.");
    GADMAdapterFyberLog(@"%@", error.localizedDescription);
    [_delegate didFailToPresentWithError:error];
    return;
  }

  if (!_fullscreenUnitController.isReady) {
    NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
        GADMAdapterFyberErrorAdNotReady, @"Fyber Interstitial ad is not ready to show.");
    GADMAdapterFyberLog(@"%@", error.localizedDescription);
    [_delegate didFailToPresentWithError:error];
    return;
  }

  [_fullscreenUnitController showAdAnimated:YES completion:nil];
}

#pragma mark - IAUnitDelegate

- (nonnull UIViewController *)IAParentViewControllerForUnitController:
    (nullable IAUnitController *)unitController {
  return _adConfiguration.topViewController;
}

- (void)IAAdDidReceiveClick:(nullable IAUnitController *)unitController {
  [_delegate reportClick];
}

- (void)IAAdWillLogImpression:(nullable IAUnitController *)unitController {
  [_delegate reportImpression];
}

- (void)IAUnitControllerWillPresentFullscreen:(nullable IAUnitController *)unitController {
  [_delegate willPresentFullScreenView];
}

- (void)IAUnitControllerWillDismissFullscreen:(nullable IAUnitController *)unitController {
  [_delegate willDismissFullScreenView];
}

- (void)IAUnitControllerDidDismissFullscreen:(nullable IAUnitController *)unitController {
  [_delegate didDismissFullScreenView];
}

- (void)IAUnitControllerWillOpenExternalApp:(nullable IAUnitController *)unitController {
  [_delegate willBackgroundApplication];
}

@end
