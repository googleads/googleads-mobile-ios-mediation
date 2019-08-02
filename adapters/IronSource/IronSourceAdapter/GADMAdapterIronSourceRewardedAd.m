// Copyright 2019 Google Inc.
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

#import "GADMAdapterIronSourceRewardedAd.h"
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceRewardedDelegate.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"
#import "ISMediationManager.h"

@interface GADMAdapterIronSourceRewardedAd () <GADMAdapterIronSourceRewardedDelegate>

// The completion handler to call when the ad loading succeeds or fails.
@property(copy, nonatomic) GADMediationRewardedLoadCompletionHandler adLoadCompletionHandler;

// Ad configuration for the ad to be rendered.
@property(weak, nonatomic) GADMediationAdConfiguration *adConfiguration;

// An ad event delegate to invoke when ad rendering events occur.
@property(weak, nonatomic) id<GADMediationRewardedAdEventDelegate> adEventDelegate;

/// Holds the ID of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceID;

/// Holds the state of the ad instance to be presented.
@property(nonatomic, copy) NSString *instanceState;

@end

@implementation GADMAdapterIronSourceRewardedAd

#pragma mark Admob GADMediationAdapter

- (instancetype)initWithGADMediationRewardedAdConfiguration:
                    (GADMediationRewardedAdConfiguration *)adConfiguration
                                          completionHandler:
                                              (GADMediationRewardedLoadCompletionHandler)
                                                  completionHandler {
  self = [super init];
  if (self) {
    _adLoadCompletionHandler = completionHandler;
    _adConfiguration = adConfiguration;
    // Default instance ID
    self.instanceID = kGADMIronSourceDefaultInstanceId;
    // Default instance state
    self.instanceState = kInstanceStateStart;
  }
  return self;
}

- (void)requestRewardedAd {
  NSDictionary *credentials = [_adConfiguration.credentials settings];

  /* Parse application key */
  NSString *applicationKey = @"";
  if (credentials[kGADMAdapterIronSourceAppKey]) {
    applicationKey = credentials[kGADMAdapterIronSourceAppKey];
  }

  if ([GADMAdapterIronSourceUtils isEmpty:applicationKey]) {
    [GADMAdapterIronSourceUtils onLog:@"Fail to setup, 'appKey' parameter is missing"];
    NSError *error = [GADMAdapterIronSourceUtils
        createErrorWith:@"IronSource Adapter failed to setUp"
              andReason:@"'appKey' parameter is missing"
          andSuggestion:@"Make sure that 'appKey' server parameter is added"];
    _adLoadCompletionHandler(nil, error);
    return;
  }
  if (credentials[kGADMAdapterIronSourceInstanceId]) {
    self.instanceID = credentials[kGADMAdapterIronSourceInstanceId];
  }

  [[ISMediationManager sharedManager]
      initIronSourceSDKWithAppKey:applicationKey
                       forAdUnits:[NSSet setWithObject:IS_REWARDED_VIDEO]];
  [[ISMediationManager sharedManager] loadRewardedAdWithDelegate:self instanceID:self.instanceID];
}

// pragma mark - GADMediationRewardedAd

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [[ISMediationManager sharedManager] presentRewardedAdFromViewController:viewController
                                                               instanceID:_instanceID];
}

// pragma mark - GADMAdapterIronSourceDelegate

- (void)rewardedVideoDidLoad:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"RewardedVideoDidLoad for Instance ID: %@", instanceId]];
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
}

- (void)rewardedVideoDidOpen:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"IronSource RewardedVideo did open for Instance ID: %@",
                                       instanceId]];

  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate willPresentFullScreenView];
  [strongDelegate didStartVideo];
  [strongDelegate reportImpression];
}

- (void)rewardedVideoDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"RewardedVideoDidFailToLoad for Instance ID: %@ with Error: %@",
                                 instanceId, error]];
  _adLoadCompletionHandler(nil, error);
}

- (void)rewardedVideoDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"IronSource rewardedVideo did fail to show with error: %@, "
                                       @"for Instance ID: %@",
                                       error.description, instanceId]];
  [_adEventDelegate didFailToPresentWithError:error];
}

- (void)rewardedVideoAdRewarded:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"IronSource received reward for Instance ID: %@", instanceId]];
  GADAdReward *reward =
      [[GADAdReward alloc] initWithRewardType:@""
                                 rewardAmount:[NSDecimalNumber decimalNumberWithString:@"1"]];
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate didEndVideo];
  [strongDelegate didRewardUserWithReward:reward];
}

- (void)rewardedVideoDidClick:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"Did click IronSource RewardedVideo for Instance ID: %@",
                                       instanceId]];
  [_adEventDelegate reportClick];
}

- (void)rewardedVideoDidClose:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"IronSource RewardedVideo did close for Instance ID: %@",
                                       instanceId]];
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate willDismissFullScreenView];
  [strongDelegate didDismissFullScreenView];
}

- (void)setState:(NSString *)state {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"RV Instance setState: changing from oldState=%@ to newState=%@",
                                 self.instanceState, state]];
  self.instanceState = state;
}

- (NSString *)getState {
  return self.instanceState;
}

@end
