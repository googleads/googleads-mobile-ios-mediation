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
#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostSingleton.h"
#import "GADMChartboostError.h"

@interface GADMRewardedAdChartboost () <GADMAdapterChartboostDataProvider, ChartboostDelegate>

@property(nonatomic, weak) GADMediationRewardedAdConfiguration *adConfig;
@property(nonatomic, copy) GADMediationRewardedLoadCompletionHandler completionHandler;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> adEventDelegate;
@property(nonatomic, copy) NSString *chartboostAdLocation;
/// YES if the adapter is loading.
@property(nonatomic, assign) BOOL loading;

@end

@implementation GADMRewardedAdChartboost

- (void)loadRewardedAdForAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                       completionHandler:
                           (GADMediationRewardedLoadCompletionHandler)completionHandler {
  self.adConfig = adConfiguration;
  self.completionHandler = completionHandler;

  NSString *appID = [adConfiguration.credentials.settings[kGADMAdapterChartboostAppID]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *appSignature = [adConfiguration.credentials.settings[kGADMAdapterChartboostAppSignature]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  NSString *adLocation = [adConfiguration.credentials.settings[kGADMAdapterChartboostAdLocation]
      stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

  if (!appID || !appSignature) {
    NSError *error = GADChartboostErrorWithDescription(@"App ID & App Signature cannot be nil.");
    self.completionHandler(nil, error);
    return;
  }

  if (adLocation) {
    _chartboostAdLocation = [adLocation copy];
  } else {
    _chartboostAdLocation = [CBLocationDefault copy];
  }

  _loading = YES;

  GADMAdapterChartboostSingleton *shared = [GADMAdapterChartboostSingleton sharedManager];
  [shared startWithAppId:appID
            appSignature:appSignature
       completionHandler:^(NSError *error) {
         if (error) {
           completionHandler(nil, error);
         } else {
           [shared configureRewardedAdWithAppID:appID appSignature:appSignature delegate:self];
         }
       }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [[GADMAdapterChartboostSingleton sharedManager] presentRewardedAdForDelegate:self];
}

#pragma mark GADMAdapterChartboostDataProvider Methods

- (NSString *)getAdLocation {
  return _chartboostAdLocation;
}

- (GADMChartboostExtras *)extras {
  GADMChartboostExtras *chartboostExtras = [self.adConfig extras];
  return chartboostExtras;
}

- (void)didFailToLoadAdWithError:(NSError *)error {
  self.completionHandler(nil, error);
}

#pragma mark - Chartboost Reward Based Video Ad Delegate Methods

- (void)didDisplayRewardedVideo:(CBLocation)location {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.adEventDelegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate reportImpression];
  [strongDelegate didStartVideo];
}

- (void)didCacheRewardedVideo:(CBLocation)location {
  if (_loading) {
    self.adEventDelegate = self.completionHandler(self, nil);
    _loading = NO;
  }
}

- (void)didFailToLoadRewardedVideo:(CBLocation)location withError:(CBLoadError)error {
  if (_loading) {
    self.completionHandler(nil, adRequestErrorTypeForCBLoadError(error));
    _loading = NO;
  } else if (error == CBLoadErrorInternetUnavailableAtShow) {
    // Chartboost sends the CBLoadErrorInternetUnavailableAtShow error when the Chartboost SDK
    // fails to present an ad for which a didCacheRewardedVideo event has already been sent.
    [self.adEventDelegate didFailToPresentWithError:adRequestErrorTypeForCBLoadError(error)];
  }
}

- (void)didDismissRewardedVideo:(CBLocation)location {
  [self.adEventDelegate didDismissFullScreenView];
}

- (void)didClickRewardedVideo:(CBLocation)location {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.adEventDelegate;
  [strongDelegate reportClick];
  [strongDelegate willDismissFullScreenView];
}

- (void)didCompleteRewardedVideo:(CBLocation)location withReward:(int)reward {
  id<GADMediationRewardedAdEventDelegate> strongDelegate = self.adEventDelegate;
  [strongDelegate didEndVideo];
  /// Chartboost doesn't provide access to the reward type.
  GADAdReward *adReward =
      [[GADAdReward alloc] initWithRewardType:@""
                                 rewardAmount:[[NSDecimalNumber alloc] initWithInt:reward]];
  [strongDelegate didRewardUserWithReward:adReward];
}
@end
