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
#import "GADMediationAdapterTapjoy.h"

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterTapjoyMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Adds |object| to |array| if |object| is not nil.
void GADMAdapterTapjoyMutableArrayAddObject(NSMutableArray *_Nullable array,
                                            NSObject *_Nonnull object);

/// Removes |object| from |array| if |object| is not nil.
void GADMAdapterTapjoyMutableArrayRemoveObject(NSMutableArray *_Nullable array,
                                               NSObject *_Nonnull object);

/// Sets |value| for |key| in mapTable if |key| and |value| are not nil.
void GADMAdapterTapjoyMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                              id<NSCopying> _Nullable key, id _Nullable value);

/// Removes the object for |key| in mapTable if |key| is not nil.
void GADMAdapterTapjoyMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key);

/// Sets |value| for |key| in |dictionary| if |key| and |value| are not nil.
void GADMAdapterTapjoyMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                       id<NSCopying> _Nullable key,
                                                       id _Nullable value);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterTapjoyErrorWithCodeAndDescription(GADMAdapterTapjoyErrorCode code,
                                                               NSString *_Nonnull description);

/// Returns a dictionary of the auction data from a specified ad response.
NSDictionary<NSString *, id> *_Nonnull GADMAdapterTapjoyAuctionDataForResponseData(
    NSDictionary<id, id> *_Nullable responseData);
