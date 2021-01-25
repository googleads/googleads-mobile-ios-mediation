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
#import <ImobileSdkAds/ImobileSdkAds.h>

typedef NS_ENUM(NSInteger, GADMAdapterIMobileErrorCode) {
  /// Missing or invalid server parameters.
  GADMAdapterIMobileErrorInvalidServerParameters = 101,
  /// Unsupported ad size requested.
  GADMAdapterIMobileErrorBannerSizeMismatch = 102,
  /// i-mobile failed to present an ad.
  GADMAdapterIMobileErrorAdNotPresented = 103,
  /// i-mobile returned an empty native ad array.
  GADMAdapterIMobileErrorEmptyNativeAdArray = 104,
  /// i-mobile failed to download native ad assets.
  GADMAdapterIMobileErrorNativeAssetsDownloadFailed = 105,
  /// i-mobile does not support requesting for multiple interstitial ads using the same Spot ID.
  GADMAdapterIMobileErrorAdAlreadyLoaded = 106
};

@interface GADMediationAdapterIMobile : NSObject

@end
