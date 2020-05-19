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

#import "GADMAdapterChartboostSingleton.h"

#if __has_include(<Chartboost/Chartboost+Mediation.h>)
#import <Chartboost/Chartboost+Mediation.h>
#else
#import "Chartboost+Mediation.h"
#endif

#import "GADMAdapterChartboostConstants.h"
#import "GADMChartboostError.h"

@implementation GADMAdapterChartboostSingleton

#pragma mark - Singleton Initializers

+ (nonnull GADMAdapterChartboostSingleton *)sharedInstance {
  static GADMAdapterChartboostSingleton *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[GADMAdapterChartboostSingleton alloc] init];
  });
  return sharedInstance;
}

- (void)startWithAppId:(nonnull NSString *)appId
          appSignature:(nonnull NSString *)appSignature
     completionHandler:(nonnull ChartboostInitCompletionHandler)completionHandler {
      [Chartboost startWithAppId:appId
                    appSignature:appSignature
                      completion:^(BOOL success) {
                        if (success) {
                          completionHandler(nil);
                        } else {
                          NSError *error = GADChartboostErrorWithDescription(
                              @"Failed to initialize Chartboost SDK.");
                          completionHandler(error);
                        }
                      }];
}

@end
