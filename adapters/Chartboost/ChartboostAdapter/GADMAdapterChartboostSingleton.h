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

// TODO: Review all imports in all files
// TODO: NS_ASSUME_NONNULL in all files
#if __has_include(<Chartboost/Chartboost+Mediation.h>)
#import <Chartboost/Chartboost+Mediation.h>
#else
#import "Chartboost+Mediation.h"
#endif

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
- (void)startWithAppId:(NSString *)appId
          appSignature:(NSString *)appSignature
     completionHandler:(nonnull ChartboostInitCompletionHandler)completionHandler;

- (void)setFrameworkWithExtras:(nullable GADMChartboostExtras *)extras;

- (CHBMediation *)mediation;

@end
