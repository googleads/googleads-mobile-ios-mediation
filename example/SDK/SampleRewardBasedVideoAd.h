//
// Copyright (C) 2016 Google, Inc.
//
// SampleRewardBasedVideoAd.h
// Sample Ad Network SDK
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

/// SampleRewardBasedVideoAd class contains reward-based video ad name and reward amount.
@interface SampleRewardBasedVideoAd : NSObject

/// Reward-based video ad name.
@property(nonatomic, readonly, copy) NSString *adName;

/// Reward-based video ad reward amount.
@property(nonatomic, readonly) int rewardAmount;

/// Returns a SampleRewardBasedVideoAd with |adName| and |reward|.
- (instancetype)initWithAdName:(NSString *)adName reward:(int)reward;

@end
