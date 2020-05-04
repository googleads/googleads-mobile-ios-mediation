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
#import "GADMChartboostError.h"
#import "GADMChartboostExtras.h"

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

- (void)startWithAppId:(nullable NSString *)appId
          appSignature:(nullable NSString *)appSignature
         networkExtras:(nullable id<GADAdNetworkExtras>)networkExtras
     completionHandler:(nonnull ChartboostInitCompletionHandler)completionHandler {
    
    appId = [appId stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    appSignature = [appSignature stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    
    if (!appId.length || !appSignature.length) {
      NSError *error = GADChartboostErrorWithDescription(@"App ID & App Signature cannot be nil.");
      completionHandler(error);
      return;
    }
    [Chartboost startWithAppId:appId appSignature:appSignature completion:^(BOOL started) {
      NSError *error = nil;
      if (started) {
        if (networkExtras && [networkExtras isKindOfClass:GADMChartboostExtras.class]) {
          GADMChartboostExtras *cbExtras = (GADMChartboostExtras *)networkExtras;
          [Chartboost setFramework:cbExtras.framework withVersion:cbExtras.frameworkVersion];
        }
      } else {
        error = GADChartboostErrorWithDescription(@"Failed to initialize Chartboost SDK.");
      }
      completionHandler(error);
    }];
}

@end
