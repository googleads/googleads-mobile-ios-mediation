// Copyright 2019 Google LLC.
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

#import "GADMediationAdapterMaio.h"

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterMaioMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Adds |object| to |array| if |object| is not nil.
void GADMAdapterMaioMutableArrayAddObject(NSMutableArray *_Nullable array,
                                          NSObject *_Nonnull object);

/// Removes the object for |key| in mapTable if |key| is not nil.
void GADMAdapterMaioMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key);

/// Sets |value| for |key| in |mapTable| if |value| is not nil.
void GADMAdapterMaioMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                            id<NSCopying> _Nullable key, id _Nullable value);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterMaioErrorWithCodeAndDescription(
    GADMAdapterMaioErrorCode *_Nonnull code, NSString *_Nonnull description);
