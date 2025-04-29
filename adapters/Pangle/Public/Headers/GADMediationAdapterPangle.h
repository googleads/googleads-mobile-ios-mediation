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
  /// User is a child.
  ///
  /// Do not call Pangle SDK if the user is a child. Adapter will respond with this error code
  /// if adapter is requested to initialize, load ad or collect signals when user is a child.
  ///
  /// Starting with Pangle SDK V71, Pangle no longer supports child user flags and you may
  /// not initialize or use the Pangle SDK in connection with a "child" as defined under
  /// applicable laws.
  GADPangleErrorChildUser = 104,
};

@interface GADMediationAdapterPangle : NSObject <GADRTBAdapter>

/// Set the GDPR setting in Pangle SDK.
///
/// @param GDPRConsent An integer value that indicates whether the user consents the use of personal
/// data to serve ads under GDPR. See <a
/// href="https://www.pangleglobal.com/integration/ios-initialize-pangle-sdk">
/// Pangle's documentation</a> for more information about what values may be provided.
+ (void)setGDPRConsent:(NSInteger)GDPRConsent;

/// Set whether the user consents to be served Personalized Ads.
+ (void)setPAConsent:(NSInteger)PAConsent;

@end
