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
  id<GADMediationRewardedAdEventDelegate> _rewardedAdEventDelegate;

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

  NSString *slotID = GADMediationAdapterLineSlotID(_adConfiguration, &error);
  if (error) {
    [self callCompletionHandlerIfNeededWithAd:nil error:error];
    return;
  }

  _rewardedAd = [[FADVideoReward alloc] initWithSlotId:slotID];
  [_rewardedAd setLoadDelegate:self];
  [_rewardedAd setAdViewEventListener:self];
  [_rewardedAd enableSound:!GADMobileAds.sharedInstance.applicationMuted];
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

#pragma mark - FADLoadDelegate

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

#pragma mark - FADAdViewEventListener

- (void)fiveAdDidClick:(id<FADAdInterface>)ad {
  // Called when the rewarded ad is clicked by the user.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did click.");
  [_rewardedAdEventDelegate reportClick];
}

- (void)fiveAdDidImpression:(id<FADAdInterface>)ad {
  // Called when the rewarded ad records a user impression.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did impression.");
  [_rewardedAdEventDelegate reportImpression];
}

- (void)fiveAdDidClose:(id<FADAdInterface>)ad {
  // Called when the rewarded ad exits full screen. Reward will be also granted if the video has
  // reached its end at least once.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did close.");

  if (ad.state != kFADStateError) {
    [_rewardedAdEventDelegate didRewardUser];
  }

  [_rewardedAdEventDelegate didDismissFullScreenView];
}

- (void)fiveAd:(id<FADAdInterface>)ad didFailedToShowAdWithError:(FADErrorCode)errorCode {
  // Called when something goes wrong in the Five Ad SDK.
  GADMediationAdapterLineLog(
      @"The FiveAd rewarded ad did fail to show. The FiveAd error code: %ld.", errorCode);
  NSError *error = GADMediationAdapterLineErrorWithFiveAdErrorCode(errorCode);
  [_rewardedAdEventDelegate didFailToPresentWithError:error];
}

- (void)fiveAdDidStart:(id<FADAdInterface>)ad {
  // Called when the rewarded ad's video starts to play in fullscreen.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did start.");
  [_rewardedAdEventDelegate didStartVideo];
}

- (void)fiveAdDidViewThrough:(id<FADAdInterface>)ad {
  // Called when the rewarded ad's video reaches its end.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did view through.");
  [_rewardedAdEventDelegate didEndVideo];
}

- (void)fiveAdDidPause:(id<FADAdInterface>)ad {
  // Called when the app goes background while the rewarded ad video is still playing.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did pause.");
}

- (void)fiveAdDidResume:(id<FADAdInterface>)ad {
  // Called if the rewarded ad video was paused and when the app comes back to foreground.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did resume.");
}

- (void)fiveAdDidReplay:(id<FADAdInterface>)ad {
  // Called when the rewarded ad's video gets replayed.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did replay.");
}

- (void)fiveAdDidStall:(id<FADAdInterface>)ad {
  // Called when the rewarded ad's video gets stalled for some reason.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did stall.");
}

- (void)fiveAdDidRecover:(id<FADAdInterface>)ad {
  // Called when the rewarded ad's video recovers from stalling.
  GADMediationAdapterLineLog(@"The FiveAd rewarded ad did recover.");
}

@end
