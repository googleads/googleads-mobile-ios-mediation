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
/// @param GDPRConsent An integer value that indicates whether the user consents the use of personal
/// data to serve ads under GDPR. See <a
/// href="https://www.pangleglobal.com/integration/ios-initialize-pangle-sdk">
/// Pangle's documentation</a> for more information about what values may be provided.
+ (void)setGDPRConsent:(NSInteger)GDPRConsent;

/// Set the CCPA setting in Pangle SDK.
///
/// @param doNotSell  An integer value that indicates whether the user opts in of the "sale" of the
/// "personal information" under CCPA. See <a
/// href="https://www.pangleglobal.com/integration/ios-initialize-pangle-sdk">
/// Pangle's documentation</a> for more information about what values may be provided.
+ (void)setDoNotSell:(NSInteger)doNotSell;

@end
