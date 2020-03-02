// Copyright 2019 Google LLC.
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

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <UnityAds/UnityAds.h>

@interface GADMAdapterUnityBannerAd : NSObject

/// Initializes a new instance with |connector| and |adapter|.
- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter
NS_DESIGNATED_INITIALIZER;

/// Init unavailable.
- (nonnull instancetype)init NS_UNAVAILABLE;

/// Loads a banner ad for a given adSize.
- (void)loadBannerWithSize:(GADAdSize)adSize;

/// Stops the receiver from delegating any notifications from Unity Ads.
- (void)stopBeingDelegate;

@end
