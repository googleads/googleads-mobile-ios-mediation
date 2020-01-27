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

#import "SampleAdRequest.h"
#import "SampleRewardedAdDelegate.h"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// The SampleRewardedAd class is used for requesting and presenting a sample rewarded ad.
@interface SampleRewardedAd : NSObject

/// Initialized a rewarded ad with the provided ad unit ID.
- (instancetype)initWithAdUnitID:(NSString *)adUnit;

/// Delegate for receiving rewarded ad notifications.
@property(nonatomic, weak) id<SampleRewardedAdDelegate> delegate;

/// Requests an rewarded ad and calls the provided completion handler when the request finishes.
- (void)fetchAd:(SampleAdRequest *)request;

/// The ad unit ID.
@property(readonly, nonatomic, copy) NSString *adUnit;

/// Indicates whether the rewarded ad is ready to be presented.
@property(nonatomic, getter=isReady) BOOL ready;

/// The reward earned by the user for interacting with a rewarded ad. Is nil until the ad has
/// successfully loaded.
@property(nonatomic, readonly) NSUInteger reward;

/// A flag that indicates whether debug logging is on.
@property(nonatomic) BOOL enableDebugLogging;

///  Present the rewarded ad on screen.
- (void)presentFromRootViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
