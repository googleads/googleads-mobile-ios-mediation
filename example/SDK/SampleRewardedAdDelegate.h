//
// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@import Foundation;

#import "SampleAdRequest.h"

@class SampleRewardedAd;

/// Delegate methods for receiving state change messages from SampleRewardedAd.
@protocol SampleRewardedAdDelegate <NSObject>

@required

/// Tells the delegate that the user earned a reward.
- (void)rewardedAd:(nonnull SampleRewardedAd *)rewardedAd userDidEarnReward:(NSUInteger)reward;

@optional

/// Tells the delegate that the rewarded ad was received.
- (void)rewardedAdDidReceiveAd:(nonnull SampleRewardedAd *)rewardedAd;

/// Tells the delegate that the rewarded ad failed to present.
- (void)rewardedAdDidFailToLoadWithError:(SampleErrorCode)error;

/// Tells the delegate that the rewarded ad was presented.
- (void)rewardedAdDidPresent:(nonnull SampleRewardedAd *)rewardedAd;

/// Tells the delegate that the rewarded ad was dismissed.
- (void)rewardedAdDidDismiss:(nonnull SampleRewardedAd *)rewardedAd;

@end
