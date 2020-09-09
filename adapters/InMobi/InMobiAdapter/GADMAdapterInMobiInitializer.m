// Copyright 2020 Google LLC.
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

#import "GADMAdapterInMobiInitializer.h"

#import <InMobiSDK/InMobiSDK.h>

#import "GADMAdapterInMobiUtils.h"
#import "GADMInMobiConsent.h"

@implementation GADMAdapterInMobiInitializer {
  /// Array to hold the InMobi SDK initialization delegates.
  NSMutableArray<GADMAdapterInMobiInitCompletionHandler> *_completionHandlers;
}

+ (nonnull GADMAdapterInMobiInitializer *)sharedInstance {
  static GADMAdapterInMobiInitializer *sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[GADMAdapterInMobiInitializer alloc] init];
  });
  return sharedInstance;
}

- (nonnull instancetype)init {
  if (self = [super init]) {
    _initializationState = GADMAdapterInMobiInitStateUninitialized;
    _completionHandlers = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)initializeWithAccountID:(nonnull NSString *)accountID
              completionHandler:(nonnull GADMAdapterInMobiInitCompletionHandler)completionHandler {
  if (_initializationState == GADMAdapterInMobiInitStateInitialized) {
    completionHandler(nil);
    return;
  }

  if (!accountID.length) {
    NSError *error = GADMAdapterInMobiErrorWithCodeAndDescription(
        GADMAdapterInMobiErrorInvalidServerParameters, @"Missing or Invalid Account ID.");
    completionHandler(error);
    return;
  }

  GADMAdapterInMobiMutableArrayAddObject(_completionHandlers, completionHandler);
  if (_initializationState == GADMAdapterInMobiInitStateInitializing) {
    return;
  }

  _initializationState = GADMAdapterInMobiInitStateInitializing;
  GADMAdapterInMobiInitializer *__weak weakSelf = self;
  [IMSdk initWithAccountID:accountID
         consentDictionary:GADMInMobiConsent.consent
      andCompletionHandler:^(NSError *_Nullable error) {
        GADMAdapterInMobiInitializer *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }

        if (error) {
          strongSelf->_initializationState = GADMAdapterInMobiInitStateUninitialized;
        } else {
          NSLog(@"[InMobi] Initialized successfully.");
          strongSelf->_initializationState = GADMAdapterInMobiInitStateInitialized;
        }

        for (GADMAdapterInMobiInitCompletionHandler completionHandler in strongSelf
                 ->_completionHandlers) {
          completionHandler(error);
        }
      }];
}

@end
