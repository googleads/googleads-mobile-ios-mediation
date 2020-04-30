// Copyright 2019 Google LLC.
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

#import "GADMAdapterChartboostRewardedAd.h"

#include <stdatomic.h>

#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostSingleton.h"
#import "GADMAdapterChartboostUtils.h"
#import "GADMChartboostError.h"

@interface GADMAdapterChartboostRewardedAd () <CHBRewardedDelegate>
@end

@implementation GADMAdapterChartboostRewardedAd {
  /// The rewarded ad configuration.
  GADMediationRewardedAdConfiguration *_adConfig;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _completionHandler;

  /// An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// Chartboost rewarded ad object
  CHBRewarded *_rewardedAd;
    
  /// YES if ad is visible, used to distinguish between show errors before and during ad presentation.
  BOOL _adIsShown;
}

- (nonnull instancetype)
    initWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfig = adConfiguration;
    _adIsShown = NO;

    __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
    __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
        [completionHandler copy];
    _completionHandler = ^id<GADMediationRewardedAdEventDelegate>(
        id<GADMediationRewardedAd> rewardedAd, NSError *error) {
      if (atomic_flag_test_and_set(&completionHandlerCalled)) {
        return nil;
      }
      id<GADMediationRewardedAdEventDelegate> delegate = nil;
      if (originalCompletionHandler) {
        delegate = originalCompletionHandler(rewardedAd, error);
      }
      originalCompletionHandler = nil;
      return delegate;
    };
  }
  return self;
}

- (void)loadRewardedAd {
  GADMAdapterChartboostRewardedAd *weakSelf = self;
  GADMAdapterChartboostSingleton *sharedInstance = GADMAdapterChartboostSingleton.sharedInstance;
  [sharedInstance startWithCredentials:_adConfig.credentials
                         networkExtras:_adConfig.extras
                     completionHandler:^(NSError *error) {
                 GADMAdapterChartboostRewardedAd *strongSelf = weakSelf;
                 if (!strongSelf) {
                   return;
                 }

                 if (error) {
                   NSLog(@"Failed to load rewarded ad from Chartboost: %@", error.localizedDescription);
                   strongSelf->_completionHandler(nil, error);
                   return;
                 }

                 NSString *adLocation = GADMAdapterChartboostAdLocationFromAdConfig(strongSelf->_adConfig);
                 CHBMediation *mediation = GADMAdapterChartboostMediation();
                 strongSelf->_rewardedAd = [[CHBRewarded alloc] initWithLocation:adLocation
                                                                       mediation:mediation
                                                                        delegate:strongSelf];
                 [strongSelf->_rewardedAd cache];
               }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [_rewardedAd showFromViewController:viewController];
}

#pragma mark - CHBRewardedDelegate Methods

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error {
  if (error) {
    NSError *loadError = NSErrorForCHBCacheError(error);
    NSLog(@"Failed to load rewarded ad from Chartboost: %@", loadError.localizedDescription);
    _completionHandler(nil, loadError);
    return;
  }

  _adEventDelegate = _completionHandler(self, nil);
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (!strongDelegate) {
    return;
  }

  if (error) {
    // if the ad is shown Chartboost will proceed to dismiss it and the rest is handled in didDismissAd:
    if (!_adIsShown) {
      NSError *showError = NSErrorForCHBShowError(error);
      NSLog(@"Failed to show rewarded ad from Chartboost: %@", showError.localizedDescription);
      [strongDelegate didFailToPresentWithError:showError];
      return;
    }
  }
  
  _adIsShown = YES;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate reportImpression];
  [strongDelegate didStartVideo];
}

- (void)didEarnReward:(CHBRewardEvent *)event {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (!strongDelegate) {
    return;
  }

  [strongDelegate didEndVideo];

  /// Chartboost doesn't provide access to the reward type.
  NSDecimalNumber *rewardValue = [[NSDecimalNumber alloc] initWithInteger:event.reward];
  GADAdReward *adReward = [[GADAdReward alloc] initWithRewardType:@"" rewardAmount:rewardValue];
  [strongDelegate didRewardUserWithReward:adReward];
}

- (void)didClickAd:(CHBClickEvent *)event error:(CHBClickError *)error {
  [_adEventDelegate reportClick];
  if (error) {
    NSError *clickError = NSErrorForCHBClickError(error);
    NSLog(@"An error occurred when clicking the Chartboost rewarded ad: %@",
          clickError.localizedDescription);
  }
}

- (void)didDismissAd:(CHBDismissEvent *)event {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  if (!strongDelegate) {
    return;
  }

  _adIsShown = NO;
  [strongDelegate willDismissFullScreenView];
  [strongDelegate didDismissFullScreenView];
}

@end
