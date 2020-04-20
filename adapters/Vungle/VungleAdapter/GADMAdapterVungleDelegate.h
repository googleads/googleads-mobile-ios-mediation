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

/// Vungle adapter ad type.
typedef NS_ENUM(NSUInteger, GADMAdapterVungleAdType) {
  GADMAdapterVungleAdTypeUnknown,            ///< Unknown adapter type.
  GADMAdapterVungleAdTypeRewarded,           ///< Rewarded adapter type.
  GADMAdapterVungleAdTypeInterstitial,       ///< Interstitial adapter type.
  GADMAdapterVungleAdTypeMREC,               ///< MREC adapter type.
  GADMAdapterVungleAdTypeBanner,             ///< Banner adapter type.
  GADMAdapterVungleAdTypeShortBanner,        ///< ShortBanner adapter type.
  GADMAdapterVungleAdTypeLeaderboardBanner   ///< LeaderboardBanner adapter type.
};

/// Vungle banner ad state.
typedef NS_ENUM(NSUInteger, BannerRouterDelegateState) {
  BannerRouterDelegateStateRequesting,
  BannerRouterDelegateStateCached,
  BannerRouterDelegateStateWillPlay,
  BannerRouterDelegateStatePlaying,
  BannerRouterDelegateStateClosing,
  BannerRouterDelegateStateClosed
};

@class GADMAdapterVungleBannerRequest;

/// Delegate for receiving state change messages from the Vungle SDK.
@protocol GADMAdapterVungleDelegate <NSObject>

/// Placement ID used to request an ad from Vungle.
@property(nonatomic, nonnull) NSString *desiredPlacement;

/// Vungle adapter ad type.
@property(nonatomic) GADMAdapterVungleAdType adapterAdType;

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error;
- (void)adAvailable;
- (void)adNotAvailable:(nonnull NSError *)error;
- (void)willShowAd;
- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;
- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload;

@optional
// Check is banner ad
- (BOOL)isBannerAd;

// Get banner request object
@property(nonatomic, nonnull) GADMAdapterVungleBannerRequest *bannerRequest;

// Vungle banner ad state.
@property(nonatomic, assign) BannerRouterDelegateState bannerState;

// Is a refreshed Banner request
@property(nonatomic, assign) BOOL isRefreshedForBannerAd;

// Is requesting a Banner ad for a refresh request
@property(nonatomic, assign) BOOL isRequestingBannerAdForRefresh;

@end
