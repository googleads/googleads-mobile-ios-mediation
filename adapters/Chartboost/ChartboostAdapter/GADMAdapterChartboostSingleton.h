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

typedef void (^ChartboostInitCompletionHandler)(NSError *_Nullable error);

@interface GADMAdapterChartboostSingleton : NSObject

/// Shared instance.
@property(class, atomic, readonly, nonnull) GADMAdapterChartboostSingleton *sharedInstance;

/// Starts the Chartboost SDK using credentials obtained from the network connector.
- (void)startWithNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                completionHandler:(nonnull ChartboostInitCompletionHandler)completionHandler;

/// Starts the Chartboost SDK using the provided credentials.
- (void)startWithCredentials:(nonnull GADMediationCredentials *)credentials
               networkExtras:(nullable id<GADAdNetworkExtras>)networkExtras
           completionHandler:(nonnull ChartboostInitCompletionHandler)completionHandler;

@end
