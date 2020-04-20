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

/// Adapter for communicating with the IronSource Network to fetch reward-based video ads.
@interface GADMAdapterIronSourceRewardedAd : NSObject <GADMediationRewardedAd>

/// Initializes a new instance with |adConfiguration| and |completionHandler|.
- (instancetype)initWithGADMediationRewardedAdConfiguration:
                    (GADMediationRewardedAdConfiguration *)adConfiguration
                                          completionHandler:
                                              (GADMediationRewardedLoadCompletionHandler)
                                                  completionHandler NS_DESIGNATED_INITIALIZER;

/// Unavailable.
- (instancetype)init __unavailable;

- (void)requestRewardedAd;

@end
