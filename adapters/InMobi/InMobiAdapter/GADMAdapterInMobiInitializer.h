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

#import <Foundation/Foundation.h>

/// Initialization state of the InMobi SDK.
typedef NS_ENUM(NSUInteger, GADMAdapterInMobiInitState) {
  GADMAdapterInMobiInitStateUninitialized,  /// < InMobi SDK is not initialized yet.
  GADMAdapterInMobiInitStateInitializing,   /// < InMobi SDK is initializing.
  GADMAdapterInMobiInitStateInitialized     /// < InMobi SDK has been initialzed.
};

typedef void (^GADMAdapterInMobiInitCompletionHandler)(NSError *_Nullable error);

@interface GADMAdapterInMobiInitializer : NSObject

/// The shared GADMAdapterInMobiInitializer instance.
@property(class, atomic, readonly, nonnull) GADMAdapterInMobiInitializer *sharedInstance;

/// Indicates the current initialization state of the InMobi SDK.
@property(nonatomic, assign, readonly) GADMAdapterInMobiInitState initializationState;

/// Initialize the InMobi SDK with the specified |accountID|. Invokes |completionHandler| when
/// initialization completes.
- (void)initializeWithAccountID:(nonnull NSString *)accountID
              completionHandler:(nonnull GADMAdapterInMobiInitCompletionHandler)completionHandler;

@end
