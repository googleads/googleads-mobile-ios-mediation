// Copyright 2019 Google LLC
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

/// Rewarded mediation network adapter for Fyber.
@interface GADMAdapterFyberRewardedAd : NSObject

/// Dedicated initializer to create a new instance of a rewarded ad.
- (nonnull instancetype)initWithAdConfiguration:
    (nonnull GADMediationRewardedAdConfiguration *)adConfiguration;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Loads a rewarded ad from the Fyber SDK.
- (void)loadRewardedAdWithCompletionHandler:
    (nonnull GADMediationRewardedLoadCompletionHandler)completionHandler;

@end
