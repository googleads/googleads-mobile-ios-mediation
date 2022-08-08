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
#import "GADMAdapterVungleDelegate.h"

extern const CGSize kVNGBannerShortSize;

@interface GADMAdapterVungleRouter : NSObject

+ (nonnull GADMAdapterVungleRouter *)sharedInstance;

/// Initializes the Vungle SDK then makes the load call to the delegate if provided
- (void)initWithAppId:(nonnull NSString *)appId
             delegate:(nullable id<GADMAdapterVungleDelegate>)delegate;

/// Queries the Vungle SDK to check if it has been initialized
- (BOOL)isSDKInitialized;

/// Queries the Vungle SDK for the signals aka Vungle bidding token
- (nullable NSString *)getSuperToken;

@end
