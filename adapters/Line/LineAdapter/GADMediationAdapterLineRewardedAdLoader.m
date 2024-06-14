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

#import "GADMediationAdapterLineRewardedAdLoader.h"

#import <UIKit/UIKit.h>

#import "GADMediationAdapterLineConstants.h"
#import "GADMediationAdapterLineUtils.h"

@implementation GADMediationAdapterLineRewardedAdLoader {
  /// The rewarded ad configuration.
  GADMediationRewardedAdConfiguration *_adConfiguration;

  /// The ad event delegate which is used to report rewarded ad events to the Google Mobile Ads SDK.
  __weak id<GADMediationRewardedAdEventDelegate> _rewardedAdEventDelegate;

  /// The rewarded ad.
  FADVideoReward *_rewardedAd;

  /// Indicates whether the load completion handler was called.
  BOOL _isCompletionHandlerCalled;

  /// The completion handler that needs to be called upon finishing loading an ad.
  GADMediationRewardedLoadCompletionHandler _rewardedAdLoadCompletionHandler;
}

- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
      loadCompletionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfiguration = adConfiguration;
    _isCompletionHandlerCalled = NO;
    _rewardedAdLoadCompletionHandler = [completionHandler copy];
  }
  return self;
}

- (void)loadAd {
  NSError *error = GADMediationAdapterLineRegisterFiveAd(@[ _adConfiguration.credentials ]);
  if (error) {
    [self callCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }

  if (_adConfiguration.bidResponse) {
    [self loadBiddingAd];
  } else {
    [self loadWaterfallAd];
  }
}

- (void)loadBiddingAd {
  __block NSError *error;
  FADAdLoader *adLoader = GADMediationAdapterLineFADAdLoaderForRegisteredConfig(&error);
  if (error) {
    [self callCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }
  NSString *watermarkString =
      GADMediationAdapterLineWatermarkStringFromAdConfiguration(_adConfiguration);
  FADBidData *bidData = [[FADBidData alloc] initWithBidResponse:_adConfiguration.bidResponse
                                                  withWatermark:watermarkString];
  GADMediationAdapterLineRewardedAdLoader *__weak weakSelf = self;
  [adLoader loadRewardAdWithBidData:bidData
                   withLoadCallback:^(FADVideoReward *_Nullable rewardedAd,
                                      NSError *_Nullable adLoadError) {
                     GADMediationAdapterLineRewardedAdLoader *strongSelf = weakSelf;
                     if (!strongSelf) {
                       return;
                     }

                     if (adLoadError) {
                       GADMediationAdapterLineLog(@"FiveAd SDK failed to load a bidding "
                                                  @"rewarded ad. The FiveAd error code: %ld.",
                                                  adLoadError.code);
                       error = GADMediationAdapterLineErrorWithFiveAdErrorCode(adLoadError.code);
                       [strongSelf callCompletionHandlerIfNeededWithAd:nil error:error];
                       return;
                     }

                     [rewardedAd setEventListener:self];
                     [rewardedAd enableSound:GADMediationAdapterLineShouldEnableAudio(
                                                 strongSelf->_adConfiguration.extras)];
                     strongSelf->_rewardedAd = rewardedAd;
                     [strongSelf callCompletionHandlerIfNeededWithAd:strongSelf error:nil];
                   }];
}

- (void)loadWaterfallAd {
  NSError *error;
  NSString *slotID = GADMediationAdapterLineSlotID(_adConfiguration.credentials, &error);
  if (error) {
    [self callCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }

  _rewardedAd = [[FADVideoReward alloc] initWithSlotId:slotID];
  [_rewardedAd setLoadDelegate:self];
  [_rewardedAd setEventListener:self];
  [_rewardedAd enableSound:GADMediationAdapterLineShouldEnableAudio(_adConfiguration.extras)];
  GADMediationAdapterLineLog(@"Start loading a rewarded ad from FiveAd SDK.");
  [_rewardedAd loadAdAsync];
}

- (void)callCompletionHandlerIfNeededWithAd:(nullable id<GADMediationRewardedAd>)ad
                                      error:(nullable NSError *)error {
  @synchronized(self) {
    if (_isCompletionHandlerCalled) {
      return;
    }
    _isCompletionHandlerCalled = YES;
  }

  if (_rewardedAdLoadCompletionHandler) {
    _rewardedAdEventDelegate = _rewardedAdLoadCompletionHandler(ad, error);
  }
  _rewardedAdLoadCompletionHandler = nil;
}

#pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  GADMediationAdapterLineLog(@"FiveAd SDK will present the rewarded ad.");
  [_rewardedAdEventDelegate willPresentFullScreenView];
  [_rewardedAd show];
}

#pragma mark - FADLoadDelegate (for waterfall rewarded ad)

- (void)fiveAdDidLoad:(id<FADAdInterface>)ad {
  GADMediationAdapterLineLog(@"FiveAd SDK loaded a rewarded ad.");
  [self callCompletionHandlerIfNeededWithAd:self error:nil];
}

- (void)fiveAd:(id<FADAdInterface>)ad didFailedToReceiveAdWithError:(FADErrorCode)errorCode {
  GADMediationAdapterLineLog(
      @"FiveAd SDK failed to load a rewarded ad. The FiveAd error code: %ld.", errorCode);
  NSError *error = GADMediationAdapterLineErrorWithFiveAdErrorCode(errorCode);
  [self callCompletionHandlerIfNeededWithAd:nil error:error];
}

#pragma mark - FADVideoRewardEventListener

- (void)fiveVideoRewardAd:(nonnull FADVideoReward *)ad
    didFailedToShowAdWithError:(FADErrorCode)errorCode {
  // Called when something goes wrong in the Five Ad SDK.
  GADMediationAdapterLineLog(
      @"The FiveAd rewarded ad did fail to show. The FiveAd error code: %ld.", errorCode);
  NSError *error = GADMediationAdapterLineErrorWithFiveAdErrorCode(errorCode);
  [_rewardedAdEventDelegate didFailToPresentWithError:error];
}

- (void)fiveVideoRewardAdDidReward:(nonnull FADVideoReward *)ad {
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did reward.");
  [_rewardedAdEventDelegate didRewardUser];
}

- (void)fiveVideoRewardAdDidImpression:(nonnull FADVideoReward *)ad {
  // Called when the rewarded ad records a user impression.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did impression.");
  [_rewardedAdEventDelegate reportImpression];
}

- (void)fiveVideoRewardAdDidClick:(nonnull FADVideoReward *)ad {
  // Called when the rewarded ad is clicked by the user.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did click.");
  [_rewardedAdEventDelegate reportClick];
}

- (void)fiveVideoRewardAdFullScreenDidOpen:(nonnull FADVideoReward *)ad {
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did open.");
}

- (void)fiveVideoRewardAdFullScreenDidClose:(nonnull FADVideoReward *)ad {
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did close.");
  [_rewardedAdEventDelegate didDismissFullScreenView];
}

- (void)fiveVideoRewardAdDidPlay:(nonnull FADVideoReward *)ad {
  // Called when the rewarded ad's video starts to play in fullscreen.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did play.");
  [_rewardedAdEventDelegate didStartVideo];
}

- (void)fiveVideoRewardAdDidPause:(nonnull FADVideoReward *)ad {
  // Called when the app goes background while the rewarded ad video is still playing.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did pause.");
}

- (void)fiveVideoRewardAdDidViewThrough:(nonnull FADVideoReward *)ad {
  // Called when the rewarded ad's video reaches its end.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did view through.");
  [_rewardedAdEventDelegate didEndVideo];
}

@end
