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
#import "GADMediationAdapterIronSource.h"
#import "ISMediationManager.h"

NSString *const kGADMAdapterIronSourceRewardedVideoPlacement = @"rewardedVideoPlacement";

@interface GADMAdapterIronSourceRewardedAd () <ISAdAvailabilityChangedDelegate>

// The completion handler to call when the ad loading succeeds or fails.
@property(copy, nonatomic) GADRewardedLoadCompletionHandler adLoadCompletionHandler;

// Ad configuration for the ad to be rendered.
@property(weak, nonatomic) GADMediationAdConfiguration *adConfiguration;

// An ad event delegate to invoke when ad rendering events occur.
@property(weak, nonatomic) id<GADMediationRewardedAdEventDelegate> adEventDelegate;

@end

@implementation GADMAdapterIronSourceRewardedAd

#pragma mark Admob GADMediationAdapter

- (instancetype)initWithGADMediationRewardedAdConfiguration:
                    (GADMediationRewardedAdConfiguration *)adConfiguration
                                          completionHandler:
                                              (GADRewardedLoadCompletionHandler)completionHandler {
  self = [super init];
  if (self) {
    _adLoadCompletionHandler = completionHandler;
    _adConfiguration = adConfiguration;
  }
  return self;
}

- (void)requestRewardedAd {
  NSDictionary *credentials = [self.adConfiguration.credentials settings];
  /* Parse enabling testing mode key for log */
  self.isLogEnabled = _adConfiguration.isTestRequest;

  /* Parse application key */
  NSString *applicationKey = @"";
  if ([credentials objectForKey:kGADMAdapterIronSourceAppKey]) {
    applicationKey = [credentials objectForKey:kGADMAdapterIronSourceAppKey];
  }

  if ([self isEmpty:applicationKey]) {
    [self onLog:@"Fail to setup, 'appKey' parameter is missing"];
    NSError *error = [self createErrorWith:@"IronSource Adapter failed to setUp"
                                 andReason:@"'appKey' parameter is missing"
                             andSuggestion:@"Make sure that 'appKey' server parameter is added"];
    _adLoadCompletionHandler(nil, error);
    _adLoadCompletionHandler = nil;
    return;
  }

  if (![ISMediationManager shared].isIronSourceRewardedInitialized) {
    [self initIronSourceSDKWithAppKey:applicationKey adUnit:IS_REWARDED_VIDEO];
    [ISMediationManager shared].ironSourceRewardedInitialized = YES;
  }

  /* Parse all other credentials */
  [self parseCredentials];
  [[ISMediationManager shared] requestRewardedAdWithDelegate:self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [[ISMediationManager shared] presentFromViewController:viewController delegate:self];
}

#pragma mark RewardBasedVideo Utils Methods

- (void)initIronSourceSDKWithAppKey:(NSString *)appKey adUnit:(NSString *)adUnit {
  [super initIronSourceSDKWithAppKey:appKey adUnit:adUnit];
}

- (void)parseCredentials {
  NSDictionary *credentials = [_adConfiguration.credentials settings];
  if ([credentials objectForKey:kGADMAdapterIronSourceInstanceId]) {
    self.instanceId = [credentials objectForKey:kGADMAdapterIronSourceInstanceId];
  }
}

/// Invoked when the user completed the video and should be rewarded.
/// placementInfo - IronSourcePlacementInfo - an object contains the placement's reward name and
/// amount
- (void)didReceiveRewardForPlacement:(ISPlacementInfo *)placementInfo
                          instanceId:(NSString *)instanceId {
  GADAdReward *reward;
  if (placementInfo) {
    NSString *rewardName = [placementInfo rewardName];
    NSNumber *rewardAmount = [placementInfo rewardAmount];
    reward = [[GADAdReward alloc]
        initWithRewardType:rewardName
              rewardAmount:[NSDecimalNumber decimalNumberWithDecimal:[rewardAmount decimalValue]]];

    id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
    [strongDelegate didEndVideo];
    [strongDelegate didRewardUserWithReward:reward];

    [self
        onLog:[NSString
                  stringWithFormat:@"IronSource received reward for placement %@ ,for instance:%@",
                                   rewardName, instanceId]];

  } else {
    [self onLog:@"IronSource received reward for placement - without placement info"];
  }
}

/// Invoked when an Ad failed to display.
/// error - NSError which contains the reason for the failure.
/// The error contains error.code and error.localizedDescription
- (void)rewardedVideoDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId {
  NSString *log = [NSString
      stringWithFormat:@"IronSource rewardedVideo did fail to show with error: %@, for intance: %@",
                       error.description, instanceId];
  [self onLog:log];
  _adLoadCompletionHandler(nil, error);
  _adLoadCompletionHandler = nil;
}

/// Invoked when the RewardedVideo ad view has opened.
- (void)rewardedVideoDidOpen:(NSString *)instanceId {
  [self onLog:[NSString stringWithFormat:@"IronSource RewardedVideo did open for instance:%@",
                                         instanceId]];

  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate didStartVideo];
  [strongDelegate willPresentFullScreenView];
}

/// Invoked when the user is about to return to the application after closing the RewardedVideo ad.
- (void)rewardedVideoDidClose:(NSString *)instanceId {
  [self onLog:[NSString stringWithFormat:@"IronSource RewardedVideo did close for instance:%@",
                                         instanceId]];
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate didDismissFullScreenView];
}

/// Invoked after a video has been clicked.
- (void)didClickRewardedVideo:(ISPlacementInfo *)placementInfo instanceId:(NSString *)instanceId {
  [self onLog:[NSString stringWithFormat:@"Did click IronSource RewardedVideo for instance:%@",
                                         instanceId]];

  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate reportClick];
}

- (void)adReady {
  [self onLog:[NSString stringWithFormat:@"Reward based video ad is available for instance is: %@",
                                         self.instanceId]];
  _adEventDelegate = _adLoadCompletionHandler(self, nil);
  _adLoadCompletionHandler = nil;
}

- (void)didFailToLoadWithError:(NSError *)error {
  _adLoadCompletionHandler(nil, error);
  _adLoadCompletionHandler = nil;
}

- (NSString *)getInstanceID {
  return self.instanceId;
}

@end
