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

typedef NS_ENUM(NSInteger, GADMAdapterMyTargetErrorCode) {
  /// MyTarget SDK does not yet have an ad available.
  GADMAdapterMyTargetErrorNoFill = 100,
  /// Missing server parameters.
  GADMAdapterMyTargetErrorInvalidServerParameters = 101,
  /// Unsupported ad format.
  GADMAdapterMyTargetErrorUnsupportedAdFormat = 102,
  /// Tried to show a myTarget ad that is not loaded.
  GADMAdapterMyTargetErrorAdNotLoaded = 103,
  /// Banner Size Mismatch.
  GADMAdapterMyTargetErrorBannerSizeMismatch = 104,
  /// Missing required native ad assets.
  GADMAdapterMyTargetErrorMissingNativeAssets = 105
};

@interface GADMediationAdapterMyTarget : NSObject <GADMediationAdapter>

@end
