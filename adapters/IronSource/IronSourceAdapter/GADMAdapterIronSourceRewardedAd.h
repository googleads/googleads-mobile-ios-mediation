// Copyright 2023 Google Inc.
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

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

/// Adapter for communicating with the IronSource Network to fetch reward-based video ads.
@interface GADMAdapterIronSourceRewardedAd : NSObject <GADMediationRewardedAd>

/// Initializes a new instance with adConfiguration and completionHandler.
- (void)loadRewardedAdForConfiguration:(GADMediationRewardedAdConfiguration *_Nullable)adConfiguration
                     completionHandler:(GADMediationRewardedLoadCompletionHandler _Nullable )
completionHandler;

#pragma mark - Instance map Access

// Add a delegate to the instance map
+ (void)setDelegate:(GADMAdapterIronSourceRewardedAd *_Nonnull)delegate forKey:(NSString *_Nonnull)key;

// Retrieve a delegate from the instance map
+ (GADMAdapterIronSourceRewardedAd *_Nonnull)delegateForKey:(NSString *_Nonnull)key;

// Remove a delegate from the instance map
+ (void)removeDelegateForKey:(NSString *_Nonnull)key;

#pragma mark - Getters and Setters

/// Get the rewarded event delegate for Admob mediation.
- (id<GADMediationRewardedAdEventDelegate>_Nullable) getRewardedAdEventDelegate;

/// Set the rewarded event delegate for Admob mediation.
- (void)setRewardedAdEventDelegate:(id<GADMediationRewardedAdEventDelegate>_Nullable)eventDelegate;

/// Get the rewarded Admob mediation load completion handler.
- (GADMediationRewardedLoadCompletionHandler _Nullable) getLoadCompletionHandler;

/// Set the ad instance state
- (void)setState:(NSString *_Nullable)state;

/// Get the ad instance state
- (NSString *_Nullable)getState;

@end
