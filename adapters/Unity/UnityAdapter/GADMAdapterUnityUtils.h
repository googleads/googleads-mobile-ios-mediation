// Copyright 2020 Google LLC.
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
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <UnityAds/UnityAds.h>
#import "GADMAdapterUnityConstants.h"
#import "GADMediationAdapterUnity.h"

/// Configures metadata needed by Unity Ads SDK before initialization.
void GADMAdapterUnityConfigureMediationService(void);

/// Safely adds |object| to |set| if |object| is not nil.
void GADMAdapterUnityMutableArrayAddObject(NSMutableArray *_Nullable array,
                                           NSObject *_Nonnull object);

/// Adds |object| to |set| if |object| is not nil.
void GADMAdapterUnityMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterUnityErrorWithCodeAndDescription(GADMAdapterUnityErrorCode code,
                                                              NSString *_Nonnull description);

/// Returns an NSError with error |error| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |message|.
NSError *_Nonnull GADMAdapterUnitySDKErrorWithUnityAdsShowErrorAndMessage(
    UnityAdsShowError errorCode, NSString *_Nonnull message);

/// Find closest supported ad size from a given ad size.
GADAdSize supportedAdSizeFromRequestedSize(GADAdSize gadAdSize);

/// Returns GADVersionNumber created from string
GADVersionNumber extractVersionFromString(NSString *_Nonnull string);
