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
  // Error codes 109, 110, and 111 were previous removed.

  /// User is a child.
  ///
  /// Do not call AppLovin SDK if the user is a child. Adapter will respond with this error code
  /// if adapter is requested to initialize, load ad or collect signals when user is a child.
  ///
  /// Starting with AppLovin SDK 13.0.0, AppLovin no longer supports child user flags and you may
  /// not initialize or use the AppLovin SDK in connection with a "child" as defined under
  /// applicable laws. For more information, see AppLovin's documentation on <a
  /// href="https://developers.applovin.com/en/max/android/overview/privacy/#children">Prohibition
  /// on Children's Data or Using the Services for Children or Apps Exclusively Targeted to
  /// Children</a>.
  GADMAdapterAppLovinErrorChildUser = 112,

  /// AppLovin SDK shared instance hasn't been initialized.
  GADMAdapterAppLovinErrorAppLovinSDKNotInitialized = 113,

  /// AppLovin SDK fails to return bid token with an error message.
  GADMAdapterAppLovinErrorFailedToReturnBidToken = 114
};

@interface GADMediationAdapterAppLovin : NSObject <GADRTBAdapter>

@end
