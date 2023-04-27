// Copyright 2019 Google LLC
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
#import <VungleAdsSDK/VungleAdsSDK.h>
#import "GADMediationAdapterVungle.h"
#import "VungleAdNetworkExtras.h"

/// Returns a NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorCode code,
                                                               NSString *_Nonnull description);

/// Returns a NSError converted from the error object from Liftoff Monetize SDK into the AdMob error
/// format The localized description will contain the Liftoff Monetize error code and the
/// description from the Vungle SDK.
NSError *_Nonnull GADMAdapterVungleErrorToGADError(GADMAdapterVungleErrorCode code,
                                                   NSInteger vungleCode,
                                                   NSString *_Nonnull description);

/// Returns a NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|, specifically for invalid placement
/// id.
NSError *_Nonnull GADMAdapterVungleInvalidPlacementErrorWithCodeAndDescription(void);

/// Returns a NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|, specifically for invalid app id.
NSError *_Nonnull GADMAdapterVungleInvalidAppIdErrorWithCodeAndDescription(void);

/// Returns a GADAdSize object that is valid for the Liftoff Monetize SDK
GADAdSize GADMAdapterVungleAdSizeForAdSize(GADAdSize adSize);

/// Returns a Liftoff Monetize BannerSize from the provided GADAdSize
BannerSize GADMAdapterVungleConvertGADAdSizeToBannerSize(GADAdSize adSize);

@interface GADMAdapterVungleUtils : NSObject

+ (nullable NSString *)findAppID:(nullable NSDictionary *)serverParameters;
+ (nullable NSString *)findPlacement:(nullable NSDictionary *)serverParameters
                       networkExtras:(nullable VungleAdNetworkExtras *)networkExtras;

@end
