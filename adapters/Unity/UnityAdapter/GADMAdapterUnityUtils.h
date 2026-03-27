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

#define GADMUnityLog(format, args...) NSLog(@"GADMediationAdapterUnity: " format, ##args)

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

/// Returns an NSError with Unity Ads SDK load error |loadError| and with NSLocalizedDescriptionKey
/// and NSLocalizedFailureReasonErrorKey values set to |message|.
NSError *_Nonnull GADMAdapterUnitySDKErrorWithUnityAdsLoadErrorAndMessage(
    UnityAdsLoadError loadError, NSString *_Nonnull message);

/// Checks whether the user provided consent to a Google Ad Tech Provider (ATP) in Google’s
/// Additional Consent technical specification. For more details, see [Google’s Additional Consent
/// technical specification](https://support.google.com/admob/answer/9681920).
///
/// Returns `GADMAdapterUnityConsentResultUnknown` if GDPR does not apply or if positive or negative
/// consent was not explicitly detected.
///
/// Parameters
/// - `vendorId`: a Google Ad Tech Provider (ATP) ID from [Additional Consent
/// Providers](https://storage.googleapis.com/tcfac/additional-consent-providers.csv).
///
/// Returns: A `GADMAdapterUnityConsentResult` indicating consent for the given ATP.
GADMAdapterUnityConsentResult GADMAdapterUnityHasACConsent(NSInteger vendorId);

/// Returns GADVersionNumber created from string
GADVersionNumber extractVersionFromString(NSString *_Nonnull string);
