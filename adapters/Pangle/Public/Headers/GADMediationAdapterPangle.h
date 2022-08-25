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

typedef NS_ENUM(NSInteger, GADPangleErrorCode) {
    /// Missing server parameters.
    GADPangleErrorInvalidServerParameters = 101,
    /// Banner size mismatch.
    GADPangleErrorBannerSizeMismatch = 102,
};

@interface GADMediationAdapterPangle : NSObject <GADRTBAdapter>

/// Set the GDPR setting in Pangle SDK.
///
/// @param GDPR An integer value that indicates whether the user consents the use of personal
/// data to serve ads under GDPR.  0 means the user consents. 1 means the user does not consent.
/// -1 means the user hasn't specified. Any value outside of -1, 0, or 1 will result in this method
/// being a no-op.
+ (void)setGDPR:(NSInteger)GDPR;

/// Set the CCPA setting in Pangle SDK.
///
/// @param CCPA An integer value that indicates whether the user opts in of the "sale" of the
/// "personal information" under CCPA. 0 means the user opts in. 1 means the user opts out. -1 means
/// the user hasn't specified. Any value outside of -1, 0, or 1 will result in this method
/// being a no-op.
+ (void)setCCPA:(NSInteger)CCPA;

@end
