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

typedef NS_ENUM(NSInteger, GADMAdapterFyberErrorCode) {
  /// Missing server parameters.
  GADMAdapterFyberErrorInvalidServerParameters = 101,
  /// Banner Size Mismatch.
  GADMAdapterFyberErrorBannerSizeMismatch = 102,
  /// Failed to show ad because ad object has already been used.
  GADMAdapterFyberErrorAdAlreadyUsed = 103,
  /// Failed to show DT Exchange ads due to ad not been ready.
  GADMAdapterFyberErrorAdNotReady = 104,
  /// The DT Exchange SDK returned an initialization error.
  GADMAdapterFyberErrorInitializationFailure = 105,
  /// The DT Exchange SDK failed to show an ad because the ad has expired.
  GADMAdapterFyberErrorPresentationFailureForAdExpiration = 106
};

/// Mediation network adapter for DT Exchange.
@interface GADMediationAdapterFyber : NSObject <GADRTBAdapter>

@end
