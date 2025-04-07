// Copyright 2023 Google LLC.
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

typedef NS_ENUM(NSInteger, GADMediationAdapterLineErrorCode) {
  /// Missing server parameters.
  GADMediationAdapterLineErrorInvalidServerParameters = 101,
  /// Loaded banner ad size does not match with the requested banner ad size.
  GADMediationAdapterLineErrorLoadedBannerSizeMismatch = 102,
  /// Failed to load an information icon image asset.
  GADMediationAdapterLineErrorInformationIconLoadFailure = 103,
  /// Failed to collect signals for bidding.
  GADMediationAdapterLineErrorFailedToCollectSignals = 104,
  /// Failed to initialize a FADAdLoader.
  GADMediationAdapterLineErrorFailedToInitializeAdLoader = 105,
};

@interface GADMediationAdapterLine : NSObject <GADRTBAdapter>

/// Indicates whether LINE SDK should be initialized in test mode.
/// Must be set prior to initializing the Google Mobile Ads SDK.
///
/// Make sure to set this to false before publishing your app.
@property(class, nonatomic, assign) BOOL testMode;

@end
