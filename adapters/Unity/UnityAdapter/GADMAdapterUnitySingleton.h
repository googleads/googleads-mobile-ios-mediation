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
@import UnityAds;

#import "GADMAdapterUnityProtocol.h"

@interface GADMAdapterUnitySingleton : NSObject

/// Shared instance.
+ (instancetype)sharedInstance;

/// Configures a reward-based video ad with provided |gameID| and |adapterDelegate| and returns
/// YES if successful; otherwise returns NO.

- (void)initializeWithGameID:(NSString *)gameID;

/// Requests a reward-based video ad with |adapterDelegate|.
- (void)requestRewardedAdWithDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate;

/// Presents a reward-based video ad for |viewController| with |adapterDelegate|.
- (void)presentRewardedAdForViewController:(UIViewController *)viewController
                                  delegate:
                                      (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)
                                          adapterDelegate;

/// Configures an interstitial ad with provided |gameID| and |adapterDelegate|.
- (void)requestInterstitialAdWithDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate;

/// Presents an interstitial ad for |viewController| with |adapterDelegate|.
- (void)presentInterstitialAdForViewController:(UIViewController *)viewController
                                      delegate:(id<GADMAdapterUnityDataProvider,
                                                   UnityAdsExtendedDelegate>)adapterDelegate;

/// Presents a banner ad for |gameID| with |adapterDelegate|
- (void)presentBannerAd:(NSString *)gameID
               delegate:(id<GADMAdapterUnityDataProvider, UnityAdsBannerDelegate>)adapterDelegate;

/// Tells the adapter to remove itself as a |adapterDelegate|.
- (void)stopTrackingDelegate:
    (id<GADMAdapterUnityDataProvider, UnityAdsExtendedDelegate>)adapterDelegate;

@end
