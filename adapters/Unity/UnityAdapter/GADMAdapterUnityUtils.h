// Copyright 2020 Google Inc.
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

#import "GADMediationAdapterUnity.h"
#import <UnityAds/UnityAds.h>

/// Safely adds |object| to |set| if the |object| is not nil.
void GADMAdapterUnityMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

void GADMUnityConfigureMediationService(void);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorCode code,
                                                              NSString *_Nonnull description);

/// Returns an NSError with error |error| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |message|.
NSError *_Nonnull GADMAdapterUnitySDKErrorWithUnityAdsErrorAndMessage(UnityAdsError errorCode,
                                                                      NSString *_Nonnull message);
