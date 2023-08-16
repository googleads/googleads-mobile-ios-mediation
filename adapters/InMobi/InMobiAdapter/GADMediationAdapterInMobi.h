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

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <InMobiSDK/InMobiSDK-Swift.h>

typedef NS_ENUM(NSInteger, GADMAdapterInMobiErrorCode) {
  /// Missing server parameters.
  GADMAdapterInMobiErrorInvalidServerParameters = 101,
  /// Invalid banner size for InMobi ad.
  GADMAdapterInMobiErrorBannerSizeMismatch = 102,
  /// An InMobi ad is already loaded for this network configuration.
  GADMAdapterInMobiErrorAdAlreadyLoaded = 103,
  /// InMobi native ad returned with missing native assets, or required image assets failed to
  /// download.
  GADMAdapterInMobiErrorMissingNativeAssets = 104,
  /// An InMobi ad is not ready to be shown.
  GADMAdapterInMobiErrorAdNotReady = 105,
  /// An empty or nil bid token is returned by InMobi.
  GADMAdapterInMobiErrorInvalidBidToken = 106
};

@interface GADMediationAdapterInMobi : NSObject <GADRTBAdapter>

@end
