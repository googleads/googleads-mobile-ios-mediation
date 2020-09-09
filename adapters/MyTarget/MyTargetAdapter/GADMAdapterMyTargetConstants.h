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

/// myTarget mediation network adapter version.
static NSString *const _Nonnull kGADMAdapterMyTargetVersion = @"5.7.5.0";

/// myTarget mediation network adapter slot ID server parameter key.
static NSString *const _Nonnull kGADMAdapterMyTargetSlotIdKey = @"slotId";

/// Error domain for myTarget adapter specific errors.
static NSString *const _Nonnull kGADMAdapterMyTargetAdapterErrorDomain =
    @"com.google.mediation.mytarget";

/// Error domain for myTarget SDK specific errors.
static NSString *const _Nonnull kGADMAdapterMyTargetSDKErrorDomain =
    @"com.google.mediation.mytargetSDK";

/// Error message for missing myTarget slot ID.
static NSString *const _Nonnull kGADMAdapterMyTargetErrorSlotId =
    @"Invalid credentials: slotId not found";

/// Error message for myTarget no fills.
static NSString *const _Nonnull kGADMAdapterMyTargetErrorNoAd = @"No ad";

/// Error message for missing required native ad assets.
static NSString *const _Nonnull kGADMAdapterMyTargetErrorMediatedAdInvalid =
    @"Some of the Always Included assets are not available for the ad";

/// Error message for requesting a banner ad format through the incorrect adapter class.
static NSString *const _Nonnull kGADMAdapterMyTargetErrorBannersNotSupported =
    @"Banners are not supported by this adapter";

/// Error message for requesting an interstitial ad format through the incorrect adapter class.
static NSString *const _Nonnull kGADMAdapterMyTargetErrorInterstitialNotSupported =
    @"Interstitial ads are not supported by this adapter";

/// Error message for requesting a banner ad with an unsupported ad size.
static NSString *const _Nonnull kGADMAdapterMyTargetErrorInvalidSize = @"Size not supported";
