//
// Copyright (C) 2016 Google, Inc.
//
// SampleRewardBasedVideoController.h
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

@import UIKit;

#import "SampleRewardBasedVideo.h"
#import "SampleRewardBasedVideoAd.h"
#import "SampleRewardBasedVideoDelegate.h"

/// This is real reward-based video ad. This classs initializes with SampleRewardBasedVideo
/// instance. It sends delegate call backs when a video ad starts/stops playing and when the user
/// clicks on the video ad.
@interface SampleRewardBasedVideoController : UIViewController

/// Designated initializer. Returns reward-based video controller with given reward-based video.
- (instancetype)initWithRewardBasedVideo:(SampleRewardBasedVideoAd *)rewardBasedVideo
    NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (instancetype)init NS_UNAVAILABLE;

/// Unavailable.
- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil NS_UNAVAILABLE;

/// Unavailable.
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/// Sample reward-based video ad delegate.
@property(nonatomic, weak) id<SampleRewardBasedVideoDelegate> delegate;

@end
