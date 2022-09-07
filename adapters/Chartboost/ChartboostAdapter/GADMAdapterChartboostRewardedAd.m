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

#if __has_include(<ChartboostSDK/ChartboostSDK.h>)
#import <ChartboostSDK/ChartboostSDK.h>
#else
#import "ChartboostSDK.h"
#endif

#include <stdatomic.h>

#import "GADMAdapterChartboostConstants.h"
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
}

- (nonnull instancetype)
    initWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(GADMediationRewardedLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adConfig = adConfiguration;

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
  NSString *appID = [_adConfig.credentials.settings[GADMAdapterChartboostAppID]
      stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
  NSString *appSignature = [_adConfig.credentials.settings[GADMAdapterChartboostAppSignature]
      stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];

  if (!appID.length || !appSignature.length) {
    NSError *error = GADMAdapterChartboostErrorWithCodeAndDescription(
        GADMAdapterChartboostErrorInvalidServerParameters,
        @"App ID and/or App Signature cannot be nil.");
    _completionHandler(nil, error);
    return;
  }

  if (SYSTEM_VERSION_LESS_THAN(GADMAdapterChartboostMinimumOSVersion)) {
    NSString *logMessage = [NSString
        stringWithFormat:
            @"Chartboost minimum supported OS version is iOS %@. Requested action is a no-op.",
            GADMAdapterChartboostMinimumOSVersion];
    NSError *error = GADMAdapterChartboostErrorWithCodeAndDescription(
        GADMAdapterChartboostErrorMinimumOSVersion, logMessage);
    _completionHandler(nil, error);
    return;
  }

  NSString *adLocation = GADMAdapterChartboostLocationFromAdConfiguration(_adConfig);
  GADMAdapterChartboostRewardedAd *weakSelf = self;
  [Chartboost startWithAppID:appID
                appSignature:appSignature
                  completion:^(CHBStartError *cbError) {
                    GADMAdapterChartboostRewardedAd *strongSelf = weakSelf;
                    if (!strongSelf) {
                      return;
                    }

                    if (cbError) {
                      NSLog(@"Failed to initialize Chartboost SDK: %@", cbError);
                      strongSelf->_completionHandler(nil, cbError);
                      return;
                    }

                    CHBMediation *mediation = GADMAdapterChartboostMediation();
                    strongSelf->_rewardedAd = [[CHBRewarded alloc] initWithLocation:adLocation
                                                                          mediation:mediation
                                                                           delegate:strongSelf];
                    [strongSelf->_rewardedAd cache];
                  }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  if (!_rewardedAd.isCached) {
    NSError *error = GADMAdapterChartboostErrorWithCodeAndDescription(
        GADMAdapterChartboostErrorAdNotCached, @"Rewarded ad not cached.");
    [_adEventDelegate didFailToPresentWithError:error];
    return;
  }
  [_rewardedAd showFromViewController:viewController];
}

#pragma mark - CHBRewardedDelegate Methods

- (void)didCacheAd:(CHBCacheEvent *)event error:(nullable CHBCacheError *)error {
  if (error) {
    NSError *loadError = GADMChartboostErrorForCHBCacheError(error);
    NSLog(@"Failed to load rewarded ad from Chartboost: %@", loadError.localizedDescription);
    _completionHandler(nil, loadError);
    return;
  }

  _adEventDelegate = _completionHandler(self, nil);
}

- (void)didShowAd:(CHBShowEvent *)event error:(nullable CHBShowError *)error {
  if (error) {
    NSError *showError = GADMChartboostErrorForCHBShowError(error);
    NSLog(@"Failed to show rewarded ad from Chartboost: %@", showError.localizedDescription);

    // If the ad has been shown, Chartboost will proceed to dismiss it and the rest is handled in
    // -didDismissAd:
    [_adEventDelegate didFailToPresentWithError:showError];
    return;
  }

  [_adEventDelegate willPresentFullScreenView];
  [_adEventDelegate reportImpression];
  [_adEventDelegate didStartVideo];
}

- (void)didEarnReward:(CHBRewardEvent *)event {
  [_adEventDelegate didEndVideo];
  [_adEventDelegate didRewardUser];
}

- (void)didClickAd:(CHBClickEvent *)event error:(CHBClickError *)error {
  [_adEventDelegate reportClick];
  if (error) {
    NSError *clickError = GADMChartboostErrorForCHBClickError(error);
    NSLog(@"An error occurred when clicking the Chartboost rewarded ad: %@",
          clickError.localizedDescription);
  }
}

- (void)didDismissAd:(CHBDismissEvent *)event {
  [_adEventDelegate willDismissFullScreenView];
  [_adEventDelegate didDismissFullScreenView];
}

@end
