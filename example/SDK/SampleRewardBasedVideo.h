//
// Copyright (C) 2016 Google, Inc.
//
// SampleRewardBasedVideo.h
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
@import UIKit;

#import "SampleAdRequest.h"
#import "SampleRewardBasedVideoDelegate.h"

/// The SampleRewardBasedVideo class is used for requesting and presenting a sample reward-based
/// video ad.
@interface SampleRewardBasedVideo : NSObject

/// Identifier for reward-based video ad placement.
@property(nonatomic, copy) NSString *adUnitID;

/// Delegate for receiving reward-based video ad notifications.
@property(nonatomic, weak) id<SampleRewardBasedVideoDelegate> delegate;

/// Checks whether or not a rewarded video ad is available. If an ad is not available, a new loadAd:
/// request is made.
- (BOOL)checkAdAvailability;

/// Sample ad request instance.
@property(nonatomic, strong) SampleAdRequest *request;

/// Returns the shared SampleRewardBasedVideo instance.
+ (SampleRewardBasedVideo *)sharedInstance;

/// Initializes with |request| and |adUnitID|.
- (void)initializeWithAdRequest:(SampleAdRequest *)request adUnitID:(NSString *)adUnitID;

/// Presents the reward-based video ad with the provided view controller.
- (void)presentFromRootViewController:(UIViewController *)viewController;

@end
