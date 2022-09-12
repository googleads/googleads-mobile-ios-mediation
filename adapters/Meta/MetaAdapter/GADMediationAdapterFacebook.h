// Copyright 2018 Google Inc.
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

typedef NS_ENUM(NSInteger, GADFBErrorCode) {
  /// Missing server parameters.
  GADFBErrorInvalidRequest = 101,
  /// Banner Size Mismatch.
  GADFBErrorBannerSizeMismatch = 102,
  /// The Meta Audience Network ad object is nil after calling its initializer.
  GADFBErrorAdObjectNil = 103,
  /// The Meta Audience Network SDK returned NO from its showAd call.
  GADFBErrorAdNotValid = 104,
  /// Root view controller is nil.
  GADFBErrorRootViewControllerNil = 105,
  /// The Meta Audience Network SDK returned an initialization error.
  GADFBErrorInitializationFailure = 106
};

@interface GADMediationAdapterFacebook : NSObject <GADRTBAdapter>

+ (NSString *)getPlacementIDFromCredentials:(GADMediationCredentials *)credentials;

@end
