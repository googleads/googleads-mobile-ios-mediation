// Copyright 2022 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMediationAdapterPangle.h"

#define GADMPangleLog(format, args...) NSLog(@"GADMediationAdapterPangle: " format, ##args)

NSError *_Nonnull GADMAdapterPangleErrorWithCodeAndDescription(GADPangleErrorCode code,
                                                               NSString *_Nonnull description);

NSError *_Nonnull GADMAdapterPangleChildUserError(void);

void GADMAdapterPangleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Checks whether the user provided consent to a Google Ad Tech Provider (ATP) in Google’s
/// Additional Consent technical specification. For more details, see [Google’s Additional Consent
/// technical specification](https://support.google.com/admob/answer/9681920).
///
/// Returns `GADMAdapterPangleConsentResultUnknown` if GDPR does not apply or if positive or
/// negative consent was not explicitly detected.
///
/// Parameters
/// - `vendorId`: a Google Ad Tech Provider (ATP) ID from [Additional Consent
/// Providers](https://storage.googleapis.com/tcfac/additional-consent-providers.csv).
///
/// Returns: A `GADMAdapterPangleConsentResult` indicating consent for the given ATP.
GADMAdapterPangleConsentResult GADMAdapterPangleHasACConsent(NSInteger vendorId);

@interface GADMAdapterPangleUtils : NSObject

+ (BOOL)isChildUser;

@end
