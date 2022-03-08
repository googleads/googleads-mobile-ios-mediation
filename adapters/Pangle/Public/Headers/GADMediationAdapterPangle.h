// Copyright 2021 Google LLC
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

typedef NS_ENUM(NSInteger, GADPangleErrorCode) {
    /// Missing server parameters.
    GADPangleErrorInvalidServerParameters = 101,
    /// Banner size mismatch.
    GADPangleErrorBannerSizeMismatch = 102,
};

@interface GADMediationAdapterPangle : NSObject <GADRTBAdapter>

/// Set the COPPA of the user, COPPA is the short of Children's Online Privacy Protection Rule, the interface only works in the United States.
/// @param COPPA  0 adult, 1 child
+ (void)setCOPPA:(NSInteger)COPPA;

/// Custom set the GDPR of the user,GDPR is the short of General Data Protection Regulation,the interface only works in The European.
/// @param GDPR GDPR 0 close privacy protection, 1 open privacy protection
+ (void)setGDPR:(NSInteger)GDPR;

/// Custom set the CCPA of the user,CCPA is the short of General Data Protection Regulation,the interface only works in USA.
/// @params CCPA  0: "sale" of personal information is permitted, 1: user has opted out of "sale" of personal information -1: default
+ (void)setCCPA:(NSInteger)CCPA;

@end
