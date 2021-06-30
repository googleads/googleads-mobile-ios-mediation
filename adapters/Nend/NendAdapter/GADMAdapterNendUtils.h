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
#import <GADMediationAdapterNend.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#import <NendAd/NADInterstitial.h>

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterNendErrorWithCodeAndDescription(GADMAdapterNendErrorCode code,
                                                             NSString *_Nonnull description);

/// Returns a generic Nend load error.
NSError *_Nonnull GADMAdapterNendSDKLoadError(void);

/// Returns a generic Nend presentation error.
NSError *_Nonnull GADMAdapterNendSDKPresentError(void);

/// Returns an NSError for result |result|.
NSError *_Nonnull GADMAdapterNendErrorForShowResult(NADInterstitialShowResult result);
