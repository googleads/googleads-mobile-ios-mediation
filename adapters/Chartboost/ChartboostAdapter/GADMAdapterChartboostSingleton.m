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

#import <Chartboost/Chartboost+Mediation.h>

#if __has_include(<Chartboost/Chartboost.h>)
#import <Chartboost/Chartboost.h>
#else
#import "Chartboost.h"
#endif

#import "GADMAdapterChartboostConstants.h"
#import "GADMAdapterChartboostUtils.h"
#import "GADMChartboostError.h"

@implementation GADMAdapterChartboostSingleton {
  /// Chartboost SDK init state.
  GADMAdapterChartboostInitState _initState;

  /// An array of completion handlers to be called once the Chartboost SDK is initialized.
  NSMutableArray<ChartboostInitCompletionHandler> *_completionHandlers;
}

#pragma mark - Singleton Initializers

+ (nonnull GADMAdapterChartboostSingleton *)sharedInstance {
  static GADMAdapterChartboostSingleton *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[GADMAdapterChartboostSingleton alloc] init];
  });
  return sharedInstance;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    _completionHandlers = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)startWithAppId:(nonnull NSString *)appId
          appSignature:(nonnull NSString *)appSignature
     completionHandler:(nonnull ChartboostInitCompletionHandler)completionHandler {
  switch (self->_initState) {
    case GADMAdapterChartboostInitialized:
      completionHandler(nil);
      break;
    case GADMAdapterChartboostInitializing:
      GADMAdapterChartboostMutableArrayAddObject(self->_completionHandlers, completionHandler);
      break;
    case GADMAdapterChartboostUninitialized:
      GADMAdapterChartboostMutableArrayAddObject(self->_completionHandlers, completionHandler);
      self->_initState = GADMAdapterChartboostInitializing;

      GADMAdapterChartboostSingleton *weakSelf = self;
      [Chartboost startWithAppId:appId
                    appSignature:appSignature
                      completion:^(BOOL success) {
                        GADMAdapterChartboostSingleton *strongSelf = weakSelf;
                        if (!strongSelf) {
                          return;
                        }

                        if (success) {
                          strongSelf->_initState = GADMAdapterChartboostInitialized;
                          for (ChartboostInitCompletionHandler completionHandler in strongSelf
                                   ->_completionHandlers) {
                            completionHandler(nil);
                          }
                        } else {
                          strongSelf->_initState = GADMAdapterChartboostUninitialized;
                          NSError *error = GADChartboostErrorWithDescription(
                              @"Failed to initialize Chartboost SDK.");
                          for (ChartboostInitCompletionHandler completionHandler in strongSelf
                                   ->_completionHandlers) {
                            completionHandler(error);
                          }
                        }
                        [strongSelf->_completionHandlers removeAllObjects];
                      }];
      break;
  }
}

@end
