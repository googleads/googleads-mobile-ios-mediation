// Copyright 2021 Google LLC
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

#import "GADMAdapterAppLovinInitializer.h"

#import "GADMAdapterAppLovinUtils.h"
#import "GADMediationAdapterAppLovin.h"

@implementation GADMAdapterAppLovinInitializer {
  /// AppLovin SDK initialization states.
  NSMutableDictionary<NSString *, NSNumber *> *_initState;

  /// AppLovin SDK completion handlers.
  NSMutableDictionary<NSString *, NSMutableArray<GADMAdapterAppLovinInitCompletionHandler> *>
      *_completionHandlers;
}

+ (nonnull GADMAdapterAppLovinInitializer *)sharedInstance {
  static dispatch_once_t onceToken;
  static GADMAdapterAppLovinInitializer *instance;
  dispatch_once(&onceToken, ^{
    instance = [[GADMAdapterAppLovinInitializer alloc] init];
  });
  return instance;
}

- (nonnull instancetype)init {
  self = [super init];
  if (self) {
    _initState = [[NSMutableDictionary alloc] init];
    _completionHandlers = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)initializeWithSDKKey:(nonnull NSString *)SDKKey
           completionHandler:(nonnull GADMAdapterAppLovinInitCompletionHandler)completionHandler {
  // Initial values.
  if (!_initState[SDKKey]) {
    GADMAdapterAppLovinMutableDictionarySetObjectForKey(
        _initState, SDKKey, @(GADMAdapterAppLovinInitStateUninitialized));
    GADMAdapterAppLovinMutableDictionarySetObjectForKey(_completionHandlers, SDKKey,
                                                        [[NSMutableArray alloc] init]);
  }

  GADMAdapterAppLovinInitState initState = _initState[SDKKey].intValue;
  switch (initState) {
    case GADMAdapterAppLovinInitStateInitialized:
      completionHandler(nil);
      return;
    case GADMAdapterAppLovinInitStateInitializing:
      GADMAdapterAppLovinMutableArrayAddObject(_completionHandlers[SDKKey], completionHandler);
      return;
    case GADMAdapterAppLovinInitStateUninitialized:
    default:
      GADMAdapterAppLovinMutableArrayAddObject(_completionHandlers[SDKKey], completionHandler);
      break;
  }

  ALSdk *SDK = [GADMAdapterAppLovinUtils retrieveSDKFromSDKKey:SDKKey];
  if (!SDK) {
    NSError *error = GADMAdapterAppLovinNilSDKError(SDKKey);
    completionHandler(error);
    return;
  }

  GADMAdapterAppLovinInitializer *__weak weakSelf = self;
  [SDK initializeSdkWithCompletionHandler:^(ALSdkConfiguration *configuration) {
    GADMAdapterAppLovinInitializer *strongSelf = weakSelf;
    if (!strongSelf) {
      [GADMAdapterAppLovinUtils log:@"Could not invoke AppLovin SDK's completion handler."];
      return;
    }

    // AppLovin currently has no method to check if initialization returned a failure.
    // Assume it is always a success.
    GADMAdapterAppLovinMutableDictionarySetObjectForKey(strongSelf->_initState, SDKKey,
                                                        @(GADMAdapterAppLovinInitStateInitialized));

    for (GADMAdapterAppLovinInitCompletionHandler handler in strongSelf
             ->_completionHandlers[SDKKey]) {
      handler(nil);
    }
    [strongSelf->_completionHandlers[SDKKey] removeAllObjects];
  }];
}

@end
