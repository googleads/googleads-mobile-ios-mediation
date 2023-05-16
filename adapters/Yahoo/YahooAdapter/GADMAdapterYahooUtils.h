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
#import "GADMediationAdapterYahoo.h"

/// Safely adds |object| to |set| if |object| is not nil.
void GADMAdapterYahooMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Initializes Yahoo Mobile SDK with the provided site ID.
BOOL GADMAdapterYahooInitializeYASAdsWithSiteID(NSString *_Nullable siteID);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterYahooErrorWithCodeAndDescription(GADMAdapterYahooErrorCode code,
                                                              NSString *_Nonnull description);

/// Retrieves a supported ad size for a given requested ad size.
CGSize GADMAdapterYahooSupportedAdSizeFromRequestedSize(GADAdSize adSize);
