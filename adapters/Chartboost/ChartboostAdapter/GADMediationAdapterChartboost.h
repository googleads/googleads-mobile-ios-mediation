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

typedef NS_ENUM(NSInteger, GADMAdapterChartboostErrorCode) {
  /// Missing server parameters.
  GADMAdapterChartboostErrorInvalidServerParameters = 101,
  /// The Chartboost SDK returned an initialization error.
  GADMAdapterChartboostErrorInitializationFailure = 102,
  /// The Chartboost  Ad is not cached at show time.
  GADMAdapterChartboostErrorAdNotCached = 103,
  /// Banner Size Mismatch.
  GADMAdapterChartboostErrorBannerSizeMismatch = 104,
  /// Device's OS version is lower than Chartboost SDK's minimum supported OS version.
  GADMAdapterChartboostErrorMinimumOSVersion = 105
};

@interface GADMediationAdapterChartboost : NSObject <GADMediationAdapter>

@end
