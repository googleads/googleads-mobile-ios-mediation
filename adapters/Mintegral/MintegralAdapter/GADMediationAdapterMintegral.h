// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

typedef NS_ENUM(NSInteger, GADMintegralErrorCode) {
  /// Missing server parameters.
  GADMintegralErrorInvalidServerParameters = 101,
  /// The ad request was successful, but no ad was returned.
  GADMintegralErrorAdNotAvailable = 102,
  /// The Mintegral SDK failed to show an ad.
  GADMintegralErrorAdFailedToShow = 103,
  /// Invalid banner size for Mintegral ad.
  GADMintegtalErrorBannerSizeInValid = 104
};
@interface GADMediationAdapterMintegral : NSObject <GADRTBAdapter>

@end
