// Copyright 2017 Google Inc.
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

#import "GADMAdapterIronSourceRewarded.h"

NSString *const kGADMAdapterIronSourceRewardedVideoPlacement = @"rewardedVideoPlacement";

@interface GADMAdapterIronSourceRewarded () {
  // Connector from Google Mobile Ads SDK to receive rewarded video ad configurations.
  __weak id<GADMRewardBasedVideoAdNetworkConnector> _rewardbasedVideoAdConnector;
}

@end

// Internal state for IronSource SDK Initialisation for RewardedVideo.
static BOOL didIronSourceInitiateRewardedVideo = NO;
// Internal state to acknowledge first availability callback on registered instance id.
static BOOL didIronSourceReceiveFirstAvailability = NO;

@implementation GADMAdapterIronSourceRewarded

#pragma mark Admob GADMRewardBasedVideoAdNetworkAdapter
- (instancetype)initWithRewardBasedVideoAdNetworkConnector:
        (id<GADMRewardBasedVideoAdNetworkConnector>)connector {
  if (!connector) {
    return nil;
  }
  self = [super init];
  if (self) {
    _rewardbasedVideoAdConnector = connector;
  }
  return self;
}

- (void)setUp {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
  NSDictionary *credentials = [strongConnector credentials];

  /* Parse enabling testing mode key for log */
  self.isLogEnabled = strongConnector.testMode;

  /* Parse application key */
  NSString *applicationKey = @"";
  if ([credentials objectForKey:kGADMAdapterIronSourceAppKey]) {
    applicationKey = [credentials objectForKey:kGADMAdapterIronSourceAppKey];
  }

  if (![self isEmpty:applicationKey]) {
    /* Parse all other credentials */
    [self parseCredentials];

    [IronSource setISDemandOnlyRewardedVideoDelegate:self];
    if (!didIronSourceInitiateRewardedVideo) {
      didIronSourceInitiateRewardedVideo = YES;
      [self initIronSourceSDKWithAppKey:applicationKey adUnit:IS_REWARDED_VIDEO];
    }
  } else {
    [self onLog:@"Fail to setup, 'appKey' parameter is missing"];
    NSError *error = [self createErrorWith:@"IronSource Adapter failed to setUp"
                                 andReason:@"'appKey' parameter is missing"
                             andSuggestion:@"Make sure that 'appKey' server parameter is added"];

    [strongConnector adapter:self didFailToSetUpRewardBasedVideoAdWithError:error];
  }
}

- (void)requestRewardBasedVideoAd {
  [self onLog:@"Requesting IronSource Rewarded Video ad"];

  /* Parse all other credentials */
  [self parseCredentials];

  if (didIronSourceReceiveFirstAvailability) {
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;

    if ([IronSource hasISDemandOnlyRewardedVideo:self.instanceId]) {
      [self onLog:[NSString
                      stringWithFormat:@"Reward based video ad is available for instance is: %@",
                                       self.instanceId]];
      [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
    } else {
      NSError *availableAdsError =
          [self createErrorWith:@"IronSource network isn't available"
                      andReason:@"Network fill issue"
                  andSuggestion:
                      @"Check that your network configuration are according to the documentation."];
      [strongConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:availableAdsError];
    }
  } else {
    // We are waiting for a response from IronSource SDK (see:
    // 'rewardedVideoHasChangedAvailability').
    // Once we retrived a response we notify AdMob for availability.
    // From then on for every other load we update AdMob with IronSource rewarded video current
    // availability (see: 'hasISDemandOnlyRewardedVideo').
  }
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
  /* Parse all other credentials */
  [self parseCredentials];

  if ([IronSource hasISDemandOnlyRewardedVideo:self.instanceId]) {
    // The reward based video ad is available, present the ad.
    [IronSource showISDemandOnlyRewardedVideo:viewController instanceId:self.instanceId];
  } else {
    // Because publishers are expected to check that an ad is available before trying to show one,
    // the above conditional should always hold true. If for any reason the adapter is not ready to
    // present an ad, however, it should log an error with reason for failure.
    [self onLog:@"No ads to show."];
  }
}

#pragma mark RewardBasedVideo Utils Methods

- (void)initIronSourceSDKWithAppKey:(NSString *)appKey adUnit:(NSString *)adUnit {
  [super initIronSourceSDKWithAppKey:appKey adUnit:adUnit];

  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
  [strongConnector adapterDidSetUpRewardBasedVideoAd:self];
}

- (void)parseCredentials {
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
  NSDictionary *credentials = [strongConnector credentials];

  // Parse instance id key.
  if ([credentials objectForKey:kGADMAdapterIronSourceInstanceId]) {
    self.instanceId = [credentials objectForKey:kGADMAdapterIronSourceInstanceId];
  }
}

#pragma mark IronSource Rewarded Video Delegate implementation

/// Invoked when there is a change in the ad availability status.
- (void)rewardedVideoHasChangedAvailability:(BOOL)available instanceId:(NSString *)instanceId {
  [self onLog:[NSString
                  stringWithFormat:
                      @"IronSource RewardedVideo has changed availability - %@, for instance: %@ ",
                      available ? @"YES" : @"NO", instanceId]];

  // We will notify only changes regarding to the registered instance.
  if (![self.instanceId isEqualToString:instanceId]) {
    return;
  }

  if (!didIronSourceReceiveFirstAvailability) {
    didIronSourceReceiveFirstAvailability = YES;
    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    if (available) {
      [strongConnector adapterDidReceiveRewardBasedVideoAd:self];
    } else {
      NSError *AvailableAdsError =
          [self createErrorWith:@"IronSource network isn't available"
                      andReason:@"Network fill issue"
                  andSuggestion:@"Please talk with your PM and check that your network "
                                @"configuration are according to the documentation."];
      [strongConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:AvailableAdsError];
    }
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

    id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
    [strongConnector adapterDidCompletePlayingRewardBasedVideoAd:self];
    [strongConnector adapter:self didRewardUserWithReward:reward];
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
}

/// Invoked when the RewardedVideo ad view has opened.
- (void)rewardedVideoDidOpen:(NSString *)instanceId {
  [self onLog:[NSString stringWithFormat:@"IronSource RewardedVideo did open for instance:%@",
                                         instanceId]];

  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
  [strongConnector adapterDidOpenRewardBasedVideoAd:self];
  [strongConnector adapterDidStartPlayingRewardBasedVideoAd:self];
}

/// Invoked when the user is about to return to the application after closing the RewardedVideo ad.
- (void)rewardedVideoDidClose:(NSString *)instanceId {
  [self onLog:[NSString stringWithFormat:@"IronSource RewardedVideo did close for instance:%@",
                                         instanceId]];

  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
  [strongConnector adapterDidCloseRewardBasedVideoAd:self];
}

/// Invoked after a video has been clicked.
- (void)didClickRewardedVideo:(ISPlacementInfo *)placementInfo instanceId:(NSString *)instanceId {
  [self onLog:[NSString stringWithFormat:@"Did click IronSource RewardedVideo for instance:%@",
                                         instanceId]];
  id<GADMRewardBasedVideoAdNetworkConnector> strongConnector = _rewardbasedVideoAdConnector;
  [strongConnector adapterDidGetAdClick:self];
  [strongConnector adapterWillLeaveApplication:self];
}

@end
