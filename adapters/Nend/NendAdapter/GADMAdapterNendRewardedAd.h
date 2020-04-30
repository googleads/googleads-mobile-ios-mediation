// Copyright 2019 Google Inc.
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

@interface GADMAdapterNendRewardedAd : NSObject <GADMediationRewardedAd>

/// Initializes a new instance with |adConfiguration| and |completionHandler|.
- (nonnull instancetype)
    initWithAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
          completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler)completionHandler
    NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Requests a rewarded ad from nend.
- (void)loadRewardedAd;

@end
