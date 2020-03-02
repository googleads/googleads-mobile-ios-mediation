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

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "GADMAdapterChartboost.h"

typedef NS_ENUM(NSInteger, GADMAdapterChartboostInitState) {
  GADMAdapterChartboostUninitialized,
  GADMAdapterChartboostInitialized,
  GADMAdapterChartboostInitializing
};

typedef void (^ChartboostInitCompletionHandler)(NSError *_Nullable error);

@protocol GADMAdapterChartboostDataProvider;

@interface GADMAdapterChartboostSingleton : NSObject

/// Shared instance.
@property(class, atomic, readonly, nonnull) GADMAdapterChartboostSingleton *sharedInstance;

/// Starts the Chartboost SDK.
- (void)startWithAppId:(nonnull NSString *)appId
          appSignature:(nonnull NSString *)appSignature
     completionHandler:(nonnull ChartboostInitCompletionHandler)completionHandler;

/// Configures a new rewarded ad instance with |appID|, |appSignature| and |adapterDelegate|.
- (void)configureRewardedAdWithAppID:(nonnull NSString *)appID
                        appSignature:(nonnull NSString *)appSignature
                            delegate:
                                (nonnull id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)
                                    adapterDelegate;

/// Presents the current rewarded ad for |adapterDelegate|.
- (void)presentRewardedAdForDelegate:
    (nonnull id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate;

/// Initializes a new interstitial ad instance.
- (void)configureInterstitialAdWithDelegate:
    (nonnull id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate;

/// Presents the current interstitial ad for |adapterDelegate|.
- (void)presentInterstitialAdForDelegate:
    (nonnull id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate;

/// Tells the adapter to remove itself as an |adapterDelegate|.
- (void)stopTrackingInterstitialDelegate:
    (nonnull id<GADMAdapterChartboostDataProvider, ChartboostDelegate>)adapterDelegate;

@end
