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
#import "GADMediationAdapterVungle.h"
#import "VungleAdNetworkExtras.h"
#import <VungleAdsSDK/VungleAdsSDK.h>

/// Return a dictionary of Vungle ad playback options.
NSDictionary *_Nullable GADMAdapterVunglePlaybackOptionsDictionaryForExtras(
    VungleAdNetworkExtras *_Nullable vungleAdNetworkExtras);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorCode code,
                                                               NSString *_Nonnull description);

@interface GADMAdapterVungleUtils : NSObject

+ (nullable NSString *)findAppID:(nullable NSDictionary *)serverParameters;
+ (nullable NSString *)findPlacement:(nullable NSDictionary *)serverParameters
                       networkExtras:(nullable VungleAdNetworkExtras *)networkExtras;

@end
