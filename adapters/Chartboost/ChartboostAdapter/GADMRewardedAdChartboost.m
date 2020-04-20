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

#import "GADMRewardedAdChartboost.h"
#import <Chartboost/Chartboost.h>
#include <stdatomic.h>
#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostSingleton.h"
#import "GADMChartboostError.h"

@interface GADMRewardedAdChartboost () <GADMAdapterChartboostDataProvider, ChartboostDelegate>
@end

@implementation GADMRewardedAdChartboost {
  /// The rewarded ad configuration.
  GADMediationRewardedAdConfiguration *_adConfig;

  /// The completion handler to call when the ad loading succeeds or fails.
  GADMediationRewardedLoadCompletionHandler _completionHandler;

  /// An ad event delegate to invoke when ad rendering events occur.
  id<GADMediationRewardedAdEventDelegate> _adEventDelegate;

  /// Chartboost's ad location.
  NSString *_chartboostAdLocation;

  /// YES if the adapter is loading.
  BOOL _loading;
}

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  _adConfig = adConfiguration;
  __block atomic_flag completionHandlerCalled = ATOMIC_FLAG_INIT;
  __block GADMediationRewardedLoadCompletionHandler originalCompletionHandler =
      [completionHandler copy];
  _completionHandler = ^id<GADMediationRewardedAdEventDelegate>(id<GADMediationRewardedAd> bannerAd,
                                                                NSError *error) {
    if (atomic_flag_test_and_set(&completionHandlerCalled)) {
      return nil;
    }
    id<GADMediationRewardedAdEventDelegate> delegate = nil;
    if (originalCompletionHandler) {
      delegate = originalCompletionHandler(bannerAd, error);
    }
    originalCompletionHandler = nil;
    return delegate;
  };

  NSString *appID = [adConfiguration.credentials.settings[kGADMAdapterChartboostAppID]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *appSignature = [adConfiguration.credentials.settings[kGADMAdapterChartboostAppSignature]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *adLocation = [adConfiguration.credentials.settings[kGADMAdapterChartboostAdLocation]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  if (!appID || !appSignature) {
    NSError *error = GADChartboostErrorWithDescription(@"App ID & App Signature cannot be nil.");
    _completionHandler(nil, error);
    return;
  }

  if (adLocation) {
    _chartboostAdLocation = [adLocation copy];
  } else {
    _chartboostAdLocation = [CBLocationDefault copy];
  }

  _loading = YES;

  GADMAdapterChartboostSingleton *sharedInstance = [GADMAdapterChartboostSingleton sharedInstance];
  [sharedInstance startWithAppId:appID
                    appSignature:appSignature
               completionHandler:^(NSError *error) {
                 if (error) {
                   self->_completionHandler(nil, error);
                 } else {
                   [sharedInstance configureRewardedAdWithAppID:appID
                                                   appSignature:appSignature
                                                       delegate:self];
                 }
               }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  GADMAdapterChartboostSingleton *sharedInstance = [GADMAdapterChartboostSingleton sharedInstance];
  [sharedInstance presentRewardedAdForDelegate:self];
}

#pragma mark GADMAdapterChartboostDataProvider Methods

- (NSString *)getAdLocation {
  return _chartboostAdLocation;
}

- (GADMChartboostExtras *)extras {
  GADMChartboostExtras *chartboostExtras = [_adConfig extras];
  return chartboostExtras;
}

- (void)didFailToLoadAdWithError:(NSError *)error {
  _completionHandler(nil, error);
}

#pragma mark - Chartboost Reward Based Video Ad Delegate Methods

- (void)didDisplayRewardedVideo:(CBLocation)location {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate reportImpression];
  [strongDelegate didStartVideo];
}

- (void)didCacheRewardedVideo:(CBLocation)location {
  if (_loading) {
    _adEventDelegate = _completionHandler(self, nil);
    _loading = NO;
  }
}

- (void)didFailToLoadRewardedVideo:(CBLocation)location withError:(CBLoadError)error {
  if (_loading) {
    _completionHandler(nil, adRequestErrorTypeForCBLoadError(error));
    _loading = NO;
  } else if (error == CBLoadErrorInternetUnavailableAtShow) {
    // Chartboost sends the CBLoadErrorInternetUnavailableAtShow error when the Chartboost SDK
    // fails to present an ad for which a didCacheRewardedVideo event has already been sent.
    [_adEventDelegate didFailToPresentWithError:adRequestErrorTypeForCBLoadError(error)];
  }
}

- (void)didDismissRewardedVideo:(CBLocation)location {
  [_adEventDelegate didDismissFullScreenView];
}

- (void)didClickRewardedVideo:(CBLocation)location {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate reportClick];
  [strongDelegate willDismissFullScreenView];
}

- (void)didCompleteRewardedVideo:(CBLocation)location withReward:(int)reward {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate didEndVideo];
  /// Chartboost doesn't provide access to the reward type.
  GADAdReward *adReward =
      [[GADAdReward alloc] initWithRewardType:@""
                                 rewardAmount:[[NSDecimalNumber alloc] initWithInt:reward]];
  [strongDelegate didRewardUserWithReward:adReward];
}
@end
