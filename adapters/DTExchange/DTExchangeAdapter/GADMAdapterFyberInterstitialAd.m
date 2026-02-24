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
  __weak id<GADMediationInterstitialAdEventDelegate> _delegate;

  /// DT Exchange Ad Spot to be loaded.
  IAAdSpot *_adSpot;

  /// DT Exchange MRAID controller to support HTML ads.
  IAMRAIDContentController *_MRAIDContentController;

  /// DT Exchange video controller to support video ads and to catch video progress events.
  IAVideoContentController *_videoContentController;

  /// DT Exchange fullscreen controller to catch interstitial related ad events.
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
      ^(BOOL success, NSError *_Nullable error) {
        GADMAdapterFyberInterstitialAd *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        if (success) {
          // DTExchange requires to set COPPA after every successful initialization.
          GADMAdapterFyberSetCOPPA();
        }

        if (error) {
          GADMAdapterFyberLog(@"Failed to initialize DT Exchange SDK: %@",
                              error.localizedDescription);
          strongSelf->_loadCompletionHandler(nil, error);
          return;
        }

        [self loadInterstitialAd];
      });
}

- (void)loadInterstitialAd {
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

  NSString *bidResponse = _adConfiguration.bidResponse;
  IAAdRequest *request;
  if (!bidResponse) {
    // Waterfall flow
    NSString *spotID = _adConfiguration.credentials.settings[GADMAdapterFyberSpotID];
    if (!spotID.length) {
      NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
          GADMAdapterFyberErrorInvalidServerParameters, @"Missing or Invalid Spot ID.");
      GADMAdapterFyberLog(@"%@", error.localizedDescription);
      _loadCompletionHandler(nil, error);
      return;
    }

    request = GADMAdapterFyberBuildRequestWithSpotIDAndAdConfiguration(spotID, _adConfiguration);
  } else {
    // Bidding flow
    request = GADMAdapterFyberBuildRequestWithAdConfiguration(_adConfiguration);
  }

  IASDKCore.sharedInstance.mediationType = [[IAMediationAdMob alloc] init];
  _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
    builder.adRequest = request;

    GADMAdapterFyberInterstitialAd *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    [builder addSupportedUnitController:strongSelf->_fullscreenUnitController];
  }];

  IAAdSpotAdResponseBlock completionCallback =
      ^(IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel, NSError *_Nullable error) {
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
      };

  if (bidResponse) {
    [_adSpot loadAdWithMarkup:bidResponse
                watermarkData:_adConfiguration.watermark
               withCompletion:completionCallback];
  } else {
    [_adSpot fetchAdWithCompletion:completionCallback];
  }
}

#pragma mark - GADMediationInterstitialAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  id<GADMediationInterstitialAdEventDelegate> delegate = _delegate;
  if (_fullscreenUnitController.isPresented) {
    NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
        GADMAdapterFyberErrorAdAlreadyUsed,
        @"DT Exchange Interstitial ad has already been presented.");
    GADMAdapterFyberLog(@"%@", error.localizedDescription);
    [delegate didFailToPresentWithError:error];
    return;
  }

  if (!_fullscreenUnitController.isReady) {
    NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
        GADMAdapterFyberErrorAdNotReady, @"DT Exchange Interstitial ad is not ready to show.");
    GADMAdapterFyberLog(@"%@", error.localizedDescription);
    [delegate didFailToPresentWithError:error];
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

- (void)IAAdDidExpire:(IAUnitController *)unitController {
  NSError *error = GADMAdapterFyberErrorWithCodeAndDescription(
      GADMAdapterFyberErrorPresentationFailureForAdExpiration,
      @"DT Exchange interstitial ad couldn't be presented because it was expired.");
  [_delegate didFailToPresentWithError:error];
}

- (void)IAUnitControllerWillOpenExternalApp:(nullable IAUnitController *)unitController {
  // Google Mobile Ads SDK doesn't have a matching event.
}

@end
