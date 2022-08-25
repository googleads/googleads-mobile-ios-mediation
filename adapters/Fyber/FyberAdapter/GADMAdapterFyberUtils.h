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
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <IASDKCore/IASDKCore.h>
#import "GADMediationAdapterFyber.h"

#define GADMAdapterFyberLog(format, args...) NSLog(@"FyberAdapter: " format, ##args)

// Fyber adapter initialization completion handler.
typedef void (^GADMAdapterFyberInitCompletionHandler)(NSError *_Nullable error);

/// Safely adds |object| to |array| if |object| is not nil.
void GADMAdapterFyberMutableArrayAddObject(NSMutableArray *_Nullable array,
                                           NSObject *_Nonnull object);

/// Safely adds |object| to |set| if |object| is not nil.
void GADMAdapterFyberMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

/// Returns an NSError with code |code| and with NSLocalizedDescriptionKey and
/// NSLocalizedFailureReasonErrorKey values set to |description|.
NSError *_Nonnull GADMAdapterFyberErrorWithCodeAndDescription(GADMAdapterFyberErrorCode code,
                                                              NSString *_Nonnull description);

/// Creates and returns a GADVersionNumber from a specified string.
GADVersionNumber GADMAdapterFyberVersionFromString(NSString *_Nonnull versionString);

/// Creates an ad request object for Fyber from a given spot ID and configuration.
IAAdRequest *_Nonnull GADMAdapterFyberBuildRequestWithSpotIDAndAdConfiguration(
    NSString *_Nonnull spotID, GADMediationAdConfiguration *_Nonnull adConfiguration);

/// Initialize the Fyber Marketplace SDK with a given application ID and completion handler.
void GADMAdapterFyberInitializeWithAppId(
    NSString *_Nonnull appID, GADMAdapterFyberInitCompletionHandler _Nonnull completionHandler);
