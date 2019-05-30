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
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"
#import "ISMediationManager.h"

@interface GADMAdapterIronSourceRewardedAd () <ISDemandOnlyRewardedVideoDelegate,
                                               GADMAdapterIronSourceDelegate>

// The completion handler to call when the ad loading succeeds or fails.
@property(copy, nonatomic) GADMediationRewardedLoadCompletionHandler adLoadCompletionHandler;

// Ad configuration for the ad to be rendered.
@property(weak, nonatomic) GADMediationAdConfiguration *adConfiguration;

// An ad event delegate to invoke when ad rendering events occur.
@property(weak, nonatomic) id<GADMediationRewardedAdEventDelegate> adEventDelegate;

/// Yes if we want to show IronSource adapter logs.
@property(nonatomic, assign) BOOL isLogEnabled;

/// Holds the ID of the ad instance to be presented.
@property(nonatomic, strong) NSString *instanceID;

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
    _instanceID = @"0";
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

  if ([GADMAdapterIronSourceUtils isEmpty:applicationKey]) {
    [self onLog:@"Fail to setup, 'appKey' parameter is missing"];
    NSError *error = [GADMAdapterIronSourceUtils
        createErrorWith:@"IronSource Adapter failed to setUp"
              andReason:@"'appKey' parameter is missing"
          andSuggestion:@"Make sure that 'appKey' server parameter is added"];
    _adLoadCompletionHandler(nil, error);
    return;
  }

  ISMediationManager *sharedManager = [ISMediationManager sharedManager];
  [sharedManager initIronSourceSDKWithAppKey:applicationKey
                                  forAdUnits:[NSSet setWithObject:IS_REWARDED_VIDEO]];

  /* Parse all other credentials */
  [self parseCredentials];
  [sharedManager requestRewardedAdWithDelegate:self];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
  [[ISMediationManager sharedManager] presentRewardedAdFromViewController:viewController
                                                                 delegate:self];
}

#pragma mark RewardBasedVideo Utils Methods

- (void)parseCredentials {
  NSDictionary *credentials = [_adConfiguration.credentials settings];
  if ([credentials objectForKey:kGADMAdapterIronSourceInstanceId]) {
    _instanceID = [credentials objectForKey:kGADMAdapterIronSourceInstanceId];
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

    [self onLog:[NSString stringWithFormat:
                              @"IronSource received reward for placement %@ ,for Instance ID: %@",
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
      stringWithFormat:
          @"IronSource rewardedVideo did fail to show with error: %@, for Instance ID: %@",
          error.description, instanceId];
  [self onLog:log];
  [_adEventDelegate didFailToPresentWithError:error];
}

/// Invoked when the RewardedVideo ad view has opened.
- (void)rewardedVideoDidOpen:(NSString *)instanceId {
  [self onLog:[NSString stringWithFormat:@"IronSource RewardedVideo did open for Instance ID: %@",
                                         instanceId]];

  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate didStartVideo];
  [strongDelegate willPresentFullScreenView];
}

/// Invoked when the user is about to return to the application after closing the RewardedVideo ad.
- (void)rewardedVideoDidClose:(NSString *)instanceId {
  [self onLog:[NSString stringWithFormat:@"IronSource RewardedVideo did close for Instance ID: %@",
                                         instanceId]];
  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate didDismissFullScreenView];
}

/// Invoked after a video has been clicked.
- (void)didClickRewardedVideo:(ISPlacementInfo *)placementInfo instanceId:(NSString *)instanceId {
  [self onLog:[NSString stringWithFormat:@"Did click IronSource RewardedVideo for Instance ID: %@",
                                         instanceId]];

  id<GADMediationRewardedAdEventDelegate> strongDelegate = _adEventDelegate;
  [strongDelegate reportClick];
}

- (NSString *)getInstanceID {
  return _instanceID;
}

- (void)didFailToLoadAdWithError:(NSError *)error {
  _adLoadCompletionHandler(nil, error);
}

- (void)rewardedVideoHasChangedAvailability:(BOOL)available instanceId:(NSString *)instanceId {
  if (available) {
    [self onLog:[NSString stringWithFormat:@"Rewarded ad is available for Instance ID: %@",
                                           _instanceID]];
    _adEventDelegate = _adLoadCompletionHandler(self, nil);
  } else {
    NSError *error = [GADMAdapterIronSourceUtils
        createErrorWith:[NSString stringWithFormat:@"Rewarded Ad not available for Instance ID: %@",
                                                   instanceId]
              andReason:@"No Ad available"
          andSuggestion:nil];
    _adLoadCompletionHandler(nil, error);
  }
}

- (void)onLog:(NSString *)log {
  if (_isLogEnabled) {
    NSLog(@"IronSourceAdapter: %@", log);
  }
}

@end
