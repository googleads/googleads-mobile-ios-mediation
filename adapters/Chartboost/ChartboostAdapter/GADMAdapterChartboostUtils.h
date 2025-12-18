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

#if __has_include(<ChartboostSDK/ChartboostSDK.h>)
#import <ChartboostSDK/ChartboostSDK.h>
#else
#import "ChartboostSDK.h"
#endif
#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import "ChartboostAdapter.h"
#import "GADMediationAdapterChartboost.h"

#define SYSTEM_VERSION_LESS_THAN(v)                    \
  ([[[UIDevice currentDevice] systemVersion] compare:v \
                                             options:NSNumericSearch] == NSOrderedAscending)

/// Sets |value| for |key| in |dictionary| if |value| is not nil.
void GADMAdapterChartboostMutableDictionarySetObjectForKey(NSMutableDictionary *_Nonnull dictionary,
                                                           id<NSCopying> _Nullable key,
                                                           id _Nullable value);

/// Adds |object| to |array| if |object| is not nil.
void GADMAdapterChartboostMutableArrayAddObject(NSMutableArray *_Nullable array,
                                                NSObject *_Nonnull object);

/// Removes the object for |key| in mapTable if |key| is not nil.
void GADMAdapterChartboostMapTableRemoveObjectForKey(NSMapTable *_Nullable mapTable,
                                                     id _Nullable key);

/// Sets |value| for |key| in |mapTable| if |value| is not nil.
void GADMAdapterChartboostMapTableSetObjectForKey(NSMapTable *_Nonnull mapTable,
                                                  id<NSCopying> _Nullable key, id _Nullable value);

/// Returns a valid Chartboost ad location string from the given |connector|.
NSString *_Nonnull GADMAdapterChartboostLocationFromConnector(
    id<GADMAdNetworkConnector> _Nonnull connector);

/// Returns a valid Chartboost ad location string from the given ad configuration.
NSString *_Nonnull GADMAdapterChartboostLocationFromAdConfiguration(
    GADMediationAdConfiguration *_Nonnull adConfiguration);

/// Creates and returns a Chartboost mediation object.
CHBMediation *_Nonnull GADMAdapterChartboostMediation(void);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterChartboostErrorWithCodeAndDescription(
    GADMAdapterChartboostErrorCode code, NSString *_Nonnull description);

/// Checks whether the user provided consent to a Google Ad Tech Provider (ATP) in Google’s
/// Additional Consent technical specification. For more details, see [Google’s Additional Consent
/// technical specification](https://support.google.com/admob/answer/9681920).
///
/// Returns `GADMAdapterChartboostConsentResultUnknown` if GDPR does not apply or if positive or
/// negative consent was not explicitly detected.
///
/// Parameters
/// - `vendorId`: a Google Ad Tech Provider (ATP) ID from [Additional Consent
/// Providers](https://storage.googleapis.com/tcfac/additional-consent-providers.csv).
///
/// Returns: A `GADMAdapterChartboostConsentResult` indicating consent for the given ATP.
GADMAdapterChartboostConsentResult GADMAdapterChartboostHasACConsent(NSInteger vendorId);

/// Returns the closest CHBBannerSize size from the requested GADAdSize.
CHBBannerSize GADMAdapterChartboostBannerSizeFromAdSize(
    GADAdSize gadAdSize, NSError *_Nullable __autoreleasing *_Nullable error);
