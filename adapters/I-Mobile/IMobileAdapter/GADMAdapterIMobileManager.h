// Copyright 2020 Google LLC
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
#import <UIKit/UIKit.h>
#import <ImobileSdkAds/ImobileSdkAds.h>

@interface GADMAdapterIMobileManager : NSObject

/// Shared instance.
@property(class, atomic, readonly, nonnull) GADMAdapterIMobileManager *sharedInstance;

/// Requests an interstitial ad from the i-mobile SDK.
- (nullable NSError *)requestInterstitialAdForSpotId:(nonnull NSString *)spotId
                                            delegate:(nonnull id<IMobileSdkAdsDelegate>)delegate;

@end
