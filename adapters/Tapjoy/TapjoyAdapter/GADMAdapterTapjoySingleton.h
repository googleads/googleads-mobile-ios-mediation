// Copyright 2019 Google LLC
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
#import <Tapjoy/Tapjoy.h>

/// Initialization state of the Tapjoy SDK.
typedef NS_ENUM(NSUInteger, GADMAdapterTapjoyInitState) {
  GADMAdapterTapjoyInitStateUninitialized,  /// < Tapjoy SDK is not initialized yet.
  GADMAdapterTapjoyInitStateInitializing,   /// < Tapjoy SDK is initializing.
  GADMAdapterTapjoyInitStateInitialized     /// < Tapjoy SDK has been initialzed.
};

typedef void (^TapjoyInitCompletionHandler)(NSError *_Nullable error);

@interface GADMAdapterTapjoySingleton : NSObject <TJPlacementDelegate, TJPlacementVideoDelegate>

+ (nonnull instancetype)sharedInstance;
- (void)initializeTapjoySDKWithSDKKey:(nonnull NSString *)sdkKey
                              options:(nullable NSDictionary<NSString *, NSNumber *> *)options
                    completionHandler:(nullable TapjoyInitCompletionHandler)completionHandler;
- (nullable TJPlacement *)
    requestAdForPlacementName:(nonnull NSString *)placementName
                     delegate:(nonnull id<TJPlacementDelegate, TJPlacementVideoDelegate>)delegate;
- (nullable TJPlacement *)
    requestAdForPlacementName:(nonnull NSString *)placementName
                  bidResponse:(nullable NSString *)bidResponse
                     delegate:(nonnull id<TJPlacementDelegate, TJPlacementVideoDelegate>)delegate;

@end
