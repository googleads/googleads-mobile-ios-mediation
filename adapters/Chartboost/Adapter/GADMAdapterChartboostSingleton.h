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

#import <Chartboost/Chartboost.h>

#import "GADMAdapterChartboost.h"

@protocol GADMAdapterChartboostDelegateProtocol;

@interface GADMAdapterChartboostSingleton : NSObject

/// Shared instance.
+ (instancetype)sharedManager;

/// Initializes the new reward-based video ad instance with |appID|, |appSignature|, |adLocation|
/// and |adapterDelegate|.
- (void)configureRewardBasedVideoAdWithAppID:(NSString *)appID
                              adAppSignature:(NSString *)appSignature
                                  adLocation:(NSString *)adLocation
                                    delegate:
                                        (id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate;

/// Requests reward-based video for |adapterDelegate| and |adLocation|.
- (void)requestRewardBasedVideoForDelegate:
            (id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate
                                adLocation:(NSString *)adLocation;

/// Presents current reward-based video ad for |adapterDelegate|.
- (void)presentRewardBasedVideoAdForDelegate:
    (id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate;

/// Initializes the new interstitial ad instance with |appID|, |appSignature|, |adLocation| and
/// |adapterDelegate|.
- (void)configureInterstitialAdWithAppID:(NSString *)appID
                          adAppSignature:(NSString *)appSignature
                              adLocation:(NSString *)adLocation
                                delegate:(id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate;

/// Presents current interstitial ad for |adapterDelegate|.
- (void)presentInterstitialAdForDelegate:(id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate;

/// Tells the adapter to remove itself as a |adapterDelegate|.
- (void)stopTrackingDelegate:(id<GADMAdapterChartboostDelegateProtocol>)adapterDelegate;

@end
