// Copyright 2015 Google LLC
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
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "GADMediationAdapterInMobi.h"

/// Adds |object| to |array| if |object| is not nil.
void GADMAdapterInMobiMutableArrayAddObject(NSMutableArray *_Nullable array,
                                            NSObject *_Nonnull object);

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterInMobiMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Sets |value| for |key| in mapTable if |key| and |value| are not nil.
void GADMAdapterInMobiMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                              id<NSCopying> _Nullable key, id _Nullable value);

/// Removes the object for |key| in mapTable if |key| is not nil.
void GADMAdapterInMobiMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key);

/// Sets |value| for |key| in |dictionary| if |key| and |value| are not nil.
void GADMAdapterInMobiMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                       id<NSCopying> _Nullable key,
                                                       id _Nullable value);

/// Sets |value| for |key| in |cache| if |key| and |value| are not nil.
void GADMAdapterInMobiCacheSetObjectForKey(NSCache *_Nonnull cache, id<NSCopying> _Nullable key,
                                           id _Nullable value);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterInMobiErrorWithCodeAndDescription(GADMAdapterInMobiErrorCode code,
                                                               NSString *_Nonnull description);

/// Validates the placement identifier obtained from the Google Mobile Ads SDK.
NSError *_Nullable GADMAdapterInMobiValidatePlacementIdentifier(
    NSNumber *_Nonnull placementIdentifier);

/// Sets up InMobi targetting information from the specified ad configuration.
void GADMAdapterInMobiSetTargetingFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfig);

/// Creates InMobi request parameters from the specified ad configuration.
NSDictionary<NSString *, id> *_Nonnull GADMAdapterInMobiCreateRequestParametersFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfig);

/// Logs with GADMediationAdapterInMobi Prefix.
void GADMAdapterInMobiLog(NSString *_Nonnull format, ...);

/// Forwards U.S. Privacy String set in NSUserDefaults to InMobi SDK.
void GADMAdapterInMobiSetUSPrivacyCompliance(void);
