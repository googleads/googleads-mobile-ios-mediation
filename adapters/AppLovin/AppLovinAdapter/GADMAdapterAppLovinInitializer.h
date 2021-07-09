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

#import <AppLovinSDK/AppLovinSDK.h>
#import <Foundation/Foundation.h>

/// AppLovin SDK initialization state.
typedef NS_ENUM(NSInteger, GADMAdapterAppLovinInitState) {
  GADMAdapterAppLovinInitStateUninitialized,  /// AppLovin SDK is not initialized.
  GADMAdapterAppLovinInitStateInitializing,   /// AppLovin SDK is initializing.
  GADMAdapterAppLovinInitStateInitialized     /// AppLovin SDK is initialized.
};

/// AppLovin adapter initialization completion handler.
typedef void (^GADMAdapterAppLovinInitCompletionHandler)(NSError *_Nullable error);

@interface GADMAdapterAppLovinInitializer : NSObject

/// The shared GADMAdapterAppLovinInitializer instance.
@property(class, atomic, readonly, nonnull) GADMAdapterAppLovinInitializer *sharedInstance;

/// Initializes the AppLovin SDK with the provided SDKKey.
- (void)initializeWithSDKKey:(nonnull NSString *)SDKKey
           completionHandler:(nonnull GADMAdapterAppLovinInitCompletionHandler)completionHandler;

@end
