// Copyright 2022 Google LLC
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
#import <VungleSDK/VungleSDK.h>
#import "GADMAdapterVungleDelegate.h"
#import "VungleAdNetworkExtras.h"

@interface GADMAdapterVungleBiddingRouter : NSObject <VungleSDKDelegate, VungleSDKHBDelegate>

+ (nonnull GADMAdapterVungleBiddingRouter *)sharedInstance;
- (void)initWithAppId:(nonnull NSString *)appId
             delegate:(nullable id<GADMAdapterVungleDelegate>)delegate;
- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error;
- (nullable NSError *)loadAdWithDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate;
- (void)removeDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate;
- (BOOL)isSDKInitialized;
- (nullable NSString *)getSuperToken;

@end
