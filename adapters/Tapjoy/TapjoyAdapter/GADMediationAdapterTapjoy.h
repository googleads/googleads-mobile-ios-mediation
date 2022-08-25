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

typedef NS_ENUM(NSInteger, GADMAdapterTapjoyErrorCode) {
  /// Missing server parameters.
  GADMAdapterTapjoyErrorInvalidServerParameters = 101,
  /// Tapjoy SDK failed to initialize.
  GADMAdapterTapjoyErrorInitializationFailure = 102,
  /// The Tapjoy adapter does not support the ad format being requested.
  GADMAdapterTapjoyErrorAdFormatNotSupported = 103,
  /// Tapjoy sent a successful load callback but no content was available.
  GADMAdapterTapjoyErrorPlacementContentNotAvailable = 104,
  /// An ad is already loaded for this network configuration.
  GADMAdapterTapjoyErrorAdAlreadyLoaded = 105,
  /// Tapjoy SDK placement video related error.
  GADMAdapterTapjoyErrorPlacementVideo = 106,
  /// Tapjoy SDK placement unknown error.
  GADMAdapterTapjoyErrorUnknown = 107
};

@interface GADMediationAdapterTapjoy : NSObject <GADRTBAdapter>

@end
