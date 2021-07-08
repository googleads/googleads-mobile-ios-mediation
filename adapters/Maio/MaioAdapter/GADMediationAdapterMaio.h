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

typedef NS_ENUM(NSInteger, GADMAdapterMaioErrorCode) {
  /// maio does not yet have an ad available.
  GADMAdapterMaioErrorAdNotAvailable = 101,
  /// Missing server parameters.
  GADMAdapterMaioErrorInvalidServerParameters = 102,
  /// The maio adapter does not support the ad format being requested.
  GADMAdapterMaioErrorAdFormatNotSupported = 103,
  /// An ad is already loaded for this network configuration.
  GADMAdapterMaioErrorAdAlreadyLoaded = 104
};

@interface GADMediationAdapterMaio : NSObject <GADRTBAdapter>

@end
