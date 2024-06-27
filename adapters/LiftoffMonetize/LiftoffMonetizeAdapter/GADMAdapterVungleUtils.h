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

/// Returns a GADAdSize object that is valid for Vungle SDK.
GADAdSize GADMAdapterVungleAdSizeForAdSize(GADAdSize adSize, NSString *_Nonnull placementId);

/// Returns a Liftoff Monetize VungleAdSize from the provided GADAdSize.
VungleAdSize *_Nonnull GADMAdapterVungleConvertGADAdSizeToBannerSize(GADAdSize adSize);

/// Returns a Liftoff Monetize VungleAdSize from the provided GADAdSize.
VungleAdSize *_Nonnull GADMAdapterVungleConvertGADAdSizeToVungleAdSize(GADAdSize adSize, NSString *_Nonnull placementId);

/// Safely adds |object| to |set| if |object| is not nil.
void GADMAdapterVungleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

@interface GADMAdapterVungleUtils : NSObject

+ (nonnull NSString *)findAppID:(nullable NSDictionary *)serverParameters;
+ (nonnull NSString *)findPlacement:(nullable NSDictionary *)serverParameters;

@end
