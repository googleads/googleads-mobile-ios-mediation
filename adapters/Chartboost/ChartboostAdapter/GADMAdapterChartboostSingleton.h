// Copyright 2016 Google Inc.
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

@import Foundation;
@import GoogleMobileAds;

#import "GADMAdapterChartboost.h"

@protocol GADMAdapterChartboostDataProvider;

@interface GADMAdapterChartboostSingleton : NSObject

/// Shared instance.
+ (instancetype)sharedManager;

/// Initializes a new reward-based video ad instance with |appID|, |appSignature| and
/// |adapterDelegate|.
- (void)configureRewardBasedVideoAdWithAppID:(NSString *)appID
                              adAppSignature:(NSString *)appSignature
                                    delegate:
                                        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)
                                            adapterDelegate;

/// Requests a reward-based video ad for |adapterDelegate|.
- (void)requestRewardBasedVideoForDelegate:
        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate;

/// Presents the current reward-based video ad for |adapterDelegate|.
- (void)presentRewardBasedVideoAdForDelegate:
        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate;

/// Initializes a new interstitial ad instance with |appID|, |appSignature| and |adapterDelegate|.
- (void)configureInterstitialAdWithAppID:(NSString *)appID
                          adAppSignature:(NSString *)appSignature
                                delegate:(id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)
                                             adapterDelegate;

/// Presents the current interstitial ad for |adapterDelegate|.
- (void)presentInterstitialAdForDelegate:
        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate;

/// Tells the adapter to remove itself as an |adapterDelegate|.
- (void)stopTrackingDelegate:
        (id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate;

@end
