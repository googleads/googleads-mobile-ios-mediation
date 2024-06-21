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

/// Adapter version string.
static NSString *const GADMAdapterInMobiVersion = @"10.7.4.0";

/// InMobi SDK key.
static NSString *const GADMAdapterInMobiAccountID = @"accountid";

/// InMobi placement identifier.
static NSString *const GADMAdapterInMobiPlacementID = @"placementid";

/// InMobi adapter error domain.
static NSString *const GADMAdapterInMobiErrorDomain = @"com.google.mediation.inmobi";

/// IAB U.S. Privacy string key.
static NSString *const GADMAdapterInMobiIABUSPrivacyString = @"IABUSPrivacy_String";

/// Key for the InMobi request parameters SDK version.
static NSString *const GADMAdapterInMobiRequestParametersSDKVersionKey = @"tp-ver";

/// Key for the InMobi request parameters mediation type.
static NSString *const GADMAdapterInMobiRequestParametersMediationTypeKey = @"tp";

/// Key for the InMobi request parameters COPPA.
static NSString *const GADMAdapterInMobiRequestParametersCOPPAKey = @"coppa";

/// Type of InMobi mediation.
typedef NSString *GADMAdapterInMobiRequestParametersMediationType NS_TYPED_ENUM;

/// InMobi waterfall mediation type.
static GADMAdapterInMobiRequestParametersMediationType const
    GADMAdapterInMobiRequestParametersMediationTypeWaterfall = @"c_admob";

/// InMobi RTB mediation type.
static GADMAdapterInMobiRequestParametersMediationType const
    GADMAdapterInMobiRequestParametersMediationTypeRTB = @"c_google";
