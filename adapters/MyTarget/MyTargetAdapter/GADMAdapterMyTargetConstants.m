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

#import "GADMAdapterMyTargetConstants.h"

NSString *const _Nonnull GADMAdapterMyTargetVersion = @"5.15.2.0";

NSString *const _Nonnull GADMAdapterMyTargetSlotIdKey = @"slotId";

NSString *const _Nonnull GADMAdapterMyTargetAdapterErrorDomain =
    @"com.google.mediation.mytarget";

NSString *const _Nonnull GADMAdapterMyTargetSDKErrorDomain =
    @"com.google.mediation.mytargetSDK";

NSString *const _Nonnull GADMAdapterMyTargetErrorSlotId =
    @"Invalid credentials: slotId not found";

NSString *const _Nonnull GADMAdapterMyTargetErrorNoAd = @"No ad";

NSString *const _Nonnull GADMAdapterMyTargetErrorMediatedAdInvalid =
    @"Some of the Always Included assets are not available for the ad";

NSString *const _Nonnull GADMAdapterMyTargetErrorBannersNotSupported =
    @"Banners are not supported by this adapter";

NSString *const _Nonnull GADMAdapterMyTargetErrorInterstitialNotSupported =
    @"Interstitial ads are not supported by this adapter";

NSString *const _Nonnull GADMAdapterMyTargetErrorInvalidSize = @"Size not supported";

CGFloat const GADMAdapterMyTargetBannerHeightMin = 50.0;

CGFloat const GADMAdapterMyTargetBannerAspectRatioMin = 0.75;
