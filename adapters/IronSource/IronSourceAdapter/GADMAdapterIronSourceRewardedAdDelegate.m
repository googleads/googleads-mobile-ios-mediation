// Copyright 2023 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterIronSourceRewardedAdDelegate.h"
#import <Foundation/Foundation.h>
#import "GADMAdapterIronSourceConstants.h"
#import "GADMAdapterIronSourceRewardedAd.h"
#import "GADMAdapterIronSourceUtils.h"
#import "GADMediationAdapterIronSource.h"

@implementation GADMAdapterIronSourceRewardedAdDelegate

- (GADMAdapterIronSourceRewardedAdDelegate *)init {
  [IronSource setISDemandOnlyRewardedVideoDelegate:self];
  return self;
}

#pragma mark - ISDemandOnlyRewardedVideoDelegate

- (void)rewardedVideoDidClick:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"IronSource rewarded ad was clicked for Instance ID: %@",
                                       instanceId]];

  GADMAdapterIronSourceRewardedAd *adInstance =
      [GADMAdapterIronSourceRewardedAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  id<GADMediationRewardedAdEventDelegate> eventDelegate = [adInstance getRewardedAdEventDelegate];
  if (eventDelegate != nil) {
    [eventDelegate reportClick];
  }
}

- (void)rewardedVideoDidClose:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"IronSource rewarded ad was closed for Instance ID: %@",
                                       instanceId]];

  GADMAdapterIronSourceRewardedAd *adInstance =
      [GADMAdapterIronSourceRewardedAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  [adInstance setState:GADMAdapterIronSourceInstanceStateCanLoad];
  id<GADMediationRewardedAdEventDelegate> eventDelegate = [adInstance getRewardedAdEventDelegate];
  if (eventDelegate == nil) {
    return;
  }

  [eventDelegate willDismissFullScreenView];
  [eventDelegate didDismissFullScreenView];
}

- (void)rewardedVideoDidFailToLoadWithError:(NSError *)error instanceId:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:
                    @"IronSource rewarded ad failed to load for Instance ID: %@ with error: %@",
                    instanceId, error.localizedDescription]];

  GADMAdapterIronSourceRewardedAd *adInstance =
      [GADMAdapterIronSourceRewardedAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  [adInstance setState:GADMAdapterIronSourceInstanceStateCanLoad];
  [adInstance getLoadCompletionHandler](nil, error);
}

- (void)rewardedVideoDidFailToShowWithError:(NSError *)error instanceId:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:
                    @"IronSource rewarded ad failed to show for Instance ID: %@ with error: %@",
                    instanceId, error.localizedDescription]];

  GADMAdapterIronSourceRewardedAd *adInstance =
      [GADMAdapterIronSourceRewardedAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  [adInstance setState:GADMAdapterIronSourceInstanceStateCanLoad];
  id<GADMediationRewardedAdEventDelegate> eventDelegate = [adInstance getRewardedAdEventDelegate];
  if (eventDelegate != nil) {
    [eventDelegate didFailToPresentWithError:error];
  }
}

- (void)rewardedVideoDidLoad:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"IronSource rewarded ad was loaded for Instance ID: %@",
                                       instanceId]];

  GADMAdapterIronSourceRewardedAd *adInstance =
      [GADMAdapterIronSourceRewardedAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  [adInstance setState:GADMAdapterIronSourceInstanceStateCanLoad];
  GADMediationRewardedLoadCompletionHandler loadCompletionHandler =
      [adInstance getLoadCompletionHandler];
  if (loadCompletionHandler != nil) {
    [adInstance setRewardedAdEventDelegate:loadCompletionHandler(adInstance, nil)];
  }
}

- (void)rewardedVideoDidOpen:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString stringWithFormat:@"IronSource rewarded ad was opened for Instance ID: %@",
                                       instanceId]];

  GADMAdapterIronSourceRewardedAd *adInstance =
      [GADMAdapterIronSourceRewardedAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  [adInstance setState:GADMAdapterIronSourceInstanceStateShowing];
  id<GADMediationRewardedAdEventDelegate> eventDelegate = [adInstance getRewardedAdEventDelegate];
  if (eventDelegate == nil) {
    return;
  }

  [eventDelegate willPresentFullScreenView];
  [eventDelegate didStartVideo];
  [eventDelegate reportImpression];
}

- (void)rewardedVideoAdRewarded:(NSString *)instanceId {
  [GADMAdapterIronSourceUtils
      onLog:[NSString
                stringWithFormat:@"IronSource rewarded ad received reward for Instance ID: %@",
                                 instanceId]];

  GADMAdapterIronSourceRewardedAd *adInstance =
      [GADMAdapterIronSourceRewardedAd delegateForKey:instanceId];
  if (adInstance == nil) {
    return;
  }

  id<GADMediationRewardedAdEventDelegate> eventDelegate = [adInstance getRewardedAdEventDelegate];
  if (eventDelegate == nil) {
    return;
  }

  [eventDelegate didEndVideo];
  [eventDelegate didRewardUser];
}

@end
