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
#import <VungleSDK/VungleSDK.h>
#import "GADMAdapterVungleDelegate.h"
#import "VungleAdNetworkExtras.h"

extern const CGSize kVNGBannerShortSize;

@interface GADMAdapterVungleRouter : NSObject <VungleSDKDelegate, VungleSDKHBDelegate>

+ (nonnull GADMAdapterVungleRouter *)sharedInstance;
- (void)initWithAppId:(nonnull NSString *)appId
             delegate:(nullable id<GADMAdapterVungleDelegate>)delegate;
- (BOOL)playAd:(nonnull UIViewController *)viewController
      delegate:(nonnull id<GADMAdapterVungleDelegate>)delegate
        extras:(nullable VungleAdNetworkExtras *)extras
         error:(NSError *_Nullable __autoreleasing *_Nullable)error;
- (nullable NSError *)loadAd:(nonnull NSString *)placement
                withDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate;
- (void)removeDelegate:(nonnull id<GADMAdapterVungleDelegate>)delegate;
- (BOOL)hasDelegateForPlacementID:(nonnull NSString *)placementID;
- (nullable NSError *)renderBannerAdInView:(nonnull UIView *)bannerView
                                  delegate:(nonnull id<GADMAdapterVungleDelegate>)delegate
                                    extras:(nullable VungleAdNetworkExtras *)extras
                            forPlacementID:(nonnull NSString *)placementID;
- (void)completeBannerAdViewForPlacementID:(nonnull id<GADMAdapterVungleDelegate>)delegate;
- (BOOL)isSDKInitialized;
- (nullable NSString *)getSuperToken;

@end
