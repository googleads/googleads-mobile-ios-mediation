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

  /// The completion handler to call when an ad loads successfully or fails.
  GADMediationRewardedLoadCompletionHandler _loadCompletionHandler;

  /// The ad event delegate to forward ad rendering events to the Google Mobile Ads SDK.
  /// Intentionally keeping a reference to the delegate because this delegate is returned from the
  /// GMA SDK, not set on the GMA SDK.
  id<GADMediationRewardedAdEventDelegate> _delegate;

  /// Fyber Ad Spot to be loaded.
  IAAdSpot *_adSpot;

  /// Fyber MRAID controller to support HTML ads.
  IAMRAIDContentController *_MRAIDContentController;

  /// Fyber video controller to support video ads and to catch video progress events.
  IAVideoContentController *_videoContentController;

  /// Fyber fullscreen controller to support fullscreen ads and to catch ad events.
  IAFullscreenUnitController *_fullscreenUnitController;

  /// View controller to display the Fyber ad.
  __weak UIViewController *_parentViewController;

  /// Flag to indicate whether the Fyber rewarded ad started playing.
  atomic_flag _didStartVideo;
}

#pragma mark - Init

- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationRewardedAdConfiguration *)adConfiguration {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
  }
  return self;
}

#pragma mark - API

- (void)loadRewardedAdWithCompletionHandler:
    (GADMediationRewardedLoadCompletionHandler)completionHandler {
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

  GADMAdapterFyberRewardedAd *__weak weakSelf = self;
  GADMAdapterFyberInitializeWithAppId(
      _adConfiguration.credentials.settings[GADMAdapterFyberApplicationID],
      ^(NSError *_Nullable error) {
        GADMAdapterFyberRewardedAd *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        if (error) {
          GADMAdapterFyberLog("Failed to initialize Fyber Marketplace SDK: %@",
                              error.localizedDescription);
          strongSelf->_loadCompletionHandler(nil, error);
          return;
        }

        [self loadRewardedAd];
      });
}

- (void)loadRewardedAd {
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
        [builder addSupportedContentController:strongSelf->_MRAIDContentController];
      }];

  IAAdRequest *request =
      GADMAdapterFyberBuildRequestWithSpotIDAndAdConfiguration(spotID, _adConfiguration);
  _adSpot = [IAAdSpot build:^(id<IAAdSpotBuilder> _Nonnull builder) {
    GADMAdapterFyberRewardedAd *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }

    builder.adRequest = request;
    builder.mediationType = [[IAMediationAdMob alloc] init];
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
  if (_fullscreenUnitController.isPresented) {
    GADMAdapterFyberLog(@"Failed to show rewarded ad, it is already presented");
  } else if (!_fullscreenUnitController.isReady) {
    GADMAdapterFyberLog(@"Failed to show rewarded ad, it has already expired");
  } else {
    _parentViewController = viewController;
    [_fullscreenUnitController showAdAnimated:YES completion:nil];
  }
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

- (void)IAAdDidReward:(nullable IAUnitController *)unitController {
  GADAdReward *reward =
      [[GADAdReward alloc] initWithRewardType:@""
                                 rewardAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];
  [_delegate didRewardUserWithReward:reward];
  [_delegate didEndVideo];
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

- (void)IAVideoCompleted:(nullable IAVideoContentController *)contentController {}

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
