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

#import <CoreLocation/CoreLocation.h>
#import <IASDKCore/IASDKCore.h>
#import <IASDKVideo/IASDKVideo.h>

#include <stdatomic.h>

#import "GADMAdapterFyberConstants.h"
#import "GADMAdapterFyberRewardedAd.h"
#import "GADMAdapterFyberUtils.h"

@interface GADMAdapterFyberRewardedAd () <GADMediationRewardedAd,
                                          IAUnitDelegate,
                                          IAVideoContentDelegate>
@end

@implementation GADMAdapterFyberRewardedAd {
  /// Ad configuration for the ad to be loaded.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// Fyber fullscreen controller to catch ad events.
  IAFullscreenUnitController *_fullscreenUnitController;

  /// Fyber video controller to catch video progress events.
  IAVideoContentController *_videoContentController;

  /// Fyber Ad spot to be loaded.
  IAAdSpot *_adSpot;

  /// View controller to display the Fyber ad.
  __weak UIViewController *_parentViewController;

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  __weak id<GADMediationRewardedAdEventDelegate> _delegate;

  /// Flag to indicate whether the Fyber rewarded ad started playing.
  atomic_flag _didStartVideo;
}

#pragma mark - Init

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;

    __block atomic_flag adLoadHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationRewardedLoadCompletionHandler originalAdLoadHandler =
        [completionHandler copy];

    // Ensure the original completion handler is only called once, and is deallocated once called.
    _loadCompletionHandler = ^id<GADMediationRewardedAdEventDelegate>(
        id<GADMediationRewardedAd> rewardedAd, NSError *error) {
      if (atomic_flag_test_and_set(&adLoadHandlerCalled)) {
        return nil;
      }

      id<GADMediationRewardedAdEventDelegate> delegate = nil;
      if (originalAdLoadHandler) {
        delegate = originalAdLoadHandler(rewardedAd, error);
      }

      originalAdLoadHandler = nil;
      return delegate;
    };
  }
  return self;
}

#pragma mark - API

- (void)loadRewardedAd {
  NSError *initError = nil;
  BOOL didInitialize = GADMAdapterFyberInitializeWithAppID(
      _adConfiguration.credentials.settings[kGADMAdapterFyberApplicationID], &initError);
  if (!didInitialize) {
    GADMAdapterFyberLog(@"Failed to load rewarded ad: %@", initError.localizedDescription);
    _loadCompletionHandler(nil, initError);
    return;
  }

  NSString *spotID = _adConfiguration.credentials.settings[kGADMAdapterFyberSpotID];
  IAAdRequest *request =
      GADMAdapterFyberBuildRequestWithSpotIDAndAdConfiguration(spotID, _adConfiguration);

  GADMAdapterFyberRewardedAd *__weak weakSelf = self;
  _videoContentController =
      [IAVideoContentController build:^(id<IAVideoContentControllerBuilder> _Nonnull builder) {
        GADMAdapterFyberRewardedAd *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        builder.videoContentDelegate = strongSelf;
      }];

  _fullscreenUnitController =
      [IAFullscreenUnitController build:^(id<IAFullscreenUnitControllerBuilder> _Nonnull builder) {
        GADMAdapterFyberRewardedAd *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        builder.unitDelegate = strongSelf;
        [builder addSupportedContentController:strongSelf->_videoContentController];
      }];

  _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
    GADMAdapterFyberRewardedAd *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    builder.adRequest = request;
    [builder addSupportedUnitController:strongSelf->_fullscreenUnitController];
  }];

  [_adSpot fetchAdWithCompletion:^(IAAdSpot *_Nullable adSpot, IAAdModel *_Nullable adModel,
                                   NSError *_Nullable error) {
    GADMAdapterFyberRewardedAd *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    if (error) {
      GADMAdapterFyberLog(@"Failed to load rewarded ad: %@", error.localizedDescription);
      strongSelf->_loadCompletionHandler(nil, error);
    } else {
      strongSelf->_delegate = strongSelf->_loadCompletionHandler(strongSelf, nil);
    }
  }];
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  _parentViewController = viewController;
  [_fullscreenUnitController showAdAnimated:YES completion:nil];
}

#pragma mark - IAUnitDelegate

- (nonnull UIViewController *)IAParentViewControllerForUnitController:
    (nullable IAUnitController *)unitController {
  return _parentViewController;
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

#pragma mark - IAVideoContentDelegate

- (void)IAVideoCompleted:(nullable IAVideoContentController *)contentController {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _delegate;
  GADAdReward *reward =
      [[GADAdReward alloc] initWithRewardType:@""
                                 rewardAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];

  [strongDelegate didEndVideo];
  [strongDelegate didRewardUserWithReward:reward];
}

- (void)IAVideoContentController:(nullable IAVideoContentController *)contentController
       videoInterruptedWithError:(nonnull NSError *)error {
  [_delegate didFailToPresentWithError:error];
}

- (void)IAVideoContentController:(nullable IAVideoContentController *)contentController
    videoProgressUpdatedWithCurrentTime:(NSTimeInterval)currentTime
                              totalTime:(NSTimeInterval)totalTime {
  if (!atomic_flag_test_and_set(&_didStartVideo)) {
    [_delegate didStartVideo];
  }
}

@end
