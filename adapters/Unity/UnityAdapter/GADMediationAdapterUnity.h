// Copyright 2020 Google LLC.
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

typedef NS_ENUM(NSInteger, GADMAdapterUnityErrorCode) {
  /// Invalid server parameters.
  GADMAdapterUnityErrorInvalidServerParameters = 101,
  /// Device not supported by UnityAds.
  GADMAdapterUnityErrorDeviceNotSupported = 102,
  /// UnityAds finished presenting with error state kUnityAdsFinishStateError.
  GADMAdapterUnityErrorFinish = 103,
  /// The Unity ad object is nil after calling its initializer.
  GADMAdapterUnityErrorAdObjectNil = 104,
  /// Failed to show Unity Ads due to ad not ready.
  GADMAdapterUnityErrorShowAdNotReady = 105,
  /// UnityAds called a placement changed callback with placement state
  /// kUnityAdsPlacementStateNoFill.
  GADMAdapterUnityErrorPlacementStateNoFill = 106,
  /// UnityAds called a placement changed callback with placement state
  /// kUnityAdsPlacementStateDisabled.
  GADMAdapterUnityErrorPlacementStateDisabled = 107,
  /// An ad was already loaded for this placement. UnityAds SDK does not support loading multiple
  /// ads for the same placement.
  GADMAdapterUnityErrorAdAlreadyLoaded = 108,
  /// Banner size mismatch.
  GADMAdapterUnityErrorSizeMismatch = 109,
  /// UnityAds returned an initialization error
  GADMAdapterUnityErrorAdInitializationFailure = 110
};

@interface GADMediationAdapterUnity : NSObject <GADMediationAdapter>

@end
