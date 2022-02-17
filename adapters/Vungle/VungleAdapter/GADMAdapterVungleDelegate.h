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

#import <GoogleMobileAds/GoogleMobileAds.h>

/// Vungle banner ad state.
typedef NS_ENUM(NSUInteger, BannerRouterDelegateState) {
  BannerRouterDelegateStateRequesting,
  BannerRouterDelegateStateWillPlay,
  BannerRouterDelegateStatePlaying,
  BannerRouterDelegateStateClosing,
  BannerRouterDelegateStateClosed
};

/// Delegate for receiving state change messages from the Vungle SDK.
@protocol GADMAdapterVungleDelegate <NSObject>

/// Placement ID used to request an ad from Vungle.
@property(nonatomic, copy, nonnull) NSString *desiredPlacement;

/// Indicates whether the ad has been loaded successfully.
@property(nonatomic) BOOL isAdLoaded;

/// Bid Response when the ad is instantiated. May be null if bidding is not enabled.
- (nullable NSString *)bidResponse;

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error;
- (void)adAvailable;
- (void)adNotAvailable:(nonnull NSError *)error;
- (void)willShowAd;
- (void)didViewAd;
- (void)willCloseAd;
- (void)didCloseAd;
- (void)trackClick;
- (void)rewardUser;
- (void)willLeaveApplication;

@optional

// A unique identifier representing the ad request used to load an ad.
@property(nonatomic, copy, nullable) NSString *uniquePubRequestID;

// Vungle banner ad state.
@property(nonatomic, assign) BannerRouterDelegateState bannerState;

// Is a refreshed Banner request
@property(nonatomic, assign) BOOL isRefreshedForBannerAd;

// Is requesting a Banner ad for a refresh request
@property(nonatomic, assign) BOOL isRequestingBannerAdForRefresh;

// Requested banner ad size.
- (GADAdSize)bannerAdSize;

@end
