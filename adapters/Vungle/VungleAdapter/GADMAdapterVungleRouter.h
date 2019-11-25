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
#import "VungleAdNetworkExtras.h"

/// Vungle adapter ad type.
typedef NS_ENUM(NSUInteger, GADMAdapterVungleAdType) {
  GADMAdapterVungleAdTypeUnknown,       ///< Unknown adapter type.
  GADMAdapterVungleAdTypeRewarded,      ///< Rewarded adapter type.
  GADMAdapterVungleAdTypeInterstitial,  ///< Interstitial adapter type.
  GADMAdapterVungleAdTypeBanner         ///< Banner adapter type.
};

typedef NS_ENUM(NSUInteger, BannerRouterDelegateState) {
  BannerRouterDelegateStateRequesting,
  BannerRouterDelegateStateCached,
  BannerRouterDelegateStatePlaying,
  BannerRouterDelegateStateClosing,
  BannerRouterDelegateStateClosed
};

@protocol VungleDelegate <NSObject>
- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error;
- (void)adAvailable;
- (void)adNotAvailable:(nonnull NSError *)error;
- (void)willShowAd;
- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
@property(nonatomic, strong, nullable) NSString *desiredPlacement;
@property(nonatomic, assign) GADMAdapterVungleAdType adapterAdType;
@optional
@property(nonatomic, assign) BannerRouterDelegateState bannerState;
@end

@interface GADMAdapterVungleRouter : NSObject <VungleSDKDelegate>

+ (nonnull GADMAdapterVungleRouter *)sharedInstance;
- (void)initWithAppId:(nonnull NSString *)appId delegate:(nullable id<VungleDelegate>)delegate;
- (BOOL)playAd:(nonnull UIViewController *)viewController
      delegate:(nonnull id<VungleDelegate>)delegate
        extras:(nullable VungleAdNetworkExtras *)extras;
- (nullable NSError *)loadAd:(nonnull NSString *)placement
                withDelegate:(nonnull id<VungleDelegate>)delegate;
- (void)removeDelegate:(nonnull id<VungleDelegate>)delegate;
- (BOOL)hasDelegateForPlacementID:(nonnull NSString *)placementID
                      adapterType:(GADMAdapterVungleAdType)adapterType;
- (nullable UIView *)renderBannerAdInView:(nonnull UIView *)bannerView
                                 delegate:(nonnull id<VungleDelegate>)delegate
                                   extras:(nullable VungleAdNetworkExtras *)extras
                           forPlacementID:(nonnull NSString *)placementID;
- (void)completeBannerAdViewForPlacementID:(nullable NSString *)placementID;
- (BOOL)canRequestBannerAdForPlacementID:(nonnull NSString *)placmentID;
@end
