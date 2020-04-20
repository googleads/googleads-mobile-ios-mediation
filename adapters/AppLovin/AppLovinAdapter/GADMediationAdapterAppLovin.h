// Copyright 2018 Google Inc.
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
#import <GoogleMobileAds/GoogleMobileAds.h>

#import "GADMediationAdapterAppLovin.h"

typedef NS_ENUM(NSInteger, GADMAdapterAppLovinErrorCode) {
  /// Banner Size Mismatch.
  GADMAdapterAppLovinErrorBannerSizeMismatch = 101,
  /// Invalid server parameters.
  GADMAdapterAppLovinErrorInvalidServerParameters = 102,
  /// Failed to show ad.
  GADMAdapterAppLovinErrorShow = 103,
  /// An ad is already loaded for this network configuration.
  GADMAdapterAppLovinErrorAdAlreadyLoaded = 104,
  /// SDK key not found.
  GADMAdapterAppLovinErrorMissingSDKKey = 105,
  /// There was an error loading data from the network.
  GADMAdapterAppLovinErrorLoadingImages = 106,
  /// Bid token is empty.
  GADMAdapterAppLovinErrorEmptyBidToken = 107,
  /// Unsupported ad format.
  GADMAdapterAppLovinErrorUnsupportedAdFormat = 108,
  /// AppLovin native ad is missing required assets.
  GADMAdapterAppLovinErrorMissingNativeAssets = 109,
  /// AppLovin sent a successful load callback but loaded zero ads.
  GADMAdapterAppLovinErrorZeroAdsLoaded = 110
};

@interface GADMediationAdapterAppLovin : NSObject <GADRTBAdapter>

@end
