// Copyright 2019 Google Inc.
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

typedef NS_ENUM(NSInteger, GADMAdapterNendErrorCode) {
  /// nend SDK returned a load failure callback.
  GADMAdapterNendErrorLoadFailureCallback = 101,
  /// nend SDK returned a show failure callback.
  GADMAdapterNendErrorShowFailureCallback = 102,
  /// Missing server parameters.
  GADMAdapterNendInvalidServerParameters = 103,
  /// There was an error loading data from the network.
  GADMAdapterNendErrorLoadingImages = 104,
  /// Failed to show nend ads due to ad not ready.
  GADMAdapterNendErrorShowAdNotReady = 105,
  /// The requested ad size does not match a Nend supported banner size.
  GADMAdapterNendErrorBannerSizeMismatch = 106
};

@interface GADMediationAdapterNend : NSObject <GADMediationAdapter>

@end
