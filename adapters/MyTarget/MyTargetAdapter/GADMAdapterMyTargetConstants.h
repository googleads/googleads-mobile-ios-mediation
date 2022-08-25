// Copyright 2017 Google LLC
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
#import <CoreGraphics/CGBase.h>

/// myTarget mediation network adapter version.
extern NSString *const _Nonnull GADMAdapterMyTargetVersion;

/// myTarget mediation network adapter slot ID server parameter key.
extern NSString *const _Nonnull GADMAdapterMyTargetSlotIdKey;

/// Error domain for myTarget adapter specific errors.
extern NSString *const _Nonnull GADMAdapterMyTargetAdapterErrorDomain;

/// Error domain for myTarget SDK specific errors.
extern NSString *const _Nonnull GADMAdapterMyTargetSDKErrorDomain;

/// Error message for missing myTarget slot ID.
extern NSString *const _Nonnull GADMAdapterMyTargetErrorSlotId;

/// Error message for myTarget no fills.
extern NSString *const _Nonnull GADMAdapterMyTargetErrorNoAd;

/// Error message for missing required native ad assets.
extern NSString *const _Nonnull GADMAdapterMyTargetErrorMediatedAdInvalid;

/// Error message for requesting a banner ad format through the incorrect adapter class.
extern NSString *const _Nonnull GADMAdapterMyTargetErrorBannersNotSupported;

/// Error message for requesting an interstitial ad format through the incorrect adapter class.
extern NSString *const _Nonnull GADMAdapterMyTargetErrorInterstitialNotSupported;

/// Error message for requesting a banner ad with an unsupported ad size.
extern NSString *const _Nonnull GADMAdapterMyTargetErrorInvalidSize;

/// Mininum supported height of myTarget banner.
extern CGFloat const GADMAdapterMyTargetBannerHeightMin;

/// Mininum supported aspect ratio of myTarget banner.
extern CGFloat const GADMAdapterMyTargetBannerAspectRatioMin;
