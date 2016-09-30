//
// Copyright (C) 2016 Google, Inc.
//
// SampleRewardBasedVideoDelegate.h
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

#import "SampleAdRequest.h"

@class SampleRewardBasedVideo;

/// Delegate methods for receiving SampleRewardBasedVideo state change messages.
@protocol SampleRewardBasedVideoDelegate<NSObject>

@optional

/// Tells the delegate that the sample reward-based video initialized.
- (void)rewardBasedVideoAdInitialized:(SampleRewardBasedVideo *)rewardBasedVideo;

/// Tells the delegate that the sample reward-based video has been received.
- (void)rewardBasedVideoAdDidReceiveAd:(SampleRewardBasedVideo *)rewardBasedVideo;

/// Tells the delegate that the sample reward-based video opened.
- (void)rewardBasedVideoAdDidOpen:(SampleRewardBasedVideo *)rewardBasedVideo;

/// Tells the delegate that the sample reward-based video has started playing.
- (void)rewardBasedVideoAdDidStartPlaying:(SampleRewardBasedVideo *)rewardBasedVideo;

/// Tells the delegate that the sample reward-based video is closed.
- (void)rewardBasedVideoAdDidClose:(SampleRewardBasedVideo *)rewardBasedVideo;

/// Tells the delegate that the sample reward-based video will leave the application.
- (void)rewardBasedVideoAdWillLeaveApplication:(SampleRewardBasedVideo *)rewardBasedVideo;

/// Tells the delegate that reward-based video was clicked.
- (void)rewardBasedVideoAdDidReceiveAdClick:(SampleRewardBasedVideo *)rewardBasedVideo;

/// Tells the delegate to reward the user with |reward|.
- (void)rewardBasedVideoAd:(SampleRewardBasedVideo *)rewardBasedVideo
      rewardUserWithReward:(int)reward;

/// Tells the delegate that the sample reward-based video failed to initialize.
- (void)rewardBasedVideoAd:(SampleRewardBasedVideo *)rewardBasedVideo
    didFailToInitializeWithError:(SampleErrorCode)error;

@end
