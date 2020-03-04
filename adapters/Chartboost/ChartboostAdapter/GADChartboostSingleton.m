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

#import "GADChartboostSingleton.h"
#import "GADMAdapterChartboostConstants.h"
#import "GADChartboostError.h"

@implementation GADChartboostSingleton

+ (nonnull GADChartboostSingleton *)sharedInstance {
  static GADChartboostSingleton *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[GADChartboostSingleton alloc] init];
  });
  return sharedInstance;
}

- (void)startWithAppId:(NSString *)appId
          appSignature:(NSString *)appSignature
     completionHandler:(nonnull ChartboostInitCompletionHandler)completionHandler {
  appId = [appId stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  appSignature = [appSignature stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
  
  if (!appId || !appSignature) {
    completionHandler(GADChartboostError(kGADErrorMediationDataError,
                                         @"App ID & App Signature cannot be nil."));
    return;
  }
  
  [Chartboost startWithAppId:appId appSignature:appSignature completion:^(BOOL started) {
    completionHandler(started ? nil : GADChartboostError(0, @"Failed to initialize Chartboost SDK."));
  }];
}

- (void)setFrameworkWithExtras:(GADMChartboostExtras *)extras {
  if (extras && [extras isKindOfClass:GADMChartboostExtras.class]) {
    [Chartboost setFramework:extras.framework withVersion:extras.frameworkVersion];
  }
}

- (CHBMediation *)mediation {
  return [[CHBMediation alloc] initWithType:CBMediationAdMob
                             libraryVersion:[GADRequest sdkVersion]
                             adapterVersion:kGADMAdapterChartboostVersion];
}

@end
