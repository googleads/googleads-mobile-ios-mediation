// Copyright 2018 Google LLC
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
  /// Bid token is empty.
  GADMAdapterAppLovinErrorEmptyBidToken = 107,
  /// Unsupported ad format.
  GADMAdapterAppLovinErrorUnsupportedAdFormat = 108,
  // Error codes 109 and 110 were previous removed.
  /// Unable to retrieve instance of the AppLovin SDK.
  GADMAdapterAppLovinErrorNilAppLovinSDK = 111
};

@interface GADMediationAdapterAppLovin : NSObject <GADRTBAdapter>

@property(class, nonatomic, strong, readonly) ALSdkSettings *SDKSettings;

@end
