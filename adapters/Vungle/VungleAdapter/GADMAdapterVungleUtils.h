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
#import <VungleSDK/VungleSDK.h>
#import "GADMediationAdapterVungle.h"
#import "VungleAdNetworkExtras.h"

/// Safely adds |object| to |set| if |object| is not nil.
void GADMAdapterVungleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Safely sets |value| for |key| in mapTable if |value| is not nil.
void GADMAdapterVungleMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                              id<NSCopying> _Nullable key, id _Nullable value);

/// Safely removes the |object| for |key| in mapTable if |key| is not nil.
void GADMAdapterVungleMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key);

/// Sets |value| for |key| in |dictionary| if |value| is not nil.
void GADMAdapterVungleMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                       id<NSCopying> _Nullable key,
                                                       id _Nullable value);

/// Safely removes the |object| for |key| in userDefaults if |key| is not nil.
void GADMAdapterVungleUserDefaultsRemoveObjectForKey(NSUserDefaults *_Nonnull userDefaults,
                                                     id _Nullable key);

/// Removes the object for |key| in |dictionary| if |key| is not nil.
void GADMAdapterVungleMutableDictionaryRemoveObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                          id<NSCopying> _Nullable key);

/// Return a dictionary of Vungle ad playback options.
NSDictionary *_Nullable GADMAdapterVunglePlaybackOptionsDictionaryForExtras(
    VungleAdNetworkExtras *_Nullable vungleAdNetworkExtras);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorCode code,
                                                               NSString *_Nonnull description);

/// Returns a VungleAdSize object from the specified adSize
VungleAdSize GADMAdapterVungleAdSizeForCGSize(CGSize adSize);

@interface GADMAdapterVungleUtils : NSObject

+ (nullable NSString *)findAppID:(nullable NSDictionary *)serverParameters;
+ (nullable NSString *)findPlacement:(nullable NSDictionary *)serverParameters
                       networkExtras:(nullable VungleAdNetworkExtras *)networkExtras;

@end
