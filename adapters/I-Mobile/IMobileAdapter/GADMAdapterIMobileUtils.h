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

#import <GoogleMobileAds/GoogleMobileAds.h>
#import <ImobileSdkAds/ImobileSdkAds.h>

#import "GADMediationAdapterIMobile.h"

#define GADMAdapterIMobileLog(format, args...) NSLog(@"IMobileAdapter: " format, ##args)

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterIMobileErrorWithCodeAndDescription(GADMAdapterIMobileErrorCode code,
                                                                NSString *_Nonnull description);

/// Returns an i-mobile SDK specific NSError object from the specified |failResult|
/// and with NSLocalizedDescriptionKey and NSLocalizedFailureReasonErrorKey
/// values set to |description|.
NSError *_Nonnull GADMAdapterIMobileErrorWithFailResultAndDescription(
    ImobileSdkAdsFailResult failResult, NSString *_Nonnull description);

/// Sets |value| for |key| in mapTable if |value| is not nil.
void GADMAdapterIMobileMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                               id<NSCopying> _Nullable key, id _Nullable value);

/// Removes the object for |key| in mapTable if |key| is not nil.
void GADMAdapterIMobileMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable, id _Nullable key);

/// Converts ad size from Google Mobile Ads SDK to ad size supported by i-mobile ad network.
GADAdSize GADMAdapterIMobileAdSizeFromGADAdSize(GADAdSize gadAdSize);
