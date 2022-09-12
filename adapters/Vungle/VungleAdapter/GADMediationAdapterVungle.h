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
@import GoogleMobileAds;

typedef NS_ENUM(NSInteger, GADMAdapterVungleErrorCode) {
  /// Missing server parameters.
  GADMAdapterVungleErrorInvalidServerParameters = 101,
  /// An ad is already loaded for this network configuration. Vungle SDK cannot load a second ad for
  /// the same placement ID.
  GADMAdapterVungleErrorAdAlreadyLoaded = 102,
  /// Banner Size Mismatch.
  GADMAdapterVungleErrorBannerSizeMismatch = 103,
  /// Vungle SDK could not render the banner ad.
  GADMAdapterVungleErrorRenderBannerAd = 104,
  /// Vungle SDK only supports loading 1 banner ad at a time, regardless of placement ID.
  GADMAdapterVungleErrorMultipleBanners = 105,
  /// Vungle SDK sent a callback saying the ad is not playable.
  GADMAdapterVungleErrorAdNotPlayable = 106
};

@interface GADMediationAdapterVungle : NSObject <GADRTBAdapter>

@end
